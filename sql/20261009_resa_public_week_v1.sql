-- DIGIY RÉSA MULTI: public, read-only weekly calendar.
-- Never infer available appointments from default opening hours or empty test profiles.
-- Public output contains NO customer names, phones, notes or private owner fields.
CREATE OR REPLACE FUNCTION public.digiy_resa_public_week_v1(p_slug text,p_start_date date)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
DECLARE
  v_profile public.digiy_resa_profiles%ROWTYPE;
  v_slots jsonb;
BEGIN
  IF p_slug IS NULL OR length(btrim(p_slug)) NOT BETWEEN 2 AND 150
    OR p_start_date IS NULL OR p_start_date < current_date
    OR p_start_date > (current_date + 56) THEN
    RETURN jsonb_build_object('ok',false,'error','invalid_request');
  END IF;

  SELECT p.* INTO v_profile FROM public.digiy_resa_profiles p
  WHERE p.slug=p_slug AND p.is_active IS TRUE AND p.is_published IS TRUE
  LIMIT 1;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok',false,'error','not_published');
  END IF;

  SELECT coalesce(jsonb_agg(
    jsonb_build_object(
      'date',s.slot_date,
      'time',to_char(s.start_time,'HH24:MI'),
      'end',CASE WHEN s.end_time IS NULL THEN NULL ELSE to_char(s.end_time,'HH24:MI') END,
      'available',s.status='open' AND NOT EXISTS(
        SELECT 1 FROM public.digiy_resa_bookings b
        WHERE b.slug=s.slug AND b.booking_date=s.slot_date
          AND b.booking_time=s.start_time
          AND coalesce(b.status,'pending') IN ('pending','confirmed')
      )
    ) ORDER BY s.slot_date,s.start_time
  ),'[]'::jsonb) INTO v_slots
  FROM public.digiy_resa_slots s
  WHERE s.slug=v_profile.slug
    AND s.slot_date BETWEEN p_start_date AND (p_start_date + 6);

  RETURN jsonb_build_object(
    'ok',true,'slug',v_profile.slug,
    'display_name',v_profile.display_name,
    'business_type',v_profile.business_type,
    'city',v_profile.city,
    'start_date',p_start_date,
    'slots',v_slots
  );
END;
$function$;
REVOKE ALL ON FUNCTION public.digiy_resa_public_week_v1(text,date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.digiy_resa_public_week_v1(text,date) TO anon,authenticated;
