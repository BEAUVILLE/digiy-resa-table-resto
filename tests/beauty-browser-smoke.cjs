'use strict';
// Browser-backed client interaction test: no digiy-core access or real bookings.
const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const path=require('node:path');
(async()=>{
 const browser=await chromium.launch({headless:true});
 try{
  const page=await browser.newPage({viewport:{width:390,height:844},locale:'fr-FR',timezoneId:'Africa/Dakar'});
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  await page.route('https://cdn.jsdelivr.net/**',route=>route.fulfill({
   status:200,contentType:'application/javascript',body:'/* offline mocked Supabase */'
  }));
  const fake=[
   "window.__rpcCalls=[];window.__requestCount=0;",
   "window.supabase={createClient:()=>({rpc:async(name,args)=>{",
   "window.__rpcCalls.push({name,args});",
   "if(name==='digiy_beauty_public_profile_v1')return {data:[{slug:'test-resa-beauty-saly',display_name:'TEST BEAUTY SALY',availability_status:'available',city:'Saly',zone:'Petite Côte',services:[{name:'Brushing',price:8000,duration_min:45}]}],error:null};",
   "if(name==='digiy_beauty_public_slots_v2')return {data:[{id:args.p_day+'-slot-09',slot_time:'09:00:00',status:'available'},{id:args.p_day+'-slot-15',slot_time:'15:30:00',status:'available'}],error:null};",
   "if(name==='digiy_beauty_public_book_v1'){window.__requestCount++;return {data:[{booking_id:'fake-test-id',status:'request'}],error:null};}",
   "return {data:null,error:{message:'Unknown RPC '+name}};",
   "}})};"
  ].join('\n');
  await page.addInitScript({content:fake});
  await page.goto('file://'+path.resolve(__dirname,'..','resa-beauty','index.html')+'?slug=test-resa-beauty-saly',{waitUntil:'domcontentloaded'});
  await page.waitForSelector('#weekBoard [data-week-slot]',{timeout:12000});
  assert.equal(await page.locator('.weekcol').count(),7,'seven calendar days');
  assert.ok(await page.locator('#weekBoard [data-week-slot]').count()>=2,'clickable hours');
  const rangeBefore=await page.locator('#weekRange').textContent();
  await page.locator('#nextWeek').click();
  await page.waitForFunction(old=>document.querySelector('#weekRange').textContent!==old,rangeBefore);
  assert.equal(await page.locator('#prevWeek').isEnabled(),true,'can go back');
  await page.waitForSelector('#weekBoard [data-week-slot]');
  const slot=page.locator('#weekBoard [data-week-slot]').first();
  const id=await slot.getAttribute('data-week-slot'),day=await slot.getAttribute('data-week-day');
  await slot.click();
  await page.waitForFunction(()=>document.querySelector('#selectionInfo').textContent.includes('Horaire sélectionné'));
  assert.equal(await page.locator('#day').inputValue(),day);
  assert.equal(await page.locator('#slots .slot.active').count(),1,'selected hour visible in form');
  assert.equal(await page.locator('#slots .slot.active').getAttribute('data-slot'),id);
  await page.locator('#clientName').fill('CLIENT TEST');
  await page.locator('#clientWa').fill('221770000000');
  await page.locator('#service').selectOption('0');
  await page.locator('#book').click();
  await page.waitForFunction(()=>document.querySelector('#bookMsg').textContent.includes('Demande TEST enregistrée'));
  assert.equal(await page.evaluate(()=>window.__requestCount),1,'exactly one fake request');
  assert.match(await page.locator('#owner').getAttribute('href'),/acces-proprietaire\.html\?slug=test-resa-beauty-saly/);
  assert.deepEqual(errors,[],'no browser JS errors');
  console.log('PASS: Chromium mobile, calendar buttons, time choice, request, owner link');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
