-- V5 fixture extends the synthetic V0/V1 environment only.
DO $guard$
BEGIN
 IF current_database()<>'digiy_appointments_test' THEN
  RAISE EXCEPTION 'V5 fixture is restricted to disposable Postgres';
 END IF;
END $guard$;
ALTER TABLE public.digiy_resa_bookings
 ADD COLUMN IF NOT EXISTS note_text text;
ALTER TABLE public.digiy_resa_bookings
 ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT clock_timestamp();

-- Never alter the status, financial trigger, original UUIDs or owner grants.
-- The real digiy-core already has these columns: this is a shape correction
-- for the synthetic fixture, not a production migration.
