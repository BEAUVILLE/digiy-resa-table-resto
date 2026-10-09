'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'..','resa-beauty','index.html'),'utf8');
const scripts=[...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)].map(m=>m[1]).filter(s=>s.includes('digiy_beauty_public_book_v1'));
assert.equal(scripts.length,1,'Expect exactly one application script');
const clientScript=scripts[0];
const flush=()=>new Promise(resolve=>setImmediate(resolve));
class FixedDate extends Date{
 constructor(...args){super(...(args.length?args:['2026-10-09T08:00:00Z']))}
 static now(){return new Date('2026-10-09T08:00:00Z').valueOf()}
}
function element(id){
 const e={id,value:'',textContent:'',href:'',_html:'',_children:[],onclick:null};
 e.classList={add(){},remove(){},toggle(){}};
 Object.defineProperty(e,'innerHTML',{get(){return e._html},set(v){
   e._html=String(v);
   e._children=[...e._html.matchAll(/<button\b[^>]*>/g)]
     .map(([tag])=>{
        const child=element('child');
        child.dataset={};
        for(const m of tag.matchAll(/data-([\w-]+)="([^"]+)"/g))
           child.dataset[m[1].replace(/-([a-z])/g,(_,ch)=>ch.toUpperCase())]=m[2];
        return child;
     });
 }});
 e.querySelectorAll=selector=>{
   if(selector.includes('[data-week-slot]'))return e._children.filter(x=>'weekSlot' in x.dataset);
   if(selector.includes('[data-slot]'))return e._children.filter(x=>'slot' in x.dataset);
   if(selector.includes('[data-day]'))return e._children.filter(x=>'day' in x.dataset);
   if(selector.includes('.slot'))return e._children.filter(x=>'slot' in x.dataset);
   if(selector.includes('.daybtn'))return e._children.filter(x=>'day' in x.dataset);
   return e._children;
 };
 return e;
}
function launch({wrongPrice=false,noAvailable=false}={}){
 const names=['name','status','place','note','services','service','wa','waMissing',
   'week','day','slots','book','bookMsg','clientName','clientWa'];
 const el=Object.fromEntries(names.map(id=>[id,element(id)]));
 const calls=[];
 let slotStatus='available';
 const rpc=async(name,args)=>{
   calls.push({name,args});
   if(name==='digiy_beauty_public_profile_v1')
     return {data:[{slug:'test-resa-beauty-saly',display_name:'TEST BEAUTY',
       availability_status:'available',services:[{name:'Coiffure',duration_min:45,price:5000}]}],error:null};
   if(name==='digiy_beauty_public_slots_v2')
     return {data:noAvailable?[]:[{id:'30303030-3030-4030-8030-303030303030',slot_time:'11:00:00',status:slotStatus}],error:null};
   if(name==='digiy_beauty_public_book_v1'){
     if(wrongPrice)return {data:null,error:{message:'service offer changed; reload'}};
     slotStatus='booked';
     return {data:[{booking_id:'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',status:'request'}],error:null};
   }
   throw Error('Unexpected RPC '+name);
 };
 vm.runInNewContext(clientScript,{
   supabase:{createClient:()=>({rpc})},
   document:{getElementById:id=>el[id]??(el[id]=element(id))},
   location:{search:'?slug=test-resa-beauty-saly'},
   URLSearchParams,Date:FixedDate,Intl,Number,String,Promise,Array,Error
 },{timeout:2000});
 return {el,calls};
}
test('le client reçoit un véritable ID V2, puis le transmet pour une demande authentique',async()=>{
 const {el,calls}=launch();
 await flush();await flush();
 assert.ok(calls.some(x=>x.name==='digiy_beauty_public_slots_v2'));
 assert.ok(!calls.some(x=>x.name==='digiy_beauty_public_slots_v1'));
 const slots=el.slots.querySelectorAll('[data-slot]');
 assert.equal(slots.length,1,'one available slot must be rendered');
 assert.equal(slots[0].dataset.slot,'30303030-3030-4030-8030-303030303030');
 slots[0].onclick();
 el.clientName.value='Client test';
 el.clientWa.value='221771234567';
 el.service.value='0';
 await el.book.onclick();
 const booking=calls.filter(x=>x.name==='digiy_beauty_public_book_v1');
 assert.equal(booking.length,1);
 assert.equal(booking[0].args.p_slot_id,slots[0].dataset.slot);
 assert.equal(booking[0].args.p_service_name,'Coiffure');
 assert.equal(booking[0].args.p_service_price,5000);
 assert.equal(booking[0].args.p_service_duration_min,45);
 assert.match(el.bookMsg.textContent,/Demande TEST enregistrée\. Aucun vrai rendez-vous confirmé\./);
 assert.equal(el.slots.querySelectorAll('[data-slot]').length,0,'taken slot is hidden after booking');
});
test('le client ne publie pas un faux prix : refus serveur traduit en message',async()=>{
 const {el,calls}=launch({wrongPrice:true});
 await flush();await flush();
 el.slots.querySelectorAll('[data-slot]')[0].onclick();
 el.clientName.value='Client test';
 el.clientWa.value='221771234567';
 el.service.value='0';
 await el.book.onclick();
 assert.match(el.bookMsg.textContent,/tarif ou la durée vient de changer/);
 assert.equal(calls.filter(x=>x.name==='digiy_beauty_public_book_v1').length,1);
});
test('aucune demande sans nom ni WhatsApp ni créneau sélectionné',async()=>{
 const {el,calls}=launch();
 await flush();await flush();
 await el.book.onclick();
 assert.equal(calls.filter(x=>x.name==='digiy_beauty_public_book_v1').length,0);
 assert.match(el.bookMsg.textContent,/créneau/);
});

