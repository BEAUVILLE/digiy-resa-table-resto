-- RÉSA V9 emergency stop. DO NOT DELETE DATA OR DROP THE CORE FUNCTIONS.
-- Use only after a controlled verified V9 migration; auth user data is retained.
-- Safe to execute in disposable PG17 CI or reviewed DIGIY CORE production.
DO $preflight$
BEGIN
 IF current_database() NOT IN ('postgres','digiy_appointments_test') THEN
  RAISE EXCEPTION 'RÉSA SAFE DISABLE refuses this database';
 END IF;
 IF to_regclass('public.digiy_resa_universal_launch_controls') IS NULL
 OR to_regprocedure('public.digiy_resa_universal_request_v1(text,uuid,uuid,text,text,uuid)') IS NULL THEN
  RAISE EXCEPTION 'RÉSA V9 pilot controls not installed';
 END IF;
END $preflight$;

-- Turn off new bookings for every professional, preserve existing status.
UPDATE public.digiy_resa_universal_launch_controls
SET enabled=false
WHERE enabled IS TRUE;
-- Revoke even on active browsers; old owner management remains available.
REVOKE EXECUTE ON FUNCTION public.digiy_resa_universal_request_v1(
 text,uuid,uuid,text,text,uuid) FROM PUBLIC,anon,authenticated;
-- Do NOT undo the PAY-neutral V0 trigger or the protective direct UPDATE RLS.
-- Do NOT delete client_request_id, GiST history, slots or any patient booking.
DO $verify$
BEGIN
 IF EXISTS(SELECT 1 FROM public.digiy_resa_universal_launch_controls WHERE enabled) OR
    has_function_privilege('anon','public.digiy_resa_universal_request_v1(text,uuid,uuid,text,text,uuid)','EXECUTE') THEN
  RAISE EXCEPTION 'Emergency stop failed; review grants and live state';
 END IF;
END $verify$;
