-- Disposable V3 rollback only; no booking or legacy object changes.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V3 rollback forbidden outside throwaway database';
 END IF;
END $guard$;
DROP FUNCTION IF EXISTS public.digiy_resa_local_time_to_utc_v3(
 timestamp without time zone,text);
DO $check$
BEGIN
 IF to_regprocedure('public.digiy_resa_local_time_to_utc_v3(timestamp without time zone,text)') IS NOT NULL THEN
  RAISE EXCEPTION 'V3 converter unexpectedly survived rollback';
 END IF;
 IF to_regprocedure('public.resa_list_recent_bookings_by_slug(text,integer)') IS NULL THEN
  RAISE EXCEPTION 'legacy function unexpectedly removed';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings)<>2 THEN
  RAISE EXCEPTION 'synthetic historical bookings changed during timezone tests';
 END IF;
 RAISE NOTICE 'PASS: V3 rollback, two historical synthetic bookings preserved';
END $check$;
