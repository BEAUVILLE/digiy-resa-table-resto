-- DIGIY RÉSA UNIVERSEL V3: timezone conversion candidate, PG17 disposable ONLY.
-- This helper is NOT wired to live bookings; existing Dakar V0 remains unchanged.
-- Reject the Paris daylight-saving gap and fall-back duplicated hour.
DO $gate$
BEGIN
 IF current_database() <> 'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V3 IANA helper is for disposable digiy_appointments_test ONLY';
 END IF;
END $gate$;

CREATE OR REPLACE FUNCTION public.digiy_resa_local_time_to_utc_v3(
 p_local timestamp without time zone, p_zone text
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY INVOKER
SET search_path = pg_catalog
AS $function$
DECLARE
 v_utc timestamptz;
 v_offset integer;
 v_other timestamptz;
BEGIN
 IF p_local IS NULL OR p_zone IS NULL OR p_zone NOT IN ('Africa/Dakar','Europe/Paris') THEN
  RETURN jsonb_build_object('ok',false,'error','unsupported_timezone');
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name=p_zone) THEN
  RETURN jsonb_build_object('ok',false,'error','unknown_timezone');
 END IF;
 v_utc := p_local AT TIME ZONE p_zone;
 -- PostgreSQL may normalize nonexistent local wall-clock times.
 IF (v_utc AT TIME ZONE p_zone) <> p_local THEN
  RETURN jsonb_build_object('ok',false,'error','nonexistent_local_time');
 END IF;
 -- PostgreSQL chooses one offset for ambiguous fall-back hours; refuse
 -- both rather than silently booking the wrong occurrence.
 FOREACH v_offset IN ARRAY ARRAY[-180,-120,-60,60,120,180] LOOP
  v_other:=v_utc+make_interval(mins=>v_offset);
  IF (v_other AT TIME ZONE p_zone)=p_local THEN
   RETURN jsonb_build_object('ok',false,'error','ambiguous_local_time');
  END IF;
 END LOOP;
 RETURN jsonb_build_object('ok',true,'time_zone',p_zone,
  'utc',to_char(v_utc AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'));
END
$function$;

REVOKE ALL ON FUNCTION public.digiy_resa_local_time_to_utc_v3(
 timestamp without time zone,text) FROM PUBLIC,anon,authenticated;
-- Internal server-side conversion only; intentionally not callable by anon.
GRANT EXECUTE ON FUNCTION public.digiy_resa_local_time_to_utc_v3(
 timestamp without time zone,text) TO service_role;
