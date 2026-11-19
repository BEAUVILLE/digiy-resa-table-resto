/* DIGIY BEAUTY: prepare a manual WhatsApp reply after an owner's decision.
 * Pure helper: no fetch, no write, no automatic message, no client lookup.
 */
(function(root){
  'use strict';
  function buildDecisionLink({phone,status,service,day,time}={}){
    if(status!=='confirmed' && status!=='cancelled')return null;
    const digits=String(phone??'').replace(/\D/g,'');
    if(!/^\d{7,20}$/.test(digits))return null;
    const serviceName=String(service??'').replace(/[\r\n\t]+/g,' ').trim().slice(0,120);
    const rawDay=String(day??'').slice(0,10);
    const dayText=/^\d{4}-\d{2}-\d{2}$/.test(rawDay)?rawDay:'';
    const rawTime=String(time??'').slice(0,5);
    const timeText=/^\d{2}:\d{2}$/.test(rawTime)?rawTime:'';
    const detail=[serviceName,dayText,timeText].filter(Boolean).join(' · ');
    const intro='Bonjour, concernant votre demande de rendez-vous'+(detail?' ('+detail+')':'')+' : ';
    const result=status==='confirmed'
      ?'le professionnel a confirmé votre rendez-vous.'
      :'le professionnel ne peut pas accepter le créneau demandé.';
    const next=status==='confirmed'
      ?'Merci de vérifier directement avec lui les modalités. Paiement direct, 0 % de commission DIGIYLYFE.'
      :'Vous pouvez lui demander directement un autre créneau. Aucun paiement n’est encaissé par DIGIYLYFE.';
    return 'https://wa.me/'+digits+'?text='+encodeURIComponent(intro+result+' '+next);
  }
  const api=Object.freeze({buildDecisionLink});
  root.DIGIYBeautyContact=api;
  if(typeof module==='object' && module.exports)module.exports=api;
})(typeof window==='object'?window:globalThis);
