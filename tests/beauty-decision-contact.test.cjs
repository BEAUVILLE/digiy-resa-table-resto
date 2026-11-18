'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const {buildDecisionLink}=require('../resa-beauty/decision-contact.js');
const root=path.resolve(__dirname,'..');
const owner=fs.readFileSync(path.join(root,'resa-beauty/gestion.html'),'utf8');
const client=fs.readFileSync(path.join(root,'resa-beauty/index.html'),'utf8');

test('confirmation: WhatsApp is only a prepared manual link to the client',()=>{
  const url=buildDecisionLink({phone:'+221 77 000 00 00',status:'confirmed',service:'Brushing',day:'2026-11-20',time:'15:30:00'});
  assert.ok(url);
  const u=new URL(url);
  assert.equal(u.hostname,'wa.me');
  assert.equal(u.pathname,'/221770000000');
  assert.match(u.searchParams.get('text'),/a confirmé votre rendez-vous/);
  assert.match(u.searchParams.get('text'),/Brushing · 2026-11-20 · 15:30/);
  assert.match(u.searchParams.get('text'),/0 % de commission/);
});

test('refus: client sees explicitly that the chosen slot was not accepted',()=>{
  const url=buildDecisionLink({phone:'221770000000',status:'cancelled',service:'Coiffure',day:'2026-11-21',time:'09:00'});
  assert.match(new URL(url).searchParams.get('text'),/ne peut pas accepter le créneau/);
  assert.match(new URL(url).searchParams.get('text'),/autre créneau/);
  assert.doesNotMatch(new URL(url).searchParams.get('text'),/a confirmé votre rendez-vous/);
});

test('pending and invalid numbers never create a decision link',()=>{
  for(const status of ['request','pending','done',null,'CONFIRMED']){
    assert.equal(buildDecisionLink({phone:'221770000000',status}),null);
  }
  for(const phone of ['','123','+221','123456789012345678901']){
    assert.equal(buildDecisionLink({phone,status:'confirmed'}),null);
  }
});

test('service text is encoded as text, not URL syntax',()=>{
  const u=new URL(buildDecisionLink({phone:'221770000000',status:'confirmed',service:'Coiffure & soin? #1\nTest'}));
  assert.equal(u.pathname,'/221770000000');
  assert.match(u.searchParams.get('text'),/Coiffure & soin\? #1 Test/);
  assert.equal(u.searchParams.has('service'),false);
});

test('owner only offers decision reply after status change, never auto-sends',()=>{
  assert.match(owner,/DIGIYBeautyContact\?\.buildDecisionLink/);
  assert.match(owner,/r\.status/);
  assert.match(owner,/>💬 Prévenir le client<\/a>/);
  assert.match(owner,/target="_blank" rel="noopener noreferrer"/);
  assert.match(owner,/aucun message n.est envoyé automatiquement/i);
  assert.doesNotMatch(owner,/window\.open\(|location\.assign\(/);
});

test('client receives accurate request, not automatic confirmation promise',()=>{
  assert.match(client,/Créneau bloqué en attente de décision/);
  assert.match(client,/aucune notification automatique/i);
  assert.match(client,/ENVOYER MA DEMANDE/);
  assert.match(client,/Demande TEST enregistrée/);
});
