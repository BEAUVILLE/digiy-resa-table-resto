-- PG17 throwaway test stand-in for LIVE digiy_resa_push_to_pay.
-- Execute only AFTER V0 SQL assertions + concurrent clients and BEFORE
-- 20261009_resa_universal_pay_owner_v1_ISOLATED.sql.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'fixture may only run in disposable PG';
 END IF;
END $guard$;

-- Undo the original V0 simple PAY test trigger; replace it with a fixture that
-- preserves the real call graph: AFTER UPDATE -> trg -> digiy_resa_push_to_pay.
DROP TRIGGER IF EXISTS test_pay_guard ON public.digiy_resa_bookings;
DROP FUNCTION IF EXISTS public.test_pay_trigger();
TRUNCATE TABLE public.test_pay_side_effects;
CREATE OR REPLACE FUNCTION public.digiy_resa_push_to_pay(p_booking_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public
AS $pay$
BEGIN
 INSERT INTO public.test_pay_side_effects DEFAULT VALUES;
 RETURN jsonb_build_object('ok',true,'booking_id',p_booking_id);
END $pay$;

GRANT USAGE ON SCHEMA public TO anon,authenticated;
GRANT SELECT,UPDATE ON public.digiy_resa_bookings TO authenticated;
ALTER TABLE public.digiy_resa_bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner A/B read only own bookings fixture" ON public.digiy_resa_bookings
FOR SELECT TO authenticated
USING (EXISTS (
 SELECT 1 FROM public.digiy_resa_profiles p
 WHERE p.slug=digiy_resa_bookings.slug AND p.is_active IS TRUE
 AND p.auth_user_id=auth.uid()
));
CREATE POLICY "owner A/B legacy update policy fixture" ON public.digiy_resa_bookings
FOR UPDATE TO authenticated
USING (EXISTS (
 SELECT 1 FROM public.digiy_resa_profiles p
 WHERE p.slug=digiy_resa_bookings.slug AND p.is_active IS TRUE
 AND p.auth_user_id=auth.uid()
))
WITH CHECK (EXISTS (
 SELECT 1 FROM public.digiy_resa_profiles p
 WHERE p.slug=digiy_resa_bookings.slug AND p.is_active IS TRUE
 AND p.auth_user_id=auth.uid()
));
