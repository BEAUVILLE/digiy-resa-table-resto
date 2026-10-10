// DIGIY RÉSA V8 — mobile client controller, gated by server-owned pilot state.
// Production is NOT activated by this file. Gate + V1 RPC are absent on CORE.
// No keys, no global data, no localStorage, no automatic WhatsApp sending.
import {createStagingBookingFlow} from './staging-booking-flow-v4.mjs';
import {BookingContractError} from './booking-client-core.mjs';

const slugRE=/^[a-z0-9_-]{2,150}$/;
const uuidRE=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const digits=x=>String(x||'').replace(/\D/g,'');
const fail=code=>{throw new BookingContractError(code)};
const safeString=(x,max)=>String(x||'').replace(/[\u0000-\u001f\u007f]/g,' ').trim().slice(0,max);

export function bookingWhatsappAfterCommit({bookingId,status,date,time,serviceName,slug,professionalWhatsapp}={}){
 if(!uuidRE.test(String(bookingId||''))||status!=='pending')fail('booking_not_recorded');
 if(!/^\d{4}-\d{2}-\d{2}$/.test(String(date||''))||
    !/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(String(time||''))||
    !slugRE.test(String(slug||'')))fail('invalid_booking_info');
 const wa=digits(professionalWhatsapp);
 if(wa.length<10||wa.length>15)return null;
 const msg=[
  '✅ RDV POSÉ · PAIEMENT SUR PLACE',
  'Bonjour, j’ai posé mon rendez-vous via DIGIY RÉSA.',
  'Référence : '+bookingId,
  'Fiche : '+slug,
  'Prestation : '+safeString(serviceName,120),
  'Date : '+date,
  'Heure : '+time+' (Sénégal)',
  'Statut : rendez-vous enregistré, en attente de votre confirmation.',
  'Merci de consulter votre planning DIGIY.',
  'Paiement sur place directement auprès du professionnel.',
  'Aucun paiement collecté par DIGIYLYFE · 0 % commission · Aucun détail médical.'
 ].join('\n');
 return Object.freeze({url:'https://wa.me/'+wa+'?text='+encodeURIComponent(msg),message:msg});
}
export function createResaPilotV8({rpc,makeRequestId}={}){
 let gate=null,flow=null,current=null;
 const server=(name,args)=>rpc(name,args);
 // The preexisting V4 transaction controller is reused only for idempotence
 // and validation. V8 forwards its internal V0 name to the GATED V1 RPC.
 const transport=(name,args)=>server(
  name==='digiy_resa_universal_request_v0'?
  'digiy_resa_universal_request_v1':name,args);
 return Object.freeze({
  get phase(){return flow?.phase||'off';},
  get options(){return flow?.options||null;},
  get confirmation(){return flow?.confirmation||null;},
  get professional(){return gate?Object.freeze({...gate}):null;},
  async load({slug,startDate}={}){
   if(typeof rpc!=='function')fail('missing_transport');
   if(flow?.hasUncertainRequest||flow?.confirmation)fail('request_resolution_pending');
   if(!slugRE.test(String(slug||'')))fail('invalid_professional');
   let response;
   try{response=await server('digiy_resa_universal_pilot_gate_v1',{p_slug:slug});}
   catch(_){fail('pilot_unavailable');}
   const info=response?.data;
   if(response?.error||info?.ok!==true||
     info?.enabled!==true||info?.slug!==slug||
     info?.time_zone!=='Africa/Dakar')fail('pilot_not_active');
   // Never allow client/query/localStorage toggles to activate a pilot.
   gate={slug,display_name:safeString(info.display_name,120),
     public_whatsapp:digits(info.public_whatsapp||'')};
   const candidate=createStagingBookingFlow({
    enabled:true,rpc:transport,makeRequestId
   });
   const options=await candidate.load({slug,startDate});
   flow=candidate;current=null;
   return options;
  },
  choose({slotId,serviceId}={}){
   if(!flow)fail('pilot_not_active');
   const chosen=flow.choose({slotId,serviceId});
   const options=flow.options;
   const slot=options.slots.find(s=>s.slot_id===chosen.slotId);
   const service=options.services.find(s=>s.service_id===chosen.serviceId);
   current=Object.freeze({date:slot.date,time:slot.time,
    serviceName:service.name,slotId,serviceId});
   return Object.freeze({...current});
  },
  async reserve({name,phone}={}){
   if(!flow||!current||!gate)fail('missing_selection');
   const result=await flow.request({name,phone});
   // Never create a WhatsApp message until the server has returned a
   // validated booking ID and the authoritative status pending.
   const wa=bookingWhatsappAfterCommit({
    bookingId:result.bookingId,status:result.status,
    ...current,slug:gate.slug,professionalWhatsapp:gate.public_whatsapp
   });
   return Object.freeze({...result,whatsapp:wa,
     receiptLabel:'RDV posé · Paiement sur place',
     confirmationDetail:'Créneau réservé, confirmation du professionnel en attente.',
     paymentStatus:'not_collected',paymentLocation:'professional_on_site',
     date:current.date,time:current.time,serviceName:current.serviceName});
  }
 });
}
