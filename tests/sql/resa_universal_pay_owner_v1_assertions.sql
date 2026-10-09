-- DIGIY RÉSA V1 — ISOLATED AUTH/JWT/OWNER + PAY CONTRACT
-- All contacts and owners are synthetic.
DO $preflight$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'refusing tests outside disposable PG';
 END IF;
 IF has_function_privilege('anon','public.digiy_resa_universal_owner_status_v1(uuid,text)','EXECUTE') THEN
  RAISE EXCEPTION 'anon may confirm client appointments';
 END IF;
 IF NOT has_function_privilege('authenticated','public.digiy_resa_universal_owner_status_v1(uuid,text)','EXECUTE') THEN
  RAISE EXCEPTION 'authenticated permission missing';
 END IF;
 IF has_table_privilege('authenticated','public.digiy_resa_bookings','UPDATE') THEN
  RAISE EXCEPTION 'authenticated retains broad booking column edits';
 END IF;
END $preflight$;

-- Idempotency UUID identifies the request, NOT the booking primary key.
-- Resolve actual synthetic booking IDs before switching to a tenant-limited role.
SELECT set_config('test.owner_a_booking_id',id::text,false)
FROM public.digiy_resa_bookings
WHERE client_request_id='ca000000-0000-4000-8000-000000000001';
SELECT set_config('test.owner_a_second_id',id::text,false)
FROM public.digiy_resa_bookings
WHERE client_request_id='ca000000-0000-4000-8000-000000000002';

BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $auth_a$
DECLARE r jsonb; fail boolean:=false;
BEGIN
 -- Direct authenticated UPDATE must be blocked even with the correct JWT.
 BEGIN
  UPDATE public.digiy_resa_bookings SET status='confirmed'
  WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 EXCEPTION WHEN insufficient_privilege THEN fail:=true;
 END;
 IF NOT fail THEN RAISE EXCEPTION 'direct UPDATE bypasses owner RPC'; END IF;

 IF (SELECT count(*) FROM public.digiy_resa_bookings WHERE slug='resa-owner-b')<>0 THEN
  RAISE EXCEPTION 'owner A can read owner B';
 END IF;
 r:=public.digiy_resa_universal_owner_status_v1(
   current_setting('test.owner_a_booking_id')::uuid,'done');
 IF r->>'error'<>'invalid_transition' THEN
  RAISE EXCEPTION 'pending->done wrongly permitted: %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_status_v1(
   current_setting('test.owner_a_booking_id')::uuid,'confirmed');
 IF r->>'ok'<>'true' OR r->>'status'<>'confirmed' THEN
  RAISE EXCEPTION 'owner A cannot confirm own V1 booking %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_status_v1(
   current_setting('test.owner_a_booking_id')::uuid,'confirmed');
 IF r->>'error'<>'invalid_transition' THEN
  RAISE EXCEPTION 'repeat confirmation not blocked';
 END IF;
 r:=public.digiy_resa_universal_owner_status_v1(
   'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','confirmed');
 IF r->>'error'<>'not_found_or_forbidden' THEN
  RAISE EXCEPTION 'owner A touched legacy owner B: %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_status_v1(
   current_setting('test.owner_a_booking_id')::uuid,'cancelled');
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'cancel own confirmed booking failed'; END IF;
 r:=public.digiy_resa_universal_owner_status_v1(
   current_setting('test.owner_a_booking_id')::uuid,'confirmed');
 IF r->>'error'<>'invalid_transition' THEN
  RAISE EXCEPTION 'cancelled booking was resurrected'; END IF;
END $auth_a$;
COMMIT;

DO $no_fake_pay$
BEGIN
 IF (SELECT count(*) FROM public.test_pay_side_effects)<>0 THEN
  RAISE EXCEPTION 'new appointments automatically posted PAY despite no payment';
 END IF;
END $no_fake_pay$;

BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $auth_b$
DECLARE r jsonb;
BEGIN
 IF (SELECT count(*) FROM public.digiy_resa_bookings WHERE slug='resa-owner-a')<>0 THEN
  RAISE EXCEPTION 'owner B can see owner A';
 END IF;
 r:=public.digiy_resa_universal_owner_status_v1(
  current_setting('test.owner_a_second_id')::uuid,'cancelled');
 IF r->>'error'<>'not_found_or_forbidden' THEN
  RAISE EXCEPTION 'owner B can mutate owner A: %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_status_v1(
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','confirmed');
 IF r->>'error'<>'not_found_or_forbidden' THEN
  RAISE EXCEPTION 'legacy booking unexpectedly entered V1 status RPC: %',r;
 END IF;
END $auth_b$;
COMMIT;

DO $legacy_and_rebooking$
DECLARE r jsonb;
BEGIN
 -- ONLY the existing legacy booking path still exhibits PAY behavior.
 UPDATE public.digiy_resa_bookings SET status='confirmed'
 WHERE id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
 IF (SELECT count(*) FROM public.test_pay_side_effects)<>1 THEN
  RAISE EXCEPTION 'legacy PAY path unexpectedly modified';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings
     WHERE client_request_id='ca000000-0000-4000-8000-000000000001' AND status='cancelled')<>1 THEN
  RAISE EXCEPTION 'V1 cancelled original request not retained';
 END IF;

 -- Original 09:00 slot is available again after cancellation.
 r:=public.digiy_resa_universal_request_v0(
 'resa-owner-a','a0000000-0000-4000-8000-000000000901',
 'aaaa0000-0000-4000-8000-000000000001',
 'Client synthetic','221770000055',
 'de000000-0000-4000-8000-000000000055');
 IF r->>'ok'<>'true' OR r->>'status'<>'pending' THEN
  RAISE EXCEPTION 'cancellation did not free capacity: %',r;
 END IF;
 IF (SELECT count(*) FROM public.test_pay_side_effects)<>1 THEN
  RAISE EXCEPTION 'new pending rebooking posted PAY';
 END IF;
 RAISE NOTICE 'PASS: tenant A/B, direct UPDATE blocked, owner status transitions, legacy PAY preserved, universal PAY neutral, capacity released';
END $legacy_and_rebooking$;
