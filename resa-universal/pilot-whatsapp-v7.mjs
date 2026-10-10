// RÉSA V7: real WhatsApp enquiry, NOT an automatic booking.
// DIGIY contact number is already published on the public DIGIYLYFE site.
// No storage, analytics, payment, Supabase writes or secrets.
export const DIGIY_ORIENTATION_WHATSAPP='221771342889';
const slugPattern=/^[a-z0-9_-]{2,150}$/;
const datePattern=/^\d{4}-\d{2}-\d{2}$/;
const timePattern=/^(?:[01]\d|2[0-3]):[0-5]\d$/;
const clean=(value,max)=>String(value??'').replace(/[\u0000-\u001f\u007f]+/g,' ').replace(/\s+/g,' ').trim().slice(0,max);
export const validSlug=x=>slugPattern.test(String(x||''));
export class EnquiryError extends Error{
 constructor(code){super(code);this.name='EnquiryError';this.code=code;}
}
export function normalizeEnquiry(input,{today}={}){
 const activity=clean(input?.activity,70),service=clean(input?.service,120);
 const locality=clean(input?.locality,90),date=String(input?.date||'');
 const time=String(input?.time||''),firstName=clean(input?.firstName,70);
 const slug=validSlug(input?.slug)?String(input.slug):'';
 if(!activity||!service||!locality)throw new EnquiryError('missing_details');
 if(!datePattern.test(date)||!timePattern.test(time)||!datePattern.test(String(today||'')))throw new EnquiryError('invalid_date');
 const d=new Date(date+'T12:00:00Z');
 if(!Number.isFinite(d.getTime())||d.toISOString().slice(0,10)!==date||date<today)throw new EnquiryError('past_or_invalid_date');
 // Operator will confirm availability; never infer a reserved slot.
 return Object.freeze({activity,service,locality,date,time,firstName,slug});
}
export function buildWhatsAppEnquiry(input,options){
 const x=normalizeEnquiry(input,options);
 const lines=[
  'Bonjour DIGIYLYFE, je souhaite demander un rendez-vous.',
  'Métier / activité : '+x.activity,
  'Prestation souhaitée : '+x.service,
  'Zone : '+x.locality,
  'Date souhaitée : '+x.date,
  'Heure souhaitée : '+x.time+' (heure du Sénégal)',
  ...(x.firstName?['Prénom : '+x.firstName]:[]),
  ...(x.slug?['Référence de fiche : '+x.slug]:[]),
  'Merci de m’orienter vers le professionnel concerné. Je sais que ce créneau n’est pas confirmé.',
  'Paiement et confirmation directement auprès du professionnel. 0 % commission DIGIYLYFE.'
 ];
 return Object.freeze({message:lines.join('\n'),url:'https://wa.me/'+DIGIY_ORIENTATION_WHATSAPP+'?text='+encodeURIComponent(lines.join('\n'))});
}
