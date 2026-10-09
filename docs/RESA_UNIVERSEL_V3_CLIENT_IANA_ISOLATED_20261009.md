# RÉSA UNIVERSEL — V3 : demande client + fuseaux IANA (isolés)

Date : 9 octobre 2026. **AUCUNE activation de réservation, aucun SQL sur digiy-core.**

## Après V2
- Le contrat V2 retourne les vrais `slot_id`, `service_id`, services actifs et créneaux compatibles. Il n'est pas encore déployé côté CORE.
- Le moteur V0 (base jetable seulement) accepte une demande avec ces IDs, conserve la capacité 1 et crée `pending`. V1 modélise la neutralité PAY et la décision propriétaire en base jetable.
- Il manquait la préparation sûre du formulaire et le refus des heures ambiguës de Paris.

## V3 livré
1. `resa-universal/booking-client-core.mjs` est un contrôleur métier pur : exige le catalogue V2, le créneau disponible, la prestation compatible et l'identifiant d'opération UUID. Il ne reçoit ni prix ni durée du navigateur pour créer une réservation.
2. `submitRequest` est **inactif par défaut**, appelle le RPC V0 uniquement avec un transport injecté et un feu vert explicite côté staging, et annonce strictement `pending` après succès du serveur. Une erreur réseau, `confirmed` imprévu ou réponse invalide reste un échec, jamais un rendez-vous inventé.
3. Le UUID de la demande est fourni par la couche UI. En cas de retry après coupure réseau, la couche UI doit **réutiliser le même UUID**, jamais en générer un nouveau. Le test vérifie ce contrat.
4. `digiy_resa_local_time_to_utc_v3` est un candidat SQL **interne** en PostgreSQL 17 jetable. Il convertit les horaires locaux Dakar/Paris en UTC, rejette explicitement les heures inexistantes du printemps et ambiguës de l'automne à Paris. Pas de permission publique EXECUTE.
5. Les tests incluent Paris 29 mars et 25 octobre 2026, Dakar aux deux dates, fuseaux invalides, API interdite à anon/authenticated et rollback sans toucher aux deux réservations historiques de simulation.

## Ce qui n'est PAS fait
- Pas de formulaire public réellement activé ; `planning.html` reste de la consultation.
- Pas de connexion SQL V3 aux réservations V0 : la conversion UTC est encore une **fonction préparatoire**. Les enregistrements actuels stockent date et heure locales.
- Pas d'insertion en production, pas d'avis TRUST, pas de notification ou confirmation automatique, pas de modification PAY.
- Le fuseau Paris n'est pas autorisé pour la réservation V0 : V2 continue de bloquer tout profil autre que Dakar jusqu'à un stockage UTC, une durée et un contrôle transactionnel IANA cohérents.
- Les **sept réservations historiques réelles**, les huit services hérités et les RPC publiques existantes ne sont pas modifiés. L'inventaire des consommateurs legacy reste bloquant avant toute modification des permissions en production.

## Prochaines portes GO
1. Faire converger le stockage et les conflits des plages horaires en UTC, avec tests concurrence Dakar/Paris ; documenter le passage à l'heure été/hiver.
2. Inventorier les vrais appels aux deux RPC héritées et UPDATE directs, sécuriser sans casser les anciennes fiches.
3. Tester un formulaire téléphone réel en **staging connecté à une base sans clients réels**, gérer les réponses idempotentes et la visibilité propriétaire A/B.
4. Démontrer une restauration de sauvegarde récente et une migration réversible non destructive.
5. BAT professionnel réel + accord de mise en production spécifique.

**Aucun de ces tests ne constitue une approbation implicite de production.** Doctrine : 0 % commission, paiement direct, aucun revenu fictif.
