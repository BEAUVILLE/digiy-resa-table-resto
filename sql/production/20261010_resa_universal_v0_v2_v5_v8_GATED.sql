-- PRODUCTION CANDIDATE ONLY -- NOT AUTO-DEPLOYED
-- DIGIY RÉSA UNIVERSAL v9 - V0/V2/V5 + server-gated V8 for digiy-core.
-- Last verified SQL shape: 2026-10-10; 7 historic rows, 0 profiles, 0 slots.
-- IMPORTANT: use Supabase apply_migration in its transaction ONLY AFTER:
-- (a) real latest backup independently restored; (b) real A/B Auth staging;
-- (c) owner BAT and security GO; (d) preflight snapshots and operator approval.
-- Never use isolated candidates directly on digiy-core.
-- This SQL performs no data deletion, no automatic pilot activation and no PAY writes.
-- PostgreSQL 17 integration tested against representative legacy SQL fixture.
-- IMPORTANT: production database is 'postgres'; test fixture DB is
-- 'digiy_appointments_test' with explicit session flag (not a security boundary).
DO $preflight$
DECLARE v_policy text;v_trigger text;
BEGIN
 IF current_database() <> 'postgres'
    AND NOT (current_database()='digiy_appointments_test'
             AND current_setting('digiy.resa_fixture_mode',true)='on') THEN
  RAISE EXCEPTION 'RÉSA v9 migration refused on unrecognized database';
 END IF;
 IF to_regclass('public.digiy_resa_bookings') IS NULL
 OR to_regclass('public.digiy_resa_slots') IS NULL
 OR to_regclass('public.digiy_resa_services') IS NULL
 OR to_regclass('public.digiy_resa_profiles') IS NULL THEN
  RAISE EXCEPTION 'RÉSA v9 required live relation missing';
 END IF;
 IF to_regprocedure('public.digiy_resa_create_booking(text,text,text,date,time,integer,text,uuid)') IS NULL THEN
  RAISE EXCEPTION 'RÉSA v9 original legacy booking entrypoint missing';
 END IF;
 IF to_regprocedure('auth.uid()') IS NULL THEN
  RAISE EXCEPTION 'RÉSA v9 Supabase Auth unavailable';
 END IF;
 IF to_regprocedure('public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)') IS NOT NULL
 OR to_regprocedure('public.digiy_resa_universal_public_options_v1(text,date)') IS NOT NULL
 OR to_regprocedure('public.digiy_resa_universal_owner_manage_v2(uuid,text,text)') IS NOT NULL
 OR to_regclass('public.digiy_resa_universal_launch_controls') IS NOT NULL THEN
  RAISE EXCEPTION 'RÉSA v9 deployment already partially/fully installed; review manually';
 END IF;
 IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.digiy_resa_bookings'::regclass) THEN
  RAISE EXCEPTION 'RÉSA v9 live booking RLS disabled';
 END IF;
 SELECT p.qual INTO v_policy FROM pg_policies p
 WHERE p.schemaname='public' AND p.tablename='digiy_resa_bookings'
 AND p.policyname='RESA owner updates own bookings' AND p.cmd='UPDATE';
 IF v_policy IS NULL OR v_policy NOT LIKE '%auth.uid()%' THEN
  RAISE EXCEPTION 'RÉSA v9 original owner update policy unexpected';
 END IF;
 SELECT pg_get_triggerdef(t.oid) INTO v_trigger
 FROM pg_trigger t WHERE t.tgrelid='public.digiy_resa_bookings'::regclass
 AND t.tgname='digiy_resa_push_to_pay_after_status' AND t.tgenabled='O';
 IF v_trigger IS NULL OR v_trigger NOT LIKE '%trg_digiy_resa_push_to_pay%' THEN
  RAISE EXCEPTION 'RÉSA v9 existing PAY trigger unexpectedly changed/missing';
 END IF;
 IF EXISTS(
  SELECT 1 FROM public.digiy_resa_bookings b1
  JOIN public.digiy_resa_bookings b2
  ON b1.id < b2.id AND b1.slug=b2.slug AND b1.booking_date=b2.booking_date
   AND b1.status IN ('pending','confirmed') AND b2.status IN ('pending','confirmed')
   AND (b1.booking_date+b1.booking_time) <
      (b2.booking_date+b2.booking_time+
       make_interval(mins=>greatest(5,coalesce(b2.duration_minutes,30))))
   AND (b2.booking_date+b2.booking_time) <
      (b1.booking_date+b1.booking_time+
       make_interval(mins=>greatest(5,coalesce(b1.duration_minutes,30))))
 ) THEN
  RAISE EXCEPTION 'RÉSA v9 legacy booking overlaps require manual classification';
 END IF;
 IF EXISTS(SELECT 1 FROM public.digiy_resa_profiles
           WHERE is_active IS TRUE AND is_published IS TRUE) THEN
  RAISE EXCEPTION 'RÉSA v9 now has published active profiles; revalidate staging';
 END IF;
