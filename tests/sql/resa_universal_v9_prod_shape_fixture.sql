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
