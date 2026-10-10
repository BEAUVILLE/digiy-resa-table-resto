-- V9: real server guard, RLS lock, PAY-neutral owner actions on a
-- synthetic booking created by the V8 exercise. PG17 disposable ONLY.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V9 owner acceptance only on throwaway PG17';
 END IF;
END $guard$;
-- Once a professional has been approved and activated for the fixture,
-- client adds pending. Pilot was disabled at the end of V8 acceptance.
DO $checks$
BEGIN
 IF (SELECT count(*) FROM public.digiy_resa_bookings
  WHERE client_request_id='c8000000-0000-4000-8000-000000000001'
  AND status='pending')<>1 THEN
  RAISE EXCEPTION 'expected synthetic pending booking missing';
 END IF;
 IF (SELECT count(*) FROM public.test_pay_side_effects)<>0 THEN
  RAISE EXCEPTION 'PAY side effect before confirmation';
 END IF;
END $checks$;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $owner_a$
DECLARE v_id uuid; v_count integer;v_result jsonb;
BEGIN
 SELECT id INTO v_id FROM public.digiy_resa_bookings
 WHERE client_request_id='c8000000-0000-4000-8000-000000000001';
 -- Old cockpit can still UPDATE legacy rows, not V0 booking.
 UPDATE public.digiy_resa_bookings
 SET status='confirmed' WHERE id=v_id;
 GET DIAGNOSTICS v_count=ROW_COUNT;
 IF v_count<>0 THEN
  RAISE EXCEPTION 'RLS allows owner to bypass V5 for a new booking';
 END IF;
 v_result:=public.digiy_resa_universal_owner_manage_v2(v_id,'note','Privé V9');
 IF v_result->>'ok'<>'true' OR v_result->>'status'<>'pending' THEN
  RAISE EXCEPTION 'V5 owner note failed: %',v_result;
 END IF;
 v_result:=public.digiy_resa_universal_owner_manage_v2(v_id,'confirmed',NULL);
 IF v_result->>'ok'<>'true' OR v_result->>'status'<>'confirmed' THEN
  RAISE EXCEPTION 'V5 owner A confirmation failed: %',v_result;
 END IF;
END $owner_a$;
COMMIT;
DO $financial$
BEGIN
 IF (SELECT count(*) FROM public.test_pay_side_effects)<>0 THEN
  RAISE EXCEPTION 'confirmed new appointment generated fake PAY income';
 END IF;
END $financial$;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $owner_b$
DECLARE v_id uuid;v_result jsonb;
BEGIN
 -- B cannot see A's customer or note directly, but even known UUID must be denied.
 SELECT id INTO v_id FROM public.digiy_resa_bookings
 WHERE client_request_id='c8000000-0000-4000-8000-000000000001';
 IF v_id IS NOT NULL THEN
  RAISE EXCEPTION 'Owner B can read Owner A personal booking data';
 END IF;
 v_result:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v9_client_booking',true)::uuid,'cancelled',NULL);
 IF v_result->>'error'<>'not_found_or_forbidden' THEN
  RAISE EXCEPTION 'Owner B was allowed to cancel A: %',v_result;
 END IF;
END $owner_b$;
COMMIT;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $owner_a_cancel$
DECLARE v_result jsonb;
BEGIN
 v_result:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v9_client_booking',true)::uuid,'cancelled',NULL);
 IF v_result->>'ok'<>'true' OR v_result->>'status'<>'cancelled' THEN
  RAISE EXCEPTION 'Owner A could not cancel and release: %',v_result;
 END IF;
END $owner_a_cancel$;
COMMIT;
DO $final$
DECLARE v_booked integer;v_pay integer;v_old integer;
BEGIN
 SELECT count(*) INTO v_booked FROM public.digiy_resa_bookings
 WHERE client_request_id='c8000000-0000-4000-8000-000000000001'
 AND status='cancelled';
 SELECT count(*) INTO v_old FROM public.digiy_resa_bookings
 WHERE client_request_id IS NULL;
 SELECT count(*) INTO v_pay FROM public.test_pay_side_effects;
 IF v_booked<>1 OR v_old<>2 OR v_pay<>0 THEN
  RAISE EXCEPTION 'V9 final after cancel wrong: new % old % pay %',
   v_booked,v_old,v_pay;
 END IF;
 RAISE NOTICE 'PASS: legacy data preserved, RLS direct UPDATE denied for V0, owner A works, B denied, status confirmed triggers no PAY, cancellation frees';
END $final$;
