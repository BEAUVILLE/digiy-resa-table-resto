-- Delete only the isolated public-options overlay. Never on digiy-core.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'public options rollback forbidden outside disposable test DB';
 END IF;
END $guard$;
DROP FUNCTION IF EXISTS public.digiy_resa_universal_public_options_v1(text,date);
ALTER TABLE public.digiy_resa_profiles DROP COLUMN IF EXISTS time_zone;
DO $verify$
BEGIN
 IF to_regprocedure('public.digiy_resa_universal_public_options_v1(text,date)') IS NOT NULL THEN
  RAISE EXCEPTION 'public options function survived rollback';
 END IF;
 IF to_regprocedure('public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)') IS NULL THEN
  RAISE EXCEPTION 'the existing isolated booking function was unexpectedly removed';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings WHERE client_request_id IS NULL)<1 THEN
  RAISE EXCEPTION 'historical synthetic reservations lost on rollback';
 END IF;
 RAISE NOTICE 'PASS: public-options-only rollback; V0 and historic reservations preserved';
END $verify$;
