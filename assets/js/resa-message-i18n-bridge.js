(() => {
  "use strict";
  const DATA=window.DIGIY_RESA_I18N||{};
  const SUPPORTED=DATA.supported||["fr","en","es","de","it","nl","ar"];
  function lang(){
    try{
      const q=String(new URLSearchParams(location.search).get("lang")||"").toLowerCase();
      if(SUPPORTED.includes(q)) return q;
      const s=String(localStorage.getItem("digiy-resa-lang")||localStorage.getItem("digiy-lang")||"").toLowerCase();
      if(SUPPORTED.includes(s)) return s;
    }catch(_){}
    return "fr";
  }
  const current=lang();
  const T=(DATA.langs&&DATA.langs[current])||{};
  const exact=DATA.frToKey||{};
  const partial=Object.entries(DATA.partial||{}).sort((a,b)=>b[0].length-a[0].length);
  function one(value){
    const raw=String(value??"");
    if(current==="fr"||!raw.trim()) return raw;
    const compact=raw.replace(/\s+/g," ").trim();
    const key=exact[compact];
    if(key&&T[key]) return T[key];
    let out=compact;
    for(const [source,k] of partial){if(T[k]&&out.includes(source))out=out.split(source).join(T[k]);}
    return out;
  }
  window.DIGIY_RESA_TRANSLATE_MESSAGE=value=>String(value||"").split("\n").map(one).join("\n");
})();