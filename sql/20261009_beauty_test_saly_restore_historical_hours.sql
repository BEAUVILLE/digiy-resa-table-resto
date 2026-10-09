-- MAINTENANCE TEST UNIQUEMENT · 09 OCTOBRE 2026
-- Fiche TEST RÉSA BEAUTY SALY : reproposer ses SIX horaires déjà existants
-- (09:00,10:30,12:00,14:00,15:30,17:00), aux dates futures de TEST.
-- N'affecte aucun professionnel réel, aucune réservation, aucun créneau existant.
-- Aucune disponibilité n'est fabriquée pour un adhérent réel.
-- Conserve intégralement le propriétaire et l'historique des anciens slots.
DO $beauty_test$
DECLARE
  v_beauty_id uuid;
  v_reference_count integer;
  v_new_slots integer;
BEGIN
  SELECT b.id INTO v_beauty_id
  FROM public.digiy_beauty_master_members b
  WHERE b.slug='test-resa-beauty-saly'
    AND b.display_name='TEST RÉSA BEAUTY · SALY'
    AND b.is_active IS TRUE AND b.owner_id IS NOT NULL;
  IF v_beauty_id IS NULL THEN
    RAISE EXCEPTION 'Refus : cible non reconnue comme fiche BEAUTY TEST active';
  END IF;

  SELECT count(DISTINCT s.slot_time) INTO v_reference_count
  FROM public.digiy_beauty_master_slots s
  WHERE s.beauty_id=v_beauty_id
    AND s.slot_day BETWEEN DATE '2026-09-30' AND DATE '2026-10-06'
    AND s.status='available';
  IF v_reference_count<>6 THEN
    RAISE EXCEPTION 'Refus : six horaires historiques attendus, trouvé %',v_reference_count;
  END IF;

  WITH reference_times AS (
    SELECT DISTINCT s.slot_time FROM public.digiy_beauty_master_slots s
    WHERE s.beauty_id=v_beauty_id
      AND s.slot_day BETWEEN DATE '2026-09-30' AND DATE '2026-10-06'
      AND s.status='available'
  ), test_days AS (
    SELECT d::date AS day
    FROM generate_series((current_date+1)::timestamp,
                         (current_date+14)::timestamp, interval '1 day') d
  )
  INSERT INTO public.digiy_beauty_master_slots(beauty_id,slot_day,slot_time,status)
  SELECT v_beauty_id,d.day,t.slot_time,'available'
  FROM test_days d CROSS JOIN reference_times t
  ON CONFLICT(beauty_id,slot_day,slot_time) DO NOTHING;
  GET DIAGNOSTICS v_new_slots=ROW_COUNT;

  RAISE NOTICE 'BEAUTY TEST SALY: % créneaux de démonstration ajoutés (0 rendez-vous créés)',v_new_slots;
END
$beauty_test$;