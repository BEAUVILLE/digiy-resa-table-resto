-- V5 rollback limited to the disposable owner-management overlay.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'RÉSA V5 rollback forbidden outside disposable database';
 END IF;
END $guard$;

DROP FUNCTION IF EXISTS public.digiy_resa_universal_owner_manage_v2(uuid,text,text);

DO $verify$
BEGIN
 IF to_regprocedure('public.digiy_resa_universal_owner_manage_v2(uuid,text,text)') IS NOT NULL THEN
  RAISE EXCEPTION 'V5 owner-management function survived rollback';
 END IF;
 IF to_regprocedure('public.digiy_resa_universal_owner_status_v1(uuid,text)') IS NULL THEN
  RAISE EXCEPTION 'V1 protected owner function unexpectedly lost';
 END IF;
 IF to_regprocedure('public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)') IS NULL THEN
  RAISE EXCEPTION 'V0 booking function unexpectedly lost';
 END IF;
 -- Rollback is run in a separate psql process from the assertions, so
 -- use the fixture's known count instead of relying on a session-local GUC.
 IF (SELECT count(*) FROM public.digiy_resa_bookings WHERE client_request_id IS NULL)
  <>2 THEN
  RAISE EXCEPTION 'synthetic legacy rows not preserved on V5 rollback';
 END IF;
 RAISE NOTICE 'PASS: V5 owner RPC removed; V0/V1, PAY and legacy still intact';
END $verify$;
