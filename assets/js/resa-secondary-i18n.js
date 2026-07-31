(() => {
  "use strict";
  const DATA=window.DIGIY_RESA_I18N||{};
  const SUPPORTED=DATA.supported||["fr","en","es","de","it","nl","ar"];
  const FLAGS={fr:"🇫🇷",en:"🇬🇧",es:"🇪🇸",de:"🇩🇪",it:"🇮🇹",nl:"🇳🇱",ar:"🇸🇦"};
  const FR=DATA.frToKey||{};
  const PARTIAL=DATA.partial||{};
  function currentLang(){
    try{
      const q=String(new URLSearchParams(location.search).get("lang")||"").toLowerCase();
      if(SUPPORTED.includes(q)) return q;
      for(const key of ["digiy-resa-lang","digiy-lang"]){
        const v=String(localStorage.getItem(key)||"").toLowerCase();
        if(SUPPORTED.includes(v)) return v;
      }
      const b=String(navigator.language||"fr").slice(0,2).toLowerCase();
      if(SUPPORTED.includes(b)) return b;
    }catch(_){}
    return "fr";
  }
  const lang=currentLang();
  const T=(DATA.langs&&DATA.langs[lang])||{};
  const partialPairs=Object.entries(PARTIAL).sort((a,b)=>b[0].length-a[0].length);
  try{localStorage.setItem("digiy-resa-lang",lang);localStorage.setItem("digiy-lang",lang)}catch(_){}
  document.documentElement.lang=lang;
  document.documentElement.dir=lang==="ar"?"rtl":"ltr";

  function keepSpace(raw,next){
    const left=(String(raw).match(/^\s*/)||[""])[0];
    const right=(String(raw).match(/\s*$/)||[""])[0];
    return left+next+right;
  }
  function translateString(value){
    const raw=String(value??"");
    if(lang==="fr"||!raw.trim()) return raw;
    const compact=raw.replace(/\s+/g," ").trim();
    const key=FR[compact];
    if(key&&T[key]) return keepSpace(raw,T[key]);
    let out=compact;
    for(const [source,k] of partialPairs){if(T[k]&&out.includes(source)) out=out.split(source).join(T[k]);}
    return out===compact?raw:keepSpace(raw,out);
  }
  function translateMessage(value){return String(value||"").split("\n").map(translateString).join("\n")}
  function rewriteUrl(value){
    if(!value) return value;
    try{
      const raw=String(value);
      if(/^(mailto:|tel:|sms:)/i.test(raw)) return raw;
      const u=new URL(raw,location.href);
      if(/(^|\.)wa\.me$/i.test(u.hostname)||/(^|\.)whatsapp\.com$/i.test(u.hostname)){
        const text=u.searchParams.get("text");
        if(text) u.searchParams.set("text",translateMessage(text));
        return u.toString();
      }
      const internal=u.origin===location.origin||/(^|\.)resa-table-resto\.digiylyfe\.com$/i.test(u.hostname)||/(^|\.)pro-resa\.digiylyfe\.com$/i.test(u.hostname);
      if(internal){u.searchParams.set("lang",lang);return u.toString()}
      return raw;
    }catch(_){return value}
  }
  function rewriteQr(img){
    try{
      if(!img?.src||!/api\.qrserver\.com/i.test(img.src)) return;
      const q=new URL(img.src);const data=q.searchParams.get("data");if(!data)return;
      const next=rewriteUrl(data);if(next!==data){q.searchParams.set("data",next);img.src=q.toString()}
    }catch(_){}
  }
  function translateNode(node){
    if(!node)return;
    if(node.nodeType===Node.TEXT_NODE){
      const p=node.parentElement;if(!p||["SCRIPT","STYLE","NOSCRIPT","TEXTAREA"].includes(p.tagName))return;
      const next=translateString(node.nodeValue);if(next!==node.nodeValue)node.nodeValue=next;return;
    }
    if(node.nodeType!==Node.ELEMENT_NODE)return;
    const el=node;if(["SCRIPT","STYLE","NOSCRIPT"].includes(el.tagName))return;
    for(const attr of ["placeholder","title","aria-label","alt"]){if(el.hasAttribute(attr)){const old=el.getAttribute(attr),next=translateString(old);if(next!==old)el.setAttribute(attr,next)}}
    if(el.tagName==="A"&&el.hasAttribute("href")){const old=el.getAttribute("href"),next=rewriteUrl(old);if(next&&next!==old)el.setAttribute("href",next)}
    if(el.tagName==="IMG")rewriteQr(el);
    for(const child of el.childNodes)translateNode(child);
  }
  function switcher(){
    if(document.getElementById("digiyResaLangSwitcher"))return;
    const box=document.createElement("div");box.id="digiyResaLangSwitcher";box.setAttribute("aria-label","Langue RESA");
    box.innerHTML=SUPPORTED.map(code=>`<button type="button" data-resa-lang="${code}" aria-pressed="${code===lang}">${FLAGS[code]}<span>${code.toUpperCase()}</span></button>`).join("");
    const style=document.createElement("style");style.textContent=`
      #digiyResaLangSwitcher{position:fixed;z-index:2147483000;top:max(8px,env(safe-area-inset-top));right:8px;display:flex;gap:3px;flex-wrap:wrap;justify-content:flex-end;max-width:min(340px,calc(100vw - 16px));padding:5px;border:1px solid rgba(250,204,21,.45);border-radius:15px;background:rgba(6,27,20,.94);box-shadow:0 10px 30px rgba(0,0,0,.28);backdrop-filter:blur(10px)}
      #digiyResaLangSwitcher button{min-width:39px;min-height:36px;padding:3px 6px;border:0;border-radius:10px;background:transparent;color:#ecfdf5;font:800 11px system-ui;display:grid;place-items:center;gap:1px;cursor:pointer}
      #digiyResaLangSwitcher button[aria-pressed="true"]{background:linear-gradient(135deg,#facc15,#f59e0b);color:#111}#digiyResaLangSwitcher button span{font-size:9px;line-height:1}
      [dir="rtl"] #digiyResaLangSwitcher{right:auto;left:8px}@media(max-width:520px){#digiyResaLangSwitcher{top:auto;bottom:max(76px,calc(8px + env(safe-area-inset-bottom)))}}
    `;
    document.head.appendChild(style);document.body.appendChild(box);
    box.addEventListener("click",event=>{const btn=event.target.closest("[data-resa-lang]");if(!btn)return;const next=btn.dataset.resaLang;if(!SUPPORTED.includes(next))return;try{localStorage.setItem("digiy-resa-lang",next);localStorage.setItem("digiy-lang",next)}catch(_){}const u=new URL(location.href);u.searchParams.set("lang",next);location.href=u.toString()});
  }
  const nativeOpen=window.open?window.open.bind(window):null;
  if(nativeOpen)window.open=function(url,target,features){return nativeOpen(rewriteUrl(url),target,features)};
  document.addEventListener("click",event=>{const a=event.target.closest?.("a[href]");if(a){const old=a.getAttribute("href"),next=rewriteUrl(old);if(next&&next!==old)a.setAttribute("href",next)}},true);
  let scheduled=false;
  const observer=new MutationObserver(records=>{if(scheduled)return;scheduled=true;requestAnimationFrame(()=>{scheduled=false;for(const record of records){if(record.type==="characterData")translateNode(record.target);for(const node of record.addedNodes||[])translateNode(node);if(record.type==="attributes")translateNode(record.target)}})});
  function start(){
    switcher();if(lang!=="fr"){document.title=translateString(document.title);translateNode(document.body)}else{document.querySelectorAll("a[href]").forEach(a=>a.setAttribute("href",rewriteUrl(a.getAttribute("href"))));document.querySelectorAll('img[src*="api.qrserver.com"]').forEach(rewriteQr)}
    observer.observe(document.documentElement,{subtree:true,childList:true,characterData:true,attributes:true,attributeFilter:["href","src","placeholder","title","aria-label","alt"]});
    setInterval(()=>{document.querySelectorAll("a[href]").forEach(a=>{const old=a.getAttribute("href"),next=rewriteUrl(old);if(next&&next!==old)a.setAttribute("href",next)});document.querySelectorAll('img[src*="api.qrserver.com"]').forEach(rewriteQr);if(lang!=="fr")translateNode(document.body)},1800);
  }
  if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",start,{once:true});else start();
})();