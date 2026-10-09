-- An authenticated BEAUTY owner alone can OPEN NEW slots on a chosen week.
-- Existing statuses/bookings are preserved: never auto-open booked/blocked slots.
-- No implicit recurring availability, no demo days inserted by this function.
CREATE OR REPLACE FUNCTION public.digiy_beauty_owner_open_week_v1(
 p_slug text,p_start_date date,p_times time without time zone[],p_weekdays integer[]
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $function$
DECLARE
 v_beauty_id uuid;
 v_added integer;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'authentication required' USING ERRCODE='42501'; END IF;
 SELECT b.id INTO v_beauty_id FROM public.digiy_beauty_master_members b
 WHERE b.slug=p_slug AND b.owner_id=auth.uid() AND b.is_active IS TRUE;
 IF v_beauty_id IS NULL THEN RAISE EXCEPTION 'beauty not owned by current user' USING ERRCODE='42501'; END IF;

 IF p_start_date IS NULL OR extract(isodow FROM p_start_date) <> 1 OR p_start_date < current_date-6 OR p_start_date > current_date+60
 THEN RAISE EXCEPTION 'week outside allowed range' USING ERRCODE='22023'; END IF;
 IF p_weekdays IS NULL OR cardinality(p_weekdays)<1 OR cardinality(p_weekdays)>7
 OR EXISTS(SELECT 1 FROM unnest(p_weekdays) x(dow) WHERE x.dow NOT BETWEEN 1 AND 7 OR x.dow IS NULL)
 OR (SELECT count(DISTINCT x.dow) FROM unnest(p_weekdays) x(dow))<>cardinality(p_weekdays) THEN
   RAISE EXCEPTION 'choose valid weekdays' USING ERRCODE='22023';
 END IF;
 IF p_times IS NULL OR cardinality(p_times)<1 OR cardinality(p_times)>12 THEN
   RAISE EXCEPTION 'choose 1 to 12 appointment times' USING ERRCODE='22023';
 END IF;
 IF EXISTS(SELECT 1 FROM unnest(p_times) x(t)
   WHERE x.t IS NULL OR x.t < TIME '06:00' OR x.t > TIME '22:00') THEN
   RAISE EXCEPTION 'appointment time outside supported window' USING ERRCODE='22023';
 END IF;
 IF (SELECT count(DISTINCT t) FROM unnest(p_times) t) <> cardinality(p_times) THEN
   RAISE EXCEPTION 'duplicate appointment times' USING ERRCODE='22023';
 END IF;

 INSERT INTO public.digiy_beauty_master_slots(beauty_id,slot_day,slot_time,status)
 SELECT v_beauty_id, d::date, t.t,'available'
 FROM generate_series(p_start_date::timestamp,(p_start_date+6)::timestamp,interval '1 day') d
 CROSS JOIN unnest(p_times) t(t)
 WHERE d::date >= current_date AND extract(isodow FROM d)=ANY(p_weekdays)
 ON CONFLICT(beauty_id,slot_day,slot_time) DO NOTHING;
 GET DIAGNOSTICS v_added = ROW_COUNT;

 RETURN jsonb_build_object('ok',true,'days',7,'added',v_added,'existing_or_unchanged',cardinality(p_weekdays)*cardinality(p_times)-v_added);
END;
$function$;
REVOKE ALL ON FUNCTION public.digiy_beauty_owner_open_week_v1(text,date,time without time zone[],integer[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.digiy_beauty_owner_open_week_v1(text,date,time without time zone[],integer[]) TO authenticated;