END $preflight$;

-- 1. V0 - idempotent client request, GiST exclusion, never a paid receipt.
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
-- V0 is INTERNAL ONLY: no browser role can invoke it directly.

-- 2. PAY trigger: only legacy reservations keep their historic semantics.
--    New V0 client_request_id bookings must never post income on status change.
CREATE OR REPLACE FUNCTION public.trg_digiy_resa_push_to_pay()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,public
AS $finance$
BEGIN
 IF NEW.client_request_id IS NOT NULL THEN RETURN NEW; END IF;
 IF coalesce(lower(OLD.status),'') IS DISTINCT FROM
    coalesce(lower(NEW.status),'')
    AND lower(coalesce(NEW.status,'')) IN ('confirmed','completed','paid') THEN
  PERFORM public.digiy_resa_push_to_pay(NEW.id);
 END IF;
 RETURN NEW;
END $finance$;

-- 3. SECURITY: owner direct UPDATE only for legacy rows, new V0
--    rows must use authenticated owner-managed RPC. This preserves existing
--    legacy cockpit writes; does not broaden UPDATE to any user.
ALTER POLICY "RESA owner updates own bookings"
ON public.digiy_resa_bookings
USING (
 client_request_id IS NULL AND
 EXISTS (
  SELECT 1 FROM public.digiy_resa_profiles p
  WHERE p.slug=digiy_resa_bookings.slug AND p.is_active IS TRUE
  AND p.auth_user_id=(SELECT auth.uid())
 )
)
WITH CHECK (
 client_request_id IS NULL AND
 EXISTS (
  SELECT 1 FROM public.digiy_resa_profiles p
  WHERE p.slug=digiy_resa_bookings.slug AND p.is_active IS TRUE
  AND p.auth_user_id=(SELECT auth.uid())
 )
);

-- 4. V2 : public catalogue, server-provided services/slots, Senegal pilot.
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

