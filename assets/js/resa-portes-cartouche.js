(() => {
  "use strict";

  const SUPPORTED=["fr","en","es","de","it","nl","ar"];
  const COPY={
    fr:{kicker:"MENU CENTRAL RESA",title:"Toutes les portes du module",sub:"Accède directement aux lieux, aux fiches, à la réservation, à l’inscription et aux outils professionnels.",places:"Voir les lieux",profile:"Fiche publique",request:"Réserver / demander",register:"Inscrire un professionnel",catalogue:"Catalogue RESA",app:"Application RESA",lexicon:"Lexique RESA",pro:"Espace professionnel",home:"Maison DIGIY"},
    en:{kicker:"RESA CENTRAL MENU",title:"Every door in the module",sub:"Open places, public profiles, booking, registration and professional tools directly.",places:"View places",profile:"Public profile",request:"Book / request",register:"Register a professional",catalogue:"RESA catalogue",app:"RESA application",lexicon:"RESA glossary",pro:"Professional area",home:"DIGIY home"},
    es:{kicker:"MENÚ CENTRAL RESA",title:"Todas las puertas del módulo",sub:"Accede directamente a lugares, fichas, reservas, inscripción y herramientas profesionales.",places:"Ver lugares",profile:"Ficha pública",request:"Reservar / solicitar",register:"Registrar un profesional",catalogue:"Catálogo RESA",app:"Aplicación RESA",lexicon:"Glosario RESA",pro:"Espacio profesional",home:"Casa DIGIY"},
    de:{kicker:"RESA-HAUPTMENÜ",title:"Alle Zugänge des Moduls",sub:"Direkter Zugang zu Orten, Profilen, Buchung, Anmeldung und Profi-Werkzeugen.",places:"Orte ansehen",profile:"Öffentliches Profil",request:"Buchen / anfragen",register:"Profi registrieren",catalogue:"RESA-Katalog",app:"RESA-Anwendung",lexicon:"RESA-Glossar",pro:"Pro-Bereich",home:"DIGIY Haus"},
    it:{kicker:"MENU CENTRALE RESA",title:"Tutte le porte del modulo",sub:"Accedi direttamente a luoghi, schede, prenotazione, iscrizione e strumenti professionali.",places:"Vedi luoghi",profile:"Scheda pubblica",request:"Prenota / richiedi",register:"Iscrivi un professionista",catalogue:"Catalogo RESA",app:"Applicazione RESA",lexicon:"Glossario RESA",pro:"Spazio professionale",home:"Casa DIGIY"},
    nl:{kicker:"CENTRAAL RESA-MENU",title:"Alle deuren van de module",sub:"Open locaties, profielen, reservering, inschrijving en professionele hulpmiddelen rechtstreeks.",places:"Bekijk locaties",profile:"Openbaar profiel",request:"Boeken / aanvragen",register:"Professional inschrijven",catalogue:"RESA-catalogus",app:"RESA-applicatie",lexicon:"RESA-woordenlijst",pro:"Pro-ruimte",home:"DIGIY huis"},
    ar:{kicker:"القائمة المركزية لـ RESA",title:"جميع بوابات الوحدة",sub:"وصول مباشر إلى الأماكن والملفات والحجز والتسجيل والأدوات المهنية.",places:"عرض الأماكن",profile:"الملف العام",request:"حجز / طلب",register:"تسجيل مهني",catalogue:"دليل RESA",app:"تطبيق RESA",lexicon:"قاموس RESA",pro:"المساحة المهنية",home:"بيت DIGIY"}
  };

  let current="fr";
  let box=null;

  function detectLang(){
    try{
      const q=String(new URLSearchParams(location.search).get("lang")||"").toLowerCase();
      if(SUPPORTED.includes(q)) return q;
      const stored=String(localStorage.getItem("digiy-resa-lang")||localStorage.getItem("digiy-lang")||"").toLowerCase();
      if(SUPPORTED.includes(stored)) return stored;
      const doc=String(document.documentElement.lang||"").slice(0,2).toLowerCase();
      if(SUPPORTED.includes(doc)) return doc;
    }catch(_){}
    return "fr";
  }

  function withLang(path,lang){
    const u=new URL(path,location.href);
    u.searchParams.set("lang",lang);
    return u.toString();
  }

  function render(next){
    current=SUPPORTED.includes(next)?next:"fr";
    if(!box) return;
    const t=COPY[current]||COPY.fr;
    box.dir=current==="ar"?"rtl":"ltr";
    box.innerHTML=`
      <div class="digiy-resa-doors-head">
        <span>${t.kicker}</span>
        <h2>${t.title}</h2>
        <p>${t.sub}</p>
      </div>
      <div class="digiy-resa-doors-grid">
        <a href="${withLang("./index.html#results",current)}"><b>🏠 ${t.places}</b><small>RESA PUBLIC</small></a>
        <a href="${withLang("./fiche.html",current)}"><b>🪪 ${t.profile}</b><small>FICHE RESA</small></a>
        <a href="${withLang("./reserver.html",current)}"><b>📅 ${t.request}</b><small>RESA CLIENT</small></a>
        <a href="${withLang("./inscription-resa.html",current)}"><b>🧾 ${t.register}</b><small>INSCRIPTION RESA</small></a>
        <a href="${withLang("./catalogue.html",current)}"><b>📚 ${t.catalogue}</b><small>CATALOGUE</small></a>
        <a href="${withLang("./app.html",current)}"><b>📲 ${t.app}</b><small>APP RESA</small></a>
        <a href="${withLang("./lexique-resa.html",current)}"><b>🗣️ ${t.lexicon}</b><small>LEXIQUE</small></a>
        <a href="${withLang("https://pro-resa.digiylyfe.com/",current)}"><b>🔐 ${t.pro}</b><small>PRO RESA</small></a>
        <a href="${withLang("https://digiy-hub.digiylyfe.com/",current)}"><b>🧭 ${t.home}</b><small>HUB DIGIY</small></a>
      </div>`;
  }

  function install(){
    if(document.getElementById("digiyResaDoors")) return;
    const anchor=document.querySelector(".hero")||document.querySelector("main")||document.body.firstElementChild;
    box=document.createElement("section");
    box.id="digiyResaDoors";
    const style=document.createElement("style");
    style.textContent=`
      #digiyResaDoors{margin:14px;padding:17px;border:1px solid rgba(250,204,21,.42);border-radius:22px;background:radial-gradient(circle at top right,rgba(250,204,21,.14),transparent 42%),linear-gradient(180deg,rgba(11,42,31,.99),rgba(9,30,22,.99));box-shadow:0 18px 55px rgba(0,0,0,.30);color:#ecfdf5;scroll-margin-top:80px}
      .digiy-resa-doors-head span{display:inline-flex;padding:6px 10px;border-radius:999px;background:rgba(250,204,21,.1);border:1px solid rgba(250,204,21,.34);color:#fde68a;font:950 11px system-ui;letter-spacing:.06em}
      .digiy-resa-doors-head h2{margin:10px 0 4px;font:950 clamp(22px,4vw,31px)/1.05 system-ui;color:#fff}
      .digiy-resa-doors-head p{margin:0;color:rgba(236,253,245,.78);font:800 13px/1.5 system-ui}
      .digiy-resa-doors-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:9px;margin-top:14px}
      .digiy-resa-doors-grid a{min-height:84px;padding:11px;border-radius:16px;border:1px solid rgba(255,255,255,.13);background:rgba(255,255,255,.05);display:grid;align-content:center;gap:5px;color:#ecfdf5;text-decoration:none;transition:.16s ease}
      .digiy-resa-doors-grid a:hover,.digiy-resa-doors-grid a:focus-visible{border-color:rgba(250,204,21,.62);background:rgba(250,204,21,.09);transform:translateY(-1px);outline:none}
      .digiy-resa-doors-grid b{font:950 13px/1.25 system-ui}.digiy-resa-doors-grid small{color:#fde68a;font:900 10px system-ui;letter-spacing:.05em}
      [dir="rtl"] .digiy-resa-doors-head,[dir="rtl"] .digiy-resa-doors-grid a{text-align:right}
      @media(max-width:760px){.digiy-resa-doors-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.digiy-resa-doors-grid a:last-child{grid-column:1/-1}}
      @media(max-width:430px){.digiy-resa-doors-grid{grid-template-columns:1fr}.digiy-resa-doors-grid a:last-child{grid-column:auto}}
    `;
    document.head.appendChild(style);
    if(anchor&&anchor.parentNode) anchor.insertAdjacentElement("afterend",box); else document.body.prepend(box);
    render(detectLang());

    document.addEventListener("click",event=>{
      const btn=event.target.closest?.("[data-lang],[data-resa-lang]");
      if(!btn) return;
      const next=String(btn.dataset.lang||btn.dataset.resaLang||"").toLowerCase();
      if(!SUPPORTED.includes(next)) return;
      setTimeout(()=>render(next),0);
    },true);
    window.addEventListener("popstate",()=>render(detectLang()));
    window.addEventListener("storage",()=>render(detectLang()));
    document.addEventListener("digiy:lang",event=>render(event.detail?.lang||detectLang()));
  }

  if(document.readyState==="loading") document.addEventListener("DOMContentLoaded",install,{once:true}); else install();
})();
