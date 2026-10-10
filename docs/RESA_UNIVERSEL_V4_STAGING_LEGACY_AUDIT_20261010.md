# DIGIY RÉSA UNIVERSEL — V4 : impact des consommateurs historiques et flux client de staging

**Audit du 10 octobre 2026. Lecture seule sur le projet `digiy-core` (`wesqmwjjtsefyjnluosj`). Aucun SQL de production exécuté.**

## Situation réelle vérifiée

| Élément | Valeur observée |
| --- | --- |
| Profils RÉSA génériques | 0 |
| Créneaux RÉSA génériques | 0 |
| Réservations historiques | 7 : 6 `pending`, 1 `confirmed` |
| Prestations actives sans profil générique | 8 |
| `authenticated` UPDATE sur `digiy_resa_bookings` | Oui, RLS activée |
| `anon` UPDATE sur `digiy_resa_bookings` | Non |
| `digiy_resa_create_booking(...)` | SECURITY DEFINER, EXECUTE anon/authenticated |
| `resa_create_booking_by_slug(...)` | SECURITY DEFINER, EXECUTE anon/authenticated |
| V0, V1 PAY/owner, V2 catalogue, V3 IANA/client dans le CORE | **Non déployés** |

Les deux RPC héritées ont `search_path=public`, et le statut `confirmed` peut déclencher le chemin financier historique. La présence d'un droit public **n'est pas à elle seule une preuve d'exploitation**. Les tables et permissions doivent être auditées avec chaque appel métier avant suppression ou changement.

## Consommateurs repérés dans les sources GitHub (échantillon contrôlé, non exhaustif)

1. **RÉSA ancien parcours archivé** — [`archive/ancienne-mecanique-pro-resa-2026-08-25/reserver.html`](https://github.com/BEAUVILLE/digiy-resa-table-resto/blob/main/archive/ancienne-mecanique-pro-resa-2026-08-25/reserver.html) : appelle `digiy_resa_create_booking` et les lecteurs de disponibilités `digiy_resa_get_available_slots` / `digiy_resa_get_slots_by_service`. **Compatibilité incertaine** : le fichier est archivé dans le code, mais son éventuel accès direct ou ses liens depuis d'autres fiches ne sont pas établis.
2. **MASTER propriétaire actuel** — [`MASTER-MAITRE-RESA-V1/gestion.html`](https://github.com/BEAUVILLE/digiy-master-modeles/blob/main/MASTER-MAITRE-RESA-V1/gestion.html) : `db.from('digiy_resa_bookings').select(...)` et `.update({status,note_text,updated_at})` filtré par ID et slug. **Consommateur confirmé du droit UPDATE direct**. Si ce droit est révoqué sans migration UI et tests A/B, la confirmation ET l'enregistrement des notes cessent de fonctionner.
3. **MASTER planning lecteur** — [`MASTER-MAITRE-RESA-V1/planning.html`](https://github.com/BEAUVILLE/digiy-master-modeles/blob/main/MASTER-MAITRE-RESA-V1/planning.html) : lit la RPC `digiy_resa_public_week_v1`. Ne crée pas de rendez-vous.
4. **EXPLORE lecture publique** — [`explore-resa-public-bridge.js`](https://github.com/BEAUVILLE/digiy-explore/blob/main/explore-resa-public-bridge.js) : lit `digiy_resa_public_week_v1`. Ce pont n'est pas une RPC de réservation.
5. **Planning RÉSA courant** — [`planning.html`](https://github.com/BEAUVILLE/digiy-resa-table-resto/blob/main/planning.html) : lit `digiy_resa_public_week_v1`, propose copie/WhatsApp, sans écriture de réservation.
6. **RÉSA RESTO** — [`resa-resto/index.html`](https://github.com/BEAUVILLE/digiy-resto/blob/main/resa-resto/index.html) : spécialisé tables/services, à garder séparé. L'inspection de ce fichier n'a pas trouvé d'appel aux deux RPC génériques.

Autres fichiers vérifiés : `admin-digiy/suivi-resa-multi.html`, `digiylyfe.com/index.html`, `digiy-resa-table-resto/index.html`, `resa-beauty/index.html` et `resa-beauty/gestion.html` ; pas d'appel textuel trouvé aux deux RPC génériques dans cet échantillon. **Ce n'est pas un inventaire global de tous les dépôts et tous les consommateurs externes.**

## Décision de compatibilité

**G05 (historique / anciennes RPC / droits propriétaire) : BLOQUÉ POUR PRODUCTION.**

- Ne pas révoquer `EXECUTE` des anciennes RPC ni `UPDATE` sur `digiy_resa_bookings` tant que le chemin historique n'a pas été inventorié, remplacé et validé.
- Faire porter les nouvelles réservations sur V0 + V1 + V2 seulement **après** un contrat de déploiement sécurisant les propriétaires et PAY ; jamais sur les anciennes RPC à dates/heures imposées.
- Migrer la mise à jour propriétaire vers une RPC vérifiant `auth.uid()`, le bon titulaire, le statut et la note privée ; préserver les autres colonnes et les sept lignes historiques. Pour les lignes orphelines sans profil, prévoir une reprise humaine et tracée, pas un rattachement implicite.
- Les annulations doivent libérer la disponibilité, le propriétaire ne peut pas marquer `done` comme une preuve indépendante DIGIY TRUST, la confirmation ne doit pas créer de recette PAY non encaissée.
- Cartographier les appels via les clients publiés et les journaux API autorisés en complément de GitHub avant toute décision de retrait.

## Livraison technique V4 (non reliée aux pages publiques)

- `resa-universal/staging-booking-flow-v4.mjs` orchestre le catalogue V2, un choix réel de créneau/prestation, les coordonnées du client, puis l'appel V0 **uniquement si un transport RPC et un indicateur staging sont explicitement injectés**.
- Sans staging activé, aucun appel n'est possible. Le code ne contient ni URL Supabase, ni clé, ni table ou commande de paiement.
- L'identifiant UUID d'une tentative reste le même après une coupure ; le formulaire ne peut pas modifier les données au moment d'un retry incertain. Deux clics simultanés ne doublent pas la demande.
- Une réponse serveur `pending` reste « demande enregistrée, en attente de confirmation », jamais « rendez-vous confirmé ».
- **Cet interrupteur côté client n'est pas une autorisation de sécurité** : RLS, authentification, idempotence, anti-abus et ownership doivent être vérifiés côté serveur en staging.

## Portes toujours nécessaires avant premier rendez-vous réel

1. SQL de migration non destructif en staging représentatif, avec fuseau IANA/UTC et chevauchements Sénégal/France sous charge.
2. RPC propriétaire pour la confirmation et les notes (y compris compatibilité historique), tests JWT A/B et suppression ciblée des droits hérités seulement après bascule.
3. Formulaire client/mobile réellement branché dans un environnement de staging sécurisé, puis cockpit propriétaire et annulation.
4. Sauvegarde **restaurée et vérifiée**, retour arrière de production non destructif ; incident [admin-digiy #9](https://github.com/BEAUVILLE/admin-digiy/issues/9) à clôturer sur preuve.
5. BAT d'un véritable professionnel consentant et validation avant tout SQL dans `digiy-core`.

**État : GO pour tests et documentation isolés. NO GO production et aucune réservation réelle.** Zéro commission, contact/paiement directs.
