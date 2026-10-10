-- DIGIY RÉSA UNIVERSEL V6 — full synthetic API role journey
-- THIS IS A THROWAWAY PostgreSQL 17 test, NOT a real staging deployment.
-- Pipeline prerequisite: fixture A/B, V0 candidate, V1 fixture+candidate,
-- V5 fixture+candidate, V2 public options candidate.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V6 acceptance restricted to isolated digiy_appointments_test';
 END IF;
 IF to_regprocedure('public.digiy_resa_universal_owner_manage_v2(uuid,text,text)') IS NULL
 OR to_regprocedure('public.digiy_resa_universal_public_options_v1(text,date)') IS NULL THEN
  RAISE EXCEPTION 'V5 owner and V2 catalogue must be loaded';
 END IF;
 -- In the disposable fixture ONLY, the owner A is published and Dakar-local.
 UPDATE public.digiy_resa_profiles SET time_zone='Africa/Dakar'
 WHERE slug='resa-owner-a';
 UPDATE public.digiy_resa_profiles SET time_zone='Africa/Dakar'
 WHERE slug='resa-owner-b';
END $guard$;

-- Snapshot the synthetic historical rows and simulated PAY side effects.
-- All inspections are by the fixture supervisor, not the customer.
CREATE TEMP TABLE acceptance_baseline AS
SELECT
 (SELECT count(*) FROM public.digiy_resa_bookings
  WHERE client_request_id IS NULL) historical_rows,
 (SELECT count(*) FROM public.test_pay_side_effects) pay_events;

-- 1: Anonymous user can see ONLY the published A services and availability.
BEGIN;
SET LOCAL ROLE anon;
DO $customer_catalogue$
DECLARE
 v_catalogue jsonb;
 v_slot jsonb;
BEGIN
 v_catalogue:=public.digiy_resa_universal_public_options_v1(
  'resa-owner-a',current_date+8);
 IF v_catalogue->>'ok'<>'true' OR
    jsonb_array_length(v_catalogue->'services')<>2 OR
    v_catalogue->>'time_zone'<>'Africa/Dakar' THEN
  RAISE EXCEPTION 'public Dakar catalogue not available: %',v_catalogue;
 END IF;
 SELECT x INTO v_slot
 FROM jsonb_array_elements(v_catalogue->'slots') x
 WHERE x->>'slot_id'='a0000000-0000-4000-8000-000000000901';
 IF v_slot->>'available'<>'true' OR
    NOT v_slot->'service_ids' ? 'aaaa0000-0000-4000-8000-000000000001' THEN
  RAISE EXCEPTION 'actual slot/service IDs not selectable: %',v_slot;
 END IF;
 IF v_catalogue::text ~* 'customer_name|customer_phone|test note' THEN
  RAISE EXCEPTION 'private customer data exposed in catalogue';
 END IF;
 IF public.digiy_resa_universal_public_options_v1('resa-owner-b',current_date+8)
  ->>'error'<>'not_published' THEN
  RAISE EXCEPTION 'unpublished owner B exposed to anon';
 END IF;
END $customer_catalogue$;
COMMIT;

-- 2: Anonymous customer creates one pending booking and proves atomic
--    overlap/idempotency constraints directly through the V0 RPC.
BEGIN;
SET LOCAL ROLE anon;
DO $customer_request$
DECLARE
 v_request jsonb;
 v_retry jsonb;
 v_overlap jsonb;
