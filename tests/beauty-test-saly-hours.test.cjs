'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const owner=fs.readFileSync(path.join(__dirname,'..','resa-beauty','gestion.html'),'utf8');
const publicPage=fs.readFileSync(path.join(__dirname,'..','resa-beauty','index.html'),'utf8');
const sql=fs.readFileSync(path.join(__dirname,'..','sql','20261009_beauty_test_saly_restore_historical_hours.sql'),'utf8');
test('propriétaire : aucun jour ni horaire précoché globalement',()=>{
 assert.doesNotMatch(owner,/data-weekday="[1-7]" checked/);
 const els=[...owner.matchAll(/class="weekTime" type="time" value="([^"]*)"/g)];
 assert.equal(els.length,6);
 assert.ok(els.every(x=>x[1]===''));
 assert.match(owner,/Le professionnel choisit librement/);
});
test('horaires historiques exclusivement en démonstration TEST SALY',()=>{
 assert.match(owner,/if\(slug==='test-resa-beauty-saly'\)/);
 assert.match(owner,/const demo=\['09:00','10:30','12:00','14:00','15:30','17:00'\]/);
 assert.match(sql,/b\.slug='test-resa-beauty-saly'/);
 assert.match(sql,/b\.display_name='TEST RÉSA BEAUTY · SALY'/);
 assert.match(sql,/v_reference_count<>6/);
 assert.match(sql,/ON CONFLICT\(beauty_id,slot_day,slot_time\) DO NOTHING/);
 assert.doesNotMatch(sql,/DELETE FROM|TRUNCATE|UPDATE public\.digiy_beauty_bookings/i);
});
test('client : le planning reste une démonstration explicite',()=>{
 assert.match(publicPage,/HORAIRES DE DÉMONSTRATION/);
 assert.match(publicPage,/Aucune prestation réelle n'est garantie/);
 assert.match(publicPage,/id="weekBoard"/);
 assert.match(publicPage,/digiy_beauty_public_slots_v2/);
 assert.match(publicPage,/Demande TEST enregistrée/);
});
test('scripts des deux pages analysables par Node',()=>{
 for(const [name,html] of [['gestion',owner],['public',publicPage]]){
  const scripts=[...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)]
    .map(x=>x[1]).filter(x=>x.trim().length);
  assert.equal(scripts.length,1);
  assert.doesNotThrow(()=>new vm.Script(scripts[0],{filename:name+'.js'}));
 }
});
