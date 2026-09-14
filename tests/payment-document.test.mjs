import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import ts from 'typescript';
async function source(path,replacements={}){let js=ts.transpileModule(await readFile(new URL(path,import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText;for(const [key,value] of Object.entries(replacements))js=js.replaceAll("'"+key+"'",JSON.stringify(value));return 'data:text/javascript;base64,'+Buffer.from(js).toString('base64');}
const academic=await source('../lib/academic.ts');const finance=await source('../lib/finance.ts',{'./academic':academic});
const {studentLedger,paymentDocument}=await import(await source('../lib/payment-document.ts',{'./finance':finance}));
test('student ledger combines courses, partial payments and voids without including another student',()=>{
 const office={entries:[{id:'e1',studentId:'s1'},{id:'e2',studentId:'s1'},{id:'e3',studentId:'s2'}]};
 const state={charges:[{id:'c1',entryId:'e1',amount:10000},{id:'c2',entryId:'e2',amount:20000},{id:'c3',entryId:'e3',amount:90000}],payments:[{id:'p1',chargeId:'c1',amount:4000,date:'2026-09-01',voidReason:''},{id:'p2',chargeId:'c1',amount:6000,date:'2026-09-02',voidReason:'Correção'},{id:'p3',chargeId:'c2',amount:10000,date:'2026-09-03',voidReason:''},{id:'p4',chargeId:'c3',amount:90000,date:'2026-09-04',voidReason:''}]};
 const l=studentLedger(state,office,'s1');assert.equal(l.charged,30000);assert.equal(l.received,14000);assert.equal(l.balance,16000);assert.deepEqual(l.payments.map(p=>p.id),['p3','p2','p1']);assert.equal(studentLedger(state,office,'none').balance,0);
});
test('receipt and voided copy retain original amount and code while distinguishing their status',()=>{
 const p={reference:'PAG-2026-000001',token:'a6c12113-df77-4406-a0ad-9e32f8826b75',name:'Ana',course:'Curso',matricula:'MAT-2026-000001',kind:'Propina',month:'2026-09',amount:4000,paymentDate:'2026-09-01',method:'Numerário',movementReference:'ABC',issued:'2026-09-14T10:00:00Z',voidReason:'',voidAt:null};
 const active=paymentDocument(p),voided=paymentDocument({...p,voidReason:'Lançamento incorreto'});
 assert.equal(active.voided,false);assert.equal(voided.voided,true);assert.equal(voided.reference,active.reference);assert.equal(voided.verificationToken,active.verificationToken);assert.match(voided.statement,/ESTORNADO/);assert.deepEqual(voided.rows.find(r=>r[0]==='Valor registado'),active.rows.find(r=>r[0]==='Valor registado'));
});
