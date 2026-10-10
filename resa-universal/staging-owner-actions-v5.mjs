// RÉSA UNIVERSAL V5 owner RPC adapter — staging only.
// No Supabase client or credentials. Disabled by default. Server must verify
// auth.uid(), tenant ownership and permitted state transitions.
const uuidRE=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const actions=new Set(['confirmed','cancelled','done','no_show','note']);
const statuses=new Set(['pending','confirmed','cancelled','done','no_show']);
export class OwnerActionError extends Error {
 constructor(code){super(code);this.code=code;this.name='OwnerActionError';}
}
export function createStagingOwnerActions({enabled=false,rpc}={}){
 const pending=new Set();
 return Object.freeze({
  async execute({bookingId,action,note=null}={}){
   if(enabled!==true)throw new OwnerActionError('not_activated');
   if(typeof rpc!=='function')throw new OwnerActionError('missing_transport');
   if(typeof bookingId!=='string'||!uuidRE.test(bookingId)||
      typeof action!=='string'||!actions.has(action))
    throw new OwnerActionError('invalid_request');
   if(action!=='note'&&note!==null)throw new OwnerActionError('unexpected_note');
   if(action==='note'&&note!==null&&
       (typeof note!=='string'||note.length>1000))
    throw new OwnerActionError('invalid_note');
   if(pending.has(bookingId))throw new OwnerActionError('request_in_progress');
   pending.add(bookingId);
   try{
    let response;
    try{
     response=await rpc('digiy_resa_universal_owner_manage_v2',{
      p_booking_id:bookingId,p_action:action,p_note_text:action==='note'?note:null
     });
    }catch(_){throw new OwnerActionError('transport_failed');}
    const result=response?.data;
    if(response?.error||result?.ok!==true){
     throw new OwnerActionError(result?.error||'owner_action_not_saved');
    }
    if(result.booking_id!==bookingId||result.action!==action||
       !statuses.has(result.status)||
       (action!=='note'&&result.status!==action))
     throw new OwnerActionError('unexpected_server_response');
    // No client notes, phone, names or financial data ever returned.
    return Object.freeze({
      ok:true,bookingId,status:result.status,action,
      confirmed:result.status==='confirmed',paid:false,
      message:action==='note'?'Note privée enregistrée.':
       action==='confirmed'?'Rendez-vous confirmé par le professionnel.':
       action==='cancelled'?'Rendez-vous annulé.':
       action==='done'?'Prestation marquée terminée (non vérifiée pour TRUST).':
       'Client marqué absent.'
    });
   }finally{pending.delete(bookingId);}
  }
 });
}
