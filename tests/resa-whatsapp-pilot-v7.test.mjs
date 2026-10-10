import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {DIGIY_ORIENTATION_WHATSAPP,buildWhatsAppEnquiry,normalizeEnquiry,validSlug,EnquiryError} from '../resa-universal/pilot-whatsapp-v7.mjs';
const today='2026-10-10';
const valid={activity:'Conseil et services professionnels',service:'Rendez-vous initial',
 locality:'Saly, Petite Côte',date:'2026-10-13',time:'10:30',firstName:'Awa',
 slug:'artisane-saly'};
const read=path=>fs.readFileSync(path,'utf8');
const index=read('index.html'),planning=read('planning.html'),form=read('demande-rdv.html');
test('WhatsApp DIGIY number matches already published Senegal contact; never infer a booking',()=>{
 assert.equal(DIGIY_ORIENTATION_WHATSAPP,'221771342889');
 const result=buildWhatsAppEnquiry(valid,{today});
 assert.equal(new URL(result.url).hostname,'wa.me');
 assert.equal(new URL(result.url).pathname,'/221771342889');
 assert.equal(new URL(result.url).searchParams.get('text'),result.message);
 for(const part of ['Saly, Petite Côte','Rendez-vous initial','2026-10-13','10:30',
   'artisane-saly','créneau n’est pas confirmé','0 % commission']){
  assert.ok(result.message.includes(part),part);
 }
 assert.doesNotMatch(result.message,/rendez-vous confirmé|réservation enregistrée|paiement reçu/i);
});
test('invalid or past dates, blank service/sector, malformed time cannot create link',()=>{
 for(const patch of [
  {date:'2026-10-09'},{date:'2026-02-29'},{date:'2026-10-45'},
  {date:'bad'},{time:'25:99'},{time:'09:80'},
  {service:' '},{activity:''},{locality:''}
 ]){
  assert.throws(()=>buildWhatsAppEnquiry({...valid,...patch},{today}),EnquiryError);
 }
});
test('simple message, safe optional slug and bounded free text',()=>{
 const x=normalizeEnquiry({...valid,slug:'javascript:alert(1)',
  service:'z'.repeat(200),firstName:'A\nB',locality:'   Saly   '},{today});
 assert.equal(x.slug,'');
 assert.equal(x.service.length,120);
 assert.equal(x.firstName,'A B');
 assert.equal(x.locality,'Saly');
 assert.equal(validSlug('saly-coiffeuse'),true);
 assert.equal(validSlug('https://other.site'),false);
 assert.equal(validSlug(''),false);
 const m=buildWhatsAppEnquiry({...valid,slug:'<script>alert()</script>'},{today}).message;
 assert.doesNotMatch(m,/Référence de fiche/);
});
test('pilot WhatsApp form works without SQL/RPC, consent requires explicit send',()=>{
 assert.match(form,/id="appointmentForm"/);
 assert.match(form,/type="date"/);
 assert.match(form,/type="time"/);
 assert.match(form,/id="activity"/);
 assert.match(form,/id="locality"/);
 assert.match(form,/id="service"/);
 assert.match(form,/id="firstName"/);
 assert.match(form,/buildWhatsAppEnquiry/);
 assert.match(form,/location\.assign\(result\.url\)/);
 assert.match(form,/event\.preventDefault\(\)/);
 assert.match(form,/Cette demande ne bloque aucun créneau|pas une réservation enregistrée/i);
 assert.doesNotMatch(form,/createClient|\.rpc\(|\.from\(|service_role|sb_publishable_/);
 assert.doesNotMatch(form,/localStorage|sessionStorage|fetch\(/);
 assert.match(form,/textContent=result\.message/);
});
test('public portal has a real pilot CTA and still links to real professional cards',()=>{
 assert.match(index,/id="manualRequest"/);
 assert.match(index,/\.\/demande-rdv\.html/);
 assert.match(index,/id="planningLink"/);
 assert.match(index,/id="realCards"/);
 assert.match(index,/0 % commission/);
});
test('planning sends manual fallback only when client opens WhatsApp; direct pro contact preserved',()=>{
 assert.match(planning,/id="pilotFallback"/);
 assert.match(planning,/\.\/demande-rdv\.html/);
 assert.match(planning,/id="contact"/);
 assert.match(planning,/publicWa/);
 assert.match(planning,/https:\/\/wa\.me\//);
 assert.match(planning,/digiy_resa_public_week_v1/);
 assert.doesNotMatch(planning,/digiy_resa_universal_request_v0/);
 assert.doesNotMatch(planning,/staging-booking-flow-v4/);
});
