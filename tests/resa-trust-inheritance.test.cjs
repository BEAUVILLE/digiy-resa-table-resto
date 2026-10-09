'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const cfg=JSON.parse(fs.readFileSync(path.join(root,'contracts/resa-trust-inheritance-v1.json'),'utf8'));
const audit=fs.readFileSync(path.join(root,'docs/RESA_UNIVERSEL_V0_SQL_ISOLE_RESULTATS_20261009.md'),'utf8');
test('Héritage de LOC explicite sans recycler la table de feedback privé LOC',()=>{
 assert.equal(cfg.source.module,'LOC');
 assert.equal(cfg.master.repo,'BEAUVILLE/digiy-master-modeles');
 assert.equal(cfg.production.LOC_reviews_migrated,false);
 assert.equal(cfg.production.core_modified,false);
 assert.equal(cfg.production.sql_enabled,false);
 assert.equal(cfg.status,'CONTRACT_ONLY_NO_PRODUCTION_RATINGS');
 assert.deepEqual(cfg.external_specialized_modules,['RESTO','LOC','DRIVER']);
});
test('Qualité-prix est une note à part et jamais une moyenne de prix bas',()=>{
 assert.equal(cfg.required_ratings.quality.required,true);
 assert.equal(cfg.required_ratings.value_for_money.required,true);
 assert.equal(cfg.required_ratings.value_for_money.independent_public_average,true);
 assert.equal(cfg.required_ratings.value_for_money.exclude_from_overall,true);
 assert.ok(cfg.optional_ratings.includes('followup'));
 assert.ok(cfg.optional_ratings.includes('proximity'));
 assert.match(audit,/note rapport qualité-prix distincte/i);
 assert.match(audit,/exclu du calcul de la moyenne générale/i);
});
test('Notes express sans commentaire, aucun chiffre fabriqué pour un nouvel adhérent',()=>{
 assert.equal(cfg.user_interface.comment_allowed,false);
 assert.equal(cfg.user_interface.comment_field,false);
 assert.equal(cfg.user_interface.no_fake_zero_or_default_stars,true);
 assert.equal(cfg.user_interface.detail_expand_on_click,true);
 assert.match(cfg.user_interface.empty_state,/Pas encore d’évaluation vérifiée/);
 assert.equal(cfg.production.public_ratings_enabled,false);
 assert.equal(cfg.production.public_submissions_enabled,false);
});
test('Preuve indépendante vraie après prestation, pas après clic ni statut propriétaire',()=>{
 const p=cfg.client_proof;
 assert.equal(p.reservation_only_sufficient,false);
 assert.equal(p.owner_done_status_only_sufficient,false);
 assert.equal(p.completed_service_required,true);
 assert.equal(p.independently_verified_client_required,true);
 assert.equal(p.owner_self_rating_denied,true);
 assert.equal(p.one_rating_per_completed_service,true);
 assert.equal(p.one_time_hash_invite,true);
 assert.equal(p.atomic_invite_consumption,true);
 assert.equal(cfg.privacy.no_legal_tax_medical_case_details,true);
 assert.ok(cfg.known_blockers.includes('independent_completion_attestation'));
});
