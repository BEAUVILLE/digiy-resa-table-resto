'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const plan=read('planning.html');
const home=read('index.html');
const beauty=read('resa-beauty/gestion.html');
const publicSQL=read('sql/20261009_resa_public_week_v1.sql');
const ownerSQL=read('sql/20261009_beauty_owner_open_week_v1.sql');
const inline=html=>[...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)]
  .map(m=>m[1]).filter(s=>s.trim());
test('scripts des pages valides sans injecter de données',()=>{
 for(const [name,html] of [['planning',plan],['home',home],['beauty owner',beauty]]){
  for(const script of inline(html))assert.doesNotThrow(()=>new vm.Script(script,{filename:name+'.js'}),name);
 }
});
test('portail propose un planning sans publier une démo comme réelle',()=>{
 assert.match(home,/id="planningLink" href="\.\/planning.html"/);
 for(const lang of ['fr','en','es','pt','it','de','nl','ar'])assert.ok(home.includes(lang+':'),lang);
 assert.match(home,/PLANNING_LANG\[l\]/);
 assert.match(plan,/digiy_resa_public_week_v1/);
 assert.match(plan,/Array\.isArray\(data\.slots\)/);
 assert.match(plan,/i<7;i\+\+/);
 assert.match(plan,/data\.public_whatsapp/);
 assert.match(plan,/https:\/\/wa\.me\//);
 assert.match(plan,/Confirmer|confirmer|confirmation/);
 assert.doesNotMatch(plan,/digiy_resa_create_booking|resa_create_booking_by_slug|digiy_resa_get_bookings_by_day/);
});
test('aucune fausse disponibilité et aucune donnée client depuis le RPC public',()=>{
 assert.match(publicSQL,/p\.is_published IS TRUE/);
 assert.match(publicSQL,/p\.is_active IS TRUE/);
 assert.match(publicSQL,/digiy_resa_slots/);
 assert.match(publicSQL,/s\.status='open'/);
 assert.match(publicSQL,/coalesce\(b\.status,'pending'\) IN \('pending','confirmed'\)/);
 assert.match(publicSQL,/make_interval\(mins/);
 assert.match(publicSQL,/grant execute/i);
 assert.doesNotMatch(publicSQL,/b\.customer_name|b\.customer_phone|b\.note_text|service_role.*grant execute/i);
});
test('ouverture propriétaire BEAUTY sécurisée, par jours choisis, idempotente',()=>{
 assert.match(beauty,/digiy_beauty_owner_open_week_v1/);
 assert.match(beauty,/p_weekdays:weekdays/);
 assert.match(beauty,/p_times:hours/);
 assert.match(ownerSQL,/b\.owner_id=auth\.uid\(\)/);
 assert.match(ownerSQL,/ON CONFLICT\(beauty_id,slot_day,slot_time\) DO NOTHING/);
 assert.match(ownerSQL,/extract\(isodow FROM d\)=ANY\(p_weekdays\)/);
 assert.match(ownerSQL,/REVOKE ALL.*FROM PUBLIC,anon/);
 assert.doesNotMatch(ownerSQL,/update public\.digiy_beauty_master_slots|delete from public\.digiy_beauty_master_slots/i);
});
