# DIGIY RÉSA CORE — V9 : bascule V0 / V2 / V5 / V8

**10 octobre 2026 — Release candidate, non activée sur `digiy-core`**

## Constat direct sur CORE

- Projet Supabase : `wesqmwjjtsefyjnluosj`, base `postgres`, PostgreSQL 17.
- Fonctions `digiy_resa_universal_request_v0`, `digiy_resa_universal_public_options_v1`, `digiy_resa_universal_owner_manage_v2`, `digiy_resa_universal_request_v1` : **absentes** à la dernière lecture.
- 7 anciennes demandes RÉSA, 0 profil universel publié, 0 créneau universel.
- Déclencheur `digiy_resa_push_to_pay_after_status` actif, pouvant générer des mouvements PAY sur `confirmed` sans reçu du règlement.
- UPDATE direct autorisé à `authenticated` sur les seules lignes des propriétaires, mais incompatible avec le contrôle de transitions V5 sur les nouvelles demandes.
- Dernière sauvegarde réelle chiffrée [run 37909800559](https://github.com/BEAUVILLE/admin-digiy/actions/runs/37909800559), artefact 11605844599. **Il manque une preuve de restauration de CETTE archive hors production.** Le succès de la sauvegarde n'est pas une restauration vérifiée. Scripts Mac existants dans `BEAUVILLE/admin-digiy`, dossier [incident #9](https://github.com/BEAUVILLE/admin-digiy/issues/9). Ne demander ni mot de passe ni dump au fondateur.

## Ce que fait le SQL de production candidat V9

Fichier : `sql/production/20261010_resa_universal_v0_v2_v5_v8_GATED.sql`.

1. Vérifie schéma/tables, Auth, déclencheur PAY, RLS, original `UPDATE` policy, absence de fonctions déjà posées, zéro profil activement publié, et absence de chevauchements historiques.
2. Ajoute `client_request_id` sans effacer ni réécrire les anciennes réservations, crée index d'idempotence et exclusion GiST pour chevauchements réels.
3. Crée V0 **interne uniquement**, aucun rôle public ne l'exécute directement.
4. Corrige `trg_digiy_resa_push_to_pay` : si `client_request_id IS NOT NULL`, **aucune écriture de recette sur changement de statut**. Sur réservation historique, l'ancien comportement PAY est préservé.
5. Limite par RLS l'ancienne mise à jour directe à `client_request_id IS NULL` ; les anciens propriétaires gardent leurs droits sur leurs anciens dossiers, tandis que les nouveaux sont modifiés **seulement via V5 sécurisé**. Pas de `REVOKE UPDATE` global.
6. Pose V2 : vrais créneaux et services sans données clients, pilote `Africa/Dakar`.
7. Pose V5 : notes privées et transitions propriétaire protégées par `auth.uid()`.
8. Pose V8 : tableau de contrôle verrouillé RLS (OFF par défaut), `pilot_gate_v1` et `request_v1` ; seul le serveur peut autoriser un professionnel. Aucun client fictif, aucune activation automatique.
9. Termine sur des assertions : V0 non publique, V5 non anonyme, tableau de contrôle non modifiable par les clients.

Le formulaire `rdv-universel.html` V8 peut ensuite afficher « **RDV posé · Paiement sur place** », mais **jamais avant confirmation serveur d'une insertion `pending`**. Le lien WhatsApp vers le professionnel n'est offert qu'après cette insertion. Le professionnel décide de la confirmation, du refus, de l'annulation. `CARNET PRO` est une vente additionnelle facultative pour les règlements réellement perçus, sans synchronisation automatique avec le rendez-vous.

## Checklist GO (preuve, non déclaration)

- [ ] Dernier ZIP **réel** téléchargé et déchiffré **en privé** par un opérateur autorisé, restauré intégralement sur PostgreSQL isolé, même cohérence pour réservations RÉSA + dates LOC ; aucun secret client exposé.
- [ ] Révérifier les tables/triggers/index/RLS historiques immédiatement avant release ; aucune divergence par rapport au preflight V9.
- [ ] Revue des fonctions héritées et appelants propriétaires ; tests Auth A/B avec comptes réels dans environnement **autorisé**, sans dépenses de staging non approuvées.
- [ ] Test de sauvegarde/rollback et maintien des données anciennes.
- [ ] Migration production **`apply_migration` transactionnelle**, opérateur autorisé, point de retour documenté. Ne jamais lancer de scripts `ISOLATED` sur `digiy-core`.
- [ ] Contrôle après migration : toutes les RPC existent, V0 n'est pas exécutable par `anon`, V5 uniquement `authenticated`, contrôle OFF, aucun PAY fictif ni changement de 7 demandes historiques.
- [ ] Premier professionnel réel de Saly avec BAT validé, profil + service + slots réels, `time_zone=\'Africa/Dakar\'`, accès propriétaire Auth. Seulement alors activation serveur et tests avec RDV réel.
- [ ] Vérifier le parcours mobile, la PWA propriétaire, la communication WhatsApp facultative et l'absence de réservation doublon.
- [ ] La France reste hors pilote tant que DST/fuseaux IANA complets non opérationnels.

## Procédure immédiate d'arrêt sans perte

`sql/production/20261010_resa_universal_v9_SAFE_DISABLE.sql` coupe toutes les activations et révoque l'exécution de `request_v1` par le public, **sans supprimer aucune réservation**, sans casser V5 et sans rétablir le déclencheur PAY dangereux. Ne jamais supprimer la colonne `client_request_id` si une réservation réelle l'utilise.

## CI indépendante de CORE

`.github/workflows/resa-v9-production-shape-isolated.yml` charge un schéma proche de la production sur PG17 jetable, applique **la même migration** de façon transactionnelle, vérifie l'activation OFF→ON, la réservation `pending`, l'idempotence, l'absence de chevauchements, RLS et accès A/B, PAY neutre sur confirmation V5, puis arrêt d'urgence et conservation des réservations.

**Politique : ne jamais contourner l'interdiction d'accès à la clé privée de restauration dans le connecteur. Réaliser cette étape sur l'appareil déjà autorisé sans partager la clé. La volonté de l'utilisateur d'aller en production ne vaut pas preuve du retour arrière.**
