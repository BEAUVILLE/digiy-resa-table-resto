import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const doc=fs.readFileSync('docs/RESA_UNIVERSEL_V4_STAGING_LEGACY_AUDIT_20261010.md','utf8');
const contract=JSON.parse(fs.readFileSync('contracts/resa-universal-pre-sql-gates.json','utf8'));
const legacy=fs.readFileSync('archive/ancienne-mecanique-pro-resa-2026-08-25/reserver.html','utf8');
const published=fs.readFileSync('planning.html','utf8');
const client=fs.readFileSync('resa-universal/staging-booking-flow-v4.mjs','utf8');
test('document actual archived legacy consumer, without claiming a global audit',()=>{
 assert.match(legacy,/digiy_resa_create_booking/);
 assert.match(legacy,/digiy_resa_get_available_slots/);
 assert.match(doc,/digiy_resa_create_booking/);
 assert.match(doc,/gestion\.html/);
 assert.match(doc,/UPDATE direct/);
 assert.match(doc,/non exhaustif/);
 assert.match(doc,/G05.*BLOQUÉ/);
});
test('no production authorization granted by V4',()=>{
 assert.equal(contract.production_sql_authorized,false);
 assert.equal(contract.automatic_booking_production_ready,false);
 assert.equal(contract.gates.find(g=>g.id==='G05').status,'BLOCKED');
 assert.match(published,/digiy_resa_public_week_v1/);
 assert.doesNotMatch(published,/digiy_resa_universal_request_v0/);
 assert.doesNotMatch(published,/staging-booking-flow-v4/);
 assert.doesNotMatch(client,/https:\/\/wesqmwjjtsefyjnluosj/);
 assert.doesNotMatch(client,/sb_publishable_|service_role|supabase\.createClient/);
});
