import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import ts from 'typescript';
const js=ts.transpileModule(await readFile(new URL('../lib/enrolment-document.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {approvedDocument,whatsappURL}=await import('data:text/javascript;base64,'+Buffer.from(js).toString('base64'));
test('approved PDF uses issued snapshot and opaque verification token',()=>{
 const d=approvedDocument({reference:'MAT-2026-000001',name:'Ana',course:'Curso',period:'Manhã',startDate:'2026-12-01',issued:'2026-09-13T10:00:00Z',token:'a6c12113-df77-4406-a0ad-9e32f8826b75'});
 assert.equal(d.official,true);assert.equal(d.reference,'MAT-2026-000001');assert.equal(d.verificationToken,'a6c12113-df77-4406-a0ad-9e32f8826b75');assert.equal(d.issued,'13/09/2026');assert.match(d.statement,/confirmada/);
});
test('WhatsApp normalises Angola and international numbers and encodes message',()=>{
 assert.equal(whatsappURL('947 968 650','Olá & sim?'),'https://wa.me/244947968650?text=Ol%C3%A1%20%26%20sim%3F');
 assert.equal(whatsappURL('+351 920 244 269','Teste'),'https://wa.me/351920244269?text=Teste');
 assert.equal(whatsappURL('00351 920244269','Teste'),'https://wa.me/351920244269?text=Teste');
 assert.equal(whatsappURL('123','Teste'),null);assert.equal(whatsappURL('javascript:alert(1)','Teste'),null);
});
