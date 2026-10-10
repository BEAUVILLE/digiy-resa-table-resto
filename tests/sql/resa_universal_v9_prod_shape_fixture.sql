-- Representative LEGACY production shape before the production release.
-- THROWAWAY fixture only. Does NOT connect to digiy-core.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'Cannot prepare production-shape fixture on live DB';
 END IF;
END $guard$;
ALTER POLICY "owner A/B legacy update policy fixture"
 ON public.digiy_resa_bookings
 RENAME TO "RESA owner updates own bookings";
CREATE FUNCTION public.trg_digiy_resa_push_to_pay()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path=public
AS $legacy$
BEGIN
 IF coalesce(lower(OLD.status),'') IS DISTINCT FROM coalesce(lower(NEW.status),'')
 AND lower(coalesce(NEW.status,'')) IN ('confirmed','completed','paid') THEN
  PERFORM public.digiy_resa_push_to_pay(NEW.id);
 END IF;
 RETURN NEW;
END $legacy$;
CREATE TRIGGER digiy_resa_push_to_pay_after_status
AFTER UPDATE OF status ON public.digiy_resa_bookings
FOR EACH ROW EXECUTE FUNCTION public.trg_digiy_resa_push_to_pay();
-- Live 10/10 has no active published RÉSA Universal profile.
UPDATE public.digiy_resa_profiles SET is_published=false;
-- The live CORE also exposes a legacy SECURITY DEFINER client booking RPC.
-- This stub preserves its signature/GRANT in the fixture; the production
-- candidate replaces the body with the verified original plus a pilot veto.
CREATE FUNCTION public.digiy_resa_create_booking(
 p_slug text,p_customer_name text,p_customer_phone text,
 p_booking_date date,p_booking_time time,
 p_guests_count integer,p_note_text text,p_service_id uuid
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public AS $fixture$
BEGIN
 RETURN jsonb_build_object('ok',false,'error','legacy_fixture_not_replaced');
END $fixture$;
