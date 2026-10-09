-- DIGIY RÉSA UNIVERSEL V0 — CANDIDATE SQL FOR DISPOSABLE PG17 ONLY.
-- NEVER RUN ON digiy-core. Before even parsing DDL, fail on unexpected DB.
-- Public RESTO/LOC/DRIVER and all legacy RPCs intentionally unchanged.
DO $guard$
BEGIN
 IF current_database() <> 'digiy_appointments_test' THEN
   RAISE EXCEPTION 'RÉSA universal candidate: isolated digiy_appointments_test ONLY';
 END IF;
END;
$guard$;

CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE public.digiy_resa_bookings
 ADD COLUMN IF NOT EXISTS client_request_id uuid;
CREATE UNIQUE INDEX IF NOT EXISTS digiy_resa_universal_idempotency_v0
 ON public.digiy_resa_bookings(slug,client_request_id)
 WHERE client_request_id IS NOT NULL;

-- Unlike the existing same-start-time unique index, this also protects
-- different start times whose service durations overlap.
-- CAUTION: Requires live legacy conflict review before a *separate* real migration.
ALTER TABLE public.digiy_resa_bookings
 ADD CONSTRAINT digiy_resa_universal_no_overlap_v0
 EXCLUDE USING gist (
   slug WITH =,
   tsrange(
     booking_date + booking_time,
     booking_date + booking_time +
       make_interval(mins => greatest(5,coalesce(duration_minutes,30))),
     '[)'
   ) WITH &&
 ) WHERE (status IN ('pending','confirmed'));

