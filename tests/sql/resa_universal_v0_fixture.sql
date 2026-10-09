-- Synthetic tenant-only extension, not for digiy-core.
-- Run AFTER tests/sql/resa_beauty_fixture.sql and resa_planning_fixture.sql.
ALTER TABLE public.digiy_resa_profiles ADD COLUMN owner_id uuid;
ALTER TABLE public.digiy_resa_bookings
 ADD COLUMN owner_id uuid,
 ADD COLUMN phone text,
 ADD COLUMN guests_count integer NOT NULL DEFAULT 1,
 ADD COLUMN service_id uuid,
 ADD COLUMN service_name text,
 ADD COLUMN price_fcfa integer;
ALTER TABLE public.digiy_resa_bookings ALTER COLUMN id SET DEFAULT gen_random_uuid();

CREATE TABLE public.digiy_resa_services(
 id uuid PRIMARY KEY,
 slug text NOT NULL,
 service_name text NOT NULL,
 duration_minutes integer NOT NULL,
 price_fcfa integer,
 is_active boolean NOT NULL DEFAULT true
);
INSERT INTO public.digiy_resa_services
(id,slug,service_name,duration_minutes,price_fcfa,is_active) VALUES
('aaaa0000-0000-4000-8000-000000000001','resa-owner-a','Consultation 45 min',45,12000,true),
('aaaa0000-0000-4000-8000-000000000002','resa-owner-a','Consultation 60 min',60,20000,true),
('bbbb0000-0000-4000-8000-000000000001','resa-owner-b','Autre professionnel',30,8000,true),
('aaaa0000-0000-4000-8000-000000000003','resa-owner-a','Service fermé',30,4000,false);

-- User A and B belong to separate private owners; B is unpublished.
INSERT INTO public.digiy_resa_slots(id,slug,slot_date,start_time,end_time,status,capacity) VALUES
('a0000000-0000-4000-8000-000000000901','resa-owner-a',current_date+8,'09:00','10:00','open',1),
('a0000000-0000-4000-8000-000000000930','resa-owner-a',current_date+8,'09:30','10:30','open',1),
('a0000000-0000-4000-8000-000000001100','resa-owner-a',current_date+8,'11:00','12:00','open',1),
('a0000000-0000-4000-8000-000000001300','resa-owner-a',current_date+8,'13:00','14:00','closed',1),
('a0000000-0000-4000-8000-000000001400','resa-owner-a',current_date+8,'14:00','14:30','open',1),
('a0000000-0000-4000-8000-000000001600','resa-owner-a',current_date+8,'16:00','17:00','open',2),
('a0000000-0000-4000-8000-000000002200','resa-owner-a',current_date+9,'09:00','10:00','open',1),
('a0000000-0000-4000-8000-000000002230','resa-owner-a',current_date+9,'09:30','10:30','open',1),
('b0000000-0000-4000-8000-000000001000','resa-owner-b',current_date+8,'10:00','11:00','open',1);
-- Optional PAY stub: the new API must not update booking status.
CREATE TABLE public.test_pay_side_effects(id uuid PRIMARY KEY DEFAULT gen_random_uuid());
CREATE FUNCTION public.test_pay_trigger() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF new.status='confirmed' THEN
  INSERT INTO public.test_pay_side_effects DEFAULT VALUES;
 END IF;
 RETURN new;
END $$;
CREATE TRIGGER test_pay_guard AFTER UPDATE OF status ON public.digiy_resa_bookings
FOR EACH ROW EXECUTE FUNCTION public.test_pay_trigger();
