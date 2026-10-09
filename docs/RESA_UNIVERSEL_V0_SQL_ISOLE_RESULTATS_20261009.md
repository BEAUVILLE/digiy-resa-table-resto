# RÉSA UNIVERSEL V0 — SQL ISOLÉ, RÉSULTATS ET VERROUS RESTANTS

**9 octobre 2026 — Phase 2 de la PR #22.**  
**Statut : TESTS POSTGRESQL ÉPHÉMÈRES VALIDÉS — PAS DE MISE EN PRODUCTION.**

## Livrable effectivement testé

- `sql/candidates/20261009_resa_universal_v0_ISOLATED.sql` : candidat technique avec garde explicite de base `digiy_appointments_test` ; refuse toute autre base, **y compris digiy-core**.
- `tests/sql/resa_universal_v0_fixture.sql` : deux propriétaires **synthétiques**, catalogue factice, créneaux fermés et chevauchants, simulation de déclencheur PAY.
- `tests/sql/resa_universal_v0_assertions.sql` : RPC accessible au rôle API `anon`, propriétaire actif/publié, créneaux réels, prix/durée côté serveur, restrictions, clé idempotente, confidentialité du résultat.
- `tests/resa-universal-v0-concurrency.cjs` : **deux connexions PostgreSQL simultanées** sur deux créneaux chevauchants, un seul succès en capacité 1.
- `sql/candidates/20261009_resa_universal_v0_ISOLATED_ROLLBACK.sql` : efface le schéma candidat en base jetable et vérifie les enregistrements hérités de la fixture.
- `.github/workflows/resa-universal-sql-isolated.yml` : orchestre l'ensemble dans PostgreSQL 17 éphémère.

### Résultats constatés dans GitHub Actions

| Contrôle isolé | Résultat |
|---|---|
| Profil actif et publié requis | **PASS** |
| Rendez-vous choisi parmi de vrais créneaux ouverts | **PASS** |
| Prestations appartenant au bon professionnel | **PASS** |
| Durée et prix provenant du serveur | **PASS** |
| Doublon même ID de requête (réseau/double clic) | **PASS** |
| Chevauchement de deux horaires | **PASS** |
| Deux clients simultanés → une seule réservation `pending` | **PASS** |
| Réponse sans données client privées | **PASS** |
| Simulation d'effet PAY sur changement de statut | **PASS**, avec risque confirmé lors d'une mise à jour `confirmed` |
| Rollback structurel en base jetable | **PASS**, en conservant les réservations historiques synthétiques |

### Pourquoi la première livraison reste volontairement `pending`

Le serveur enregistre une **demande réelle en base isolée**, non une réservation confirmée automatiquement. Cela empêche le candidat d'activer sans contrôle le déclencheur RÉSA → PAY/CARNET qui existe sur la base historique lorsque le statut change. Dans ce système, une réservation confirmée ne doit jamais être assimilée à un encaissement constaté.

La confirmation automatique est un objectif validé **mais une étape technique distincte** : prévoir statut/notification, règles du professionnel et comportement PAY explicitement vérifiés avant toute ouverture publique. La capacité V0 est limitée à **une place**. Les groupes nécessitent un moteur capacité/occupation distinct.

## Contraintes de conception encore ouvertes

1. **Fonctions héritées anon :** `digiy_resa_create_booking` et `resa_create_booking_by_slug` restent appelables publiquement sur digiy-core. Elles ne valident pas toutes l'ouverture réelle du nouveau calendrier. Cartographier les appels, préserver les compatibilités, puis corriger de manière ciblée avant de brancher l'interface.
2. **Historique réel :** 7 réservations (6 `pending`, 1 `confirmed`) et 8 prestations déjà présentes, sans profil générique actuel. Les conserver et tester contraintes/index contre un clone anonymisé ou un audit de contraintes read-only ; aucun effacement.
3. **Règles horaires :** V0 vérifie le futur dans le fuseau **Africa/Dakar**, sans profil IANA ni DST France. **Interdit pour diffusion France** tant que les fuseaux et passages d'heure ne sont pas testés.
4. **Confirmation & PAY :** le déclencheur réel `digiy_resa_push_to_pay_after_status` doit être audité en staging : aucun mouvement PAY/CARNET ne doit être pris pour preuve de paiement réel.
5. **Annulations et propriétaire A/B :** développer et tester les transitions autorisées, les réservations en attente, la libération des créneaux, la non-divulgation des détails et les contrôles JWT/RLS pour chaque mutation.
6. **Prestation / métier :** un avocat, comptable ou architecte présente seulement ses créneaux et prestations, jamais un motif de dossier ou information sensible au calendrier public.
7. **Vrai BAT mobile :** relier plus tard les écrans `planning.html` et `gestion.html` au moteur après migration approuvée ; un test de la fonction SQL seule ne prouve pas le parcours complet client/propriétaire.
8. **Rollback de production :** le rollback V0 est **exclusivement destructif de schéma dans une DB jetable**. Pour une vraie migration, un retour arrière doit préserver les ID de requête, réserver un snapshot, fournir le mécanisme de retour et gérer les écritures intervenues après activation.

## Décision GO / NO GO

- **GO technique limité :** le candidat SQL et son test d'exclusion/concurrence peuvent être conservés dans le dépôt comme référence, **dans `sql/candidates/` seulement**.
- **NO GO pour tout SQL sur digiy-core, tout remplacement de RPC legacy et toute publication de réservation automatique.**
- **Étape suivante :** branche distincte d'architecture/réconciliation des RPC héritées + évolution IANA + plan de transitions et d'intégration PAY, tests de staging isolé, puis **revue humaine avant SQL CORE**.
- Les portes de `contracts/resa-universal-pre-sql-gates.json` restent **bloquées pour la production**. Une CI verte du prototype ne signifie pas une autorisation de migration.

**Doctrine immuable : 0 % commission, paiement et relation directs, professionnel maître de son agenda, RESTO/LOC/DRIVER et particularités terrain sur leurs moteurs propres.**