CREATE OR REPLACE FUNCTION public.digiy_resa_universal_request_v0(
 p_slug text,
 p_slot_id uuid,
 p_service_id uuid,
 p_client_name text,
 p_client_phone text,
 p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog,public
AS $function$
DECLARE
 v_slug text := lower(btrim(coalesce(p_slug,'')));
 v_profile public.digiy_resa_profiles%ROWTYPE;
 v_slot public.digiy_resa_slots%ROWTYPE;
 v_service public.digiy_resa_services%ROWTYPE;
 v_existing public.digiy_resa_bookings%ROWTYPE;
 v_phone text := regexp_replace(coalesce(p_client_phone,''),'[^0-9]','','g');
 v_booking_id uuid;
 v_now_local timestamp;
BEGIN
 IF v_slug='' OR length(v_slug)>150
    OR p_slot_id IS NULL OR p_service_id IS NULL OR p_request_id IS NULL THEN
   RETURN jsonb_build_object('ok',false,'error','invalid_request');
 END IF;
 IF length(btrim(coalesce(p_client_name,''))) NOT BETWEEN 2 AND 120
    OR length(v_phone) NOT BETWEEN 7 AND 18 THEN
   RETURN jsonb_build_object('ok',false,'error','invalid_contact');
 END IF;

 SELECT * INTO v_profile FROM public.digiy_resa_profiles
 WHERE slug=v_slug AND is_active IS TRUE AND is_published IS TRUE;
 IF NOT FOUND THEN
   RETURN jsonb_build_object('ok',false,'error','not_published');
 END IF;

 SELECT * INTO v_slot FROM public.digiy_resa_slots
 WHERE id=p_slot_id AND slug=v_slug;
 IF NOT FOUND THEN
   RETURN jsonb_build_object('ok',false,'error','invalid_slot');
 END IF;

 -- Single tenant/day advisory lock covers different overlapping slot IDs too.
 -- Existing historical RPCs do NOT take this lock; GiST exclusion catches them.
 PERFORM pg_advisory_xact_lock(hashtextextended(v_slug||':'||v_slot.slot_date::text,0));

 SELECT * INTO v_existing FROM public.digiy_resa_bookings
 WHERE slug=v_slug AND client_request_id=p_request_id;
 IF FOUND THEN
   IF v_existing.booking_date=v_slot.slot_date
      AND v_existing.booking_time=v_slot.start_time
      AND v_existing.service_id=p_service_id
      AND v_existing.customer_phone=v_phone THEN
     RETURN jsonb_build_object('ok',true,'already',true,
       'booking_id',v_existing.id,'status',v_existing.status);
   END IF;
   RETURN jsonb_build_object('ok',false,'error','request_key_reused');
 END IF;

 SELECT * INTO v_slot FROM public.digiy_resa_slots
 WHERE id=p_slot_id AND slug=v_slug FOR UPDATE;
 IF NOT FOUND OR v_slot.status<>'open'
    OR coalesce(v_slot.capacity,1)<>1 THEN
   RETURN jsonb_build_object('ok',false,'error','slot_unavailable');
 END IF;

 -- Explicit pilot timezone: no automatic France deployment until profile
 -- IANA timezone and DST handling are implemented and tested (G07 blocked).
 v_now_local := timezone('Africa/Dakar',clock_timestamp());
 IF (v_slot.slot_date + v_slot.start_time) <= v_now_local
    OR v_slot.slot_date>v_now_local::date+56 THEN
   RETURN jsonb_build_object('ok',false,'error','outside_booking_window');
 END IF;

 SELECT * INTO v_service FROM public.digiy_resa_services
 WHERE id=p_service_id AND slug=v_slug AND is_active IS TRUE;
 IF NOT FOUND OR v_service.duration_minutes IS NULL
    OR v_service.duration_minutes NOT BETWEEN 5 AND 480 THEN
   RETURN jsonb_build_object('ok',false,'error','invalid_service');
 END IF;

 -- For V0 the professional must define a real bounded slot. No default.
 IF v_slot.end_time IS NULL
    OR v_slot.slot_date+v_slot.start_time+
       make_interval(mins=>v_service.duration_minutes) >
       v_slot.slot_date+v_slot.end_time THEN
   RETURN jsonb_build_object('ok',false,'error','service_exceeds_slot');
 END IF;

 IF EXISTS (
  SELECT 1 FROM public.digiy_resa_bookings b
  WHERE b.slug=v_slug AND b.booking_date=v_slot.slot_date
    AND b.status IN ('pending','confirmed')
    AND (b.booking_date+b.booking_time) <
        (v_slot.slot_date+v_slot.start_time+make_interval(mins=>v_service.duration_minutes))
    AND (b.booking_date+b.booking_time+
         make_interval(mins=>greatest(5,coalesce(b.duration_minutes,30)))) >
        (v_slot.slot_date+v_slot.start_time)
 ) THEN
   RETURN jsonb_build_object('ok',false,'error','slot_unavailable');
 END IF;

 -- Pending is deliberate: inserting "confirmed" without audited PAY trigger
 -- semantics could record income without an actual payment. Auto-confirmation
 -- requires a separately approved SQL phase, never assumed from client state.
 INSERT INTO public.digiy_resa_bookings
 (slug,owner_id,customer_name,customer_phone,phone,
  booking_date,booking_time,guests_count,status,
  service_id,service_name,duration_minutes,price_fcfa,client_request_id)
 VALUES
 (v_slug,v_profile.owner_id,btrim(p_client_name),v_phone,v_phone,
  v_slot.slot_date,v_slot.start_time,1,'pending',
  v_service.id,v_service.service_name,v_service.duration_minutes,
  v_service.price_fcfa,p_request_id)
 RETURNING id INTO v_booking_id;

 RETURN jsonb_build_object('ok',true,'already',false,
   'booking_id',v_booking_id,'status','pending');
EXCEPTION
 WHEN exclusion_violation OR unique_violation THEN
   RETURN jsonb_build_object('ok',false,'error','slot_unavailable');
END;
$function$;

REVOKE ALL ON FUNCTION public.digiy_resa_universal_request_v0(
 text,uuid,uuid,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.digiy_resa_universal_request_v0(
 text,uuid,uuid,text,text,uuid) TO anon,authenticated;
