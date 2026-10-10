# DIGIY RÉSA UNIVERSEL — V5 : décision propriétaire + notes privées

**10 octobre 2026. Candidat SQL sur PostgreSQL 17 jetable uniquement, sans modification de DIGIY CORE.**

## Problème opérationnel confirmé

Le MASTER propriétaire `BEAUVILLE/digiy-master-modeles/MASTER-MAITRE-RESA-V1/gestion.html` gère encore directement le `status` et la `note_text` des réservations par un `UPDATE` côté navigateur. La PR V1 a validé en base jetable le remplacement d'un droit `UPDATE` large par une RPC étroite pour les **statuts**, mais pas encore la gestion des **notes privées**.

Si on retire le droit global `UPDATE` aujourd'hui sur `digiy-core`, ce cockpit historique risque de perdre ses actions. Il faut migrer ses clients et vérifier les autorisations avant de toucher aux privilèges.

## V5 : périmètre effectivement préparé et testé par la CI

- Une seule RPC candidate `digiy_resa_universal_owner_manage_v2(uuid,text,text)`, accessible uniquement au rôle `authenticated` **dans la fixture isolée**. `anon` est explicitement privé d'`EXECUTE`. Un JWT sans `auth.uid()` ne peut pas muter.
- Le serveur choisit la ligne par UUID **et** vérifie `digiy_resa_profiles.auth_user_id=auth.uid()` avec profil actif ; verrouille la réservation avec `FOR UPDATE` avant mutation. A ne voit pas B et B ne modifie pas A.
- Ne s'applique **qu'aux demandes universelles V0** (`client_request_id IS NOT NULL`). Les anciennes réservations restent conservées et hors de portée de la nouvelle RPC.
- Distinction stricte des opérations : `note` modifie uniquement `note_text` (1000 caractères maximum, valeur vide = effacement) et `updated_at`, mais **pas le statut**. Les décisions `confirmed`, `cancelled`, `done`, `no_show` modifient uniquement `status` et `updated_at` ; il est interdit de mélanger décision et note dans le même appel.
- Matrice : `pending→confirmed/cancelled`, `confirmed→cancelled/done/no_show`. Annulation conservée en historique, pas de résurrection et libération du créneau validée en base isolée.
- Grâce au garde-fou PAY V1 déjà testé dans la fixture, **aucune écriture financière** n'est créée lors de la confirmation d'une nouvelle demande. Le fonctionnement des réservations anciennes est conservé dans le test, sans prétendre qu'il est conforme en production.
- Réponses de RPC réduites à `ok`, `booking_id`, `action` et `status`. Ni nom, ni téléphone, ni note, ni montant ne sont renvoyés.
- Adaptateur cockpit `resa-universal/staging-owner-actions-v5.mjs` désactivé par défaut ; transport injecté, vérification de réponse, double-clic refusé, `done` **non assimilé à une preuve réelle** pour DIGIY TRUST.
- Exécution uniquement sur `digiy_appointments_test` ; le rollback supprime la seule RPC V5 et démontre la conservation de V0, V1 et des réservations historiques **synthétiques**.

## Garde-fous restants : aucun GO production

1. Le MASTER propriétaire réellement utilisé doit consommer la nouvelle RPC **après** déploiement côté serveur, ou basculer progressivement par type d'enregistrement ; garder les anciennes lignes accessibles tant que leurs contrats ne sont pas migrés.
2. Inventaire exhaustif des appels historiques, des droits `UPDATE` et des permissions `PUBLIC`. **Ne pas faire de REVOKE en CORE** sans compatibilité de l'interface.
3. La RPC V5 couvre la **gestion des demandes V0**, pas l'activation des profils, la création des créneaux ou le flux de confirmation automatique. Les fuseaux `Europe/Paris` restent bloqués tant que stockage/chevauchements UTC n'ont pas été intégrés au moteur.
4. Tester avec deux **vrais comptes** propriétaires A/B dans un staging représentatif et un navigateur mobile (le test actuel utilise des identités factices + rôles Postgres).
5. Contrôler la prévention de l'abus, le journal d'audit et la consultation des notes privées uniquement dans le contexte propriétaire ; séparer tout traitement PAY de l'état de réservation.
6. **Restaurer une sauvegarde réelle** et tester le retour arrière non destructif en staging. L'incident [admin-digiy #9](https://github.com/BEAUVILLE/admin-digiy/issues/9) reste une porte bloquante.
7. Obtenir le BAT d'un professionnel réel et autorisation explicite avant migration `digiy-core`.

**Règle : SQL candidat dans le dépôt ≠ SQL exécuté sur la production.** Les 7 réservations historiques réelles, les 8 services et les applications spécialisées RESTO / LOC / DRIVER ne sont pas modifiés par cette PR. 0 % commission, relation et paiement directs.
