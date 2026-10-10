-- RÉSA UNIVERSAL V5: narrowly-scoped owner actions and PRIVATE notes.
-- CANDIDATE: PostgreSQL 17 throwaway database only, never digiy-core.
-- Depends on isolated V0 and PAY-neutral owner V1 fixtures.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'RÉSA V5 owner actions restricted to disposable database';
 END IF;
 IF to_regprocedure('public.digiy_resa_universal_owner_status_v1(uuid,text)') IS NULL
 OR to_regprocedure('public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)') IS NULL THEN
  RAISE EXCEPTION 'RÉSA V0+V1 isolated contracts required';
 END IF;
END $guard$;

-- Real CORE has updated_at; fixture adds it only for a representative test.
CREATE OR REPLACE FUNCTION public.digiy_resa_universal_owner_manage_v2(
 p_booking_id uuid,
 p_action text,
 p_note_text text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog,public
AS $action$
DECLARE
 v_uid uuid := auth.uid();
 v_booking public.digiy_resa_bookings%ROWTYPE;
 v_action text := lower(btrim(coalesce(p_action,'')));
 v_note text;
BEGIN
 IF v_uid IS NULL THEN
  RETURN jsonb_build_object('ok',false,'error','authentication_required');
 END IF;
 IF p_booking_id IS NULL OR
    v_action NOT IN ('note','confirmed','cancelled','done','no_show') THEN
  RETURN jsonb_build_object('ok',false,'error','invalid_request');
 END IF;
 -- Notes never accompany status transitions; distinct operations prevent
 -- inadvertent note overwrite or status change through a single payload.
 IF v_action <> 'note' AND p_note_text IS NOT NULL THEN
  RETURN jsonb_build_object('ok',false,'error','unexpected_note');
 END IF;
 IF v_action='note' THEN
  IF char_length(coalesce(p_note_text,'')) > 1000 THEN
   RETURN jsonb_build_object('ok',false,'error','note_too_long');
  END IF;
  v_note := nullif(btrim(coalesce(p_note_text,'')),'');
 END IF;

 -- Lock exactly this row AND prove identity via immutable server-side owner
 -- relation. Legacy requests (without client_request_id) deliberately excluded.
 SELECT b.* INTO v_booking
 FROM public.digiy_resa_bookings b
 WHERE b.id=p_booking_id
   AND b.client_request_id IS NOT NULL
   AND EXISTS (
     SELECT 1
     FROM public.digiy_resa_profiles p
     WHERE p.slug=b.slug
       AND p.is_active IS TRUE
       AND p.auth_user_id=v_uid
   )
 FOR UPDATE;
 IF NOT FOUND THEN
  RETURN jsonb_build_object('ok',false,'error','not_found_or_forbidden');
 END IF;

 IF v_action='note' THEN
  UPDATE public.digiy_resa_bookings
  SET note_text=v_note,updated_at=clock_timestamp()
  WHERE id=v_booking.id;
  RETURN jsonb_build_object('ok',true,'booking_id',v_booking.id,
    'action','note','status',v_booking.status);
 END IF;
 IF NOT (
  (v_booking.status='pending' AND v_action IN ('confirmed','cancelled')) OR
  (v_booking.status='confirmed' AND v_action IN ('cancelled','done','no_show'))
 ) THEN
  RETURN jsonb_build_object('ok',false,'error','invalid_transition');
 END IF;
 UPDATE public.digiy_resa_bookings
 SET status=v_action,updated_at=clock_timestamp()
 WHERE id=v_booking.id;
 RETURN jsonb_build_object('ok',true,'booking_id',v_booking.id,
  'action',v_action,'status',v_action);
END
$action$;

-- Supabase PostgREST must never expose this SECURITY DEFINER to anonymous API.
REVOKE ALL ON FUNCTION public.digiy_resa_universal_owner_manage_v2(uuid,text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.digiy_resa_universal_owner_manage_v2(uuid,text,text)
 TO authenticated;