BEGIN
 v_request:=public.digiy_resa_universal_request_v0(
 'resa-owner-a','a0000000-0000-4000-8000-000000000901',
 'aaaa0000-0000-4000-8000-000000000001',
 'Client V6 fictif','221770000600',
 'f6000000-0000-4000-8000-000000000001');
 IF v_request->>'ok'<>'true' OR
    v_request->>'status'<>'pending' OR
    v_request->>'already'<>'false' THEN
  RAISE EXCEPTION 'client booking was not pending: %',v_request;
 END IF;
 v_retry:=public.digiy_resa_universal_request_v0(
 'resa-owner-a','a0000000-0000-4000-8000-000000000901',
 'aaaa0000-0000-4000-8000-000000000001',
 'Client V6 fictif','221770000600',
 'f6000000-0000-4000-8000-000000000001');
 IF v_retry->>'ok'<>'true' OR
    v_retry->>'already'<>'true' OR
    v_retry->>'booking_id'<>v_request->>'booking_id' THEN
  RAISE EXCEPTION 'network retry not idempotent: %',v_retry;
 END IF;
 v_overlap:=public.digiy_resa_universal_request_v0(
 'resa-owner-a','a0000000-0000-4000-8000-000000000930',
 'aaaa0000-0000-4000-8000-000000000001',
 'Autre client V6','221770000601',
 'f6000000-0000-4000-8000-000000000002');
 IF v_overlap->>'error'<>'slot_unavailable' THEN
  RAISE EXCEPTION 'overlap erroneously booked: %',v_overlap;
 END IF;
END $customer_request$;
COMMIT;

-- Ensure the customer never receives the booked person's private data
-- from the calendar; 09:00 AND its overlapping 09:30 must disappear.
BEGIN;
SET LOCAL ROLE anon;
DO $customer_after$
DECLARE
 v_catalogue jsonb;
 v_a jsonb;
 v_overlap jsonb;
BEGIN
 v_catalogue:=public.digiy_resa_universal_public_options_v1(
  'resa-owner-a',current_date+8);
 SELECT x INTO v_a FROM jsonb_array_elements(v_catalogue->'slots') x
 WHERE x->>'slot_id'='a0000000-0000-4000-8000-000000000901';
 SELECT x INTO v_overlap FROM jsonb_array_elements(v_catalogue->'slots') x
 WHERE x->>'slot_id'='a0000000-0000-4000-8000-000000000930';
 IF v_a->>'available'<>'false' OR v_overlap->>'available'<>'false' THEN
  RAISE EXCEPTION 'calendar exposed occupied or overlapping time';
 END IF;
END $customer_after$;
COMMIT;

-- 3: Third party owner B has no access to A's PII or actions.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 '22222222-2222-4222-8222-222222222222',true);
DO $wrong_owner$
DECLARE v_booking uuid;v_result jsonb;
BEGIN
 SELECT id INTO v_booking FROM public.digiy_resa_bookings
 WHERE client_request_id='f6000000-0000-4000-8000-000000000001';
 IF FOUND THEN
  RAISE EXCEPTION 'owner B can read owner A booking';
 END IF;
 v_result:=public.digiy_resa_universal_owner_manage_v2(
  (SELECT b.id FROM public.digiy_resa_bookings b WHERE false),
  'confirmed',NULL);
 IF v_result->>'error' NOT IN ('invalid_request','not_found_or_forbidden') THEN
  RAISE EXCEPTION 'invalid owner request unexpectedly accepted: %',v_result;
 END IF;
END $wrong_owner$;
COMMIT;

-- 4: Supervisor resolves UUID out-of-band for tests; no anonymous SELECT.
SELECT set_config('test.v6_id',b.id::text,false)
FROM public.digiy_resa_bookings b
WHERE b.client_request_id='f6000000-0000-4000-8000-000000000001';

-- Owner B knows a booking UUID by observation? Still cannot touch it.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 '22222222-2222-4222-8222-222222222222',true);
DO $wrong_owner_id$
DECLARE v_result jsonb;
BEGIN
 v_result:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v6_id')::uuid,'note','not owned');
 IF v_result->>'error'<>'not_found_or_forbidden' THEN
  RAISE EXCEPTION 'owner B wrote owner A private note: %',v_result;
 END IF;
 v_result:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v6_id')::uuid,'confirmed',NULL);
 IF v_result->>'error'<>'not_found_or_forbidden' THEN
  RAISE EXCEPTION 'owner B confirmed owner A appointment: %',v_result;
 END IF;
END $wrong_owner_id$;
COMMIT;

