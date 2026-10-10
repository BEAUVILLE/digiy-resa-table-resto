-- V10 synthetic fixture only. No data from DIGIY production.
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;
CREATE SCHEMA auth;
GRANT USAGE ON SCHEMA auth TO authenticated, anon;
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$
 SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
$$;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated, anon;
CREATE FUNCTION public.digiy_owner_mfa_gate() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path TO pg_catalog AS $$
 SELECT coalesce(current_setting('digiy.test_mfa_ok',true),'off')='on'
$$;
CREATE TABLE public.digiy_resa_profiles (slug text PRIMARY KEY,auth_user_id uuid,is_active boolean,is_published boolean);
CREATE TABLE public.digiy_explore_places (slug text PRIMARY KEY,auth_user_id uuid,is_active boolean,is_published boolean);
CREATE TABLE public.digiy_resa_services (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),slug text NOT NULL,service_name text NOT NULL,
 duration_minutes integer NOT NULL DEFAULT 30,price_fcfa integer,is_active boolean NOT NULL DEFAULT true);
CREATE TABLE public.digiy_resa_slots (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),slug text NOT NULL REFERENCES public.digiy_resa_profiles(slug),
 slot_date date NOT NULL,start_time time NOT NULL,end_time time,status text NOT NULL DEFAULT 'open',
 capacity integer DEFAULT 1,note text,
 UNIQUE(slug,slot_date,start_time));
CREATE TABLE public.digiy_resa_universal_launch_controls(slug text PRIMARY KEY,enabled boolean DEFAULT false);
ALTER TABLE public.digiy_resa_universal_launch_controls ENABLE ROW LEVEL SECURITY;
CREATE FUNCTION public.digiy_resa_universal_owner_manage_v2(uuid,text,text) RETURNS jsonb LANGUAGE sql SECURITY DEFINER AS $$ SELECT '{}'::jsonb $$;
REVOKE ALL ON FUNCTION public.digiy_resa_universal_owner_manage_v2(uuid,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.digiy_resa_universal_owner_manage_v2(uuid,text,text) TO authenticated,service_role;
GRANT SELECT ON public.digiy_resa_profiles,public.digiy_explore_places TO authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.digiy_resa_slots TO authenticated;
ALTER TABLE public.digiy_resa_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digiy_explore_places ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digiy_resa_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digiy_resa_slots ENABLE ROW LEVEL SECURITY;
CREATE POLICY profile_owner ON public.digiy_resa_profiles FOR SELECT TO authenticated
 USING(auth_user_id=auth.uid());
CREATE POLICY explore_owner ON public.digiy_explore_places FOR SELECT TO authenticated
 USING(auth_user_id=auth.uid());
CREATE POLICY slot_owner_r ON public.digiy_resa_slots FOR SELECT TO authenticated
 USING(EXISTS(SELECT 1 FROM public.digiy_resa_profiles p WHERE p.slug=digiy_resa_slots.slug AND p.auth_user_id=auth.uid()));
CREATE POLICY slot_owner_w ON public.digiy_resa_slots FOR INSERT TO authenticated
 WITH CHECK(EXISTS(SELECT 1 FROM public.digiy_resa_profiles p WHERE p.slug=digiy_resa_slots.slug AND p.auth_user_id=auth.uid()));
CREATE POLICY slot_owner_update ON public.digiy_resa_slots FOR UPDATE TO authenticated
 USING(EXISTS(SELECT 1 FROM public.digiy_resa_profiles p WHERE p.slug=digiy_resa_slots.slug AND p.auth_user_id=auth.uid()))
 WITH CHECK(EXISTS(SELECT 1 FROM public.digiy_resa_profiles p WHERE p.slug=digiy_resa_slots.slug AND p.auth_user_id=auth.uid()));
CREATE POLICY public_service_read ON public.digiy_resa_services FOR SELECT TO anon USING(is_active IS TRUE);
GRANT SELECT ON public.digiy_resa_services TO anon;
INSERT INTO public.digiy_resa_profiles(slug,auth_user_id,is_active,is_published) VALUES
('saly-owner','11111111-1111-4111-8111-111111111111',true,false),
('other-owner','22222222-2222-4222-8222-222222222222',true,true);
INSERT INTO public.digiy_explore_places(slug,auth_user_id,is_active,is_published) VALUES
('saly-owner','11111111-1111-4111-8111-111111111111',true,true),
('other-owner','22222222-2222-4222-8222-222222222222',true,true);
INSERT INTO public.digiy_resa_universal_launch_controls(slug,enabled) VALUES('saly-owner',false);
