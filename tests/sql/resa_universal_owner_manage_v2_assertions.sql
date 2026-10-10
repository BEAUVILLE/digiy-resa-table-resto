-- RÉSA V5 — synthetic A/B owners, real role separation, no production data.
DO $preflight$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V5 assertions forbidden outside disposable database';
 END IF;
 IF has_function_privilege('anon',
  'public.digiy_resa_universal_owner_manage_v2(uuid,text,text)','EXECUTE') THEN
  RAISE EXCEPTION 'anon may call owner management';
 END IF;
 IF NOT has_function_privilege('authenticated',
  'public.digiy_resa_universal_owner_manage_v2(uuid,text,text)','EXECUTE') THEN
  RAISE EXCEPTION 'authenticated owner method unreachable';
 END IF;
 IF has_table_privilege('authenticated','public.digiy_resa_bookings','UPDATE') THEN
  RAISE EXCEPTION 'broad direct UPDATE unexpectedly available in throwaway fixture';
 END IF;
END $preflight$;

-- V0 idempotency key and PK differ. Fetch the real row id, never guess.
SELECT set_config('test.v5_a_booking_id',id::text,false)
 FROM public.digiy_resa_bookings
 WHERE client_request_id='ca000000-0000-4000-8000-000000000002';
SELECT set_config('test.v5_legacy_count',
 (SELECT count(*)::text FROM public.digiy_resa_bookings WHERE client_request_id IS NULL),false);
SELECT set_config('test.v5_pay_count',
 (SELECT count(*)::text FROM public.test_pay_side_effects),false);
SELECT set_config('test.v5_original_name',
 (SELECT customer_name FROM public.digiy_resa_bookings
  WHERE id=current_setting('test.v5_a_booking_id')::uuid),false);
SELECT set_config('test.v5_original_phone',
 (SELECT customer_phone FROM public.digiy_resa_bookings
  WHERE id=current_setting('test.v5_a_booking_id')::uuid),false);

-- Verify role anon fails EXECUTE, including legacy row targets.
BEGIN;
SET LOCAL ROLE anon;
DO $anon$
DECLARE denied boolean:=false;
BEGIN
 BEGIN
  PERFORM public.digiy_resa_universal_owner_manage_v2(
   current_setting('test.v5_a_booking_id')::uuid,'confirmed',NULL);
 EXCEPTION WHEN insufficient_privilege THEN denied:=true;
 END;
 IF NOT denied THEN
  RAISE EXCEPTION 'anonymous caller could execute owner RPC';
 END IF;
END $anon$;
ROLLBACK;

-- An authenticated session without a JWT user cannot edit bookings.
BEGIN;
SET LOCAL ROLE authenticated;
DO $no_jwt$
DECLARE r jsonb;
BEGIN
 r:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v5_a_booking_id')::uuid,'confirmed',NULL);
 IF r->>'error'<>'authentication_required' THEN
  RAISE EXCEPTION 'anonymous-with-authenticated-role bypassed UID: %',r;
 END IF;
END $no_jwt$;
ROLLBACK;

BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 '22222222-2222-4222-8222-222222222222',true);
DO $wrong_owner$
DECLARE r jsonb;
BEGIN
 r:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v5_a_booking_id')::uuid,'note','B changed A');
 IF r->>'error'<>'not_found_or_forbidden' THEN
  RAISE EXCEPTION 'B edited notes belonging to A: %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_manage_v2(
  current_setting('test.v5_a_booking_id')::uuid,'confirmed',NULL);
 IF r->>'error'<>'not_found_or_forbidden' THEN
  RAISE EXCEPTION 'B confirmed A booking: %',r;
 END IF;
END $wrong_owner$;
ROLLBACK;

BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 '11111111-1111-4111-8111-111111111111',true);
DO $owner_a$
DECLARE
 r jsonb;
 booking_id uuid:=current_setting('test.v5_a_booking_id')::uuid;
 BEGIN
 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'done',NULL);
 IF r->>'error'<>'invalid_transition' THEN
  RAISE EXCEPTION 'pending -> done incorrectly allowed: %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'note',repeat('n',1001));
 IF r->>'error'<>'note_too_long' THEN
  RAISE EXCEPTION 'oversized note accepted: %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'confirmed','do not overwrite');
 IF r->>'error'<>'unexpected_note' THEN
  RAISE EXCEPTION 'status call silently altered notes: %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_manage_v2(
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','note','legacy should stay untouched');
 IF r->>'error'<>'not_found_or_forbidden' THEN
  RAISE EXCEPTION 'owner RPC entered a legacy booking: %',r;
 END IF;

 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'note',
  '  Note privée propriétaire TEST  ');
 IF r->>'ok'<>'true' OR r->>'status'<>'pending'
    OR r::text LIKE '%Note privée%'
    OR r::text LIKE '%221770000001%' THEN
  RAISE EXCEPTION 'note RPC failed, disclosed private data or changed status: %',r;
 END IF;
 IF (SELECT note_text FROM public.digiy_resa_bookings WHERE id=booking_id)
   <>'Note privée propriétaire TEST' THEN
  RAISE EXCEPTION 'private note was not saved';
 END IF;
 -- Clearing note must preserve status and all other booking properties.
 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'note',NULL);
 IF r->>'ok'<>'true'
    OR (SELECT note_text IS NOT NULL FROM public.digiy_resa_bookings WHERE id=booking_id) THEN
  RAISE EXCEPTION 'clearing note failed';
 END IF;
 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'note','Suivi rendez-vous');
 IF r->>'ok'<>'true' THEN RAISE EXCEPTION 'note after clear failed'; END IF;

 -- PAY is neutral when the universal appointment becomes confirmed,
 -- independent of the price defined on the synthetic service.
 -- The authenticated owner must not be granted SELECT on PAY.
 -- A separate privileged post-action check below validates PAY neutrality.
 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'confirmed',NULL);
 IF r->>'ok'<>'true' OR r->>'status'<>'confirmed' THEN
  RAISE EXCEPTION 'owner A could not confirm V0 request: %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'confirmed',NULL);
 IF r->>'error'<>'invalid_transition' THEN
  RAISE EXCEPTION 'confirmation replay was accepted: %',r;
 END IF;
 IF (SELECT customer_name FROM public.digiy_resa_bookings WHERE id=booking_id)
   <>current_setting('test.v5_original_name')
   OR (SELECT customer_phone FROM public.digiy_resa_bookings WHERE id=booking_id)
   <>current_setting('test.v5_original_phone') THEN
  RAISE EXCEPTION 'owner RPC modified private customer identity';
 END IF;

 -- Cancel confirmed, never delete. This frees the appointment interval.
 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'cancelled',NULL);
 IF r->>'ok'<>'true' OR r->>'status'<>'cancelled' THEN
  RAISE EXCEPTION 'cancellation failed: %',r;
 END IF;
 r:=public.digiy_resa_universal_owner_manage_v2(booking_id,'confirmed',NULL);
 IF r->>'error'<>'invalid_transition' THEN
  RAISE EXCEPTION 'cancelled booking resurrected: %',r;
 END IF;
 IF (SELECT note_text FROM public.digiy_resa_bookings WHERE id=booking_id)
  <>'Suivi rendez-vous' THEN
  RAISE EXCEPTION 'status change erased private note';
 END IF;
END $owner_a$;
COMMIT;

DO $capacity_and_history$
DECLARE res jsonb;
BEGIN
 IF (SELECT count(*) FROM public.digiy_resa_bookings
     WHERE client_request_id IS NULL)<>current_setting('test.v5_legacy_count')::bigint THEN
  RAISE EXCEPTION 'legacy booking rows unexpectedly changed';
 END IF;
 IF (SELECT count(*) FROM public.test_pay_side_effects)<>
    current_setting('test.v5_pay_count')::bigint THEN
  RAISE EXCEPTION 'PAY side effect unexpectedly triggered by V5';
 END IF;
 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-a','a0000000-0000-4000-8000-000000001100',
  'aaaa0000-0000-4000-8000-000000000001',
  'Client synthetic','221770000083',
  'de000000-0000-4000-8000-000000000083');
 IF res->>'ok'<>'true' OR res->>'status'<>'pending' THEN
  RAISE EXCEPTION 'cancelled slot not reusable: %',res;
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings
  WHERE client_request_id='ca000000-0000-4000-8000-000000000002'
  AND status='cancelled')<>1 THEN
  RAISE EXCEPTION 'cancelled appointment was deleted';
 END IF;
 RAISE NOTICE 'PASS: RÉSA V5 JWT anon/A/B, note/clear, transitions, PAY neutral, slot free, legacy preserved';
END $capacity_and_history$;
