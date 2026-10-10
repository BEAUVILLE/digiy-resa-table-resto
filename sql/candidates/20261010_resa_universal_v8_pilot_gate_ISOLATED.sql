-- DIGIY RÉSA V8 — pilot activation and booking RPC, disposable PG17 ONLY.
-- Not a migration: refused on digiy-core. The real migration must be audited
-- against PAY triggers, legacy writers, existing RLS and restored backups.
DO $guard$
BEGIN
 IF current_database() <> 'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V8 pilot SQL is isolated to disposable digiy_appointments_test';
 END IF;
 IF to_regprocedure('public.digiy_resa_universal_request_v0(text,uuid,uuid,text,text,uuid)') IS NULL
 OR to_regprocedure('public.digiy_resa_universal_public_options_v1(text,date)') IS NULL THEN
  RAISE EXCEPTION 'V0 and V2 candidates must be installed first';
 END IF;
END $guard$;

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
