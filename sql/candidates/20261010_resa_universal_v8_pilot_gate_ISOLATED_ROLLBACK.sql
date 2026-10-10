-- DISPOSABLE ONLY: undo the V8 launch gate without touching historic fixture.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V8 rollback forbidden outside disposable database';
 END IF;
END $guard$;
DROP FUNCTION IF EXISTS public.digiy_resa_universal_request_v1(text,uuid,uuid,text,text,uuid);
DROP FUNCTION IF EXISTS public.digiy_resa_universal_pilot_gate_v1(text);
DROP TABLE IF EXISTS public.digiy_resa_universal_launch_controls;
-- Restore pre-V8 fixture access for the preceding V0 candidate rollback tests.
GRANT EXECUTE ON FUNCTION public.digiy_resa_universal_request_v0(
 text,uuid,uuid,text,text,uuid) TO anon,authenticated;
DO $verify$
BEGIN
 IF to_regprocedure('public.digiy_resa_universal_request_v1(text,uuid,uuid,text,text,uuid)') IS NOT NULL
 OR to_regprocedure('public.digiy_resa_universal_pilot_gate_v1(text)') IS NOT NULL
 OR to_regclass('public.digiy_resa_universal_launch_controls') IS NOT NULL THEN
  RAISE EXCEPTION 'V8 isolated rollback incomplete';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings WHERE client_request_id IS NULL)<>2 THEN
  RAISE EXCEPTION 'V8 rollback altered synthetic historical requests';
 END IF;
 RAISE NOTICE 'PASS: V8 isolated rollback; legacy requests preserved';
END $verify$;
