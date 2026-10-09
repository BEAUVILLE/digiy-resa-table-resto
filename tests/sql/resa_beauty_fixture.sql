-- Disposable PostgreSQL 17 fixture. Never run this file on digiy-core.
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE service_role NOLOGIN;
CREATE SCHEMA auth;
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE
AS $$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;

CREATE TABLE public.digiy_resa_profiles(
  slug text PRIMARY KEY,auth_user_id uuid,is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE public.digiy_resa_bookings(
  id uuid PRIMARY KEY,slug text,customer_name text,customer_phone text,booking_date date
);
INSERT INTO public.digiy_resa_profiles(slug,auth_user_id,is_active) VALUES
 ('resa-owner-a','11111111-1111-4111-8111-111111111111',true),
 ('resa-owner-b','22222222-2222-4222-8222-222222222222',true);
INSERT INTO public.digiy_resa_bookings(id,slug,customer_name,customer_phone,booking_date) VALUES
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','resa-owner-a','TEST A','0000000000','2026-10-09'),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','resa-owner-b','TEST B','0000000000','2026-10-09');

CREATE FUNCTION public.resa_list_recent_bookings_by_slug(p_slug text,p_limit integer DEFAULT 20)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER
AS $$
 SELECT jsonb_build_object('ok',true,'rows',coalesce(jsonb_agg(to_jsonb(b)),'[]'::jsonb))
 FROM (SELECT * FROM public.digiy_resa_bookings WHERE slug=p_slug LIMIT p_limit) b;
$$;

CREATE TABLE public.digiy_beauty_master_members(
  id uuid PRIMARY KEY,slug text NOT NULL UNIQUE,owner_id uuid,
  is_active boolean NOT NULL DEFAULT true,services jsonb NOT NULL DEFAULT '[]'::jsonb
);
CREATE TABLE public.digiy_beauty_master_slots(
  id uuid PRIMARY KEY,beauty_id uuid NOT NULL REFERENCES public.digiy_beauty_master_members(id),
  slot_day date NOT NULL,slot_time time NOT NULL,status text NOT NULL DEFAULT 'available',
  CONSTRAINT digiy_beauty_master_slots_status_check CHECK(status IN ('available','blocked','booked')),
  UNIQUE(beauty_id,slot_day,slot_time)
);
CREATE TABLE public.digiy_beauty_bookings(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  beauty_id uuid NOT NULL REFERENCES public.digiy_beauty_master_members(id),
  slot_id uuid NOT NULL REFERENCES public.digiy_beauty_master_slots(id),
  service_name text NOT NULL,service_duration_min integer,service_price integer,
  client_name text NOT NULL,client_whatsapp text NOT NULL,
  status text NOT NULL DEFAULT 'request',
  CONSTRAINT digiy_beauty_bookings_status_check CHECK(status IN ('request','confirmed','cancelled')),
  CONSTRAINT digiy_beauty_bookings_slot_id_key UNIQUE(slot_id) DEFERRABLE
);

INSERT INTO public.digiy_beauty_master_members(id,slug,owner_id,services) VALUES
 ('10101010-1010-4010-8010-101010101010','beauty-a','11111111-1111-4111-8111-111111111111','[{"name":"Soin test","price":5000,"duration_min":45}]'),
 ('20202020-2020-4020-8020-202020202020','beauty-b','22222222-2222-4222-8222-222222222222','[{"name":"Soin test","price":8000,"duration_min":60}]');
INSERT INTO public.digiy_beauty_master_slots(id,beauty_id,slot_day,slot_time,status) VALUES
 ('30303030-3030-4030-8030-303030303030','10101010-1010-4010-8010-101010101010','2026-10-12','11:00','available'),
 ('40404040-4040-4040-8040-404040404040','20202020-2020-4020-8020-202020202020','2026-10-12','12:00','available');

-- Historical V1 slots shape deliberately omits id.
CREATE FUNCTION public.digiy_beauty_public_slots_v1(p_slug text,p_day date)
RETURNS TABLE(slot_time time,status text) LANGUAGE sql STABLE SECURITY DEFINER
AS $$ SELECT s.slot_time,s.status
 FROM public.digiy_beauty_master_slots s JOIN public.digiy_beauty_master_members b ON b.id=s.beauty_id
 WHERE b.slug=p_slug AND s.slot_day=p_day $$;
