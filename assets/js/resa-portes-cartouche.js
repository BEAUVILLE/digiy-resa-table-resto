(() => {
  "use strict";
  const SUPPORTED=["fr","en","es","de","it","nl","ar"];
  const COPY={
    fr:{kicker:"PORTES RESA",title:"Tout le parcours RESA depuis une seule cartouche",sub:"Consulter, réserver, inscrire un professionnel ou ouvrir les outils du module.",places:"Voir les professionnels",request:"Faire une demande",register:"Inscrire un professionnel",catalogue:"Catalogue public",profile:"Fiche modèle",lexicon:"Lexique RESA",pro:"Espace professionnel",home:"Maison DIGIY"},
    en:{kicker:"RESA DOORS",title:"The complete RESA journey from one panel",sub:"Browse, book, register a professional or open the module tools.",places:"View professionals",request:"Make a request",register:"Register a professional",catalogue:"Public catalogue",profile:"Profile template",lexicon:"RESA glossary",pro:"Professional area",home:"DIGIY home"},
    es:{kicker:"PUERTAS RESA",title:"Todo el recorrido RESA desde un solo panel",sub:"Consultar, reservar, registrar un profesional o abrir las herramientas del módulo.",places:"Ver profesionales",request:"Hacer una solicitud",register:"Registrar un profesional",catalogue:"Catálogo público",profile:"Ficha modelo",lexicon:"Léxico RESA",pro:"Espacio profesional",home:"Casa DIGIY"},
    de:{kicker:"RESA-ZUGÄNGE",title:"Der gesamte RESA-Ablauf in einer Leiste",sub:"Ansehen, reservieren, Profi registrieren oder Modulwerkzeuge öffnen.",places:"Profis ansehen",request:"Anfrage stellen",register:"Profi registrieren",catalogue:"Öffentlicher Katalog",profile:"Profilvorlage",lexicon:"RESA-Lexikon",pro:"Pro-Bereich",home:"DIGIY Haus"},
    it:{kicker:"PORTE RESA",title:"Tutto il percorso RESA in un solo pannello",sub:"Consulta, prenota, iscrivi un professionista o apri gli strumenti del modulo.",places:"Vedi professionisti",request:"Fai una richiesta",register:"Iscrivi un professionista",catalogue:"Catalogo pubblico",profile:"Scheda modello",lexicon:"Lessico RESA",pro:"Spazio professionale",home:"Casa DIGIY"},
    nl:{kicker:"RESA-TOEGANGEN",title:"Het volledige RESA-traject in één paneel",sub:"Bekijken, reserveren, een professional inschrijven of moduletools openen.",places:"Bekijk professionals",request:"Aanvraag doen",register:"Professional inschrijven",catalogue:"Openbare catalogus",profile:"Profielsjabloon",lexicon:"RESA-woordenlijst",pro:"Pro-ruimte",home:"DIGIY huis"},
    ar:{kicker:"بوابات RESA",title:"مسار RESA الكامل من لوحة واحدة",sub:"تصفّح أو احجز أو سجّل مهنياً أو افتح أدوات الوحدة.",places:"عرض المهنيين",request:"إرسال طلب",register:"تسجيل مهني",catalogue:"الكتالوج العام",profile:"نموذج البطاقة",lexicon:"معجم RESA",pro:"المساحة المهنية",home:"بيت DIGIY"}
  };
  function lang(){
    try{
      const q=String(new URLSearchParams(location.search).get("lang")||"").toLowerCase();
      if(SUPPORTED.includes(q)) return q;
      const s=String(localStorage.getItem("digiy-resa-lang")||localStorage.getItem("digiy-lang")||"").toLowerCase();
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
    const doors=[
      ["🏠",t.places,"DIGIY RESA","./index.html#results"],
      ["📅",t.request,"RESA CLIENT","./reserver.html"],
      ["🧾",t.register,"RESA PRO","./inscription-resa.html"],
      ["📚",t.catalogue,"CATALOGUE","./catalogue.html"],
      ["🪪",t.profile,"FICHE","./fiche.html"],
      ["🗣️",t.lexicon,"LEXIQUE","./lexique-resa.html"],
      ["🔐",t.pro,"PRO RESA","https://pro-resa.digiylyfe.com/"],
      ["🧭",t.home,"HUB DIGIY","https://digiy-hub.digiylyfe.com/"]
    ];
    box.innerHTML=`<div class="digiy-resa-doors-head"><span>${t.kicker}</span><h2>${t.title}</h2><p>${t.sub}</p></div><div class="digiy-resa-doors-grid">${doors.map(([ico,label,small,url])=>`<a href="${withLang(url)}"><b>${ico} ${label}</b><small>${small}</small></a>`).join("")}</div>`;
    const style=document.createElement("style");
    style.textContent=`#digiyResaDoors{margin:14px;padding:17px;border:1px solid rgba(250,204,21,.34);border-radius:22px;background:radial-gradient(circle at top right,rgba(250,204,21,.12),transparent 42%),linear-gradient(180deg,rgba(11,42,31,.98),rgba(9,30,22,.98));box-shadow:0 18px 55px rgba(0,0,0,.28);color:#ecfdf5}.digiy-resa-doors-head span{display:inline-flex;padding:6px 10px;border-radius:999px;background:rgba(250,204,21,.1);border:1px solid rgba(250,204,21,.3);color:#fde68a;font:950 11px system-ui;letter-spacing:.06em}.digiy-resa-doors-head h2{margin:10px 0 4px;font:950 clamp(22px,4vw,31px)/1.05 system-ui;color:#fff}.digiy-resa-doors-head p{margin:0;color:rgba(236,253,245,.75);font:800 13px/1.5 system-ui}.digiy-resa-doors-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:9px;margin-top:14px}.digiy-resa-doors-grid a{min-height:82px;padding:11px;border-radius:16px;border:1px solid rgba(255,255,255,.12);background:rgba(255,255,255,.045);display:grid;align-content:center;gap:5px;color:#ecfdf5;text-decoration:none;transition:.16s ease}.digiy-resa-doors-grid a:hover{border-color:rgba(250,204,21,.55);transform:translateY(-1px)}.digiy-resa-doors-grid b{font:950 13px/1.25 system-ui}.digiy-resa-doors-grid small{color:#fde68a;font:900 10px system-ui;letter-spacing:.05em}@media(max-width:850px){.digiy-resa-doors-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:430px){.digiy-resa-doors-grid{grid-template-columns:1fr}}`;
    document.head.appendChild(style);
    if(anchor&&anchor.parentNode) anchor.insertAdjacentElement("afterend",box); else document.body.prepend(box);
  }
  if(document.readyState==="loading") document.addEventListener("DOMContentLoaded",install,{once:true}); else install();
})();