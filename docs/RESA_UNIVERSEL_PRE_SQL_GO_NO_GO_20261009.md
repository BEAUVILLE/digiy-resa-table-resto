# DIGIY RÉSA UNIVERSEL — CONTRÔLES AVANT SQL / CORE

**Audit de préparation : 9 octobre 2026**  
**Périmètre :** prise de rendez-vous générique pour professions compatibles (services professionnels, beauté et autres métiers à créneaux), **hors RESTO, LOC, DRIVER et autres exceptions qualifiées sur le terrain**.  
**Dépôts :** `BEAUVILLE/digiy-resa-table-resto` (moteur), `BEAUVILLE/digiy-master-modeles` (contrat MAÎTRE).  
**CORE visé :** projet Supabase `digiy-core` (réf. `wesqmwjjtsefyjnluosj`), **seulement après contrôle et test isolé des SQL**. DIGIY AGENT CORE n'est pas activé par ce chantier.

## Verdict du contrôle

**NO GO pour une réservation automatique générique en production.**  
Le planning public et les ouvertures propriétaires sont des fondations opérationnelles, mais le chemin transactionnel universel et les contraintes métier complètes ne sont pas encore validés. Ce document n'autorise **aucun SQL de production** et **aucune nouvelle réservation réelle**. Aucun droit, client, créneau, réservation, mouvement PAY ni déclencheur n'a été modifié dans ce contrôle.

### Constats vérifiés en lecture seule sur le CORE

| Repère | Observation | Impact |
|---|---|---|
| C01 | `digiy_resa_profiles` : **0 ligne** ; `digiy_resa_slots` : **0 ligne** | Pas de professionnel générique réel pour un BAT bout en bout. |
| C02 | `digiy_resa_bookings` : **7 anciennes lignes** (6 `pending`, 1 `confirmed`) ; toutes sans profil actuel sur le même slug | **Préserver l'historique** et établir sa provenance/dépendances avant toute migration. Ne pas purger, renommer ni réaffecter. |
| C03 | `digiy_resa_services` : **8 services actifs**, tous sans profil actuel correspondant dans `digiy_resa_profiles` | Analyser les consommateurs du modèle hérité avant de le relier au nouveau planning. |
| C04 | `digiy_resa_public_week_v1(text,date)` accessible à `anon`, lecture des créneaux `open` du professionnel **actif et publié**, masque les rendez-vous actifs par chevauchement | Fondations de lecture conformes, mais **lecture ≠ réservation atomique**. |
| C05 | Profils, créneaux et réservations génériques ont RLS active ; les politiques propriétaires relient `auth_user_id = auth.uid()` | Vérifier en vrais tests A/B et avec les rôles API ; RLS seule ne prouve pas la sécurité d'une fonction `SECURITY DEFINER`. |
| C06 | `digiy_resa_create_booking(...)` et `resa_create_booking_by_slug(...)` possèdent `EXECUTE` pour `anon` | **Bloquant** : contrôler les vrais consommateurs et le chemin d'autorisation avant de réutiliser, remplacer ou retirer ces RPC. |
| C07 | La fonction héritée `digiy_resa_create_booking` choisit un service par slug et vérifie un conflit à **heure de début identique** ; elle ne vérifie pas les créneaux `digiy_resa_slots` publiés et ouverts dans sa définition consultée | **Bloquant** : interdiction de la présenter comme la nouvelle réservation universelle. |
| C08 | Index partiel `digiy_resa_unique_active_slot` : unicité `(slug,booking_date,booking_time)` pour `pending/confirmed` | Protège le début identique, **pas** les plages qui se chevauchent ni les capacités multiples. |
| C09 | Déclencheur actif `digiy_resa_push_to_pay_after_status` sur changement de statut des réservations | Une transition vers `confirmed` peut entraîner, si montant/abonnement PAY valides, l'écriture d'un **mouvement DIGIY PAY/CARNET** ; ce n'est pas un encaissement, mais **aucune recette présumée sans traitement métier explicite**. Analyser ses usages et ses effets avant de modifier les transitions. |
| C10 | `digiy_resa_get_available_slots` et variantes `digiy_resa_get_slots_by_service` génèrent certaines heures depuis des valeurs par défaut | Les futures interfaces publiques ne doivent **jamais** les utiliser pour inventer une disponibilité : rester sur les vrais slots du professionnel. |
| C11 | `RESA` générique ne possède pas, à cet audit, de première fiche professionnelle activée | Test réel propriétaire/client A/B impossible **sans** une instance autorisée, créée avec BAT. |

Les observations sont des **photographies datées** et devront être revérifiées juste avant tout SQL.

## Contrat fonctionnel verrouillé avant le SQL

