-- V8 end-to-end access gate + real booking state, PostgreSQL17 fixture ONLY.
-- No real customer, no live site, no financial record.
DO $preflight$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V8 test forbidden outside disposable PG17';
 END IF;
 IF has_function_privilege('anon',
  'public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)','EXECUTE') THEN
  RAISE EXCEPTION 'raw V0 RPC is publicly bypassable';
 END IF;
 IF NOT has_function_privilege('anon',
  'public.digiy_resa_universal_request_v1(text,uuid,uuid,text,text,uuid)','EXECUTE') THEN
  RAISE EXCEPTION 'guarded V1 RPC is not callable';
 END IF;
 IF has_table_privilege('anon','public.digiy_resa_universal_launch_controls','SELECT')
 OR has_table_privilege('authenticated','public.digiy_resa_universal_launch_controls','UPDATE') THEN
  RAISE EXCEPTION 'pilot launch controls exposed through public table';
 END IF;
END $preflight$;

-- 1: the default is OFF even for a real published fixture profile.
BEGIN;
SET LOCAL ROLE anon;
DO $off$
DECLARE r jsonb;g jsonb;
BEGIN
 g:=public.digiy_resa_universal_pilot_gate_v1('resa-owner-a');
 IF g->>'enabled'<>'false' THEN
  RAISE EXCEPTION 'pilot auto-enabled before admin approval: %',g;
 END IF;
 r:=public.digiy_resa_universal_request_v1(
 'resa-owner-a','a0000000-0000-4000-8000-000000000901',
 'aaaa0000-0000-4000-8000-000000000001',
 'Client de test V8','221770000800','c8000000-0000-4000-8000-000000000001');
 IF r->>'error'<>'pilot_not_active' THEN
  RAISE EXCEPTION 'unguarded appointment inserted: %',r;
 END IF;
END $off$;
COMMIT;

-- Operator manages activation out of band, not via website, URL or JWT.
UPDATE public.digiy_resa_profiles
SET time_zone='Africa/Dakar' WHERE slug='resa-owner-a';
INSERT INTO public.digiy_resa_universal_launch_controls(slug,enabled)
VALUES ('resa-owner-a',false);
BEGIN;
SET LOCAL ROLE anon;
DO $disabled$
DECLARE r jsonb;
BEGIN
 r:=public.digiy_resa_universal_request_v1(
 'resa-owner-a','a0000000-0000-4000-8000-000000000901',
 'aaaa0000-0000-4000-8000-000000000001',
 'Client de test V8','221770000800','c8000000-0000-4000-8000-000000000001');
 IF r->>'error'<>'pilot_not_active' THEN
  RAISE EXCEPTION 'disabled launch row ignored: %',r;
 END IF;
END $disabled$;
COMMIT;

-- Fixture-only operator approval; this never happens automatically.
UPDATE public.digiy_resa_universal_launch_controls
SET enabled=true,activated_at=clock_timestamp() WHERE slug='resa-owner-a';

BEGIN;
SET LOCAL ROLE anon;
DO $booked$
DECLARE g jsonb;r jsonb;retry jsonb;overlap jsonb;notb jsonb;
BEGIN
 g:=public.digiy_resa_universal_pilot_gate_v1('resa-owner-a');
 IF g->>'enabled'<>'true' OR g->>'public_whatsapp'<>'221771234567' THEN
  RAISE EXCEPTION 'published and enabled gate missing public contact: %',g;
 END IF;
 IF g::text ~* 'customer_name|customer_phone|auth_user_id|owner_id' THEN
  RAISE EXCEPTION 'private owner or customer data leaked in gate';
 END IF;
 IF public.digiy_resa_universal_pilot_gate_v1('resa-owner-b')->>'enabled'<>'false' THEN
  RAISE EXCEPTION 'unpublished owner B should never activate';
 END IF;
 r:=public.digiy_resa_universal_request_v1(
 'resa-owner-a','a0000000-0000-4000-8000-000000000901',
 'aaaa0000-0000-4000-8000-000000000001',
 'Client de test V8','221770000800','c8000000-0000-4000-8000-000000000001');
 IF r->>'ok'<>'true' OR r->>'status'<>'pending' OR r->>'already'<>'false' THEN
  RAISE EXCEPTION 'V8 client appointment was not posed: %',r;
 END IF;
 retry:=public.digiy_resa_universal_request_v1(
 'resa-owner-a','a0000000-0000-4000-8000-000000000901',
 'aaaa0000-0000-4000-8000-000000000001',
 'Client de test V8','221770000800','c8000000-0000-4000-8000-000000000001');
 IF retry->>'already'<>'true' OR retry->>'booking_id'<>r->>'booking_id' THEN
  RAISE EXCEPTION 'V8 retry duplicated booking: %',retry;
 END IF;
 overlap:=public.digiy_resa_universal_request_v1(
 'resa-owner-a','a0000000-0000-4000-8000-000000000930',
 'aaaa0000-0000-4000-8000-000000000001',
 'Autre client','221770000801','c8000000-0000-4000-8000-000000000002');
 IF overlap->>'error'<>'slot_unavailable' THEN
  RAISE EXCEPTION 'overlap not prevented after pending reservation: %',overlap;
 END IF;
END $booked$;
COMMIT;

DO $ledger$
BEGIN
 IF (SELECT count(*) FROM public.test_pay_side_effects)<>0 THEN
  RAISE EXCEPTION 'V8 appointment generated fake PAY';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings
  WHERE client_request_id='c8000000-0000-4000-8000-000000000001')<>1 THEN
  RAISE EXCEPTION 'V8 pending booking missing or duplicated';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings
  WHERE client_request_id IS NULL)<>2 THEN
  RAISE EXCEPTION 'synthetic historic booking rows changed';
 END IF;
END $ledger$;

-- 2: once pilot is disabled, NEW submissions are rejected, while the
-- existing booking remains on the owner calendar.
UPDATE public.digiy_resa_universal_launch_controls SET enabled=false
WHERE slug='resa-owner-a';
BEGIN;
SET LOCAL ROLE anon;
DO $stopped$
DECLARE r jsonb;
BEGIN
 r:=public.digiy_resa_universal_request_v1(
 'resa-owner-a','a0000000-0000-4000-8000-000000001100',
 'aaaa0000-0000-4000-8000-000000000001',
 'Late test client','221770000802','c8000000-0000-4000-8000-000000000003');
 IF r->>'error'<>'pilot_not_active' THEN
  RAISE EXCEPTION 'deactivation did not stop further reservations: %',r;
 END IF;
END $stopped$;
COMMIT;
DO $final$
BEGIN
 IF (SELECT count(*) FROM public.digiy_resa_bookings WHERE client_request_id
    ='c8000000-0000-4000-8000-000000000001' AND status='pending')<>1 THEN
  RAISE EXCEPTION 'deactivation discarded booked patient';
 END IF;
 IF (SELECT count(*) FROM public.digiy_resa_bookings
  WHERE client_request_id='c8000000-0000-4000-8000-000000000003')<>0 THEN
  RAISE EXCEPTION 'booking created after kill switch';
 END IF;
 RAISE NOTICE 'PASS V8 isolated: default OFF, anon V0 denied, operator activation, booking locked, retry idempotent, no double booking, no PAY, deactivation preserves booked client';
END $final$;
