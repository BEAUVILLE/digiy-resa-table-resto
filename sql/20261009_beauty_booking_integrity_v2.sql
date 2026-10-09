-- DIGIY BEAUTY: verified against digiy-core PostgreSQL 17 (2026-10-09)
-- Pilot tables had 0 bookings and 42 available slots at the read-only preflight.
-- Apply only after approval of the compatible frontend change.
-- The generic RESTO/LOC engines are not modified here.

-- Preserve cancelled requests for audit while preventing concurrent active claims.
-- Existing UNIQUE(slot_id) also covers cancelled requests, making a cancelled
-- slot impossible to book a second time.
ALTER TABLE public.digiy_beauty_bookings
  DROP CONSTRAINT IF EXISTS digiy_beauty_bookings_slot_id_key;

CREATE UNIQUE INDEX IF NOT EXISTS digiy_beauty_bookings_one_active_slot_v2
  ON public.digiy_beauty_bookings (slot_id)
  WHERE status IN ('request','confirmed');

-- The V1 public slots RPC only returns (slot_time,status). The existing client
-- expects an id, so expose a new V2 instead of changing V1's return type.
CREATE OR REPLACE FUNCTION public.digiy_beauty_public_slots_v2(p_slug text,p_day date)
RETURNS TABLE(id uuid,slot_time time without time zone,status text)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
  SELECT s.id,s.slot_time,s.status
  FROM public.digiy_beauty_master_slots s
  JOIN public.digiy_beauty_master_members b ON b.id=s.beauty_id
  WHERE b.slug=p_slug AND b.is_active IS TRUE AND s.slot_day=p_day
  ORDER BY s.slot_time;
