'use strict';
const {chromium}=require('playwright');
const fs=require('fs');
const path=require('path');
const assert=require('node:assert/strict');
const url='https://resa-table-resto.digiylyfe.com/resa-beauty/index.html?slug=test-resa-beauty-saly&check=client-readiness';
const html=fs.readFileSync(path.join(__dirname,'..','resa-beauty','index.html'),'utf8');
function msg(e){return String(e||'').slice(0,220).replace(/(?:sb_publishable_[a-zA-Z0-9_-]+|eyJ[a-zA-Z0-9_.-]+)/g,'[redacted]')}
(async()=>{
 const browser=await chromium.launch({headless:true});
 let failures=0;
 try{
  for(const mode of ['live','candidate']){
   const page=await browser.newPage({viewport:{width:390,height:844},locale:'fr-FR',timezoneId:'Africa/Dakar'});
   const network=[],errors=[];
   page.on('pageerror',e=>errors.push(msg(e.message)));
   page.on('requestfailed',request=>network.push({host:new URL(request.url()).host,error:msg(request.failure()?.errorText)}));
   page.on('response',res=>{if(res.status()>=400){let host;try{host=new URL(res.url()).host}catch{host='unknown'}network.push({host,status:res.status()})}});
   if(mode==='candidate'){
    await page.route('**/resa-beauty/index.html?*',route=>route.fulfill({status:200,contentType:'text/html; charset=utf-8',body:html}));
   }
   let result={mode};
   try{
    await page.goto(url,{waitUntil:'domcontentloaded',timeout:20000});
    await page.waitForFunction(()=>!document.querySelector('#name')?.textContent.includes('Chargement'),{timeout:18000});
    await page.waitForFunction(()=>document.querySelector('#calendarStatus')?.textContent!=='Lecture des disponibilités…'&&document.querySelector('#calendarStatus')?.textContent!=='Chargement du planning réel…',{timeout:18000});
    result.pageTitle=await page.locator('#name').textContent();
    result.calendar=await page.locator('#calendarStatus').textContent();
    result.days=await page.locator('.weekcol').count();
    result.clickableHours=await page.locator('[data-week-slot]').count();
    result.serviceOptions=await page.locator('#service option').count();
    result.weekNextEnabled=await page.locator('#nextWeek').isEnabled();
    if(result.clickableHours>0){
      const b=page.locator('[data-week-slot]').first();
      await b.click({timeout:5000});
      result.selection=await page.locator('#selectionInfo').textContent();
      result.selectedSlot=await page.locator('#slots .slot.active').count();
    }
    assert.ok(result.pageTitle.includes('BEAUTY'),'profile name');
    assert.equal(result.days,7,'seven day calendar');
    assert.ok(result.clickableHours>0,'available public times');
    assert.ok(result.serviceOptions>0,'services');
    assert.match(result.selection||'',/sélectionné/i,'hour is clickable');
    assert.equal(result.selectedSlot,1,'slot linked to form');
    assert.deepEqual(errors,[],'no browser JS exceptions');
    result.ok=true;
   }catch(e){result.ok=false;result.reason=msg(e.message);if(mode==='candidate')failures++;}
   result.errors=errors.slice(0,6);
   result.network=network.slice(0,8);
   console.log('BEAUTY_CLIENT_DIAGNOSTIC '+JSON.stringify(result));
   await page.close();
  }
 }finally{await browser.close()}
 if(failures)process.exitCode=1;
 else console.log('CANDIDATE_REAL_SUPABASE_PASS; baseline LIVE may still be an earlier deployment');
})().catch(e=>{console.error('BEAUTY_BROWSER_FATAL',msg(e.message));process.exitCode=1});
