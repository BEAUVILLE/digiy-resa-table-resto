import test from 'node:test';
import assert from 'node:assert/strict';
import {createStagingBookingFlow} from '../resa-universal/staging-booking-flow-v4.mjs';
const slotId='a0000000-0000-4000-8000-000000000901';
const serviceId='aaaa0000-0000-4000-8000-000000000001';
const requestId='ca000000-0000-4000-8000-000000000091';
const bookingId='ca000000-0000-4000-8000-000000000092';
const calendar={ok:true,slug:'pro-a',time_zone:'Africa/Dakar',
 services:[{service_id:serviceId,name:'Entretien',duration_minutes:45,price_fcfa:12000}],
 slots:[{slot_id:slotId,date:'2026-10-20',time:'09:00',available:true,service_ids:[serviceId]}]};
const args={slug:'pro-a',startDate:'2026-10-19'};
const contact={name:'Client de test',phone:'+221 77 000 00 01'};
test('disabled by default: no external RPC can be reached',async()=>{
 let calls=0;
 const flow=createStagingBookingFlow({rpc:async()=>{calls++;return{data:calendar}},makeRequestId:()=>requestId});
 assert.equal(flow.phase,'disabled');
 await assert.rejects(flow.load(args),{code:'not_activated'});
 await assert.rejects(flow.request(contact),{code:'not_activated'});
 assert.equal(calls,0);
});
test('only the V2 public catalogue is queried; service and slot come from server',async()=>{
 const calls=[];
 const flow=createStagingBookingFlow({
  enabled:true,makeRequestId:()=>requestId,
  rpc:async(name,params)=>{calls.push({name,params});return{data:calendar}}
 });
 const options=await flow.load(args);
 assert.equal(flow.phase,'ready');
 assert.equal(options.time_zone,'Africa/Dakar');
 assert.deepEqual(calls,[{name:'digiy_resa_universal_public_options_v1',
  params:{p_slug:'pro-a',p_start_date:'2026-10-19'}}]);
 assert.throws(()=>flow.choose({slotId,serviceId:'bbbb0000-0000-4000-8000-000000000001'}),{code:'unavailable'});
 assert.deepEqual(flow.choose({slotId,serviceId}),{slotId,serviceId});
 assert.equal(flow.phase,'selected');
});
test('invalid contact does not freeze an operation id; valid retry after network loss is idempotent',async()=>{
 let counter=0;const requests=[];let attempt=0;
 const flow=createStagingBookingFlow({enabled:true,
  makeRequestId:()=>{counter++;return requestId;},
  rpc:async(name,params)=>{
   if(name==='digiy_resa_universal_public_options_v1')return{data:calendar};
   requests.push(params);attempt++;
   if(attempt===1)throw Error('temporary disconnection');
   return{data:{ok:true,status:'pending',booking_id:bookingId,already:true}};
  }
 });
 await flow.load(args);flow.choose({slotId,serviceId});
 await assert.rejects(flow.request({name:'A',phone:'1'}),{code:'invalid_contact'});
 assert.equal(counter,1,'an invalid first submission must not lock the UUID');
 await assert.rejects(flow.request(contact),{code:'transport_failed'});
 assert.equal(flow.phase,'uncertain');
 assert.equal(flow.hasUncertainRequest,true);
 await assert.rejects(flow.load(args),{code:'request_resolution_pending'});
 assert.throws(()=>flow.choose({slotId,serviceId}),{code:'request_resolution_pending'});
 await assert.rejects(flow.request({...contact,phone:'221779999999'}),{code:'retry_data_changed'});
 const success=await flow.request(contact);
 assert.equal(success.status,'pending');assert.equal(success.confirmed,false);
 assert.equal(success.already,true);
 assert.equal(flow.phase,'pending');
 assert.equal(flow.confirmation?.bookingId,bookingId);
 assert.equal(counter,2,'invalid submission one ID; correct submission one ID; retry none');
 assert.deepEqual(requests.map(r=>r.p_request_id),[requestId,requestId]);
 assert.ok(requests.every(r=>Object.keys(r).length===6));
 await assert.rejects(flow.request(contact),{code:'already_recorded'});
});
test('catalogue missing or wrong timezone is not accepted as bookable',async()=>{
 for(const data of [
  {...calendar,time_zone:'Europe/Paris'}, {...calendar,slug:'another'},
  {...calendar,services:null}, {ok:false,error:'not_published'}
 ]){
  const flow=createStagingBookingFlow({enabled:true,makeRequestId:()=>requestId,
   rpc:async()=>({data})});
  await assert.rejects(flow.load(args));
  assert.equal(flow.phase,'idle');
 }
});
test('parallel click is blocked until server finishes one pending submission',async()=>{
 let resolveSubmit;let requestCalls=0;
 const flow=createStagingBookingFlow({enabled:true,makeRequestId:()=>requestId,
  rpc:async(name)=>{
   if(name==='digiy_resa_universal_public_options_v1')return{data:calendar};
   requestCalls++;
   return await new Promise(resolve=>{resolveSubmit=resolve;});
  }});
 await flow.load(args);flow.choose({slotId,serviceId});
 const first=flow.request(contact);
 await assert.rejects(flow.request(contact),{code:'request_in_progress'});
 assert.equal(requestCalls,1);
 resolveSubmit({data:{ok:true,status:'pending',booking_id:bookingId}});
 const accepted=await first;
 assert.equal(accepted.confirmed,false);assert.equal(flow.phase,'pending');
});
test('server cannot claim confirmed or paid and still make UI announce success',async()=>{
 const flow=createStagingBookingFlow({enabled:true,makeRequestId:()=>requestId,
  rpc:async(name)=>name==='digiy_resa_universal_public_options_v1'?
   {data:calendar}:{data:{ok:true,status:'confirmed',booking_id:bookingId}}
 });
 await flow.load(args);flow.choose({slotId,serviceId});
 await assert.rejects(flow.request(contact),{code:'untrusted_server_status'});
 assert.equal(flow.phase,'uncertain');assert.equal(flow.confirmation,null);
});
