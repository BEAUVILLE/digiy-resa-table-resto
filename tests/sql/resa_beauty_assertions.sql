-- SQL behavior assertions on disposable PostgreSQL 17, never the live project.
DO $verify$
DECLARE
  v_owner_a uuid := '11111111-1111-4111-8111-111111111111';
  v_owner_b uuid := '22222222-2222-4222-8222-222222222222';
  v_slot uuid := '30303030-3030-4030-8030-303030303030';
  v_booking1 uuid;
  v_booking2 uuid;
  v_data jsonb;
  v_slot_count integer;
  v_denied boolean;
BEGIN
  IF has_function_privilege('anon','public.digiy_resa_get_bookings_by_day(text,date)','EXECUTE') THEN
    RAISE EXCEPTION 'P0 FAIL: anon still has private bookings access';
  END IF;
  IF NOT has_function_privilege('authenticated','public.digiy_resa_get_bookings_by_day(text,date)','EXECUTE') THEN
    RAISE EXCEPTION 'P0 FAIL: owner role cannot access bookings';
  END IF;
  PERFORM set_config('request.jwt.claim.sub',v_owner_a::text,false);
  v_data := public.digiy_resa_get_bookings_by_day('resa-owner-a','2026-10-09');
  IF (v_data->>'count')::int<>1 THEN RAISE EXCEPTION 'owner A list incorrect'; END IF;
  v_denied:=false;
  BEGIN
    PERFORM public.digiy_resa_get_bookings_by_day('resa-owner-b','2026-10-09');
  EXCEPTION WHEN insufficient_privilege THEN v_denied:=true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'P0 FAIL: cross-owner bookings readable'; END IF;
  PERFORM set_config('request.jwt.claim.sub','',false);
  v_denied:=false;
  BEGIN
    PERFORM public.digiy_resa_get_bookings_by_day('resa-owner-a','2026-10-09');
  EXCEPTION WHEN insufficient_privilege THEN v_denied:=true;
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'P0 FAIL: no JWT can read bookings'; END IF;

  SELECT count(*) INTO v_slot_count FROM public.digiy_beauty_public_slots_v2('beauty-a','2026-10-12');
  IF v_slot_count<>1 THEN RAISE EXCEPTION 'V2 FAIL: public slot ID missing'; END IF;
  IF (SELECT count(*) FROM public.digiy_beauty_public_slots_v1('beauty-a','2026-10-12'))<>1 THEN
    RAISE EXCEPTION 'Backward compatibility V1 broken';
  END IF;
  PERFORM set_config('request.jwt.claim.sub',v_owner_a::text,false);
  v_denied:=false;
  BEGIN
    PERFORM public.digiy_beauty_public_book_v1(
      'beauty-a',v_slot,'Soin test',45,1,'Client TEST','221771234567');
  EXCEPTION WHEN OTHERS THEN
    v_denied := SQLERRM LIKE 'service offer changed%';
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'PRICE FAIL: client forged price accepted'; END IF;
  IF (SELECT count(*) FROM public.digiy_beauty_bookings)<>0 THEN
    RAISE EXCEPTION 'PRICE FAIL: forged booking inserted';
  END IF;
  SELECT booking_id INTO v_booking1
  FROM public.digiy_beauty_public_book_v1(
    'beauty-a',v_slot,'Soin test',45,5000,'Client TEST','221771234567');
  IF v_booking1 IS NULL THEN RAISE EXCEPTION 'Valid booking not saved'; END IF;
  IF (SELECT service_price FROM public.digiy_beauty_bookings WHERE id=v_booking1)<>5000 THEN
    RAISE EXCEPTION 'server price not preserved';
  END IF;

  v_denied:=false;
  BEGIN
    PERFORM public.digiy_beauty_public_book_v1(
      'beauty-a',v_slot,'Soin test',45,5000,'Client TEST','221771234567');
  EXCEPTION WHEN OTHERS THEN v_denied:=SQLERRM LIKE 'slot unavailable%';
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'DUPLICATE FAIL: booked slot accepted twice'; END IF;

  v_denied:=false;
  BEGIN
    PERFORM public.digiy_beauty_owner_set_slot_status_v1(v_slot,'available');
  EXCEPTION WHEN OTHERS THEN v_denied:=SQLERRM LIKE 'slot has an active booking%';
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'OWNER FAIL: opened active booked slot'; END IF;

  PERFORM set_config('request.jwt.claim.sub',v_owner_b::text,false);
  v_denied:=false;
  BEGIN
    PERFORM public.digiy_beauty_owner_set_booking_status_v1(v_booking1,'cancelled');
  EXCEPTION WHEN OTHERS THEN v_denied:=SQLERRM LIKE 'booking not owned%';
  END;
  IF NOT v_denied THEN RAISE EXCEPTION 'OWNER FAIL: B cancelled A booking'; END IF;

  PERFORM set_config('request.jwt.claim.sub',v_owner_a::text,false);
  PERFORM public.digiy_beauty_owner_set_booking_status_v1(v_booking1,'cancelled');
  IF (SELECT status FROM public.digiy_beauty_master_slots WHERE id=v_slot)<>'available' THEN
    RAISE EXCEPTION 'CANCEL FAIL: slot not released';
  END IF;

  SELECT booking_id INTO v_booking2
  FROM public.digiy_beauty_public_book_v1(
    'beauty-a',v_slot,'Soin test',45,5000,'Client TEST 2','221771234568');
  IF v_booking2=v_booking1 OR v_booking2 IS NULL THEN RAISE EXCEPTION 'REBOOK FAIL'; END IF;
  IF (SELECT count(*) FROM public.digiy_beauty_bookings WHERE slot_id=v_slot)<>2 THEN
    RAISE EXCEPTION 'HISTORY FAIL: cancellation overwritten';
  END IF;
  IF (SELECT count(*) FROM public.digiy_beauty_bookings
      WHERE slot_id=v_slot AND status IN ('request','confirmed'))<>1 THEN
    RAISE EXCEPTION 'UNIQUE FAIL: incorrect active count';
  END IF;
  PERFORM public.digiy_beauty_owner_set_booking_status_v1(v_booking2,'confirmed');
  IF (SELECT status FROM public.digiy_beauty_bookings WHERE id=v_booking2)<>'confirmed' THEN
    RAISE EXCEPTION 'CONFIRM FAIL';
  END IF;
  PERFORM public.digiy_beauty_owner_set_booking_status_v1(v_booking2,'cancelled');
  IF (SELECT status FROM public.digiy_beauty_master_slots WHERE id=v_slot)<>'available' THEN
    RAISE EXCEPTION 'CANCEL CONFIRMED FAIL';
  END IF;
  IF (SELECT count(*) FROM public.digiy_beauty_bookings WHERE slot_id=v_slot)<>2 THEN
    RAISE EXCEPTION 'HISTORY FAIL after second cancellation';
  END IF;
  RAISE NOTICE 'PASS: anonymous denial, ownership, V2 ids, trusted prices, duplicate guard, cancellation, rebook, history';
END;
$verify$;
