-- Disposable fixture extension. Do NOT run on digiy-core.
ALTER TABLE public.digiy_resa_profiles
 ADD COLUMN display_name text, ADD COLUMN business_type text,
 ADD COLUMN city text,ADD COLUMN whatsapp text,
 ADD COLUMN is_published boolean NOT NULL DEFAULT false;
ALTER TABLE public.digiy_resa_bookings ADD COLUMN booking_time time,ADD COLUMN status text NOT NULL DEFAULT 'pending',ADD COLUMN duration_minutes integer;
CREATE TABLE public.digiy_resa_slots(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),slug text NOT NULL,
 slot_date date NOT NULL,start_time time NOT NULL,end_time time,
 status text NOT NULL DEFAULT 'open',
 capacity integer,note text
);
UPDATE public.digiy_resa_profiles
SET display_name='TEST A',business_type='prestations',city='Saly',is_published=true,
 whatsapp='221771234567' WHERE slug='resa-owner-a';
UPDATE public.digiy_resa_profiles
SET display_name='TEST B',is_published=false WHERE slug='resa-owner-b';
INSERT INTO public.digiy_resa_slots(slug,slot_date,start_time,status,note) VALUES
 ('resa-owner-a',current_date+7,'09:00','open','private test note'),
 ('resa-owner-a',current_date+7,'10:00','closed','secret closure'),
 ('resa-owner-a',current_date+7,'11:00','open','customer ignored'),
 ('resa-owner-b',current_date+7,'12:00','open','not public');
UPDATE public.digiy_resa_bookings
SET booking_date=current_date+7,booking_time='11:00',status='confirmed'
WHERE slug='resa-owner-a';
