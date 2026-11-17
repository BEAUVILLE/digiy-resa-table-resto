// DIGIY RÉSA MULTI · 10 langues sans changer le moteur ni les données personnelles.
const fs=require('fs'), assert=require('node:assert/strict');
const page=fs.readFileSync('index.html','utf8');
const buttons=[...page.matchAll(/data-lang="(fr|en|es|pt|it|de|nl|ar|wo|zh)"/g)].map(m=>m[1]);
const languages=['fr','en','es','pt','it','de','nl','ar','wo','zh'];
assert.equal(buttons.length,10,'10 boutons de langue attendus');
assert.deepEqual(new Set(buttons),new Set(languages));
const begin=page.indexOf('var T=');
assert.ok(begin>0);
const start=begin+'var T='.length;
const end=page.indexOf(';\nfunction ',start);
assert.ok(end>start,'fin du dictionnaire attendue');
const T=new Function('var T='+page.slice(start,end)+';return T')();
assert.deepEqual(new Set(Object.keys(T)),new Set(languages));
for(const lang of languages) {
  assert.deepEqual(new Set(Object.keys(T[lang])),new Set(Object.keys(T.fr)),'complet : '+lang);
  for(const [key,value] of Object.entries(T[lang]))assert.ok(value!==null&&value!==undefined&&value!=='','manque '+lang+'.'+key);
}
assert.notEqual(T.wo.title,T.fr.title);
assert.notEqual(T.zh.title,T.fr.title);
assert.ok(T.wo.rule.includes('du réservation'));
assert.ok(T.zh.rule.includes('不等于'));
assert.ok(page.includes("locURL.searchParams.set('lang',l)"));
assert.ok(page.includes('REAL.map'));
const scripts=page.split('<script').slice(1).map(x=>{const a=x.indexOf('>'),b=x.indexOf('</script>');return [x.slice(0,a),x.slice(a+1,b)]}).filter(x=>x[1].trim()&&!x[0].includes('application/ld+json'));
for(const m of scripts)new Function(m[1]);
console.log('DIGIY RÉSA MULTI: 10/10 langues, JS et doctrines contrôlés');
