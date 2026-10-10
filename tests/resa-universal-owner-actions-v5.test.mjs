import test from 'node:test';
import assert from 'node:assert/strict';
import {createStagingOwnerActions,OwnerActionError} from '../resa-universal/staging-owner-actions-v5.mjs';
const bookingId='ca000000-0000-4000-8000-000000000092';
test('owner adapter disabled by default, sends nothing to API',async()=>{
 let count=0;
 const api=createStagingOwnerActions({rpc:async()=>{count++;return{data:{ok:true}};}});
 await assert.rejects(api.execute({bookingId,action:'confirmed'}),{code:'not_activated'});
 assert.equal(count,0);
});
test('only allowed status transitions and independent note intent pass client boundary',async()=>{
 const calls=[];
 const api=createStagingOwnerActions({enabled:true,rpc:async(name,p)=>{
  calls.push({name,p});
  return{data:{ok:true,booking_id:p.p_booking_id,action:p.p_action,
   status:p.p_action==='note'?'pending':p.p_action}};
 }});
 const note=await api.execute({bookingId,action:'note',note:'Suivi privé <b>en texte</b>'});
 assert.equal(note.action,'note');assert.equal(note.status,'pending');
 assert.equal(note.paid,false);assert.equal(note.confirmed,false);
 assert.equal(note.message,'Note privée enregistrée.');
 const confirm=await api.execute({bookingId,action:'confirmed'});
 assert.equal(confirm.status,'confirmed');assert.equal(confirm.confirmed,true);
 assert.equal(confirm.paid,false);
 assert.deepEqual(calls.map(x=>x.name),[
  'digiy_resa_universal_owner_manage_v2',
  'digiy_resa_universal_owner_manage_v2'
 ]);
 assert.deepEqual(calls.map(x=>x.p.p_note_text),[
  'Suivi privé <b>en texte</b>',null]);
 assert.equal(calls[0].p.p_booking_id,bookingId);
 assert.equal(Object.keys(note).includes('customer_phone'),false);
});
test('forbid forged booking id, action, excessive note, status+note bundle',async()=>{
 let count=0;
 const api=createStagingOwnerActions({enabled:true,
  rpc:async()=>{count++;return{data:{ok:true}};}});
 for(const args of [
  {bookingId:'fake',action:'confirmed'},
  {bookingId,action:'paid'},
  {bookingId,action:'confirmed',note:'inject'},
  {bookingId,action:'note',note:'x'.repeat(1001)},
  {bookingId,action:'note',note:4},
  {bookingId,action:'pending'}
 ]){
  await assert.rejects(api.execute(args),OwnerActionError);
 }
 assert.equal(count,0);
});
test('transport, authorization and untrusted response do not appear as success',async()=>{
 for(const rpc of [
  async()=>{throw Error('connection');},
  async()=>({data:{ok:false,error:'not_found_or_forbidden'}}),
  async()=>({data:{ok:true,booking_id:bookingId,action:'confirmed',status:'pending'}}),
  async()=>({data:{ok:true,booking_id:'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',action:'confirmed',status:'confirmed'}}),
  async()=>({data:{ok:true,booking_id:bookingId,action:'confirmed',status:'paid'}})
 ]){
  await assert.rejects(createStagingOwnerActions({enabled:true,rpc})
   .execute({bookingId,action:'confirmed'}),OwnerActionError);
 }
});
test('double owner click blocked during one pending response',async()=>{
 let resolve; let calls=0;
 const api=createStagingOwnerActions({enabled:true,rpc:async(n,p)=>{
  calls++;return await new Promise(res=>{resolve=res;});
 }});
 const first=api.execute({bookingId,action:'confirmed'});
 await assert.rejects(api.execute({bookingId,action:'cancelled'}),{code:'request_in_progress'});
 assert.equal(calls,1);
 resolve({data:{ok:true,booking_id:bookingId,action:'confirmed',status:'confirmed'}});
 const done=await first;assert.equal(done.status,'confirmed');
});
test('marking done does not prove completed service for DIGIY TRUST',async()=>{
 const api=createStagingOwnerActions({enabled:true,rpc:async(n,p)=>({
  data:{ok:true,booking_id:p.p_booking_id,action:p.p_action,status:p.p_action}
 })});
 const result=await api.execute({bookingId,action:'done'});
 assert.equal(result.confirmed,false);
 assert.match(result.message,/non vérifiée pour TRUST/);
 assert.equal(result.paid,false);
});
