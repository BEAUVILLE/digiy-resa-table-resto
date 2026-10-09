-- ISOLATED ROLLBACK TEST ONLY: DO NOT RUN ON digiy-core.
-- For a future real deployment, retain idempotency history and perform
-- audited data migration. This is only for a disposable test database.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'Refusing V0 rollback outside disposable test DB';
 END IF;
END $guard$;
DROP FUNCTION IF EXISTS public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid);
ALTER TABLE public.digiy_resa_bookings
 DROP CONSTRAINT IF EXISTS digiy_resa_universal_no_overlap_v0;
DROP INDEX IF EXISTS public.digiy_resa_universal_idempotency_v0;
ALTER TABLE public.digiy_resa_bookings
 DROP COLUMN IF EXISTS client_request_id;
DO $verify$
BEGIN
 IF to_regprocedure('public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)') IS NOT NULL
  OR EXISTS (
   SELECT 1 FROM information_schema.columns
   WHERE table_schema='public' AND table_name='digiy_resa_bookings'
     AND column_name='client_request_id'
  ) THEN
   RAISE EXCEPTION 'candidate schema rollback failed';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings WHERE id IN (
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
 ))<>2 THEN RAISE EXCEPTION 'legacy fixture records lost'; END IF;
 RAISE NOTICE 'PASS: isolated candidate structures reversed; legacy records intact';
END $verify$;