-- 5. V5 owner actions: tenant-isolated; no PAY, no cross-tenant access.
CREATE OR REPLACE FUNCTION public.digiy_resa_universal_owner_manage_v2(
 p_booking_id uuid,
 p_action text,
 p_note_text text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog,public
AS $action$
DECLARE
 v_uid uuid := auth.uid();
 v_booking public.digiy_resa_bookings%ROWTYPE;
 v_action text := lower(btrim(coalesce(p_action,'')));
 v_note text;
BEGIN
 IF v_uid IS NULL THEN
  RETURN jsonb_build_object('ok',false,'error','authentication_required');
 END IF;
 IF p_booking_id IS NULL OR
    v_action NOT IN ('note','confirmed','cancelled','done','no_show') THEN
  RETURN jsonb_build_object('ok',false,'error','invalid_request');
 END IF;
 -- Notes never accompany status transitions; distinct operations prevent
 -- inadvertent note overwrite or status change through a single payload.
 IF v_action <> 'note' AND p_note_text IS NOT NULL THEN
  RETURN jsonb_build_object('ok',false,'error','unexpected_note');
 END IF;
 IF v_action='note' THEN
  IF char_length(coalesce(p_note_text,'')) > 1000 THEN
   RETURN jsonb_build_object('ok',false,'error','note_too_long');
  END IF;
  v_note := nullif(btrim(coalesce(p_note_text,'')),'');
 END IF;

 -- Lock exactly this row AND prove identity via immutable server-side owner
 -- relation. Legacy requests (without client_request_id) deliberately excluded.
 SELECT b.* INTO v_booking
 FROM public.digiy_resa_bookings b
 WHERE b.id=p_booking_id
   AND b.client_request_id IS NOT NULL
   AND EXISTS (
     SELECT 1
     FROM public.digiy_resa_profiles p
     WHERE p.slug=b.slug
       AND p.is_active IS TRUE
       AND p.auth_user_id=v_uid
   )
 FOR UPDATE;
 IF NOT FOUND THEN
  RETURN jsonb_build_object('ok',false,'error','not_found_or_forbidden');
 END IF;

 IF v_action='note' THEN
  UPDATE public.digiy_resa_bookings
  SET note_text=v_note,updated_at=clock_timestamp()
  WHERE id=v_booking.id;
  RETURN jsonb_build_object('ok',true,'booking_id',v_booking.id,
    'action','note','status',v_booking.status);
 END IF;
 IF NOT (
  (v_booking.status='pending' AND v_action IN ('confirmed','cancelled')) OR
  (v_booking.status='confirmed' AND v_action IN ('cancelled','done','no_show'))
 ) THEN
  RETURN jsonb_build_object('ok',false,'error','invalid_transition');
 END IF;
 UPDATE public.digiy_resa_bookings
 SET status=v_action,updated_at=clock_timestamp()
 WHERE id=v_booking.id;
 RETURN jsonb_build_object('ok',true,'booking_id',v_booking.id,
  'action',v_action,'status',v_action);
END
$action$;

-- Supabase PostgREST must never expose this SECURITY DEFINER to anonymous API.
REVOKE ALL ON FUNCTION public.digiy_resa_universal_owner_manage_v2(uuid,text,text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.digiy_resa_universal_owner_manage_v2(uuid,text,text)
 TO authenticated;

-- 6. V8 pilot control: default OFF; operator-activated only.
CREATE TABLE public.digiy_resa_universal_launch_controls (
 slug text PRIMARY KEY REFERENCES public.digiy_resa_profiles(slug),
 enabled boolean NOT NULL DEFAULT false,
 activated_at timestamptz,
 CONSTRAINT launch_slug_v8 CHECK (slug ~ '^[a-z0-9_-]{2,150}$')
);
ALTER TABLE public.digiy_resa_universal_launch_controls ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.digiy_resa_universal_launch_controls FROM PUBLIC,anon,authenticated;
-- No anon/auth INSERT, UPDATE or SELECT; only an authorized server administrator
-- may activate a real owner, after external backup / A-B security approval.

CREATE FUNCTION public.digiy_resa_universal_pilot_gate_v1(p_slug text)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path=pg_catalog,public
AS $gate$
DECLARE
 v_slug text:=lower(btrim(coalesce(p_slug,'')));
 v_prof public.digiy_resa_profiles%ROWTYPE;
 v_raw text;
 v_wa text;
BEGIN
 IF v_slug !~ '^[a-z0-9_-]{2,150}$' THEN
  RETURN jsonb_build_object('ok',false,'enabled',false,'error','invalid_request');
 END IF;
 SELECT p.* INTO v_prof FROM public.digiy_resa_profiles p
 JOIN public.digiy_resa_universal_launch_controls g ON g.slug=p.slug
 WHERE p.slug=v_slug AND p.is_active IS TRUE AND p.is_published IS TRUE
  AND p.time_zone='Africa/Dakar' AND g.enabled IS TRUE;
 IF NOT FOUND THEN
  RETURN jsonb_build_object('ok',true,'enabled',false);
 END IF;
 v_raw:=regexp_replace(coalesce(v_prof.whatsapp,''),'[^0-9]','','g');
 v_wa:=CASE WHEN length(v_raw) BETWEEN 10 AND 15 THEN v_raw ELSE NULL END;
 RETURN jsonb_build_object('ok',true,'enabled',true,
   'slug',v_slug,'time_zone','Africa/Dakar',
   'display_name',left(coalesce(v_prof.display_name,''),120),
   'public_whatsapp',v_wa);
END $gate$;
REVOKE ALL ON FUNCTION public.digiy_resa_universal_pilot_gate_v1(text)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.digiy_resa_universal_pilot_gate_v1(text)
 TO anon,authenticated;

-- V0 remains an internal transaction engine. Only this guarded wrapper is
-- exposed to anonymous/authenticated callers in V8 pilot.
REVOKE ALL ON FUNCTION public.digiy_resa_universal_request_v0(
 text,uuid,uuid,text,text,uuid) FROM PUBLIC,anon,authenticated;

CREATE FUNCTION public.digiy_resa_universal_request_v1(
 p_slug text,p_slot_id uuid,p_service_id uuid,
 p_client_name text,p_client_phone text,p_request_id uuid
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path=pg_catalog,public
AS $request$
DECLARE
 v_slug text:=lower(btrim(coalesce(p_slug,'')));
 v_allowed boolean;
BEGIN
 IF v_slug !~ '^[a-z0-9_-]{2,150}$' OR p_request_id IS NULL THEN
  RETURN jsonb_build_object('ok',false,'error','invalid_request');
 END IF;
 -- SHARE lock serializes owner pilot deactivation against client commit.
 SELECT true INTO v_allowed
 FROM public.digiy_resa_universal_launch_controls g
 JOIN public.digiy_resa_profiles p ON p.slug=g.slug
 WHERE g.slug=v_slug AND g.enabled IS TRUE
 AND p.is_active IS TRUE AND p.is_published IS TRUE
 AND p.time_zone='Africa/Dakar'
 FOR SHARE OF g,p;
 IF v_allowed IS DISTINCT FROM true THEN
  RETURN jsonb_build_object('ok',false,'error','pilot_not_active');
 END IF;
 RETURN public.digiy_resa_universal_request_v0(
  v_slug,p_slot_id,p_service_id,p_client_name,p_client_phone,p_request_id);
END $request$;
REVOKE ALL ON FUNCTION public.digiy_resa_universal_request_v1(
 text,uuid,uuid,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.digiy_resa_universal_request_v1(
 text,uuid,uuid,text,text,uuid) TO anon,authenticated;

-- 7. Legacy browser RPC isolation for new universal pilot owners:
--    the old entrypoint remains unchanged for every owner without a
--    V8 launch-control row. Pilot owners must use request_v1, never bypass
--    real published slots or server idempotency through the old endpoint.
CREATE OR REPLACE FUNCTION public.digiy_resa_create_booking(p_slug text, p_customer_name text, p_customer_phone text, p_booking_date date, p_booking_time time without time zone, p_guests_count integer, p_note_text text, p_service_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO pg_catalog, public
AS $function$
declare
  v_slug text;
  v_service public.digiy_resa_services%rowtype;
  v_row public.digiy_resa_bookings%rowtype;
begin
  v_slug := lower(trim(coalesce(p_slug, '')));
  -- Pilot professionals must never use the permissive legacy public RPC.
  -- Old dossiers remain untouched: only a deliberate launch-control row
  -- opts this owner out of the historical booking entrypoint.
  if exists (
    select 1 from public.digiy_resa_universal_launch_controls g
    where g.slug = v_slug
  ) then
    return jsonb_build_object('ok',false,'error','use_secure_resa_universal_request_v1');
  end if;

  if v_slug = '' then
    return jsonb_build_object('ok', false, 'error', 'slug_required');
  end if;

  if p_booking_date is null or p_booking_time is null then
    return jsonb_build_object('ok', false, 'error', 'booking_datetime_required');
  end if;

  if coalesce(trim(p_customer_name), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'customer_name_required');
  end if;

  select *
  into v_service
  from public.digiy_resa_services
  where id = p_service_id
    and slug = v_slug
    and coalesce(is_active, true) = true
  limit 1;

  if v_service.id is null then
    return jsonb_build_object('ok', false, 'error', 'service_not_found');
  end if;

  if exists (
    select 1
    from public.digiy_resa_bookings b
    where b.slug = v_slug
      and b.booking_date = p_booking_date
      and b.booking_time = p_booking_time
      and b.status <> 'cancelled'
  ) then
    return jsonb_build_object('ok', false, 'error', 'slot_not_available');
  end if;

  insert into public.digiy_resa_bookings (
    slug,
    phone,
    customer_name,
    customer_phone,
    booking_date,
    booking_time,
    guests_count,
    note_text,
    status,
    service_id,
    service_name,
    duration_minutes,
    price_fcfa
  )
  values (
    v_slug,
    regexp_replace(coalesce(p_customer_phone, ''), '\D', '', 'g'),
    trim(p_customer_name),
    regexp_replace(coalesce(p_customer_phone, ''), '\D', '', 'g'),
    p_booking_date,
    p_booking_time,
    coalesce(p_guests_count, 1),
    nullif(trim(coalesce(p_note_text, '')), ''),
    'pending',
    v_service.id,
    v_service.service_name,
    coalesce(v_service.duration_minutes, 30),
    v_service.price_fcfa
  )
  returning *
  into v_row;

  return jsonb_build_object(
    'ok', true,
    'booking', jsonb_build_object(
      'id', v_row.id,
      'slug', v_row.slug,
      'customer_name', v_row.customer_name,
      'customer_phone', v_row.customer_phone,
      'booking_date', v_row.booking_date,
      'booking_time', v_row.booking_time,
      'guests_count', v_row.guests_count,
      'status', v_row.status,
      'service_id', v_row.service_id,
      'service_name', v_row.service_name,
      'duration_minutes', v_row.duration_minutes,
      'price_fcfa', v_row.price_fcfa,
      'created_at', v_row.created_at
    )
  );
end;
$function$

-- 8. Final preflight assertion - new APIs do not expose raw V0,
--    existing historical booking count/data is untouched by this migration.
DO $postcheck$
BEGIN
 IF has_function_privilege('anon',
  'public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)',
  'EXECUTE') THEN
  RAISE EXCEPTION 'Unsafe: V0 internal method public';
 END IF;
 IF has_function_privilege('anon',
  'public.digiy_resa_universal_owner_manage_v2(uuid,text,text)',
  'EXECUTE') THEN
  RAISE EXCEPTION 'Unsafe: V5 owner method public';
 END IF;
 IF has_table_privilege('authenticated',
  'public.digiy_resa_universal_launch_controls','UPDATE') THEN
  RAISE EXCEPTION 'Unsafe: launch controls customer-writable';
 END IF;
 IF EXISTS(SELECT 1 FROM public.digiy_resa_universal_launch_controls WHERE enabled) THEN
  RAISE EXCEPTION 'Unsafe: pilot automatically activated';
 END IF;
 IF (SELECT count(*) FROM pg_policies
     WHERE schemaname='public' AND tablename='digiy_resa_bookings'
     AND policyname='RESA owner updates own bookings'
       AND qual LIKE '%client_request_id IS NULL%')<>1 THEN
  RAISE EXCEPTION 'Unsafe: legacy write isolation missing';
 END IF;
END $postcheck$;
