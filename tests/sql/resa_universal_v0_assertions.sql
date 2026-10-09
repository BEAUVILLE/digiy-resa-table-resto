-- PostgreSQL 17 unit assertions: synthetic owners, no real clients.
DO $checks$
DECLARE
 d date:=current_date+8;
 a uuid:='a0000000-0000-4000-8000-000000000901';
 overlap_slot uuid:='a0000000-0000-4000-8000-000000000930';
 later uuid:='a0000000-0000-4000-8000-000000001100';
 service uuid:='aaaa0000-0000-4000-8000-000000000001';
 longer uuid:='aaaa0000-0000-4000-8000-000000000002';
 key_one uuid:='ca000000-0000-4000-8000-000000000001';
 key_two uuid:='ca000000-0000-4000-8000-000000000002';
 res jsonb;
 again jsonb;
 first_id text;
BEGIN
 IF NOT has_function_privilege('anon','public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)','EXECUTE')
 THEN RAISE EXCEPTION 'anon execution missing'; END IF;
 IF has_table_privilege('anon','public.digiy_resa_bookings','SELECT') THEN
   RAISE EXCEPTION 'anon can read client bookings table'; END IF;

 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-a',a,service,'Client inventé','221770000001',key_one);
 IF res->>'ok'<>'true' OR res->>'status'<>'pending' THEN
  RAISE EXCEPTION 'expected pending request, got %',res;
 END IF;
 IF res::text LIKE '%221770000001%' OR res::text LIKE '%Client inventé%' THEN
  RAISE EXCEPTION 'private data leaked in response'; END IF;
 first_id:=res->>'booking_id';
 again:=public.digiy_resa_universal_request_v0(
  'resa-owner-a',a,service,'Client inventé','221770000001',key_one);
 IF again->>'ok'<>'true' OR again->>'already'<>'true'
   OR again->>'booking_id'<>first_id THEN
   RAISE EXCEPTION 'idempotency failed %',again;
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings WHERE client_request_id=key_one)<>1
 THEN RAISE EXCEPTION 'duplicate request inserted'; END IF;
 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-a',a,service,'Autre','221770000002',key_one);
 IF res->>'error'<>'request_key_reused' THEN
  RAISE EXCEPTION 'reused request key accepted'; END IF;

 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-a',overlap_slot,service,'Deuxième','221770000003',
  'ca000000-0000-4000-8000-000000000003');
 IF res->>'error'<>'slot_unavailable' THEN
  RAISE EXCEPTION 'overlapping slots were both booked: %',res; END IF;

 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-a','a0000000-0000-4000-8000-000000001300',
  service,'Test','221770000004','ca000000-0000-4000-8000-000000000004');
 IF res->>'error'<>'slot_unavailable' THEN RAISE EXCEPTION 'closed slot accepted'; END IF;
 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-a','a0000000-0000-4000-8000-000000001600',
  service,'Test','221770000004','ca000000-0000-4000-8000-000000000005');
 IF res->>'error'<>'slot_unavailable' THEN RAISE EXCEPTION 'group-capacity slot accepted in V0'; END IF;
 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-a','a0000000-0000-4000-8000-000000001400',
  longer,'Test','221770000004','ca000000-0000-4000-8000-000000000006');
 IF res->>'error'<>'service_exceeds_slot' THEN RAISE EXCEPTION 'duration overflow accepted: %',res; END IF;
 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-b','b0000000-0000-4000-8000-000000001000',
  'bbbb0000-0000-4000-8000-000000000001',
  'Test','221770000004','ca000000-0000-4000-8000-000000000007');
 IF res->>'error'<>'not_published' THEN RAISE EXCEPTION 'unpublished B accepted'; END IF;
 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-a',later,'bbbb0000-0000-4000-8000-000000000001',
  'Test','221770000004','ca000000-0000-4000-8000-000000000008');
 IF res->>'error'<>'invalid_service' THEN RAISE EXCEPTION 'cross-tenant service accepted'; END IF;

 res:=public.digiy_resa_universal_request_v0(
  'resa-owner-a',later,service,'Client fictif','221770000009',key_two);
 IF res->>'ok'<>'true' THEN RAISE EXCEPTION 'second distinct time refused: %',res; END IF;

 IF (SELECT count(*) FROM public.test_pay_side_effects)<>0 THEN
  RAISE EXCEPTION 'booking insertion incorrectly fired the PAY trigger'; END IF;
 IF (SELECT service_name FROM public.digiy_resa_bookings WHERE client_request_id=key_one)
   <>'Consultation 45 min' THEN RAISE EXCEPTION 'service data not authoritative'; END IF;
 IF (SELECT price_fcfa FROM public.digiy_resa_bookings WHERE client_request_id=key_one)
   <>12000 THEN RAISE EXCEPTION 'price unexpectedly taken from client'; END IF;

 RAISE NOTICE 'PASS: publication, tenant scope, real slots, duration, overlap, idempotency, owner/price, PAY insert neutrality';
END
$checks$;

-- Explicitly test the function with anonymous API privileges rather than
-- relying solely on postgres/superuser EXECUTE.
BEGIN;
SET LOCAL ROLE anon;
DO $anonymous$
DECLARE
 r jsonb;
BEGIN
 r:=public.digiy_resa_universal_request_v0(
 'resa-owner-b',
 'b0000000-0000-4000-8000-000000001000',
 'bbbb0000-0000-4000-8000-000000000001',
 'Test API','221770000040',
 'ca000000-0000-4000-8000-000000000040');
 IF r->>'error'<>'not_published' THEN
  RAISE EXCEPTION 'anonymous public access bypassed profile rule: %',r;
 END IF;
END $anonymous$;
ROLLBACK;

-- PAY-style trigger is a legacy compatibility risk: only test it in a
-- disposable transaction, with synthetic rows. Roll back the status change.
BEGIN;
UPDATE public.digiy_resa_bookings SET status='confirmed'
WHERE client_request_id='ca000000-0000-4000-8000-000000000002';
DO $check_pay$
BEGIN
 IF (SELECT count(*) FROM public.test_pay_side_effects)<>1 THEN
  RAISE EXCEPTION 'PAY-side-effect trigger not modeled'; END IF;
END $check_pay$;
ROLLBACK;
SELECT 'PASS: PAY trigger integration modeled without altering persistent mock rows' AS test_result;
