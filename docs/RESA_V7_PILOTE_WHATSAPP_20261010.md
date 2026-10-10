# RÉSA V7 — réception de demandes réelles sur WhatsApp

**Pilote Saly, 10 octobre 2026.**

## Pourquoi

Le portail RÉSA public `index.html` et `planning.html` sont déjà publiés, mais aucun profil/slot de RÉSA UNIVERSEL n'est encore actif dans `digiy-core`. Les candidates SQL V0–V6 ont passé une recette **isolée**, pas une migration de production. Afficher « Réserver » sans contact utilisable laisserait les personnes bloquées sur une vitrine.

## Première fonction utile au public

- `demande-rdv.html` : demande réelle de mise en relation pour un métier sur rendez-vous (beauté, artisanat, conseil, cours, etc.).
- Activité, prestation, secteur, date et heure *souhaitées* ; prénom facultatif, aucun téléphone supplémentaire demandé : le contact est porté par WhatsApp.
- Bouton utilisateur explicite ouvrant un message prérempli à la **ligne DIGIYLYFE déjà publiée** (`+221 77 134 28 89`). La personne doit valider elle-même l'envoi dans WhatsApp.
- Depuis `index.html` : accès visible avec libellé traduit en 8 langues. Depuis `planning.html` : bouton d'orientation même sans créneau ; la route directe au WhatsApp du professionnel demeure prioritaire lorsqu'une disponibilité publiée existe.
- **Aucune réservation enregistrée** par la page, aucun blocage de créneau, aucune transaction SQL, aucune donnée stockée, aucun paiement, aucune note TRUST, aucune dépendance payante.
- Le message dit clairement que DIGIYLYFE **oriente** le client ; le professionnel garde la disponibilité, l'accord final, ses prix et le règlement.

## Parcours de recette terrain

1. Ouvrir `https://resa-table-resto.digiylyfe.com/` (ou son alias de production vérifié) depuis téléphone ; cliquer sur « Demander sur WhatsApp ».
2. Remplir avec une vraie demande volontaire. Vérifier que le formulaire ne fabrique aucun nom de professionnel ni horaire « disponible ».
3. Appuyer sur « Ouvrir ma demande dans WhatsApp » et **envoyer le message dans WhatsApp** ; confirmer sa réception sur le téléphone DIGIYLYFE. Sans appui Envoyer dans WhatsApp, DIGIYLYFE ne reçoit rien.
4. DIGIYLYFE oriente vers un professionnel réellement identifié et recueille la décision. La confirmation reste manuelle ; aucune valeur `confirmed` n'est écrite par V7.
5. Vérifier le retour du client, les heures Sénégal, la qualité des informations reçues et les éventuelles incompréhensions ; ajuster le formulaire via retours terrain.
6. Faire la recette aussi depuis `planning.html` sans créneaux puis depuis une fiche professionnelle qui dispose de son **propre** WhatsApp : ce contact direct ne doit pas être remplacé par le central DIGIY.

## Limites à ne pas masquer

**V7 est un pilote d'orientation par WhatsApp, pas l'activation de la réservation universelle automatique.** Pour ouvrir une véritable réservation (slots atomiques `pending` en CORE), il faudra encore une restauration récente prouvée, un staging Auth A/B avec vrais comptes, l'audit des anciens RPC/permissions et PAY, une migration non destructive, un professionnel réel et un BAT validé. Voir l'[issue #31](https://github.com/BEAUVILLE/digiy-resa-table-resto/issues/31).

Ne pas multiplier les suivis centralisés : dès qu'un professionnel a sa fiche et son WhatsApp, on privilégie sa relation **directe**. DIGIYLYFE ne devient ni caisse, ni plateforme de commission, ni arbitre de disponibilités.
