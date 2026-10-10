import test from 'node:test';
import assert from 'node:assert/strict';
import {buildRequestPayload,submitRequest,BookingContractError}
 from '../resa-universal/booking-client-core.mjs';
const slotId='a0000000-0000-4000-8000-000000000901';
const serviceId='aaaa0000-0000-4000-8000-000000000001';
const requestId='ca000000-0000-4000-8000-000000000091';
const bookingId='ca000000-0000-4000-8000-000000000092';
const base={
 catalog:{ok:true,slug:'saly-pro-a',time_zone:'Africa/Dakar',
  services:[{service_id:serviceId,name:'Consultation',duration_minutes:45,price_fcfa:12000}],
  slots:[{slot_id:slotId,date:'2026-10-20',time:'09:00',available:true,service_ids:[serviceId]}]},
 slotId,serviceId,name:'Client test',phone:'+221 77 000 00 01',requestId
};
test('contract uses only server-listed slot and service, no client price/duration',()=>{
 const payload=buildRequestPayload({...base,price_fcfa:1,duration_minutes:1});
 assert.deepEqual(Object.keys(payload).sort(),[
  'p_client_name','p_client_phone','p_request_id','p_service_id','p_slot_id','p_slug'].sort());
 assert.equal(payload.p_client_phone,'221770000001');
 assert.equal(payload.p_request_id,requestId);
});
test('closed or overlapping, cross-tenant or absent service, bad identity blocked',()=>{
 for(const replacement of [
  {catalog:{...base.catalog,slots:[{...base.catalog.slots[0],available:false}]}},
  {catalog:{...base.catalog,slots:[]}},
  {catalog:{...base.catalog,services:[]}},
  {catalog:{...base.catalog,slug:'../another-user'}},
  {catalog:{...base.catalog,time_zone:'Europe/Paris'}},
  {catalog:{...base.catalog,ok:false}},
  {serviceId:'bbbb0000-0000-4000-8000-000000000001'},
  {phone:'123'}, {name:'X'}, {requestId:'not-uuid'}
 ]){
  assert.throws(()=>buildRequestPayload({...base,...replacement}),BookingContractError);
 }
});
test('no request until explicit opt-in: disabled paths never call transport',async()=>{
 let calls=0; const rpc=async()=>{calls++;return {data:{ok:true}};};
 await assert.rejects(submitRequest({...base,rpc}),{code:'not_activated'});
 assert.equal(calls,0);
 await assert.rejects(submitRequest({...base,enabled:true}),{code:'missing_transport'});
 assert.equal(calls,0);
});
test('success says PENDING, never says paid or confirmed',async()=>{
 const calls=[];
 const rpc=async(...args)=>{calls.push(args);return {data:{ok:true,status:'pending',booking_id:bookingId,already:false}};};
 const result=await submitRequest({...base,rpc,enabled:true});
 assert.equal(result.status,'pending');assert.equal(result.confirmed,false);
 assert.match(result.message,/en attente/);
 assert.match(result.message,/RDV posé · Paiement sur place/);
 assert.doesNotMatch(result.message,/paiement reçu|encaissement effectué|payé/i);
 assert.doesNotMatch(result.message,/payé|confirmé/i);
 assert.equal(calls.length,1);
 assert.equal(calls[0][0],'digiy_resa_universal_request_v0');
 assert.equal(calls[0][1].p_request_id,requestId);
});
test('retry uses same client key; no new generated key inside transport',async()=>{
 const seen=[];
 const rpc=async(_,p)=>{seen.push(p.p_request_id);
  return {data:{ok:true,status:'pending',booking_id:bookingId,already:seen.length>1}};};
 await submitRequest({...base,rpc,enabled:true});
 const second=await submitRequest({...base,rpc,enabled:true});
 assert.deepEqual(seen,[requestId,requestId]);assert.equal(second.already,true);
});
test('server errors, network failures and unexpected confirmed cannot appear as success',async()=>{
 for(const rpc of [
  async()=>{throw Error('offline');},
  async()=>({error:{message:'unauthorized'},data:null}),
  async()=>({data:{ok:false,error:'slot_unavailable'}}),
  async()=>({data:{ok:true,status:'confirmed',booking_id:bookingId}}),
  async()=>({data:{ok:true,status:'pending',booking_id:'invalid'}})
 ]){
  await assert.rejects(submitRequest({...base,rpc,enabled:true}),BookingContractError);
 }
});
