-- P0 DIGIY RESA: private bookings may not be read with an anonymous slug.
-- Snapshot reviewed on digiy-core 2026-10-09; original definition preserved in
-- docs/RESA_BEAUTY_SECURITY_AUDIT_20261009.md for rollback review.
-- No customer rows are read or changed by this migration.
BEGIN;

CREATE OR REPLACE FUNCTION public.digiy_resa_get_bookings_by_day(p_slug text, p_date date)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $function$
DECLARE
  v_src jsonb;
  v_rows jsonb := '[]'::jsonb;
BEGIN
  -- This function returns reservation records including names and phone numbers.
  -- An arbitrary slug is not proof of ownership.
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.digiy_resa_profiles AS p
    WHERE p.slug = p_slug AND p.is_active IS TRUE
      AND p.auth_user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'reservation access denied' USING ERRCODE='42501';
  END IF;

  IF p_date IS NULL THEN
    RAISE EXCEPTION 'invalid booking date' USING ERRCODE='22023';
  END IF;

  v_src := public.resa_list_recent_bookings_by_slug(p_slug, 1000);
  IF v_src IS NULL THEN
    RETURN jsonb_build_object('ok',true,'bookings','[]'::jsonb,'count',0);
  END IF;

  IF jsonb_typeof(v_src)='object' AND (v_src ? 'ok')
     AND coalesce((v_src->>'ok')::boolean,true)=false THEN
    RETURN v_src;
  END IF;

  WITH src_rows AS (
    SELECT elem FROM jsonb_array_elements(
      CASE
        WHEN jsonb_typeof(v_src)='array' THEN v_src
        WHEN jsonb_typeof(v_src->'bookings')='array' THEN v_src->'bookings'
        WHEN jsonb_typeof(v_src->'rows')='array' THEN v_src->'rows'
        WHEN jsonb_typeof(v_src->'data')='array' THEN v_src->'data'
        ELSE '[]'::jsonb
      END
    ) AS elem
  ), filtered AS (
    SELECT elem FROM src_rows
    WHERE coalesce(elem->>'booking_date',elem->>'reservation_date',elem->>'date') = p_date::text
  )
  SELECT coalesce(jsonb_agg(elem),'[]'::jsonb) INTO v_rows FROM filtered;
  RETURN jsonb_build_object('ok',true,'bookings',v_rows,'count',jsonb_array_length(v_rows));
END;
$function$;

-- Explicitly prevent any anonymous call, including inherited PUBLIC EXECUTE.
REVOKE ALL ON FUNCTION public.digiy_resa_get_bookings_by_day(text,date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.digiy_resa_get_bookings_by_day(text,date) TO authenticated, service_role;

COMMIT;
