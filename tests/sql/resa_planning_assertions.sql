-- Isolated PostgreSQL 17: verify published-only availability, no client data,
-- owner-only future BEAUTY openings, and idempotence.
DO $verify$
DECLARE
 v_start date:=current_date+7;
 v_mon date:=current_date+(8-extract(isodow FROM current_date)::integer);
 v jsonb;
 v2 jsonb;
 v_test uuid;
 v_result jsonb;
 v_blocked_id uuid;
 v_denied boolean;
BEGIN
 IF NOT has_function_privilege('anon','public.digiy_resa_public_week_v1(text,date)','EXECUTE')
 THEN RAISE EXCEPTION 'anon cannot view public appointments'; END IF;
 IF has_function_privilege('anon','public.digiy_beauty_owner_open_week_v1(text,date,time[],integer[])','EXECUTE')
 THEN RAISE EXCEPTION 'anon can open a private BEAUTY week'; END IF;
 v:=public.digiy_resa_public_week_v1('resa-owner-a',v_start);
 IF v->>'ok'<>'true' OR jsonb_array_length(v->'slots')<>3 THEN
  RAISE EXCEPTION 'public appointment window missing';
 END IF;
 IF (SELECT count(*) FROM jsonb_array_elements(v->'slots') x
     WHERE x->>'available'='true')<>1
 THEN RAISE EXCEPTION 'availability ignores closed or booked slot'; END IF;
 IF v::text LIKE '%private test note%' OR v::text LIKE '%customer_name%'
   OR v::text LIKE '%customer_phone%' OR v::text LIKE '%secret closure%'
 THEN RAISE EXCEPTION 'private information leaked'; END IF;
 IF v->>'public_whatsapp'<>'221771234567' THEN RAISE EXCEPTION 'public contact missing'; END IF;
 IF (public.digiy_resa_public_week_v1('resa-owner-b',v_start)->>'ok')<>'false' THEN
  RAISE EXCEPTION 'unpublished test returned public availability'; END IF;
 IF (public.digiy_resa_public_week_v1('resa-owner-a',current_date-1)->>'ok')<>'false' THEN
  RAISE EXCEPTION 'past day allowed'; END IF;
 PERFORM set_config('request.jwt.claim.sub','',false);
 v_denied:=false;
 BEGIN
  PERFORM public.digiy_beauty_owner_open_week_v1(
   'beauty-a',v_mon,ARRAY['09:00','11:00']::time[],ARRAY[1,3,5]);
 EXCEPTION WHEN insufficient_privilege THEN v_denied:=true;
 END;
 IF NOT v_denied THEN RAISE EXCEPTION 'no user can open a week'; END IF;
 PERFORM set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
 v_result:=public.digiy_beauty_owner_open_week_v1(
  'beauty-a',v_mon,ARRAY['09:00','11:00']::time[],ARRAY[1,3,5]);
 IF (v_result->>'added')::int<>6 THEN
  RAISE EXCEPTION 'expected 6 new owner-selected slots, got %',v_result;
 END IF;
 v2:=public.digiy_beauty_owner_open_week_v1(
  'beauty-a',v_mon,ARRAY['09:00','11:00']::time[],ARRAY[1,3,5]);
 IF (v2->>'added')::int<>0 THEN RAISE EXCEPTION 'opening same week must be idempotent'; END IF;
 SELECT id INTO v_blocked_id FROM public.digiy_beauty_master_slots
 WHERE beauty_id='10101010-1010-4010-8010-101010101010'
 AND slot_day=v_mon AND slot_time='09:00' LIMIT 1;
 UPDATE public.digiy_beauty_master_slots SET status='blocked' WHERE id=v_blocked_id;
 PERFORM public.digiy_beauty_owner_open_week_v1(
  'beauty-a',v_mon,ARRAY['09:00','11:00']::time[],ARRAY[1,3,5]);
 IF (SELECT status FROM public.digiy_beauty_master_slots WHERE id=v_blocked_id)<>'blocked'
 THEN RAISE EXCEPTION 'previous block overwritten'; END IF;
 PERFORM set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',false);
 v_denied:=false;
 BEGIN
  PERFORM public.digiy_beauty_owner_open_week_v1(
   'beauty-a',v_mon,ARRAY['15:00']::time[],ARRAY[1]);
 EXCEPTION WHEN insufficient_privilege THEN v_denied:=true;
 END;
 IF NOT v_denied THEN RAISE EXCEPTION 'owner B can open A appointment slots'; END IF;
 RAISE NOTICE 'PASS: real published-only slots, no private leak, owner A/B, selected weekdays, block preservation and idempotence';
END;
$verify$;
