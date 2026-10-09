'use strict';
// Run only inside disposable PostgreSQL CI; no service account access.
const {execFile}=require('node:child_process');
const {promisify}=require('node:util');
const assert=require('node:assert/strict');
const run=promisify(execFile);
const sql=(slot,token,phone)=>"SELECT public.digiy_resa_universal_request_v0("+
 "'resa-owner-a',"+
 "'"+slot+"'::uuid,"+
 "'aaaa0000-0000-4000-8000-000000000001'::uuid,"+
 "'Client concurrence',"+
 "'"+phone+"',"+
 "'"+token+"'::uuid)::text";
async function query(s){
 const {stdout}=await run('psql',['-X','-A','-t','-v','ON_ERROR_STOP=1','-c',s],{timeout:20000});
 return stdout.trim();
}
(async()=>{
 if(process.env.PGDATABASE!=='digiy_appointments_test')throw Error('Run ONLY on isolated digiy_appointments_test');
 const slots=[
  'a0000000-0000-4000-8000-000000002200',
  'a0000000-0000-4000-8000-000000002230'
 ];
 const requestIds=[
  'cc000000-0000-4000-8000-000000000001',
  'cc000000-0000-4000-8000-000000000002'
 ];
 // Launch two separate PostgreSQL client connections without awaiting either first.
 const [a,b]=await Promise.all([
  query(sql(slots[0],requestIds[0],'221770000021')),
  query(sql(slots[1],requestIds[1],'221770000022'))
 ]);
 const results=[JSON.parse(a),JSON.parse(b)];
 const winners=results.filter(x=>x.ok===true),losers=results.filter(x=>x.ok===false);
 assert.equal(winners.length,1,'capacity-1 overlapping slots cannot both book');
 assert.equal(losers.length,1,'exactly one losing transaction');
 assert.equal(losers[0].error,'slot_unavailable');
 const count=Number(await query(
  "SELECT count(*) FROM public.digiy_resa_bookings WHERE client_request_id IN ("+
  "'cc000000-0000-4000-8000-000000000001'::uuid,"+
  "'cc000000-0000-4000-8000-000000000002'::uuid)"));
 assert.equal(count,1,'database must contain exactly one winner');
 console.log('PASS: simultaneous PostgreSQL clients on overlapping real slots => 1 pending request and 1 refusal');
})().catch(e=>{console.error(e);process.exitCode=1});