test('vrai planning visible de sept jours et navigation de la semaine',async()=>{
 const {el,calls}=launch();
 await flush();await flush();await flush();await flush();
 assert.match(el.weekBoard.innerHTML,/weekcol/);
 assert.equal((el.weekBoard.innerHTML.match(/class="weekcol"/g)||[]).length,7);
 assert.ok(calls.filter(x=>x.name==='digiy_beauty_public_slots_v2').length>=7);
 assert.match(el.calendarStatus.textContent,/créneau\(x\) réellement ouvert/);
 assert.ok(el.weekBoard.querySelectorAll('[data-week-slot]').length>0);
 assert.equal(typeof el.nextWeek.onclick,'function');
 el.nextWeek.onclick();
 await flush();await flush();await flush();
 assert.match(el.weekRange.textContent,/→/);
 assert.ok(el.prevWeek.disabled===false);
});
test('aucune disponibilité future n’est inventée : colonnes visibles mais vides',async()=>{
 const {el}=launch({noAvailable:true});
 await flush();await flush();await flush();await flush();
 assert.equal((el.weekBoard.innerHTML.match(/class="weekcol"/g)||[]).length,7);
 assert.equal(el.weekBoard.querySelectorAll('[data-week-slot]').length,0);
 assert.match(el.calendarStatus.textContent,/Aucun créneau futur ouvert/);
 assert.equal(el.slots.querySelectorAll('[data-slot]').length,0);
});

test('clic sur une heure de la grille : sélection répercutée dans le formulaire avec confirmation visible',async()=>{
 const {el,calls}=launch();
 for(let i=0;i<5;i++)await flush();
 const buttons=el.weekBoard.querySelectorAll('[data-week-slot]');
 assert.ok(buttons.length>0,'at least one selectable time');
 await buttons[0].onclick();
 assert.match(el.selectionInfo.textContent,/Horaire sélectionné/);
 assert.equal(el.day.value,buttons[0].dataset.weekDay);
 assert.ok(el.slots.querySelectorAll('[data-slot]').some(x=>x.dataset.slot===buttons[0].dataset.weekSlot));
 el.clientName.value='Client test';
 el.clientWa.value='221771234567';
 el.service.value='0';
 await el.book.onclick();
 assert.equal(calls.filter(x=>x.name==='digiy_beauty_public_book_v1').length,1);
});
test('clic sur le jour et navigation semaine suivante gardent les heures opérationnelles',async()=>{
 const {el,calls}=launch();
 for(let i=0;i<5;i++)await flush();
 assert.equal(el.prevWeek.disabled,true,'no navigation into the past');
 assert.equal(typeof el.nextWeek.onclick,'function');
 const day=el.week.querySelectorAll('[data-day]')[1];
 await day.onclick();
 assert.equal(el.day.value,day.dataset.day);
 assert.match(el.selectionInfo.textContent,/Jour choisi/);
 const previousCalls=calls.filter(x=>x.name==='digiy_beauty_public_slots_v2').length;
 await el.nextWeek.onclick();
 for(let i=0;i<5;i++)await flush();
 assert.equal(el.prevWeek.disabled,false);
 assert.ok(calls.filter(x=>x.name==='digiy_beauty_public_slots_v2').length>previousCalls);
 assert.match(el.selectionInfo.textContent,/Nouvelle semaine affichée/);
});
