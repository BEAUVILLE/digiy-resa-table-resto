# RÉSA UNIVERSEL — V6 · Recette E2E isolée et garde-fou de restauration

**Contrôle effectué le 10 octobre 2026. AUCUN SQL exécuté sur digiy-core, aucune fiche ni demande réelle créée.**

## Vérifications du dispositif de sauvegarde existant

Dépôt : [BEAUVILLE/admin-digiy](https://github.com/BEAUVILLE/admin-digiy).

- Workflow `DIGIY — Sauvegarde Supabase chiffrée`, [exécution du 9 octobre 2026 à 09:12 UTC](https://github.com/BEAUVILLE/admin-digiy/actions/runs/37909800559) : **SUCCESS**. Étapes vérifiées : lecture pré-export, export chiffré, téléversement de l'artefact.
- Artefact GitHub chiffré **ID 11605844599**, créé 9 octobre à 09:19 UTC, non expiré lors de ce contrôle, expiration annoncée **8 novembre 2026**, taille ~1,40 Mo. Attention : un artefact présent ne prouve PAS qu'il est restaurable.
- Étape « Copier l'archive hors site » : **SKIPPED** sur cette exécution ; ce n'est pas une preuve de réplication indépendante.
- `docs/RESTORE_DIGIY_CORE_LOCAL_MAC.md` consigne le contrôle réel d'une **archive précédente #74**, restaurée localement avec les marqueurs `ISOLATED_RESTORE_SQL_OK`, `ISOLATED_RESTORE_PROOF_OK` et `ISOLATED_RESTORE_PRODUCTION_UNTOUCHED`. Ce document souligne explicitement que **l'archive #75** (du 9 octobre 08:27 UTC) n'avait pas été restaurée. Aucun justificatif de restauration de la **plus récente archive #76** (9 octobre 09:13 UTC) n'a été constaté dans l'audit.
- L'incident prioritaire [admin-digiy #9](https://github.com/BEAUVILLE/admin-digiy/issues/9) doit donc rester **ouvert pour preuve de restauration à jour**, même si l'export chiffré fonctionne à nouveau.

**Ne JAMAIS** télécharger, déchiffrer ou envoyer ici le dump réel, la passphrase ou une URL contenant un mot de passe. La procédure locale du dépôt protège le Mac chiffré et refuse un lancement en CI.

## Quel staging est disponible ?

La liste Supabase consultée le 10 octobre comporte deux projets dans l'organisation :
- `wesqmwjjtsefyjnluosj` : `digiy-core`, ACTIVE_HEALTHY et **PRODUCTION — ne pas écrire**.
- `qovwdxemfmgvjyfotatd` : ancien projet intitulé « BEAUVILLE's Project », **INACTIVE**. Aucun élément ne démontre qu'il s'agit d'un staging utilisable ou autorisé. **Ne pas le réactiver ni y toucher** sans configuration validée, isolement et maîtrise du coût.

La recette réalisée par cette PR est donc une **simulation E2E en PostgreSQL 17 jetable GitHub Actions**. Elle utilise les **vraies fonctions SQL candidates** V0, V1, V2, V5 et les **rôles SQL `anon` / `authenticated` avec UID synthétiques** ; ce n'est **PAS** un test OAuth/magic-link sur deux comptes Supabase réels ou un navigateur connecté à un serveur réel.

## Parcours E2E exécuté par la CI V6

1. Monte une base PostgreSQL 17 jetable `digiy_appointments_test` ; installe les contrats V0 (réservation atomique), V1 (statut propriétaire et neutralité PAY), V2 (catalogue public) et V5 (statut et note privée).
2. Avec le rôle `anon`, consulte uniquement un catalogue A publié sur `Africa/Dakar`, exclut B non publié et toute donnée personnelle. Choisit **un vrai `slot_id` et `service_id` de fixture**.
3. Crée `pending` au serveur avec un UUID de demande ; réessaie le même UUID (idempotence) et refuse la réservation d'un second créneau qui chevauche le premier.
4. Après réservation, vérifie que le planning public indique les deux plages comme indisponibles.
5. Avec `authenticated` UID B, démontre l'impossibilité de voir/modifier la demande de A, même quand son UUID exact est connu.
6. Avec `authenticated` UID A, enregistre une note privée sans l'exposer dans le résultat, confirme puis annule ; n'écrit aucun paiement fictif.
7. Vérifie sous privilèges de test que le prix et la durée viennent du serveur, que les anciennes lignes synthétiques et le compteur PAY sont inchangés, puis que le créneau redevient réservable par le client.
8. Supprime les seules fonctions SQL candidates et vérifie le retour arrière sur la base jetable. **Ce rollback destructif de fixture n'est PAS une procédure de rollback production** et ne doit jamais être copié dans `digiy-core`.

## Reste bloquant pour le GO réel

- **Restauration d'une archive chiffrée récente sur Mac privé**, avec marqueurs et inventaire vérifiés (au moins le snapshot choisi pour pré-migration). Pour les sauvegardes quotidiennes, la qualité du retour arrière doit tenir compte de l'instantané et des données modifiées depuis.
- Staging réellement isolé, authentification Supabase vraie de deux professionnels A/B et test mobile/desktop avec connexion, expiration de session, notes, cross-tenant et refus de l'ancien UPDATE.
- Revue et correction des anciennes RPC, droits PUBLIC et déclencheurs PAY. Préparer une **migration non destructive** tenant compte des sept réservations historiques réelles.
- Le contrôle de fuseau `Europe/Paris`, changements d'heure IANA et chevauchements UTC n'est pas intégré à V0. Aucun RDV générique France n'est activable.
- Validation métier d'un professionnel réel et de sa fiche, puis feu vert humain sur migration distincte en production. Séparer définitivement les états de RDV des écritures d'encaissement.

**État : GO CI isolée ; NO-GO staging réel non identifié, NO-GO SQL DIGIY CORE, NO-GO émission d'une vraie réservation.**