-- 5: Owner A can save a private note, confirm, and later cancel.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 '11111111-1111-4111-8111-111111111111',true);
DO $owner_correct$
DECLARE v_result jsonb;
BEGIN
 v_result:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v6_id')::uuid,'note','Rappeler le client V6');
 IF v_result->>'ok'<>'true' OR v_result->>'status'<>'pending' THEN
  RAISE EXCEPTION 'private note not saved: %',v_result;
 END IF;
 IF v_result::text ILIKE '%Rappeler%' THEN
  RAISE EXCEPTION 'private note leaked back over status API';
 END IF;
 v_result:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v6_id')::uuid,'confirmed',NULL);
 IF v_result->>'ok'<>'true' OR v_result->>'status'<>'confirmed' THEN
  RAISE EXCEPTION 'owner A could not confirm: %',v_result;
 END IF;
 v_result:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v6_id')::uuid,'cancelled',NULL);
 IF v_result->>'ok'<>'true' OR v_result->>'status'<>'cancelled' THEN
  RAISE EXCEPTION 'owner A could not cancel: %',v_result;
 END IF;
END $owner_correct$;
COMMIT;

-- 6: Privileged assertions after owner operations; owners do NOT receive
-- SELECT permissions on the financial audit or each other's bookings.
DO $supervisor$
DECLARE
 v_historic integer;
 v_pay integer;
 v_record public.digiy_resa_bookings%ROWTYPE;
 v_initial record;
BEGIN
 SELECT * INTO v_initial FROM acceptance_baseline;
 SELECT count(*) INTO v_historic FROM public.digiy_resa_bookings
 WHERE client_request_id IS NULL;
 SELECT count(*) INTO v_pay FROM public.test_pay_side_effects;
 IF v_historic<>v_initial.historical_rows OR v_pay<>v_initial.pay_events THEN
  RAISE EXCEPTION 'historical booking count or PAY ledger changed';
 END IF;
 SELECT * INTO v_record FROM public.digiy_resa_bookings
 WHERE client_request_id='f6000000-0000-4000-8000-000000000001';
 IF v_record.status<>'cancelled' OR
    v_record.note_text<>'Rappeler le client V6' OR
    v_record.price_fcfa<>12000 OR
    v_record.duration_minutes<>45 OR
    v_record.customer_phone<>'221770000600' THEN
  RAISE EXCEPTION 'server-priced V6 booking corrupted';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings
  WHERE client_request_id='f6000000-0000-4000-8000-000000000001')<>1 THEN
  RAISE EXCEPTION 'idempotent client operation duplicated';
 END IF;
END $supervisor$;

-- 7: After cancellation, the slot is visible and bookable again.
BEGIN;
SET LOCAL ROLE anon;
DO $retry_after_cancel$
DECLARE v_catalogue jsonb;v_slot jsonb;v_request jsonb;
BEGIN
 v_catalogue:=public.digiy_resa_universal_public_options_v1(
  'resa-owner-a',current_date+8);
 SELECT s INTO v_slot FROM jsonb_array_elements(v_catalogue->'slots') s
 WHERE s->>'slot_id'='a0000000-0000-4000-8000-000000000901';
 IF v_slot->>'available'<>'true' THEN
  RAISE EXCEPTION 'cancelled time not available again';
 END IF;
 v_request:=public.digiy_resa_universal_request_v0(
 'resa-owner-a','a0000000-0000-4000-8000-000000000901',
 'aaaa0000-0000-4000-8000-000000000001',
 'Nouveau client V6 fictif','221770000602',
 'f6000000-0000-4000-8000-000000000003');
 IF v_request->>'ok'<>'true' OR v_request->>'status'<>'pending' THEN
  RAISE EXCEPTION 'new customer cannot reuse released slot: %',v_request;
 END IF;
END $retry_after_cancel$;
COMMIT;
DO $done$
BEGIN
 IF (SELECT count(*) FROM public.test_pay_side_effects)<>
    (SELECT pay_events FROM acceptance_baseline) THEN
  RAISE EXCEPTION 'rebook after cancellation unexpectedly wrote PAY';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings
  WHERE client_request_id IS NULL)<>
    (SELECT historical_rows FROM acceptance_baseline) THEN
  RAISE EXCEPTION 'rebooking affected legacy records';
 END IF;
 RAISE NOTICE 'PASS V6 simulated anon client→pending→owner A note/confirm/cancel→slot rebook, owner B denied, PAY neutral, old records intact';
END $done$;