1. **Client :** fiche publiée → liste des prestations validées → 7 jours de vrais créneaux → clic immédiat → récapitulatif → demande/réservation avec **état exact**. Affichage instantané ne signifie pas disponibilité garantie avant le commit serveur.
2. **Professionnel :** choisit jours, heures, durées, prestations, créneaux fermés, jours d'absence et mode de confirmation. Aucune heure imposée. Il peut consulter, confirmer/refuser si mode manuel, annuler et retrouver l'historique.
3. **Mode de confirmation :** `pending` si validation humaine requise ; `confirmed` **uniquement si** le professionnel a autorisé la confirmation automatique et que le moteur métier contrôle toutes les conditions. Ne jamais afficher `confirmé` pour une simple sélection.
4. **Capacité MVP :** un rendez-vous = un client/un créneau (`capacity=1`) tant que les capacités multi-places et les durées chevauchantes n'ont pas leurs propres tests transactionnels. Pour les groupes, employer une adaptation ultérieure explicitement validée.
5. **Catalogue :** prestation, durée et conditions doivent provenir du serveur et de la fiche active, jamais d'un tarif/durée arbitraire communiqué par le navigateur.
6. **Fuso-horaire :** dates et heures calculées selon le fuseau déclaré du professionnel (IANA), correctement distingué de celui du visiteur ; tester Sénégal/France et changements d'heure avant publication interterritoriale.
7. **Contact et relation directs :** coordonnées et paiement restent entre client et professionnel. Pas de caisse DIGIYLYFE, **0 % commission** ; aucun enregistrement financier fictif.
8. **Confidentialité :** ne pas recueillir de motif juridique, médical, fiscal ni de dossier sensible dans le calendrier public. Le client ne voit jamais l'identité d'un autre client.
9. **Spécialisations :** RESTO conserve tables/services/capacités ; LOC nuits/séjours ; DRIVER trajets/destinations ; les cas particuliers révélés sur le terrain font l'objet d'une fiche de qualification avant toute adaptation générique.

## Garde-fous SQL à concevoir, mais **pas encore à exécuter**

- **Transaction de réservation atomique** : validation du profil actif/publié, du service actif, du vrai créneau ouvert, de la durée, de la capacité et de l'état de confirmation dans le même commit.
- **Concurrence** : verrou au niveau du propriétaire/créneau ou contrainte d'exclusion/alternative prouvée ; `2 clients en parallèle → 1 seul résultat gagnant` en capacité 1 ; aucune collision par chevauchement horaire.
- **Idempotence** : même identifiant d'opération répété/rejoué/réseau instable ne doit produire qu'une réservation et qu'une notification.
- **Transitions** : `pending → confirmed/cancelled`, `confirmed → cancelled/done/no_show` selon règles explicites ; libération cohérente de capacité et pas de résurrection abusive d'un rendez-vous.
- **Droits API** : inventaire des fonctions `SECURITY DEFINER`, droits `anon/authenticated/PUBLIC`, `search_path`, validation propriétaire `auth.uid()` ; aucune lecture privée par simple slug.
- **Compatibilité héritée** : appeler les anciennes RPC depuis un chemin contrôlé ? Les déprécier ? Décision seulement après inventaire de leurs consommateurs, sauvegarde des signatures et analyse d'impact des 7 réservations/8 services existants.
- **PAY/CARNET** : caractériser le déclencheur lors du passage à `confirmed` en sandbox isolée ; ne jamais assimiler confirmation de rendez-vous à encaissement constaté.
- **Rollback et preuve** : snapshot de schéma/permissions, migration réversible, tests sur PostgreSQL éphémère puis environnement de staging isolé avant digiy-core. Préserver toutes les données réelles.

## Matrice de recette GO / NO GO

| Porte | Condition exacte de GO | État au 09/10 |
|---|---|---|
| G01 Contrat métier | Règles et exceptions écrites, `pending/confirmed`, capacité 1 et liberté de l'agenda validées | **GO documentaire** |
| G02 UX client/pro | Clic immédiat, semaine, confirmation sans faux `success`, propriétaire contrôle horaires ; vraie instance générique testée | **NO GO** (modèle prêt, pas d'instance générique active) |
| G03 Autorisation | Isolation A/B, `anon`, auth, lectures privées/écritures et RPC héritées testées négativement | **NO GO** |
| G04 Concurrence | Deux réservations parallèles et plages chevauchantes : un seul succès en capacité 1 | **NO GO** |
| G05 Historique & intégration | 7 réservations/8 services hérités et appels à anciennes RPC cartographiés, sans perte ni publication | **NO GO** |
| G06 PAY et effets secondaires | Confirmation / annulation sans faux revenu ; déclencheur audité et neutralité financière prouvée | **NO GO** |
| G07 Fuseau & durée | Tests Sénégal/France, dates limites, jours fermés, offre serveur, calcul des durées | **NO GO** |
| G08 Staging et rollback | Migration et retour arrière exécutés dans DB jetable puis staging ; CI vert ; aucun effet prod | **NO GO** |
| G09 CORE | BAT d'une fiche réellement autorisée, contre-test propriétaire B, validation explicite du déploiement | **NO GO** |

### Ordre de travail sans dispersion

**Étape 1 — maintenant :** figer ces contrôles, leurs scénarios automatiques et l'état de référence, **sans SQL de modification**.  
**Étape 2 — quand les prérequis sont définis :** préparer les migrations dans une branche séparée ; tester PostgreSQL éphémère (dont concurrence, héritage PAY et rollback), sans prod.  
**Étape 3 — après tests verts et BAT :** ouvrir une revue SQL/droits, activation progressive dans **digiy-core**, puis vérification mobile d'un vrai client/pro.  
**Étape 4 — seulement après preuve terrain :** produire la procédure de duplication MASTER/MAÎTRE, puis étendre aux métiers compatibles.

**Règle de fusion :** ce document peut être fusionné comme référence de contrôle ; il n'est en aucun cas un feu vert pour exécuter un SQL sur `digiy-core`.
