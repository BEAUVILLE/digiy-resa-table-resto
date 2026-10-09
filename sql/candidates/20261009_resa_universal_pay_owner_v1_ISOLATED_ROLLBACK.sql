-- DISPOSABLE PG ONLY, undo the isolated PAY/owner V1 overlay.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V1 rollback only in disposable test DB';
 END IF;
END $guard$;
DROP FUNCTION IF EXISTS public.digiy_resa_universal_owner_status_v1(uuid,text);
DROP TRIGGER IF EXISTS digiy_resa_push_to_pay_after_status
ON public.digiy_resa_bookings;
DROP FUNCTION IF EXISTS public.trg_digiy_resa_push_to_pay();
DROP FUNCTION IF EXISTS public.digiy_resa_push_to_pay(uuid);
-- Restore solely synthetic test fixture's old broad privileges for rollback.
GRANT UPDATE ON public.digiy_resa_bookings TO authenticated;
DO $verify$
BEGIN
 IF to_regprocedure('public.digiy_resa_universal_owner_status_v1(uuid,text)') IS NOT NULL
    OR to_regprocedure('public.trg_digiy_resa_push_to_pay()') IS NOT NULL
 THEN RAISE EXCEPTION 'V1 overlay not rolled back'; END IF;
 RAISE NOTICE 'PASS: isolated PAY/owner V1 candidate rolled back';
END $verify$;
