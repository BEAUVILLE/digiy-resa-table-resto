const test=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const source=fs.readFileSync(path.join(__dirname,'../resa-beauty/world10-pro.js'),'utf8');
function makePage(items,href='./index.html?slug=salon-saly'){
 const host='https://resa-table-resto.digiylyfe.com';
 const link={
   value:href,
   getAttribute(k){return k==='href'?this.value:null},
   setAttribute(k,v){if(k==='href')this.value=v}
 };
 let picker=null;
 const header={
   firstChild:null,
   matches(){return false},
   appendChild(x){picker=x;return x},
   insertBefore(x){picker=x;return x}
 };
 const nodes=items.map(item=>({
   nodeValue:item.text,
   parentElement:{
     id:item.id||'',
     closest(sel){
       if(item.owned && sel.includes('#title, .bookingName'))return {};
       return null;
     }
   }
 }));
 const document={
   readyState:'complete',title:'Gestion BEAUTY — DIGIYLYFE',
   documentElement:{lang:'fr',dir:'ltr'},
   body:{},
   querySelector(sel){return sel==='header.top'?header:null},
   querySelectorAll(sel){return sel==='a[href]'?[link]:[]},
   getElementById(id){return id==='beautyProWorld10'?picker:null},
   createElement(tag){
     return {tagName:tag,children:[],style:{},value:'',setAttribute(){},
       appendChild(x){this.children.push(x);return x},
       addEventListener(){}};
   },
   createTreeWalker(){
     let index=-1;
     return {currentNode:null,nextNode(){index++;if(index>=nodes.length)return false;this.currentNode=nodes[index];return true}};
   }
 };
 const storage={};
 const sandbox={
   URL,URLSearchParams,
   location:{href:host+'/resa-beauty/gestion.html?slug=salon-saly',origin:host,
     search:'?slug=salon-saly',pathname:'/resa-beauty/gestion.html'},
   document,history:{replaceState(){}},NodeFilter:{SHOW_TEXT:4},
   localStorage:{getItem(k){return storage[k]||null},setItem(k,v){storage[k]=v}},
   MutationObserver:class{observe(){}}
 };
 sandbox.window=sandbox;
 vm.runInNewContext(source,sandbox,{timeout:3000});
 return {api:sandbox.DIGIY_BEAUTY_PRO_WORLD10,nodes,document,link,picker,storage};
}
test('BEAUTY PRO translates all ten languages, including Arabic RTL, without touching owner data',()=>{
 const p=makePage([
  {text:'Prestations & tarifs'},
  {text:'Lundi'},
  {text:'Nouvelle demande'},
  {text:'Disponible',owned:true},
  {text:'Connecté : salon@example.com',id:'who'},
  {text:'✅ 3 créneau(x) créé(s). 2 créneau(x) existant(s) préservé(s).',id:'weekMsg'},
  {text:'Client Rose',owned:true}
 ]);
 assert.equal(p.api.locales.length,10);
 assert.equal(p.picker.children.length,10);
 p.api.setLang('en');
 assert.equal(p.nodes[0].nodeValue,'Services & prices');
 assert.equal(p.nodes[1].nodeValue,'Monday');
 assert.equal(p.nodes[2].nodeValue,'New request');
 assert.equal(p.nodes[3].nodeValue,'Disponible');
 assert.equal(p.nodes[4].nodeValue,'Signed in: salon@example.com');
 assert.equal(p.nodes[5].nodeValue,'✅ 3 slot(s) created. 2 existing slot(s) preserved.');
 assert.equal(p.nodes[6].nodeValue,'Client Rose');
 const u=new URL(p.link.value);
 assert.equal(u.searchParams.get('slug'),'salon-saly');
 assert.equal(u.searchParams.get('lang'),'en');
 p.api.setLang('ar');
 assert.equal(p.document.documentElement.dir,'rtl');
 assert.match(p.nodes[0].nodeValue,/[\u0600-\u06FF]/);
 assert.equal(p.nodes[4].nodeValue,'متصل: salon@example.com');
 p.api.setLang('zh');
 assert.match(p.nodes[0].nodeValue,/[\u4e00-\u9fff]/);
 assert.equal(p.nodes[6].nodeValue,'Client Rose');
 p.api.setLang('fr');
 assert.equal(p.nodes[0].nodeValue,'Prestations & tarifs');
 assert.equal(p.nodes[5].nodeValue,'✅ 3 créneau(x) créé(s). 2 créneau(x) existant(s) préservé(s).');
});
