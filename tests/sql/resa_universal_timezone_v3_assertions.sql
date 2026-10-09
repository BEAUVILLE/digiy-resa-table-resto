-- Isolated test matrix: Paris 2026 DST spring/fall, Dakar, API isolation.
DO $check$
DECLARE
 r jsonb;
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'isolated timezone tests only';
 END IF;
 IF has_function_privilege('anon',
  'public.digiy_resa_local_time_to_utc_v3(timestamp without time zone,text)',
  'EXECUTE') THEN
  RAISE EXCEPTION 'anon can invoke internal IANA converter';
 END IF;
 IF has_function_privilege('authenticated',
  'public.digiy_resa_local_time_to_utc_v3(timestamp without time zone,text)',
  'EXECUTE') THEN
  RAISE EXCEPTION 'authenticated can invoke internal IANA converter';
 END IF;
 IF NOT has_function_privilege('service_role',
  'public.digiy_resa_local_time_to_utc_v3(timestamp without time zone,text)',
  'EXECUTE') THEN
  RAISE EXCEPTION 'service_role cannot invoke internal IANA converter';
 END IF;
 r:=public.digiy_resa_local_time_to_utc_v3(
  '2026-03-29 01:30:00','Europe/Paris');
 IF r->>'utc'<>'2026-03-29T00:30:00Z' THEN
  RAISE EXCEPTION 'Paris before spring DST wrong %',r;
 END IF;
 r:=public.digiy_resa_local_time_to_utc_v3(
  '2026-03-29 02:30:00','Europe/Paris');
 IF r->>'error'<>'nonexistent_local_time' THEN
  RAISE EXCEPTION 'Paris spring gap accepted %',r;
 END IF;
 r:=public.digiy_resa_local_time_to_utc_v3(
  '2026-03-29 03:30:00','Europe/Paris');
 IF r->>'utc'<>'2026-03-29T01:30:00Z' THEN
  RAISE EXCEPTION 'Paris after spring DST wrong %',r;
 END IF;
 r:=public.digiy_resa_local_time_to_utc_v3(
  '2026-10-25 01:30:00','Europe/Paris');
 IF r->>'utc'<>'2026-10-24T23:30:00Z' THEN
  RAISE EXCEPTION 'Paris before fall DST wrong %',r;
 END IF;
 r:=public.digiy_resa_local_time_to_utc_v3(
  '2026-10-25 02:30:00','Europe/Paris');
 IF r->>'error'<>'ambiguous_local_time' THEN
  RAISE EXCEPTION 'Paris fall repeat hour accepted %',r;
 END IF;
 r:=public.digiy_resa_local_time_to_utc_v3(
  '2026-10-25 03:30:00','Europe/Paris');
 IF r->>'utc'<>'2026-10-25T02:30:00Z' THEN
  RAISE EXCEPTION 'Paris after fall DST wrong %',r;
 END IF;
 r:=public.digiy_resa_local_time_to_utc_v3(
  '2026-03-29 02:30:00','Africa/Dakar');
 IF r->>'utc'<>'2026-03-29T02:30:00Z' THEN
  RAISE EXCEPTION 'Dakar spring local wrong %',r;
 END IF;
 r:=public.digiy_resa_local_time_to_utc_v3(
  '2026-10-25 02:30:00','Africa/Dakar');
 IF r->>'utc'<>'2026-10-25T02:30:00Z' THEN
  RAISE EXCEPTION 'Dakar autumn local wrong %',r;
 END IF;
 r:=public.digiy_resa_local_time_to_utc_v3(
  '2026-10-25 02:30:00','Europe/Invalid');
 IF r->>'error'<>'unsupported_timezone' THEN
  RAISE EXCEPTION 'unknown zone accepted %',r;
 END IF;
 RAISE NOTICE 'PASS: Paris gap and duplicate hour rejected; Dakar stable; UTC conversion, restricted EXECUTE';
END $check$;
