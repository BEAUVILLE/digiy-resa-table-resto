(() => {
  "use strict";

  const DATA = window.DIGIY_RESA_I18N || {};
  const SUPPORTED = DATA.supported || ["fr","en","es","de","it","nl","ar"];
  const FLAGS = {fr:"🇫🇷",en:"🇬🇧",es:"🇪🇸",de:"🇩🇪",it:"🇮🇹",nl:"🇳🇱",ar:"🇸🇦"};

  const BENEFIT_KEYS = {
    "Carte de visibilité numérique RESA":"benefitDigitalVisibilityResa",
    "QR et lien partageable":"benefitQrShareable",
    "Présence sur le site":"benefitSitePresence",
    "Contact direct":"benefitDirectContact",
    "Validation humaine":"benefitHumanValidation",
    "0% commission":"benefitZeroCommission",
    "Paiement direct avec preuve WhatsApp":"benefitDirectPaymentProof",
    "Carte de visibilité RESA":"benefitVisibilityCardResa",
    "QR officiel":"benefitOfficialQr",
    "Lien partageable":"benefitShareableLink",
    "Visibilité RESA renforcée":"benefitEnhancedResaVisibility",
    "Accompagnement renforcé":"benefitEnhancedSupport",
    "Fiche établissement détaillée":"benefitDetailedEstablishment",
    "Moteur métier RESA":"benefitResaBusinessEngine",
    "Planning et rendez-vous":"benefitScheduleAppointments",
    "Tables ou créneaux":"benefitTablesSlots",
    "Suivi des demandes":"benefitRequestTracking",
    "Boost local":"benefitLocalBoost",
    "Visibilité renforcée":"benefitEnhancedVisibility",
    "Priorité visibilité":"benefitVisibilityPriority",
    "Réservé abonnés":"benefitSubscribersOnly",
    "Visibilité 7 jours":"benefitVisibility7Days",
    "Visibilité 15 jours":"benefitVisibility15Days",
    "Visibilité 1 mois":"benefitVisibility1Month",
    "Réservé non-abonnés":"benefitNonSubscribersOnly",
    "Fiche premium":"benefitPremiumProfile",
    "QR et lien":"benefitQrAndLink"
  };

  const BENEFIT_LANGS = {
    en: {
      benefitDigitalVisibilityResa:"Digital RESA visibility card",
      benefitQrShareable:"QR and shareable link",
      benefitSitePresence:"Presence on the site",
      benefitDirectContact:"Direct contact",
      benefitHumanValidation:"Human validation",
      benefitZeroCommission:"0% commission",
      benefitDirectPaymentProof:"Direct payment with WhatsApp proof",
      benefitVisibilityCardResa:"RESA visibility card",
      benefitOfficialQr:"Official QR",
      benefitShareableLink:"Shareable link",
      benefitEnhancedResaVisibility:"Enhanced RESA visibility",
      benefitEnhancedSupport:"Enhanced support",
      benefitDetailedEstablishment:"Detailed establishment page",
      benefitResaBusinessEngine:"RESA business engine",
      benefitScheduleAppointments:"Schedule and appointments",
      benefitTablesSlots:"Tables or time slots",
      benefitRequestTracking:"Request tracking",
      benefitLocalBoost:"Local boost",
      benefitEnhancedVisibility:"Enhanced visibility",
      benefitVisibilityPriority:"Visibility priority",
      benefitSubscribersOnly:"Reserved for subscribers",
      benefitVisibility7Days:"Visibility for 7 days",
      benefitVisibility15Days:"Visibility for 15 days",
      benefitVisibility1Month:"Visibility for 1 month",
      benefitNonSubscribersOnly:"Reserved for non-subscribers",
      benefitPremiumProfile:"Premium profile",
      benefitQrAndLink:"QR and link"
    },
    es: {
      benefitDigitalVisibilityResa:"Tarjeta digital de visibilidad RESA",
      benefitQrShareable:"QR y enlace compartible",
      benefitSitePresence:"Presencia en el sitio",
      benefitDirectContact:"Contacto directo",
      benefitHumanValidation:"Validación humana",
      benefitZeroCommission:"0% de comisión",
      benefitDirectPaymentProof:"Pago directo con comprobante por WhatsApp",
      benefitVisibilityCardResa:"Tarjeta de visibilidad RESA",
      benefitOfficialQr:"QR oficial",
      benefitShareableLink:"Enlace compartible",
      benefitEnhancedResaVisibility:"Visibilidad RESA reforzada",
      benefitEnhancedSupport:"Acompañamiento reforzado",
      benefitDetailedEstablishment:"Ficha detallada del establecimiento",
      benefitResaBusinessEngine:"Motor profesional RESA",
      benefitScheduleAppointments:"Agenda y citas",
      benefitTablesSlots:"Mesas o franjas horarias",
      benefitRequestTracking:"Seguimiento de solicitudes",
      benefitLocalBoost:"Impulso local",
      benefitEnhancedVisibility:"Visibilidad reforzada",
      benefitVisibilityPriority:"Prioridad de visibilidad",
      benefitSubscribersOnly:"Reservado a abonados",
      benefitVisibility7Days:"Visibilidad durante 7 días",
      benefitVisibility15Days:"Visibilidad durante 15 días",
      benefitVisibility1Month:"Visibilidad durante 1 mes",
      benefitNonSubscribersOnly:"Reservado a no abonados",
      benefitPremiumProfile:"Ficha premium",
      benefitQrAndLink:"QR y enlace"
    },
    de: {
      benefitDigitalVisibilityResa:"Digitale RESA-Sichtbarkeitskarte",
      benefitQrShareable:"QR und teilbarer Link",
      benefitSitePresence:"Präsenz auf der Website",
      benefitDirectContact:"Direkter Kontakt",
      benefitHumanValidation:"Menschliche Prüfung",
      benefitZeroCommission:"0 % Provision",
      benefitDirectPaymentProof:"Direkte Zahlung mit WhatsApp-Nachweis",
      benefitVisibilityCardResa:"RESA-Sichtbarkeitskarte",
      benefitOfficialQr:"Offizieller QR",
      benefitShareableLink:"Teilbarer Link",
      benefitEnhancedResaVisibility:"Verstärkte RESA-Sichtbarkeit",
      benefitEnhancedSupport:"Verstärkte Begleitung",
      benefitDetailedEstablishment:"Detaillierte Betriebsseite",
      benefitResaBusinessEngine:"RESA-Geschäftsmotor",
      benefitScheduleAppointments:"Planung und Termine",
      benefitTablesSlots:"Tische oder Zeitfenster",
      benefitRequestTracking:"Anfragenachverfolgung",
      benefitLocalBoost:"Lokaler Boost",
      benefitEnhancedVisibility:"Verstärkte Sichtbarkeit",
      benefitVisibilityPriority:"Sichtbarkeitspriorität",
      benefitSubscribersOnly:"Nur für Abonnenten",
      benefitVisibility7Days:"Sichtbarkeit für 7 Tage",
      benefitVisibility15Days:"Sichtbarkeit für 15 Tage",
      benefitVisibility1Month:"Sichtbarkeit für 1 Monat",
      benefitNonSubscribersOnly:"Nur für Nicht-Abonnenten",
      benefitPremiumProfile:"Premium-Profil",
      benefitQrAndLink:"QR und Link"
    },
    it: {
      benefitDigitalVisibilityResa:"Carta digitale di visibilità RESA",
      benefitQrShareable:"QR e link condivisibile",
      benefitSitePresence:"Presenza sul sito",
      benefitDirectContact:"Contatto diretto",
      benefitHumanValidation:"Validazione umana",
      benefitZeroCommission:"0% commissioni",
      benefitDirectPaymentProof:"Pagamento diretto con prova WhatsApp",
      benefitVisibilityCardResa:"Carta di visibilità RESA",
      benefitOfficialQr:"QR ufficiale",
      benefitShareableLink:"Link condivisibile",
      benefitEnhancedResaVisibility:"Visibilità RESA rafforzata",
      benefitEnhancedSupport:"Accompagnamento rafforzato",
      benefitDetailedEstablishment:"Scheda dettagliata della struttura",
      benefitResaBusinessEngine:"Motore professionale RESA",
      benefitScheduleAppointments:"Agenda e appuntamenti",
      benefitTablesSlots:"Tavoli o fasce orarie",
      benefitRequestTracking:"Monitoraggio delle richieste",
      benefitLocalBoost:"Boost locale",
      benefitEnhancedVisibility:"Visibilità rafforzata",
      benefitVisibilityPriority:"Priorità di visibilità",
      benefitSubscribersOnly:"Riservato agli abbonati",
      benefitVisibility7Days:"Visibilità per 7 giorni",
      benefitVisibility15Days:"Visibilità per 15 giorni",
      benefitVisibility1Month:"Visibilità per 1 mese",
      benefitNonSubscribersOnly:"Riservato ai non abbonati",
      benefitPremiumProfile:"Scheda premium",
      benefitQrAndLink:"QR e link"
    },
    nl: {
      benefitDigitalVisibilityResa:"Digitale RESA-zichtbaarheidskaart",
      benefitQrShareable:"QR en deelbare link",
      benefitSitePresence:"Aanwezigheid op de site",
      benefitDirectContact:"Direct contact",
      benefitHumanValidation:"Menselijke validatie",
      benefitZeroCommission:"0% commissie",
      benefitDirectPaymentProof:"Directe betaling met WhatsApp-bewijs",
      benefitVisibilityCardResa:"RESA-zichtbaarheidskaart",
      benefitOfficialQr:"Officiële QR",
      benefitShareableLink:"Deelbare link",
      benefitEnhancedResaVisibility:"Versterkte RESA-zichtbaarheid",
      benefitEnhancedSupport:"Versterkte begeleiding",
      benefitDetailedEstablishment:"Gedetailleerde vestigingsfiche",
      benefitResaBusinessEngine:"RESA-bedrijfsmotor",
      benefitScheduleAppointments:"Planning en afspraken",
      benefitTablesSlots:"Tafels of tijdsloten",
      benefitRequestTracking:"Opvolging van aanvragen",
      benefitLocalBoost:"Lokale boost",
      benefitEnhancedVisibility:"Versterkte zichtbaarheid",
      benefitVisibilityPriority:"Zichtbaarheidsprioriteit",
      benefitSubscribersOnly:"Alleen voor abonnees",
      benefitVisibility7Days:"Zichtbaarheid voor 7 dagen",
      benefitVisibility15Days:"Zichtbaarheid voor 15 dagen",
      benefitVisibility1Month:"Zichtbaarheid voor 1 maand",
      benefitNonSubscribersOnly:"Alleen voor niet-abonnees",
      benefitPremiumProfile:"Premiumprofiel",
      benefitQrAndLink:"QR en link"
    },
    ar: {
      benefitDigitalVisibilityResa:"بطاقة ظهور رقمية RESA",
      benefitQrShareable:"رمز QR ورابط قابل للمشاركة",
      benefitSitePresence:"وجود على الموقع",
      benefitDirectContact:"اتصال مباشر",
      benefitHumanValidation:"تحقق بشري",
      benefitZeroCommission:"0% عمولة",
      benefitDirectPaymentProof:"دفع مباشر مع إثبات عبر واتساب",
      benefitVisibilityCardResa:"بطاقة ظهور RESA",
      benefitOfficialQr:"رمز QR رسمي",
      benefitShareableLink:"رابط قابل للمشاركة",
      benefitEnhancedResaVisibility:"ظهور RESA معزز",
      benefitEnhancedSupport:"مرافقة معززة",
      benefitDetailedEstablishment:"بطاقة تفصيلية للمؤسسة",
      benefitResaBusinessEngine:"محرك أعمال RESA",
      benefitScheduleAppointments:"الجدول والمواعيد",
      benefitTablesSlots:"الطاولات أو الفترات الزمنية",
      benefitRequestTracking:"متابعة الطلبات",
      benefitLocalBoost:"تعزيز محلي",
      benefitEnhancedVisibility:"ظهور معزز",
      benefitVisibilityPriority:"أولوية الظهور",
      benefitSubscribersOnly:"مخصص للمشتركين",
      benefitVisibility7Days:"ظهور لمدة 7 أيام",
      benefitVisibility15Days:"ظهور لمدة 15 يوماً",
      benefitVisibility1Month:"ظهور لمدة شهر",
      benefitNonSubscribersOnly:"مخصص لغير المشتركين",
      benefitPremiumProfile:"بطاقة مميزة",
      benefitQrAndLink:"رمز QR ورابط"
    }
  };

  Object.assign(DATA.frToKey || (DATA.frToKey = {}), BENEFIT_KEYS);
  DATA.langs = DATA.langs || {};
  for(const [code, values] of Object.entries(BENEFIT_LANGS)){
    Object.assign(DATA.langs[code] || (DATA.langs[code] = {}), values);
  }

  const FR = DATA.frToKey || {};
  const PARTIAL = DATA.partial || {};

  function currentLang(){
    try{
      const q = String(new URLSearchParams(location.search).get("lang") || "").toLowerCase();
      if(SUPPORTED.includes(q)) return q;
      for(const key of ["digiy-resa-lang","digiy-lang"]){
        const v = String(localStorage.getItem(key) || "").toLowerCase();
        if(SUPPORTED.includes(v)) return v;
      }
      const b = String(navigator.language || "fr").slice(0,2).toLowerCase();
      if(SUPPORTED.includes(b)) return b;
    }catch(_){}
    return "fr";
  }

  const lang = currentLang();
  const T = (DATA.langs && DATA.langs[lang]) || {};
  const partialPairs = Object.entries(PARTIAL).sort((a,b) => b[0].length - a[0].length);

  try{
    localStorage.setItem("digiy-resa-lang", lang);
    localStorage.setItem("digiy-lang", lang);
  }catch(_){}

  document.documentElement.lang = lang;
  document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";

  function keepSpace(raw, next){
    const left = (String(raw).match(/^\s*/) || [""])[0];
    const right = (String(raw).match(/\s*$/) || [""])[0];
    return left + next + right;
  }

  function translateCore(compact){
    const key = FR[compact];
    if(key && T[key]) return T[key];

    let out = compact;
    for(const [source, k] of partialPairs){
      if(T[k] && out.includes(source)) out = out.split(source).join(T[k]);
    }
    return out;
  }

  function translateString(value){
    const raw = String(value ?? "");
    if(lang === "fr" || !raw.trim()) return raw;

    const compact = raw.replace(/\s+/g, " ").trim();
    const direct = translateCore(compact);
    if(direct !== compact) return keepSpace(raw, direct);

    const marked = compact.match(/^((?:(?:✅|☑️|✔️|✔|✓|•|[-–—])\s*)+)(.+)$/u);
    if(marked){
      const prefix = marked[1];
      const core = marked[2].trim();
      const translated = translateCore(core);
      if(translated !== core) return keepSpace(raw, prefix + translated);
    }

    return raw;
  }

  function translateMessage(value){
    return String(value || "").split("\n").map(translateString).join("\n");
  }

  function rewriteUrl(value){
    if(!value) return value;
    try{
      const raw = String(value);
      if(/^(mailto:|tel:|sms:)/i.test(raw)) return raw;

      const u = new URL(raw, location.href);
      if(/(^|\.)wa\.me$/i.test(u.hostname) || /(^|\.)whatsapp\.com$/i.test(u.hostname)){
        const text = u.searchParams.get("text");
        if(text) u.searchParams.set("text", translateMessage(text));
        return u.toString();
      }

      const internal =
        u.origin === location.origin ||
        /(^|\.)resa-table-resto\.digiylyfe\.com$/i.test(u.hostname) ||
        /(^|\.)pro-resa\.digiylyfe\.com$/i.test(u.hostname);

      if(internal){
        u.searchParams.set("lang", lang);
        return u.toString();
      }

      return raw;
    }catch(_){
      return value;
    }
  }

  function rewriteQr(img){
    try{
      if(!img?.src || !/api\.qrserver\.com/i.test(img.src)) return;
      const q = new URL(img.src);
      const data = q.searchParams.get("data");
      if(!data) return;
      const next = rewriteUrl(data);
      if(next !== data){
        q.searchParams.set("data", next);
        img.src = q.toString();
      }
    }catch(_){}
  }

  function translateNode(node){
    if(!node) return;

    if(node.nodeType === Node.TEXT_NODE){
      const parent = node.parentElement;
      if(!parent || ["SCRIPT","STYLE","NOSCRIPT","TEXTAREA"].includes(parent.tagName)) return;
      const next = translateString(node.nodeValue);
      if(next !== node.nodeValue) node.nodeValue = next;
      return;
    }

    if(node.nodeType !== Node.ELEMENT_NODE) return;
    const el = node;
    if(["SCRIPT","STYLE","NOSCRIPT"].includes(el.tagName)) return;

    for(const attr of ["placeholder","title","aria-label","alt"]){
      if(el.hasAttribute(attr)){
        const old = el.getAttribute(attr);
        const next = translateString(old);
        if(next !== old) el.setAttribute(attr, next);
      }
    }

    if(el.tagName === "A" && el.hasAttribute("href")){
      const old = el.getAttribute("href");
      const next = rewriteUrl(old);
      if(next && next !== old) el.setAttribute("href", next);
    }

    if(el.tagName === "IMG") rewriteQr(el);
    for(const child of el.childNodes) translateNode(child);
  }

  function switcher(){
    if(document.getElementById("digiyResaLangSwitcher")) return;

    const box = document.createElement("div");
    box.id = "digiyResaLangSwitcher";
    box.setAttribute("aria-label", "Langue RESA");
    box.innerHTML = SUPPORTED.map(code =>
      `<button type="button" data-resa-lang="${code}" aria-pressed="${code === lang}">${FLAGS[code]}<span>${code.toUpperCase()}</span></button>`
    ).join("");

    const style = document.createElement("style");
    style.textContent = `
      #digiyResaLangSwitcher{position:fixed;z-index:2147483000;top:max(8px,env(safe-area-inset-top));right:8px;display:flex;gap:3px;flex-wrap:wrap;justify-content:flex-end;max-width:min(340px,calc(100vw - 16px));padding:5px;border:1px solid rgba(250,204,21,.45);border-radius:15px;background:rgba(6,27,20,.94);box-shadow:0 10px 30px rgba(0,0,0,.28);backdrop-filter:blur(10px)}
      #digiyResaLangSwitcher button{min-width:39px;min-height:36px;padding:3px 6px;border:0;border-radius:10px;background:transparent;color:#ecfdf5;font:800 11px system-ui;display:grid;place-items:center;gap:1px;cursor:pointer}
      #digiyResaLangSwitcher button[aria-pressed="true"]{background:linear-gradient(135deg,#facc15,#f59e0b);color:#111}
      #digiyResaLangSwitcher button span{font-size:9px;line-height:1}
      [dir="rtl"] #digiyResaLangSwitcher{right:auto;left:8px}
      @media(max-width:520px){#digiyResaLangSwitcher{top:auto;bottom:max(76px,calc(8px + env(safe-area-inset-bottom)))}}
    `;

    document.head.appendChild(style);
    document.body.appendChild(box);

    box.addEventListener("click", event => {
      const btn = event.target.closest("[data-resa-lang]");
      if(!btn) return;
      const next = btn.dataset.resaLang;
      if(!SUPPORTED.includes(next)) return;
      try{
        localStorage.setItem("digiy-resa-lang", next);
        localStorage.setItem("digiy-lang", next);
      }catch(_){}
      const u = new URL(location.href);
      u.searchParams.set("lang", next);
      location.href = u.toString();
    });
  }

  const nativeOpen = window.open ? window.open.bind(window) : null;
  if(nativeOpen){
    window.open = function(url, target, features){
      return nativeOpen(rewriteUrl(url), target, features);
    };
  }

  document.addEventListener("click", event => {
    const anchor = event.target.closest?.("a[href]");
    if(anchor){
      const old = anchor.getAttribute("href");
      const next = rewriteUrl(old);
      if(next && next !== old) anchor.setAttribute("href", next);
    }
  }, true);

  let scheduled = false;
  const observer = new MutationObserver(records => {
    if(scheduled) return;
    scheduled = true;
    requestAnimationFrame(() => {
      scheduled = false;
      for(const record of records){
        if(record.type === "characterData") translateNode(record.target);
        for(const node of record.addedNodes || []) translateNode(node);
        if(record.type === "attributes") translateNode(record.target);
      }
    });
  });

  function start(){
    switcher();

    if(lang !== "fr"){
      document.title = translateString(document.title);
      translateNode(document.body);
    }else{
      document.querySelectorAll("a[href]").forEach(anchor =>
        anchor.setAttribute("href", rewriteUrl(anchor.getAttribute("href")))
      );
      document.querySelectorAll('img[src*="api.qrserver.com"]').forEach(rewriteQr);
    }

    observer.observe(document.documentElement, {
      subtree:true,
      childList:true,
      characterData:true,
      attributes:true,
      attributeFilter:["href","src","placeholder","title","aria-label","alt"]
    });

    setInterval(() => {
      document.querySelectorAll("a[href]").forEach(anchor => {
        const old = anchor.getAttribute("href");
        const next = rewriteUrl(old);
        if(next && next !== old) anchor.setAttribute("href", next);
      });
      document.querySelectorAll('img[src*="api.qrserver.com"]').forEach(rewriteQr);
      if(lang !== "fr") translateNode(document.body);
    }, 1800);
  }

  if(document.readyState === "loading"){
    document.addEventListener("DOMContentLoaded", start, {once:true});
  }else{
    start();
  }
})();