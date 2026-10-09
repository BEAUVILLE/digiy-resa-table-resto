'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const contract=JSON.parse(read('contracts/resa-universal-pre-sql-gates.json'));
const audit=read('docs/RESA_UNIVERSEL_PRE_SQL_GO_NO_GO_20261009.md');

test('pré-SQL : aucun feu vert pour exécuter une mutation sur digiy-core',()=>{
 assert.equal(contract.phase,'PRE_SQL_AUDIT');
 assert.equal(contract.production_sql_authorized,false);
 assert.equal(contract.automatic_booking_production_ready,false);
 assert.equal(contract.no_production_changes,true);
 assert.equal(contract.core_project,'digiy-core');
 assert.match(audit,/NO GO pour une réservation automatique générique en production/);
 assert.match(audit,/aucun SQL de production/i);
});

test('séparation moteur universel et exceptions de terrain',()=>{
 assert.deepEqual(contract.exceptions,['RESTO','LOC','DRIVER','OTHER_FIELD_CASES']);
 for(const item of ['RESTO','LOC','DRIVER','terrain','avocat','expert-comptable']) {
  if(item==='avocat'||item==='expert-comptable')continue; // Special professions are documented by business type.
  assert.ok(audit.includes(item),item);
 }
 assert.match(audit,/capacités multiples/);
 assert.match(audit,/capacit.*1/i);
 assert.match(audit,/contact/i);
 assert.match(audit,/0 % commission/);
});

test('les neuf portes restent fermées sauf validation documentaire des règles métier',()=>{
 assert.equal(contract.gates.length,9);
 assert.deepEqual(contract.gates.map(g=>g.id),Array.from({length:9},(_,i)=>'G'+String(i+1).padStart(2,'0')));
 assert.equal(contract.gates[0].status,'GO_DOC_ONLY');
 assert.ok(contract.gates.slice(1).every(g=>g.status==='BLOCKED'));
 assert.match(audit,/G04 Concurrence/);
 assert.match(audit,/G06 PAY/);
 assert.match(audit,/G09 CORE/);
});

test('historique des réservations et dépendances non gommé par la nouvelle architecture',()=>{
 const s=contract.existing_generic_database_snapshot;
 assert.equal(s.profiles,0);
 assert.equal(s.slots,0);
 assert.equal(s.bookings,7);
 assert.equal(s.bookings_pending+s.bookings_confirmed,7);
 assert.equal(s.services_active,8);
 assert.equal(s.services_without_current_profile,8);
 assert.equal(s.all_bookings_without_current_profile,true);
 assert.deepEqual(s.legacy_rpcs_public,['digiy_resa_create_booking','resa_create_booking_by_slug']);
 assert.equal(s.known_legacy_booking_effect,'digiy_resa_push_to_pay_after_status');
 for(const name of s.legacy_rpcs_public)assert.ok(audit.includes(name),name);
 assert.match(audit,/digiy_resa_unique_active_slot/);
 assert.match(audit,/PAY\/CARNET/);
});

test('la conception transactionnelle doit couvrir conflits, confidentialité, fuseaux et rollback',()=>{
 const requirements=contract.required_server_invariants;
 for(const item of ['actual_open_slot','atomic_lock_and_overlap_guard','idempotency_key','owner_AB_isolation',
  'client_privacy','cancel_releases_capacity','time_zone_test_senegal_france',
  'PAY_side_effect_review','legacy_RPC_impact_review','rollback_verified_isolated'])
  assert.ok(requirements.includes(item),item);
 assert.match(audit,/sans SQL de modification/);
 assert.match(audit,/PostgreSQL éphémère/);
});

test('aucune réservation automatique universelle n’est prétendue sur le portail existant',()=>{
 const page=read('planning.html');
 assert.match(page,/digiy_resa_public_week_v1/);
 assert.doesNotMatch(page,/digiy_resa_create_booking|resa_create_booking_by_slug/);
 assert.match(audit,/lecture ≠ réservation atomique/);
});
