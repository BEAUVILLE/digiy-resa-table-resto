(() => {
  "use strict";
  const SUPPORTED=["fr","en","es","de","it","nl","ar"];
  const COPY={
    fr:{kicker:"PORTES RESA",title:"Accès directs au parcours complet",sub:"Choisir un lieu, faire une demande, inscrire un professionnel ou ouvrir l’espace métier.",places:"Voir les lieux",request:"Faire une demande",register:"Inscrire un professionnel",pro:"Espace professionnel",home:"Maison DIGIY"},
    en:{kicker:"RESA DOORS",title:"Direct access to the complete journey",sub:"Choose a place, make a request, register a professional or open the business area.",places:"View places",request:"Make a request",register:"Register a professional",pro:"Professional area",home:"DIGIY home"},
    es:{kicker:"PUERTAS RESA",title:"Accesos directos al recorrido completo",sub:"Elige un lugar, haz una solicitud, registra un profesional o abre el espacio profesional.",places:"Ver lugares",request:"Hacer una solicitud",register:"Registrar un profesional",pro:"Espacio profesional",home:"Casa DIGIY"},
    de:{kicker:"RESA-ZUGÄNGE",title:"Direkter Zugang zum gesamten Ablauf",sub:"Ort wählen, Anfrage stellen, Profi registrieren oder den Pro-Bereich öffnen.",places:"Orte ansehen",request:"Anfrage stellen",register:"Profi registrieren",pro:"Pro-Bereich",home:"DIGIY Haus"},
    it:{kicker:"PORTE RESA",title:"Accessi diretti al percorso completo",sub:"Scegli un luogo, invia una richiesta, iscrivi un professionista o apri lo spazio professionale.",places:"Vedi luoghi",request:"Fai una richiesta",register:"Iscrivi un professionista",pro:"Spazio professionale",home:"Casa DIGIY"},
    nl:{kicker:"RESA-TOEGANGEN",title:"Directe toegang tot het volledige traject",sub:"Kies een locatie, doe een aanvraag, schrijf een professional in of open de pro-ruimte.",places:"Bekijk locaties",request:"Aanvraag doen",register:"Professional inschrijven",pro:"Pro-ruimte",home:"DIGIY huis"},
    ar:{kicker:"بوابات RESA",title:"وصول مباشر إلى المسار الكامل",sub:"اختر مكاناً، أرسل طلباً، سجّل مهنياً أو افتح المساحة المهنية.",places:"عرض الأماكن",request:"إرسال طلب",register:"تسجيل مهني",pro:"المساحة المهنية",home:"بيت DIGIY"}
  };
  function lang(){
    try{
      const q=new URLSearchParams(location.search).get("lang");
      if(SUPPORTED.includes(q)) return q;
      const s=localStorage.getItem("digiy-resa-lang")||localStorage.getItem("digiy-lang");
      if(SUPPORTED.includes(s)) return s;
    }catch(_){}
    return "fr";
  }
  const current=lang(),t=COPY[current]||COPY.fr;
  function withLang(path){
    const u=new URL(path,location.href);
    u.searchParams.set("lang",current);
    return u.toString();
  }
  function install(){
    if(document.getElementById("digiyResaDoors")) return;
    const anchor=document.querySelector(".hero")||document.querySelector("main")||document.body.firstElementChild;
    const box=document.createElement("section");
    box.id="digiyResaDoors";
    box.dir=current==="ar"?"rtl":"ltr";
    box.innerHTML=`
      <div class="digiy-resa-doors-head">
        <span>${t.kicker}</span>
        <h2>${t.title}</h2>
        <p>${t.sub}</p>
      </div>
      <div class="digiy-resa-doors-grid">
        <a href="${withLang("./index.html#results")}"><b>🏠 ${t.places}</b><small>DIGIY RESA</small></a>
        <a href="${withLang("./reserver.html")}"><b>📅 ${t.request}</b><small>RESA CLIENT</small></a>
        <a href="${withLang("./inscription-resa.html")}"><b>🧾 ${t.register}</b><small>RESA PRO</small></a>
        <a href="${withLang("https://pro-resa.digiylyfe.com/")}"><b>🔐 ${t.pro}</b><small>PRO RESA</small></a>
        <a href="${withLang("https://digiy-hub.digiylyfe.com/")}"><b>🧭 ${t.home}</b><small>HUB DIGIY</small></a>
      </div>`;
    const style=document.createElement("style");
    style.textContent=`
      #digiyResaDoors{margin:14px;padding:17px;border:1px solid rgba(250,204,21,.34);border-radius:22px;background:radial-gradient(circle at top right,rgba(250,204,21,.12),transparent 42%),linear-gradient(180deg,rgba(11,42,31,.98),rgba(9,30,22,.98));box-shadow:0 18px 55px rgba(0,0,0,.28);color:#ecfdf5}
      .digiy-resa-doors-head span{display:inline-flex;padding:6px 10px;border-radius:999px;background:rgba(250,204,21,.1);border:1px solid rgba(250,204,21,.3);color:#fde68a;font:950 11px system-ui;letter-spacing:.06em}
      .digiy-resa-doors-head h2{margin:10px 0 4px;font:950 clamp(22px,4vw,31px)/1.05 system-ui;color:#fff}
      .digiy-resa-doors-head p{margin:0;color:rgba(236,253,245,.75);font:800 13px/1.5 system-ui}
      .digiy-resa-doors-grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:9px;margin-top:14px}
      .digiy-resa-doors-grid a{min-height:82px;padding:11px;border-radius:16px;border:1px solid rgba(255,255,255,.12);background:rgba(255,255,255,.045);display:grid;align-content:center;gap:5px;color:#ecfdf5;text-decoration:none}
      .digiy-resa-doors-grid a:hover{border-color:rgba(250,204,21,.55);transform:translateY(-1px)}
      .digiy-resa-doors-grid b{font:950 13px/1.25 system-ui}.digiy-resa-doors-grid small{color:#fde68a;font:900 10px system-ui;letter-spacing:.05em}
      @media(max-width:850px){.digiy-resa-doors-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.digiy-resa-doors-grid a:last-child{grid-column:1/-1}}
      @media(max-width:430px){.digiy-resa-doors-grid{grid-template-columns:1fr}.digiy-resa-doors-grid a:last-child{grid-column:auto}}
    `;
    document.head.appendChild(style);
    if(anchor&&anchor.parentNode) anchor.insertAdjacentElement("afterend",box); else document.body.prepend(box);
  }
  if(document.readyState==="loading") document.addEventListener("DOMContentLoaded",install,{once:true}); else install();
})();