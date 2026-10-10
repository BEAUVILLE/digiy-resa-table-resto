// DIGIY RÉSA UNIVERSEL V4 — staging-only orchestration, NO live activation.
// This module has no Supabase client, credentials, DOM, persistent storage,
// or network side effect unless an explicit RPC adapter is injected.
// The flag is not a security boundary: the server must still enforce
// ownership, real slots, rate limits and idempotency.
import {buildRequestPayload,submitRequest,BookingContractError} from './booking-client-core.mjs';

const slugRE=/^[a-z0-9_-]{2,150}$/;
const dateRE=/^\d{4}-\d{2}-\d{2}$/;
const digits=s=>String(s||'').replace(/\D/g,'');
const failure=code=>{throw new BookingContractError(code);};

export function createStagingBookingFlow({enabled=false,rpc,makeRequestId}={}){
 let catalogue=null;
 let selection=null;
 let operationId=null;
 let fingerprint=null;
 let pending=null;
 let phase='idle';
 let inFlight=false;

 function allowed(slotId,serviceId){
  const s=catalogue?.slots?.find(x=>x.slot_id===slotId);
  const p=catalogue?.services?.find(x=>x.service_id===serviceId);
  return !!s&&s.available===true&&!!p&&Array.isArray(s.service_ids)&&s.service_ids.includes(serviceId);
 }

 return Object.freeze({
  get phase(){return enabled?phase:'disabled';},
  get hasUncertainRequest(){return !!operationId&&phase==='uncertain';},
  get confirmation(){return pending;},
  get currentSelection(){return selection?Object.freeze({...selection}):null;},
  get options(){
   if(!catalogue)return null;
   return Object.freeze({slug:catalogue.slug,time_zone:catalogue.time_zone,
    services:catalogue.services.map(s=>Object.freeze({...s})),
    slots:catalogue.slots.map(s=>Object.freeze({...s,service_ids:[...(s.service_ids||[])]}))});
  },
  async load({slug,startDate}={}){
   if(!enabled)failure('not_activated');
   if(typeof rpc!=='function')failure('missing_transport');
   if(inFlight)failure('request_in_progress');
   if(operationId)failure('request_resolution_pending');
   if(!slugRE.test(slug||'')||!dateRE.test(startDate||''))failure('invalid_request');
   let response;
   try{response=await rpc('digiy_resa_universal_public_options_v1',
      {p_slug:slug,p_start_date:startDate});}
   catch(_){failure('transport_failed');}
   if(response?.error||response?.data?.ok!==true)failure(response?.data?.error||'catalogue_unavailable');
   const d=response.data;
   if(d.slug!==slug||d.time_zone!=='Africa/Dakar'
      ||!Array.isArray(d.slots)||!Array.isArray(d.services))
    failure('invalid_catalogue');
   catalogue=d;selection=null;pending=null;phase='ready';
   return this.options;
  },
  choose({slotId,serviceId}={}){
   if(!enabled)failure('not_activated');
   if(inFlight||operationId)failure('request_resolution_pending');
   if(!catalogue)failure('catalogue_not_ready');
   if(!allowed(slotId,serviceId))failure('unavailable');
   selection=Object.freeze({slotId,serviceId});
   phase='selected';
   return selection;
  },
  async request({name,phone}={}){
   if(!enabled)failure('not_activated');
   if(inFlight)failure('request_in_progress');
   if(phase==='pending')failure('already_recorded');
   if(!catalogue||!selection)failure('missing_selection');
   if(typeof makeRequestId!=='function')failure('missing_uuid_generator');
   const nameClean=typeof name==='string'?name.trim():'';
   const contactKey=JSON.stringify([nameClean,digits(phone),selection.slotId,selection.serviceId]);
   if(fingerprint&&fingerprint!==contactKey)failure('retry_data_changed');
   // Invalid form entries must not consume the stable retry key.
   // Allocate one UUID only after validating the payload.
   const id=operationId||makeRequestId();
   const data={catalog:catalogue,slotId:selection.slotId,
    serviceId:selection.serviceId,name:nameClean,phone,requestId:id};
   buildRequestPayload(data);
   if(!operationId){operationId=id;fingerprint=contactKey;}
   inFlight=true;phase='submitting';
   try{
    const res=await submitRequest({...data,enabled:true,rpc});
    pending=res;phase='pending';
    return res;
   }catch(err){
    phase='uncertain';
    throw err;
   }finally{inFlight=false;}
  }
 });
}
