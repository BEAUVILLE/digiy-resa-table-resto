-- DIGIY RÉSA UNIVERSEL — public booking options, disposable PG17 ONLY.
-- This deliberately does not change public_week_v1 or deploy to digiy-core.
-- It exposes IDs needed by the already-tested V0 request RPC, never client PII.
DO $guard$
BEGIN
 IF current_database() <> 'digiy_appointments_test' THEN
  RAISE EXCEPTION 'Public options candidate restricted to disposable digiy_appointments_test';
 END IF;
 IF to_regprocedure('public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)') IS NULL THEN
  RAISE EXCEPTION 'V0 isolated reservation candidate must be installed first';
 END IF;
END $guard$;

-- Only the throwaway fixture gains this nullable field. Real IANA support
-- remains a separate production design and France is explicitly NO-GO.
ALTER TABLE public.digiy_resa_profiles ADD COLUMN IF NOT EXISTS time_zone text;

CREATE OR REPLACE FUNCTION public.digiy_resa_universal_public_options_v1(
 p_slug text, p_start_date date
)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
DECLARE
 v_slug text := lower(btrim(coalesce(p_slug,'')));
 v_tz text;
 v_local_now timestamp;
 v_services jsonb;
 v_slots jsonb;
BEGIN
 IF v_slug !~ '^[a-z0-9_-]{2,150}$' OR p_start_date IS NULL THEN
  RETURN jsonb_build_object('ok',false,'error','invalid_request');
 END IF;
 SELECT p.time_zone INTO v_tz
 FROM public.digiy_resa_profiles p
 WHERE p.slug=v_slug AND p.is_active IS TRUE AND p.is_published IS TRUE
 LIMIT 1;
 IF NOT FOUND THEN
  RETURN jsonb_build_object('ok',false,'error','not_published');
 END IF;
 IF coalesce(v_tz,'') <> 'Africa/Dakar' THEN
  RETURN jsonb_build_object('ok',false,'error','unsupported_timezone');
 END IF;
 v_local_now := statement_timestamp() AT TIME ZONE v_tz;
 IF p_start_date < v_local_now::date OR p_start_date > v_local_now::date + 56 THEN
  RETURN jsonb_build_object('ok',false,'error','outside_booking_window');
 END IF;

 -- A catalogue is a read-only indication. The request RPC independently
 -- reads server-side price, duration and ownership at transaction time.
 SELECT coalesce(jsonb_agg(jsonb_build_object(
  'service_id',svc.id,
  'name',svc.service_name,
  'duration_minutes',svc.duration_minutes,
  'price_fcfa',svc.price_fcfa
 ) ORDER BY svc.service_name,svc.id),'[]'::jsonb)
 INTO v_services
 FROM public.digiy_resa_services svc
 WHERE svc.slug=v_slug AND svc.is_active IS TRUE
   AND svc.duration_minutes BETWEEN 5 AND 480;

 SELECT coalesce(jsonb_agg(jsonb_build_object(
  'slot_id',s.id,
  'date',s.slot_date,
  'time',to_char(s.start_time,'HH24:MI'),
  'end',to_char(s.end_time,'HH24:MI'),
  'service_ids',(
    SELECT coalesce(jsonb_agg(svc.id ORDER BY svc.service_name,svc.id),'[]'::jsonb)
    FROM public.digiy_resa_services svc
    WHERE svc.slug=v_slug AND svc.is_active IS TRUE
      AND svc.duration_minutes BETWEEN 5 AND 480
      AND s.end_time > s.start_time
      AND (s.slot_date + s.start_time
        + make_interval(mins=>svc.duration_minutes)) <=
          (s.slot_date + s.end_time)
  ),
  'available',(
    s.status='open' AND coalesce(s.capacity,1)=1
    AND s.end_time > s.start_time
    AND s.slot_date + s.start_time > v_local_now
    AND EXISTS (
      SELECT 1 FROM public.digiy_resa_services svc
      WHERE svc.slug=v_slug AND svc.is_active IS TRUE
        AND svc.duration_minutes BETWEEN 5 AND 480
        AND s.slot_date+s.start_time
          +make_interval(mins=>svc.duration_minutes)
          <=s.slot_date+s.end_time
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.digiy_resa_bookings b
      WHERE b.slug=v_slug AND b.booking_date=s.slot_date
        AND coalesce(b.status,'pending') IN ('pending','confirmed')
        AND (s.slot_date+s.start_time) <
            (b.booking_date+b.booking_time
             +make_interval(mins=>greatest(5,coalesce(b.duration_minutes,30))))
        AND (s.slot_date+s.end_time) > (b.booking_date+b.booking_time)
    )
  )
 ) ORDER BY s.slot_date,s.start_time,s.id),'[]'::jsonb)
 INTO v_slots
 FROM public.digiy_resa_slots s
 WHERE s.slug=v_slug
   AND s.slot_date BETWEEN p_start_date AND (p_start_date+6)
   AND s.slot_date >= v_local_now::date;

 RETURN jsonb_build_object('ok',true,
   'slug',v_slug,'time_zone',v_tz,'start_date',p_start_date,
   'services',v_services,'slots',v_slots);
END $function$;

REVOKE ALL ON FUNCTION public.digiy_resa_universal_public_options_v1(text,date)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.digiy_resa_universal_public_options_v1(text,date)
 TO anon,authenticated;
