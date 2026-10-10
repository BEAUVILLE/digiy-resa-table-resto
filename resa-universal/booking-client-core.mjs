// DIGIY RÉSA UNIVERSAL V3 — pure client booking contract.
// No Supabase keys, no network side effects, no automatic publication.
// Only an explicitly authorised staging controller may call submitRequest().
const uuidRE=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const idOK=x=>typeof x==='string'&&uuidRE.test(x);
const digits=x=>String(x||'').replace(/\D/g,'');
export class BookingContractError extends Error {
 constructor(code){super(code);this.name='BookingContractError';this.code=code;}
}
export function buildRequestPayload({catalog,slotId,serviceId,name,phone,requestId}={}){
 if(!catalog||catalog.ok!==true||catalog.time_zone!=='Africa/Dakar')
  throw new BookingContractError('catalogue_not_ready');
 if(!idOK(slotId)||!idOK(serviceId)||!idOK(requestId))
  throw new BookingContractError('invalid_identifier');
 if(!/^[a-z0-9_-]{2,150}$/.test(catalog.slug||''))
  throw new BookingContractError('invalid_professional');
 const slot=(Array.isArray(catalog.slots)?catalog.slots:[]).find(s=>s.slot_id===slotId);
 const service=(Array.isArray(catalog.services)?catalog.services:[]).find(s=>s.service_id===serviceId);
 if(!slot||slot.available!==true||!service||!Array.isArray(slot.service_ids)||!slot.service_ids.includes(serviceId))
  throw new BookingContractError('unavailable');
 if(!Number.isInteger(service.duration_minutes)||service.duration_minutes<5||service.duration_minutes>480)
  throw new BookingContractError('invalid_service');
 const customerName=typeof name==='string'?name.trim():'';
 const customerPhone=digits(phone);
 if(customerName.length<2||customerName.length>120||customerPhone.length<7||customerPhone.length>18)
  throw new BookingContractError('invalid_contact');
 return {
  p_slug:catalog.slug,
  p_slot_id:slotId,
  p_service_id:serviceId,
  p_client_name:customerName,
  p_client_phone:customerPhone,
  p_request_id:requestId
 };
}
export async function submitRequest({enabled=false,rpc,...data}={}){
 // No live call can happen without an explicit, reviewed staging opt-in.
 if(enabled!==true)throw new BookingContractError('not_activated');
 if(typeof rpc!=='function')throw new BookingContractError('missing_transport');
 const payload=buildRequestPayload(data);
 let response;
 try{response=await rpc('digiy_resa_universal_request_v0',payload);}
 catch(_){throw new BookingContractError('transport_failed');}
 const result=response?.data;
 if(response?.error||!result||result.ok!==true)
  throw new BookingContractError(result?.error||'request_not_recorded');
 // V0 can only record pending. Never call it a confirmed appointment.
 if(result.status!=='pending'||!idOK(result.booking_id))
  throw new BookingContractError('untrusted_server_status');
 return Object.freeze({
  ok:true,confirmed:false,bookingId:result.booking_id,
  status:'pending',already:result.already===true,
  message:'RDV posé · Paiement sur place. Créneau réservé, confirmation du professionnel en attente.'
 });
}
