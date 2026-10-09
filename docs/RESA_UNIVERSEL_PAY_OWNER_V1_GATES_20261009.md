# RÉSA UNIVERSEL — V1 PAY / DROITS PROPRIÉTAIRES EN BASE JETABLE

**Contrôle daté du 9 octobre 2026. Aucun SQL sur digiy-core.**

## Constat confirmé sur la vraie base — lecture seule

- `trg_digiy_resa_push_to_pay` exécute `digiy_resa_push_to_pay` lorsqu'une réservation change de statut et devient `confirmed`. Pour un abonnement PAY actif avec un montant positif, cela peut enregistrer un mouvement `posted` de type vente sans preuve de paiement. Une confirmation de rendez-vous **n'est pas** un encaissement.
- `authenticated` conserve aujourd'hui `UPDATE` sur **toute la table** `digiy_resa_bookings` avec RLS propriétaire, sans restriction de colonnes. Il faut cartographier et migrer les consommateurs de cette autorisation avant de la retirer en production.
- Les RPC héritées `digiy_resa_create_booking` et `resa_create_booking_by_slug` restent exécutables par `anon`; la première ne vérifie pas les horaires réellement ouverts ni les durées chevauchantes. Elles **ne doivent pas** être raccordées au calendrier universel V1.
- Base actuelle : **0 profil et 0 créneau RÉSA générique**, **7 réservations et 8 prestations historiques**. Ne pas les déplacer ou effacer pour activer les nouvelles fiches.

## Solution candidate uniquement dans PostgreSQL éphémère

1. **PAY** : si la réservation appartient au nouveau moteur universel (`client_request_id IS NOT NULL`), le trigger de changement de statut ne crée **aucun mouvement PAY automatique**. Le mouvement dépendra plus tard d'une **preuve réelle de paiement direct** et d'un contrat PAY distinct. Comportement historique conservé dans la simulation pour les anciennes réservations.
2. **Propriétaire** : fonction `digiy_resa_universal_owner_status_v1(uuid,text)` contrôlant strictement `auth.uid()` contre `digiy_resa_profiles.auth_user_id`, l'état `is_active`, l'identité de réservation et une transition autorisée. Aucun prénom, téléphone ni motif client n'est renvoyé.
3. **Matrice de transitions V1** : `pending→confirmed/cancelled`, `confirmed→cancelled/done/no_show`, et aucune réactivation de `cancelled`. `done` reste un statut de gestion **et non une preuve de prestation pour DIGIY TRUST**.
4. **Droits** : la maquette PostgreSQL simule le retrait du droit global UPDATE de `authenticated`, avec conservation du droit de lecture filtrée par l'identité (tests rôle JWT A/B). **Le retrait du droit sur CORE doit être préparé après inventaire des clients existants**.
5. **Concurrence** : conserver le candidat SQL V0 et son index d'exclusion sur les chevauchements horaires ; une annulation libère la capacité à la nouvelle demande sans effacer l'historique.
6. **Compatibilité** : anciens enregistrements `client_request_id IS NULL` non repris de force par cette RPC. Effet PAY ancien simulé pour ne pas changer son comportement sans revue d'impact.
7. **Déploiement** : SQL gardé par `current_database()='digiy_appointments_test'`; impossible de l'appliquer tel quel à `digiy-core`. Le rollback démontre uniquement une restauration de structures dans **une base jetable**.

## Gates bloquantes à lever avant le CORE

- Cartographier dans toutes les pages GitHub la consommation réelle des anciennes RPC et des UPDATE RLS (et sur les fiches anciennes).
- Séparer les droits publics dans une migration production **non destructive**, compatible avec les anciennes réservations ; réviser le trigger PAY historique avec le propriétaire du registre financier.
- Passer les propriétaires **A/B réels** et les profils abonnés autorisés dans un staging représentatif. Revoir l'isolation, les quotas, l'antibot, la confidentialité et les logs.
- Mettre en place les **fuseaux horaires IANA** pour Sénégal, France et futurs territoires, ainsi que les contrôles DST avant les réservations interterritoriales.
- Finaliser la réservation côté page client et la réponse propriétaire sur un BAT réel. La page `planning.html` est actuellement un lecteur de disponibilités, **pas un formulaire qui crée une réservation**.
- Procéder à une revue humaine finale, restauration sauvegarde prouvée et rollback non destructif avant toute migration `digiy-core`.

## Périmètre livré

- `sql/candidates/20261009_resa_universal_pay_owner_v1_ISOLATED.sql`
- `tests/sql/resa_universal_pay_owner_v1_fixture.sql`
- `tests/sql/resa_universal_pay_owner_v1_assertions.sql`
- `sql/candidates/20261009_resa_universal_pay_owner_v1_ISOLATED_ROLLBACK.sql`
- `.github/workflows/resa-universal-pay-owner-isolated.yml`

**Doctrine : pas de caisse, pas de commission ; client et professionnel règlent directement leurs prestations.**