$function$;
REVOKE ALL ON FUNCTION public.digiy_beauty_public_slots_v2(text,date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.digiy_beauty_public_slots_v2(text,date) TO anon, authenticated;

-- Derive the price and duration from the OWNER's configured catalogue, not from
-- user-controlled RPC parameters. Keep V1 signature for the deployed client.
CREATE OR REPLACE FUNCTION public.digiy_beauty_public_book_v1(
  p_slug text,p_slot_id uuid,p_service_name text,p_service_duration_min integer,
  p_service_price integer,p_client_name text,p_client_whatsapp text
)
RETURNS TABLE(booking_id uuid,status text)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $function$
DECLARE
  v_beauty_id uuid;
  v_catalog jsonb;
  v_matches jsonb;
  v_service jsonb;
  v_duration_txt text;
  v_price_txt text;
  v_duration integer;
  v_price integer;
  v_slot_status text;
  v_new_booking uuid;
  v_phone text;
BEGIN
  SELECT b.id,b.services INTO v_beauty_id,v_catalog
  FROM public.digiy_beauty_master_members b
  WHERE b.slug=p_slug AND b.is_active IS TRUE LIMIT 1;
  IF v_beauty_id IS NULL THEN RAISE EXCEPTION 'beauty not found'; END IF;
  IF jsonb_typeof(v_catalog) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'service catalogue unavailable';
  END IF;

  SELECT jsonb_agg(x.value) INTO v_matches
  FROM jsonb_array_elements(v_catalog) x(value)
  WHERE jsonb_typeof(x.value)='object'
    AND btrim(coalesce(x.value->>'name',''))=btrim(coalesce(p_service_name,''));
  IF v_matches IS NULL OR jsonb_array_length(v_matches)<>1 THEN
    RAISE EXCEPTION 'service unavailable or ambiguous';
  END IF;
  v_service := v_matches->0;
  v_duration_txt := v_service->>'duration_min';
  v_price_txt := v_service->>'price';
  IF v_duration_txt IS NULL OR v_duration_txt !~ '^[0-9]{1,4}$'
    OR v_price_txt IS NULL OR v_price_txt !~ '^[0-9]{1,8}$' THEN
    RAISE EXCEPTION 'invalid service configuration';
  END IF;
  v_duration := v_duration_txt::integer;
  v_price := v_price_txt::integer;
  IF v_duration<5 OR v_duration>1440 THEN
    RAISE EXCEPTION 'invalid service duration';
  END IF;
  -- Mismatched displayed offer is never silently accepted or stored.
  IF p_service_duration_min IS DISTINCT FROM v_duration
    OR p_service_price IS DISTINCT FROM v_price THEN
    RAISE EXCEPTION 'service offer changed; reload';
  END IF;

  IF length(btrim(coalesce(p_client_name,''))) NOT BETWEEN 2 AND 120 THEN
    RAISE EXCEPTION 'invalid client name';
  END IF;
  v_phone := regexp_replace(coalesce(p_client_whatsapp,''),'[^0-9]','','g');
  IF length(v_phone) NOT BETWEEN 7 AND 20 THEN
    RAISE EXCEPTION 'invalid client whatsapp';
  END IF;

  -- Row lock plus partial unique index: one active request per slot,
  -- while old cancelled bookings remain accessible as history.
  SELECT s.status INTO v_slot_status
  FROM public.digiy_beauty_master_slots s
  WHERE s.id=p_slot_id AND s.beauty_id=v_beauty_id
  FOR UPDATE;
  IF v_slot_status IS DISTINCT FROM 'available' THEN
    RAISE EXCEPTION 'slot unavailable';
  END IF;
  UPDATE public.digiy_beauty_master_slots
    SET status='booked'
    WHERE id=p_slot_id AND beauty_id=v_beauty_id;
  INSERT INTO public.digiy_beauty_bookings(
    beauty_id,slot_id,service_name,service_duration_min,service_price,
    client_name,client_whatsapp,status
  ) VALUES (
    v_beauty_id,p_slot_id,btrim(p_service_name),v_duration,v_price,
    btrim(p_client_name),v_phone,'request'
  ) RETURNING id INTO v_new_booking;
  RETURN QUERY SELECT v_new_booking,'request'::text;
END;
$function$;

-- Deterministic owner-only state transitions, with locks in the same order as
-- public booking: slot first, then booking.
CREATE OR REPLACE FUNCTION public.digiy_beauty_owner_set_booking_status_v1(
  p_booking_id uuid,p_status text
)
RETURNS TABLE(id uuid,status text)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $function$
DECLARE
  v_slot_id uuid;
  v_previous_status text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  IF p_status NOT IN ('confirmed','cancelled') THEN
    RAISE EXCEPTION 'invalid status';
  END IF;
  SELECT bk.slot_id INTO v_slot_id
  FROM public.digiy_beauty_bookings bk
  JOIN public.digiy_beauty_master_members b ON b.id=bk.beauty_id
  WHERE bk.id=p_booking_id AND b.owner_id=auth.uid()
    AND b.is_active IS TRUE;
  IF v_slot_id IS NULL THEN RAISE EXCEPTION 'booking not owned by current user'; END IF;

  PERFORM 1 FROM public.digiy_beauty_master_slots s WHERE s.id=v_slot_id FOR UPDATE;
  SELECT bk.status INTO v_previous_status
  FROM public.digiy_beauty_bookings bk WHERE bk.id=p_booking_id FOR UPDATE;
  IF v_previous_status IS NULL THEN RAISE EXCEPTION 'booking missing'; END IF;
  IF v_previous_status=p_status THEN
    RETURN QUERY SELECT p_booking_id,p_status;
    RETURN;
  END IF;
  IF v_previous_status NOT IN ('request','confirmed')
    OR (v_previous_status='confirmed' AND p_status<>'cancelled') THEN
    RAISE EXCEPTION 'invalid booking transition';
  END IF;
  UPDATE public.digiy_beauty_bookings bk
  SET status=p_status WHERE bk.id=p_booking_id;
  UPDATE public.digiy_beauty_master_slots s
  SET status=CASE WHEN p_status='confirmed' THEN 'booked' ELSE 'available' END
  WHERE s.id=v_slot_id;
  RETURN QUERY SELECT p_booking_id,p_status;
END;
$function$;

-- Prevent manually re-opening a slot whose request remains active.
CREATE OR REPLACE FUNCTION public.digiy_beauty_owner_set_slot_status_v1(
  p_slot_id uuid,p_status text
)
RETURNS TABLE(id uuid,slot_time time without time zone,status text)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  IF p_status NOT IN ('available','blocked','booked') THEN
    RAISE EXCEPTION 'invalid status';
  END IF;
  PERFORM 1
  FROM public.digiy_beauty_master_slots s
  JOIN public.digiy_beauty_master_members b ON b.id=s.beauty_id
  WHERE s.id=p_slot_id AND b.owner_id=auth.uid() AND b.is_active IS TRUE
  FOR UPDATE OF s;
  IF NOT FOUND THEN RAISE EXCEPTION 'slot not owned by current user'; END IF;
  IF p_status<>'booked' AND EXISTS (
    SELECT 1 FROM public.digiy_beauty_bookings bk
    WHERE bk.slot_id=p_slot_id AND bk.status IN ('request','confirmed')
  ) THEN
    RAISE EXCEPTION 'slot has an active booking';
  END IF;
  UPDATE public.digiy_beauty_master_slots s SET status=p_status WHERE s.id=p_slot_id;
  RETURN QUERY SELECT s.id,s.slot_time,s.status
    FROM public.digiy_beauty_master_slots s WHERE s.id=p_slot_id;
END;
$function$;

-- Strict privileges on the owner RPCs; public booking remains callable.
REVOKE ALL ON FUNCTION public.digiy_beauty_owner_set_booking_status_v1(uuid,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.digiy_beauty_owner_set_slot_status_v1(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.digiy_beauty_owner_set_booking_status_v1(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.digiy_beauty_owner_set_slot_status_v1(uuid,text) TO authenticated;
