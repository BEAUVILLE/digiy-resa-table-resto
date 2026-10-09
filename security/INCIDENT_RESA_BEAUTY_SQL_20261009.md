# Incident RÉSA / BEAUTY — contrôle réel SQL du 09/10/2026

## Ce qui a été vérifié

Projet : `digiy-core` (réf. `wesqmwjjtsefyjnluosj`). Aucune réservation ni coordonnée client réel(le) n'a été retournée par les requêtes d'audit.

### Correctif P0 RÉSA — APPLIQUÉ en production

- Fonction : `public.digiy_resa_get_bookings_by_day(text,date)`.
- Ancien risque : fonction `SECURITY DEFINER` exécutable par `anon` qui délègue à une autre fonction lisant des noms et téléphones, sur simple slug.
- Correction : `auth.uid()` non nul et propriétaire actif via `digiy_resa_profiles.auth_user_id`, retrait d'EXECUTE à `PUBLIC` et `anon`, maintien contrôlé de `authenticated`.
- Migration enregistrée : `resa_private_bookings_owner_guard_20261009`.
- Contrôle production après intervention : `anon_execute=false`, `authenticated_execute=true`, garde propriétaire présente.

### Correctifs BEAUTY — SQL APPLIQUÉ, INTERFACE NON ENCORE DÉPLOYÉE

- Ancienne RPC `digiy_beauty_public_slots_v1` : renvoie uniquement `slot_time,status`, ce qui ne convient pas au front qui attend `id`. La nouvelle `digiy_beauty_public_slots_v2` ajoute `id` sans modifier le contrat V1.
- Réservation publique `digiy_beauty_public_book_v1` : contrôle la prestation, le prix et la durée d'après `digiy_beauty_master_members.services`, refuse une offre falsifiée/périmée.
- Unicité `UNIQUE(slot_id)` remplacée par `UNIQUE (slot_id) WHERE status IN ('request','confirmed')` pour garder les annulations en historique et autoriser un nouveau client sur le créneau réellement libéré.
- Les fonctions de confirmation/refus et de gestion des créneaux verrouillent la ligne créneau, respectent le propriétaire, et interdisent de libérer un créneau toujours occupé.
- Migration enregistrée : `beauty_booking_integrity_server_validated_v2_20261009`.
- Contrôle production : ancien `UNIQUE(slot_id)` absent ; nouvel index partiel présent ; RPC V2 (id,slot_time,status) présente ; fonctions propriétaires refusent `anon` ; aucune réservation réelle constatée lors du contrôle.
- La page publique mise à jour pour consommer V2 est **sur la PR #17 seulement** : ne pas prétendre que le site hébergé sert déjà cette version.

### Contrôle d'intégration PostgreSQL isolé — RÉUSSI

Workflow `RÉSA / BEAUTY SQL isolation tests`, exécution GitHub Actions `37985816276` :

- PostgreSQL 17 isolé, base et profils entièrement fictifs ;
- même SQL P0 et BEAUTY que dans le dépôt ;
- test anonyme refusé, propriétaire A/B, ID public V2, tarif forgé refusé, double demande refusée, confirmation/refus, réutilisation d'un créneau après annulation avec historique intact ;
- vérification de la présence du nom RPC V2 côté HTML.

Les tests n'incluent ni un navigateur connecté à DIGIY CORE, ni des vraies sessions Auth sur deux comptes réels. Aucun BAT humain à ce stade.

### RESTO — privilèges propriétaires durcis

Les trois RPC `digiy_resa_resto_claim_site_by_email_v1`, `digiy_resa_resto_owner_refresh_no_shows_v1`, `digiy_resa_resto_owner_set_booking_status_v1` ont perdu le droit d'exécution `anon` et conservent `authenticated`. Migration enregistrée `resto_owner_rpcs_revoke_anon_20261009`, SQL de référence PR [BEAUVILLE/digiy-resto #34](https://github.com/BEAUVILLE/digiy-resto/pull/34) (brouillon).

## Contrôles restant obligatoires avant fusion de la page BEAUTY

1. Page TEST BEAUTY SALY, navigateur mobile et desktop : service, vrai ID du créneau, demande, message de confirmation, disparition du créneau après demande.
2. Propriétaire connecté : réception, confirmation et refus ; vérifier qu'une deuxième demande est possible après refus sans dévoiler les détails du précédent client.
3. Deux vrais comptes tests A/B et une session anonyme : lecture et écriture inter-sites refusées.
4. Fuseaux : date du jour et dates passées selon pays/territoire ; non garanties par le présent lot SQL.
5. Gérer la rétrocompatibilité des navigateurs/caches/PWA ; vérifier le HTML réellement servi par GitHub Pages.
6. Audit distinct de `digiy_resa_public_profiles_v2` (vue à privilèges élevés). Ne pas basculer en `security_invoker` sans contrôler les permissions RLS/GRANT des tables sous-jacentes : le public pourrait être cassé.
7. Vérifier la sauvegarde Supabase et obtenir le BAT humain avant généralisation.

**Ne pas annuler l'index partiel en rétablissant aveuglément l'ancienne contrainte** dès que l'historique des demandes annulées contient plusieurs lignes pour un même créneau ; privilégier un correctif de suivi.

## Doctrine

Aucune caisse, aucun encaissement DIGIYLYFE, contact et confirmation professionnels directs, 0 % commission. Un écran prêt, une PR verte et un SQL appliqué ne sont **jamais** trois synonymes de « parcours terrain validé ».
