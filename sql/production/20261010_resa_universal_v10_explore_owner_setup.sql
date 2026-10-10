-- DIGIY RÉSA UNIVERSAL V10 / EXPLORE — owner setup without exposing a pilot.
-- No test rows. No automatic publication. No public EXECUTE function.
-- A verified EXPLORE owner may prepare draft services and real Dakar slots.
-- V9 launch control is immutable to anon/authenticated.
BEGIN;
DO $preflight$
BEGIN
  IF to_regclass('public.digiy_resa_profiles') IS NULL
    OR to_regclass('public.digiy_resa_services') IS NULL
    OR to_regclass('public.digiy_resa_slots') IS NULL
    OR to_regclass('public.digiy_explore_places') IS NULL
    OR to_regclass('public.digiy_resa_universal_launch_controls') IS NULL
    OR to_regprocedure('public.digiy_owner_mfa_gate()') IS NULL
  THEN RAISE EXCEPTION 'RESA_V10_REQUIRED_CORE_MISSING';
  END IF;
  IF EXISTS (SELECT 1 FROM public.digiy_resa_universal_launch_controls WHERE enabled)
  THEN RAISE EXCEPTION 'RESA_V10_PILOT_MUST_REMAIN_CLOSED';
  END IF;
END $preflight$;

ALTER TABLE public.digiy_resa_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digiy_resa_slots ENABLE ROW LEVEL SECURITY;

-- This grant does NOT allow unauthenticated or other-user edits: RLS below.
-- There is deliberately no DELETE privilege for services: disable instead.
GRANT SELECT, INSERT, UPDATE ON public.digiy_resa_services TO authenticated;
REVOKE DELETE ON public.digiy_resa_services FROM authenticated;
-- Preserve existing anon public read and V9 SECURITY DEFINER read behavior.

DO $constraints$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='digiy_resa_services_owner_valid_v10'
   AND conrelid='public.digiy_resa_services'::regclass) THEN
  ALTER TABLE public.digiy_resa_services
   ADD CONSTRAINT digiy_resa_services_owner_valid_v10
   CHECK (length(btrim(service_name)) BETWEEN 2 AND 120
     AND duration_minutes BETWEEN 5 AND 480
     AND (price_fcfa IS NULL OR price_fcfa BETWEEN 0 AND 5000000));
 END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conname='digiy_resa_slots_owner_no_overlap_v10'
   AND conrelid='public.digiy_resa_slots'::regclass) THEN
  ALTER TABLE public.digiy_resa_slots
   ADD CONSTRAINT digiy_resa_slots_owner_no_overlap_v10
   EXCLUDE USING gist (
      slug WITH =,
      tsrange(slot_date+start_time,slot_date+end_time,'[)') WITH &&
   ) WHERE (status='open' AND end_time IS NOT NULL);
 END IF;
END $constraints$;

-- Explicitly require matching *real* EXPLORE owner and RÉSA Auth identity.
-- This accepts unpublished profiles for private preparation, but never a
-- foreign RÉSA profile merely because a browser provided its slug.
DROP POLICY IF EXISTS "RÉSA V10 EXPLORE owner sees own services" ON public.digiy_resa_services;
CREATE POLICY "RÉSA V10 EXPLORE owner sees own services"
 ON public.digiy_resa_services FOR SELECT TO authenticated
 USING (
  public.digiy_owner_mfa_gate()
  AND EXISTS (
   SELECT 1 FROM public.digiy_resa_profiles p
    JOIN public.digiy_explore_places e ON e.slug=p.slug
   WHERE p.slug=digiy_resa_services.slug AND p.auth_user_id=(SELECT auth.uid())
     AND e.auth_user_id=p.auth_user_id
     AND p.is_active IS TRUE AND e.is_active IS TRUE
  )
 );

DROP POLICY IF EXISTS "RÉSA V10 EXPLORE owner adds draft services" ON public.digiy_resa_services;
CREATE POLICY "RÉSA V10 EXPLORE owner adds draft services"
 ON public.digiy_resa_services FOR INSERT TO authenticated
 WITH CHECK (
  public.digiy_owner_mfa_gate()
  AND EXISTS (
   SELECT 1 FROM public.digiy_resa_profiles p
    JOIN public.digiy_explore_places e ON e.slug=p.slug
   WHERE p.slug=digiy_resa_services.slug AND p.auth_user_id=(SELECT auth.uid())
     AND e.auth_user_id=p.auth_user_id
     AND p.is_active IS TRUE AND e.is_active IS TRUE
     -- Do not expose drafts via the existing public read policy before publication.
     AND (digiy_resa_services.is_active IS NOT TRUE OR p.is_published IS TRUE)
  )
 );

DROP POLICY IF EXISTS "RÉSA V10 EXPLORE owner updates own services" ON public.digiy_resa_services;
CREATE POLICY "RÉSA V10 EXPLORE owner updates own services"
 ON public.digiy_resa_services FOR UPDATE TO authenticated
 USING (
  public.digiy_owner_mfa_gate()
  AND EXISTS (
   SELECT 1 FROM public.digiy_resa_profiles p
    JOIN public.digiy_explore_places e ON e.slug=p.slug
   WHERE p.slug=digiy_resa_services.slug AND p.auth_user_id=(SELECT auth.uid())
     AND e.auth_user_id=p.auth_user_id
     AND p.is_active IS TRUE AND e.is_active IS TRUE
  )
 ) WITH CHECK (
  public.digiy_owner_mfa_gate()
  AND EXISTS (
   SELECT 1 FROM public.digiy_resa_profiles p
    JOIN public.digiy_explore_places e ON e.slug=p.slug
   WHERE p.slug=digiy_resa_services.slug AND p.auth_user_id=(SELECT auth.uid())
     AND e.auth_user_id=p.auth_user_id
     AND p.is_active IS TRUE AND e.is_active IS TRUE
     AND (digiy_resa_services.is_active IS NOT TRUE OR p.is_published IS TRUE)
  )
 );

-- Existing slot RLS is scoped to auth.uid() + profile slug. Make phone MFA
-- *restrictive* so older permissive slot policies cannot bypass it.
DROP POLICY IF EXISTS "RÉSA V10 owner phone security for slots" ON public.digiy_resa_slots;
CREATE POLICY "RÉSA V10 owner phone security for slots"
 ON public.digiy_resa_slots AS RESTRICTIVE FOR ALL TO authenticated
 USING (public.digiy_owner_mfa_gate())
 WITH CHECK (public.digiy_owner_mfa_gate());

-- Do not expose the pilot switch via V10 rights.
DO $postflight$
BEGIN
 IF has_table_privilege('authenticated','public.digiy_resa_universal_launch_controls','UPDATE')
   OR has_table_privilege('anon','public.digiy_resa_universal_launch_controls','UPDATE')
   OR has_function_privilege('anon','public.digiy_resa_universal_owner_manage_v2(uuid,text,text)','EXECUTE')
 THEN RAISE EXCEPTION 'RESA_V10_GATE_OR_OWNER_PERMISSION_DRIFT'; END IF;
 IF EXISTS(SELECT 1 FROM public.digiy_resa_universal_launch_controls WHERE enabled)
 THEN RAISE EXCEPTION 'RESA_V10_MUST_NOT_ACTIVATE_PILOT'; END IF;
END $postflight$;
COMMIT;
