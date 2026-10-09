-- DIGIY RÉSA — isolated public-options contract assertions.
-- Run only on disposable digiy_appointments_test, with synthetic A/B profiles.
DO $assert$
DECLARE
 d date:=current_date+8;
 result jsonb;
 after_booking jsonb;
 slot_a jsonb;
 slot_overlap jsonb;
 slot_short jsonb;
 slot_closed jsonb;
 slot_group jsonb;
 booking jsonb;
 historical_before bigint;
 historical_after bigint;
BEGIN
 IF current_database() <> 'digiy_appointments_test' THEN
  RAISE EXCEPTION 'isolated assertions only';
 END IF;
 IF has_table_privilege('anon','public.digiy_resa_bookings','SELECT') THEN
  RAISE EXCEPTION 'anonymous booking table read unexpectedly allowed';
 END IF;
 IF NOT has_function_privilege('anon',
 'public.digiy_resa_universal_public_options_v1(text,date)','EXECUTE') THEN
  RAISE EXCEPTION 'anon must be able to read safe public options';
 END IF;
 result:=public.digiy_resa_universal_public_options_v1('resa-owner-a',d);
 IF result->>'error'<>'unsupported_timezone' THEN
  RAISE EXCEPTION 'timezone-less profile incorrectly published: %',result;
 END IF;
 UPDATE public.digiy_resa_profiles SET time_zone='Africa/Dakar'
 WHERE slug IN ('resa-owner-a','resa-owner-b');
 result:=public.digiy_resa_universal_public_options_v1('resa-owner-b',d);
 IF result->>'error'<>'not_published' THEN
  RAISE EXCEPTION 'unpublished owner B options leaked: %',result;
 END IF;
 result:=public.digiy_resa_universal_public_options_v1('resa-owner-a',current_date+57);
 IF result->>'error'<>'outside_booking_window' THEN
  RAISE EXCEPTION 'far future calendar unexpectedly allowed';
 END IF;
 result:=public.digiy_resa_universal_public_options_v1('resa-owner-a',d);
 IF result->>'ok'<>'true' OR result->>'time_zone'<>'Africa/Dakar' THEN
  RAISE EXCEPTION 'pilot A options absent: %',result;
 END IF;
 IF jsonb_array_length(result->'services') <> 2 THEN
  RAISE EXCEPTION 'inactive service was exposed: %',result->'services';
 END IF;
 IF result::text LIKE '%private test note%'
    OR result::text LIKE '%customer_name%'
    OR result::text LIKE '%customer_phone%' THEN
  RAISE EXCEPTION 'private data leaked in public options';
 END IF;
 SELECT elem INTO slot_a FROM jsonb_array_elements(result->'slots') elem
 WHERE elem->>'slot_id'='a0000000-0000-4000-8000-000000000901';
 SELECT elem INTO slot_short FROM jsonb_array_elements(result->'slots') elem
 WHERE elem->>'slot_id'='a0000000-0000-4000-8000-000000001400';
 SELECT elem INTO slot_closed FROM jsonb_array_elements(result->'slots') elem
 WHERE elem->>'slot_id'='a0000000-0000-4000-8000-000000001300';
 SELECT elem INTO slot_group FROM jsonb_array_elements(result->'slots') elem
 WHERE elem->>'slot_id'='a0000000-0000-4000-8000-000000001600';
 IF slot_a->>'available'<>'true' OR jsonb_array_length(slot_a->'service_ids')<>2 THEN
  RAISE EXCEPTION 'real bounded slot or matching services not exposed: %',slot_a;
 END IF;
 IF slot_short->>'available'<>'false'
    OR jsonb_array_length(slot_short->'service_ids')<>0
    OR slot_closed->>'available'<>'false'
    OR slot_group->>'available'<>'false' THEN
  RAISE EXCEPTION 'closed, short, or capacity>1 slot incorrectly bookable';
 END IF;
 historical_before := (SELECT count(*) FROM public.digiy_resa_bookings
                       WHERE client_request_id IS NULL);
 booking:=public.digiy_resa_universal_request_v0(
 'resa-owner-a','a0000000-0000-4000-8000-000000000901',
 'aaaa0000-0000-4000-8000-000000000001',
 'Client de test','221770000001','ca000000-0000-4000-8000-000000000091');
 IF booking->>'ok'<>'true' OR booking->>'status'<>'pending' THEN
  RAISE EXCEPTION 'new isolated booking failed: %',booking;
 END IF;
 after_booking:=public.digiy_resa_universal_public_options_v1('resa-owner-a',d);
 SELECT elem INTO slot_a FROM jsonb_array_elements(after_booking->'slots') elem
 WHERE elem->>'slot_id'='a0000000-0000-4000-8000-000000000901';
 SELECT elem INTO slot_overlap FROM jsonb_array_elements(after_booking->'slots') elem
 WHERE elem->>'slot_id'='a0000000-0000-4000-8000-000000000930';
 IF slot_a->>'available'<>'false' OR slot_overlap->>'available'<>'false' THEN
  RAISE EXCEPTION 'active booking did not hide overlapping slots';
 END IF;
 historical_after := (SELECT count(*) FROM public.digiy_resa_bookings
                      WHERE client_request_id IS NULL);
 IF historical_after <> historical_before THEN
  RAISE EXCEPTION 'historical bookings were modified';
 END IF;
 UPDATE public.digiy_resa_profiles SET time_zone='Europe/Paris'
 WHERE slug='resa-owner-a';
 result:=public.digiy_resa_universal_public_options_v1('resa-owner-a',d);
 IF result->>'error'<>'unsupported_timezone' THEN
  RAISE EXCEPTION 'France must remain blocked until IANA/DST tests';
 END IF;
 UPDATE public.digiy_resa_profiles SET time_zone='Africa/Dakar'
 WHERE slug='resa-owner-a';
 RAISE NOTICE 'PASS: IDs, active services, no PII, slot fit, UTC-neutral Dakar pilot, capacity1, overlap, legacy, France NO-GO';
END $assert$;

BEGIN;
SET LOCAL ROLE anon;
DO $anon$
DECLARE
 r jsonb;
BEGIN
 r:=public.digiy_resa_universal_public_options_v1('resa-owner-a',current_date+8);
 IF r->>'ok'<>'true' OR jsonb_array_length(r->'services')<>2 THEN
  RAISE EXCEPTION 'anonymous public contract failed: %',r;
 END IF;
END $anon$;
ROLLBACK;
SELECT 'PASS: anonymous read limited to public option contract' AS result;
