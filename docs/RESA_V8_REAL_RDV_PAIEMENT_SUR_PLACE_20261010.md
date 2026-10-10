# RÉSA V8 — Rendez-vous posé, paiement sur place, carnet métier optionnel

**10 octobre 2026 · code client/SQL candidat uniquement · CORE PRODUCTION INCHANGÉ**

## Expérience finale décidée

1. Le client ouvre le module RÉSA du professionnel depuis sa fiche mobile et choisit **un créneau réellement disponible**.
2. Le serveur réalise une réservation atomique et retourne un `booking_id` et le statut `pending`. **Dès ce retour positif, le créneau est occupé**, même en attente de la confirmation du professionnel.
3. Affichage clair et rassurant côté client : **✅ RDV posé · Paiement sur place**. Le détail nuance : confirmation du professionnel en attente, aucun encaissement DIGIY.
4. **Après** succès serveur, le patient peut envoyer une copie WhatsApp au **numéro du professionnel**, avec jour, heure, prestation, référence et statut. Envoi facultatif : la réservation reste dans son planning même sans message.
5. Le professionnel ouvre sa PWA dans sa poche et retrouve ses rendez-vous. Seul le serveur valide ses changements de statut; annuler libère le créneau.
6. Le client règle **sur place directement au professionnel**. Pas d'acompte imposé, pas d'API WhatsApp payante, 0 % commission.
7. **Vente additionnelle après la prestation : CARNET PRO**, abonnement métier facultatif pour saisir **seulement les encaissements effectivement reçus**, suivre les recettes et piloter l'activité. Tarif Sénégal validé : **13 000 FCFA/mois**. L'offre ne s'affiche **jamais sur le formulaire client** et n'est pas obligatoire pour utiliser RÉSA.

Doctrine vitale : **RDV posé ≠ RDV confirmé ≠ somme encaissée**. Le trigger financier actuel `digiy_resa_push_to_pay_after_status` est inacceptable pour les nouvelles demandes : sa mise à jour sur `confirmed` peut créer une recette automatique sans paiement. `CARNET PRO` n'y remédie pas à lui seul : la migration sécurisée doit neutraliser toute écriture financière déclenchée par le statut d'un RDV. **Aucune écriture CARNET ou PAY n'est intégrée ni simulée dans V8.**

## Fichiers livrés

- `rdv-universel.html` : page publique responsive branchée sur le **contrôle serveur** et la vraie disponibilité V2, avec confirmation client strictement après succès V1 et WhatsApp facultatif.
- `resa-universal/pilot-booking-v8.mjs` : réutilise les validations, le UUID idempotent et les contrôles de V4, mais ne transmet la requête qu'au nouveau `digiy_resa_universal_request_v1` protégé par le serveur. Aucune activation via paramètre URL ou `localStorage`.
- `sql/candidates/20261010_resa_universal_v8_pilot_gate_ISOLATED.sql` : candidate **PG17 jetable uniquement**, crée `digiy_resa_universal_launch_controls`, `digiy_resa_universal_pilot_gate_v1` et `digiy_resa_universal_request_v1`. Par défaut chaque professionnel est **OFF**. Le SQL révoque l'accès API direct à la V0 : impossible de contourner la règle depuis le navigateur. Les comptes clients ne peuvent pas éditer le contrôle d'activation.
- Test SQL de scénario complet `tests/sql/resa_universal_v8_gate_assertions.sql` : OFF → refus → activation admin dans fixture → RDV réel synthétique → retry idempotent → créneau concurrent refusé → PAY vide → désactivation → plus de nouvelle réservation et RDV existant conservé. Retour arrière isolé.
- `contracts/resa-v8-carnet-pro-upsell.json` : vente additionnelle facultative réservée à la PWA propriétaire et **à un vrai encaissement**, jamais au patient.
- CI isolée V8, en plus des CI V0–V7 existantes.

## Portes de mise en production non résolues

**Aucune candidate ISOLATED ne doit être exécutée telle quelle sur digiy-core** : ses gardes refusent les bases hors `digiy_appointments_test`. Toute future migration production devra être indépendante et atomique, revue puis testée dans un staging autorisé.

- La dernière sauvegarde chiffrée du 9 octobre 2026 a un artefact GitHub valide, mais **pas encore de preuve de restauration récente** ; ne jamais publier les identifiants ou un dump.
- Production : zéro profil RÉSA universel et zéro créneau universel actif ; **7 réservations historiques à conserver** (4 tests explicites, 3 à qualifier).
- Trigger de synchronisation PAY **actif** sur modification de `status` : tout statut `confirmed` génère potentiellement une écriture de recette fictive. Tester neutralisation ciblée aux réservations V0 (`client_request_id` non NULL), en conservant uniquement les usages legacy réellement établis.
- `authenticated` peut encore effectuer des `UPDATE` directs sur les réservations historiques. Une nouvelle RPC propriétaire seule **ne protège pas les demandes V0** tant que ce contournement n'a pas été supprimé après migration des anciens cockpits. Éviter un `REVOKE` aveugle.
- Deux comptes propriétaires Auth **réels** sur un staging séparé, tests PWA smartphone, réseaux interrompus, annulation, RLS, capabilité, et parcours jusqu'au WhatsApp. Aucun projet de staging opérationnel autorisé n'a été identifié.
- Activer le premier professionnel réel par contrôle **serveur et validation BAT** seulement après ces preuves, sans générer de faux clients.
- France/Paris et variations DST doivent être achevés séparément ; le pilote V8 est `Africa/Dakar`.

**GO GitHub et tests isolés. NO-GO SQL CORE, activation publique de la réservation et écriture PAY/CARNET tant que ces portes restent ouvertes.**

## Prochaine étape après preuve de restauration

Construire et valider la migration de production non destructive comme **une seule opération contrôlée**, avec backup, tests à blanc, inventaire des anciennes fonctions, neutralisation du trigger financier pour les nouvelles demandes, retrait de la mise à jour directe aux consommateurs migrés, et reprise des 7 anciennes demandes sans suppression. Le formulaire `rdv-universel.html` ne doit être relié aux fiches réelles qu'une fois le contrôle `pilot_gate_v1` activé pour un vrai adhérent.
