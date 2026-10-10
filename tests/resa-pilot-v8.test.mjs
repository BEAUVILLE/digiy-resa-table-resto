import test from 'node:test';
import assert from 'node:assert/strict';
import {createResaPilotV8,bookingWhatsappAfterCommit} from '../resa-universal/pilot-booking-v8.mjs';
const slotId='a0000000-0000-4000-8000-000000000901';
const serviceId='aaaa0000-0000-4000-8000-000000000001';
const requestId='ca000000-0000-4000-8000-000000000091';
const bookingId='ca000000-0000-4000-8000-000000000092';
const slug='cabinet-saly';
const base={ok:true,slug,time_zone:'Africa/Dakar',
 services:[{service_id:serviceId,name:'Consultation',duration_minutes:45,price_fcfa:12000}],
 slots:[{slot_id:slotId,date:'2026-10-20',time:'10:00',available:true,service_ids:[serviceId]}]};
const gate={ok:true,enabled:true,slug,time_zone:'Africa/Dakar',display_name:'Cabinet de Saly',
 public_whatsapp:'221771234567'};
const setup=(overrides={})=>{
 const calls=[];
 const rpc=async(name,params)=>{
  calls.push({name,params});
  if(name==='digiy_resa_universal_pilot_gate_v1')return {data:overrides.gate??gate};
  if(name==='digiy_resa_universal_public_options_v1')return {data:overrides.catalogue??base};
  if(name==='digiy_resa_universal_request_v1'){
   if(overrides.reject) return {data:{ok:false,error:'slot_unavailable'}};
   if(overrides.network)throw Error('offline');
   return {data:overrides.booking??{ok:true,status:'pending',booking_id:bookingId,already:false}};
  }
  throw Error('unexpected_rpc_'+name);
 };
 return {client:createResaPilotV8({rpc,makeRequestId:()=>requestId}),calls};
};
const args={slug,startDate:'2026-10-19'};
test('no client books without live server gate; URL toggles cannot bypass',async()=>{
 for(const status of [
  {ok:true,enabled:false},
  {ok:true,enabled:true,slug:'other',time_zone:'Africa/Dakar'},
  {ok:true,enabled:true,slug,time_zone:'Europe/Paris'},
  {ok:false,enabled:true}
 ]){
  const {client,calls}=setup({gate:status});
  await assert.rejects(client.load(args),{code:'pilot_not_active'});
  assert.deepEqual(calls.map(x=>x.name),['digiy_resa_universal_pilot_gate_v1']);
  await assert.rejects(client.reserve({name:'Awa',phone:'221771234567'}),{code:'missing_selection'});
 }
});
test('server-gated V1 commit precedes client WhatsApp copy',async()=>{
 const {client,calls}=setup();
 const options=await client.load(args);
 assert.equal(options.slug,slug);
 assert.deepEqual(client.choose({slotId,serviceId}).serviceName,'Consultation');
 const result=await client.reserve({name:'Awa',phone:'+221 77 000 00 02'});
 assert.equal(result.status,'pending');
 assert.equal(result.confirmed,false);
 assert.equal(result.bookingId,bookingId);
 assert.equal(result.receiptLabel,'RDV posé · Paiement sur place');
 assert.equal(result.paymentStatus,'not_collected');
 assert.equal(result.paymentLocation,'professional_on_site');
 assert.match(result.confirmationDetail,/confirmation du professionnel en attente/);
 assert.equal(result.whatsapp?.url.startsWith('https://wa.me/221771234567?text='),true);
 const decoded=new URL(result.whatsapp.url).searchParams.get('text');
 for(const part of [bookingId,'2026-10-20','10:00','Consultation','en attente de votre confirmation','Aucun détail médical','RDV POSÉ · PAIEMENT SUR PLACE','Aucun paiement collecté par DIGIYLYFE'])assert.ok(decoded.includes(part),part);
 assert.deepEqual(calls.map(x=>x.name),
  ['digiy_resa_universal_pilot_gate_v1','digiy_resa_universal_public_options_v1','digiy_resa_universal_request_v1']);
 assert.deepEqual(calls[2].params.p_request_id,requestId);
 assert.equal(calls[2].params.p_client_phone,'221770000002');
});
test('failed or forged server replies yield no WhatsApp or false confirmation',async()=>{
 for(const setupOptions of [
  {reject:true},
  {booking:{ok:true,status:'confirmed',booking_id:bookingId}},
  {booking:{ok:true,status:'pending',booking_id:'invalid-uuid'}}
 ]){
  const {client}=setup(setupOptions);
  await client.load(args);
  client.choose({slotId,serviceId});
  await assert.rejects(client.reserve({name:'Awa',phone:'221771234567'}));
  assert.equal(client.confirmation,null);
 }
});
test('network failure is uncertain, not safe to switch slot or fabricate receipt',async()=>{
 const {client,calls}=setup({network:true});
 await client.load(args);
 client.choose({slotId,serviceId});
 await assert.rejects(client.reserve({name:'Awa',phone:'221771234567'}),{code:'transport_failed'});
 assert.equal(client.phase,'uncertain');
 assert.equal(client.confirmation,null);
 assert.throws(()=>client.choose({slotId,serviceId}),{code:'request_resolution_pending'});
 await assert.rejects(client.load(args),{code:'request_resolution_pending'});
 assert.equal(calls.filter(x=>x.name==='digiy_resa_universal_request_v1').length,1);
});
test('owner WhatsApp message never appears before an accepted pending booking',()=>{
 for(const bad of [
  {bookingId,status:'confirmed',date:'2026-10-20',time:'10:00',slug},
  {bookingId:'bad',status:'pending',date:'2026-10-20',time:'10:00',slug},
  {bookingId,status:'pending',date:'2026-10-32',time:'10:00',slug},
 ]){
  assert.throws(()=>bookingWhatsappAfterCommit({...bad,professionalWhatsapp:'221771234567'}));
 }
 const result=bookingWhatsappAfterCommit({bookingId,status:'pending',date:'2026-10-20',time:'10:00',slug,serviceName:'Consultation',professionalWhatsapp:''});
 assert.equal(result,null);
});
test('Le reçu et WhatsApp ne prétendent jamais à un paiement encaissé',async()=>{
 const {client}=setup();
 await client.load(args);client.choose({slotId,serviceId});
 const result=await client.reserve({name:'Awa',phone:'221770000001'});
 const text=result.receiptLabel+'\\n'+result.confirmationDetail+'\\n'+result.whatsapp.message;
 assert.match(text,/RDV posé · Paiement sur place/i);
 assert.match(text,/confirmation.*en attente/i);
 assert.doesNotMatch(text,/paiement (reçu|encaissé|effectué)|payé|réglé en ligne/i);
 assert.equal(result.status,'pending');
 assert.equal(result.confirmed,false);
});
