-- DIGIY RÉSA UNIVERSEL V1 — PAY + OWNER CONTROLS (ISOLATED ONLY)
-- Intended for a throwaway PG17 service. Never on digiy-core.
-- This deliberately models a possible, tightly scoped fix, NOT an approved
-- production migration. Legacy booking updates keep their previous PAY logic.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'refusing owner/PAY candidate outside disposable DB';
 END IF;
 IF to_regprocedure('public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)') IS NULL THEN
  RAISE EXCEPTION 'install isolated V0 first';
 END IF;
END $guard$;

-- Existing real trigger calls PAY on status=confirmed even when there was
-- no payment. For a booking with a V0 idempotency key, NO financial movement
-- may be inferred from an appointment status change alone.
-- For legacy bookings without an idempotency key, original behavior is kept
-- in the experiment and must be separately audited before production.
CREATE OR REPLACE FUNCTION public.trg_digiy_resa_push_to_pay()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog,public
AS $trigger$
BEGIN
 IF new.client_request_id IS NOT NULL THEN
  RETURN new;
 END IF;
 IF coalesce(lower(old.status),'') IS DISTINCT FROM coalesce(lower(new.status),'')
    AND lower(coalesce(new.status,'')) IN ('confirmed','completed','paid') THEN
  PERFORM public.digiy_resa_push_to_pay(new.id);
 END IF;
 RETURN new;
END
$trigger$;

DROP TRIGGER IF EXISTS digiy_resa_push_to_pay_after_status
 ON public.digiy_resa_bookings;
CREATE TRIGGER digiy_resa_push_to_pay_after_status
AFTER UPDATE OF status ON public.digiy_resa_bookings
FOR EACH ROW EXECUTE FUNCTION public.trg_digiy_resa_push_to_pay();

-- The current live table grants UPDATE to 'authenticated' for ALL columns.
-- In the throwaway test only, prove the safe strategy: revoke broad direct
-- writes and provide a narrow authenticated owner-status RPC.
REVOKE UPDATE ON public.digiy_resa_bookings FROM authenticated;

CREATE OR REPLACE FUNCTION public.digiy_resa_universal_owner_status_v1(
 p_booking_id uuid,p_status text
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog,public
AS $owner$
DECLARE
 v_uid uuid:=auth.uid();
 v_booking public.digiy_resa_bookings%ROWTYPE;
 v_next text:=lower(btrim(coalesce(p_status,'')));
BEGIN
 IF v_uid IS NULL THEN
   RETURN jsonb_build_object('ok',false,'error','authentication_required');
 END IF;
 IF p_booking_id IS NULL OR v_next NOT IN ('confirmed','cancelled','done','no_show') THEN
   RETURN jsonb_build_object('ok',false,'error','invalid_request');
 END IF;
 SELECT * INTO v_booking
 FROM public.digiy_resa_bookings b
 WHERE b.id=p_booking_id AND b.client_request_id IS NOT NULL
   AND EXISTS (
      SELECT 1 FROM public.digiy_resa_profiles p
      WHERE p.slug=b.slug AND p.is_active IS TRUE AND p.auth_user_id=v_uid
   )
 FOR UPDATE;
 IF NOT FOUND THEN
   RETURN jsonb_build_object('ok',false,'error','not_found_or_forbidden');
 END IF;
 IF NOT (
   (v_booking.status='pending' AND v_next IN ('confirmed','cancelled')) OR
   (v_booking.status='confirmed' AND v_next IN ('cancelled','done','no_show'))
 ) THEN
   RETURN jsonb_build_object('ok',false,'error','invalid_transition');
 END IF;
 UPDATE public.digiy_resa_bookings SET status=v_next
 WHERE id=v_booking.id;
 RETURN jsonb_build_object('ok',true,'booking_id',v_booking.id,'status',v_next);
END
$owner$;

REVOKE ALL ON FUNCTION public.digiy_resa_universal_owner_status_v1(uuid,text)
FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.digiy_resa_universal_owner_status_v1(uuid,text)
TO authenticated;
