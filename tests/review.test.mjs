import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import ts from 'typescript';
async function source(path,replacements={}){let js=ts.transpileModule(await readFile(new URL(path,import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText;for(const [key,value] of Object.entries(replacements))js=js.replaceAll("'"+key+"'",JSON.stringify(value));return 'data:text/javascript;base64,'+Buffer.from(js).toString('base64');}
const academicURL=await source('../lib/academic.ts');
const {initialAcademic,cohortErrors,assignEntry,saveSession,saveAssessment,progress}=await import(academicURL);
const {initialOffice,decideEntry}=await import(await source('../lib/office.ts',{'./registration':new URL('../lib/registration.ts',import.meta.url).href}));
const {initialFinance,addCharge,addPayment,voidPayment,balance,issueCertificate,eligibility}=await import(await source('../lib/finance.ts',{'./academic':academicURL}));
test('confirmed registration travels through class, finance and certificate with the same student',()=>{
 let o=initialOffice(),a=initialAcademic(),f=initialFinance();const id='PRE-DEMO-001';
 o=decideEntry(o,id,'Confirmada','','Secretaria','2026-09-10T10:00:00');
 const e=o.entries.find(e=>e.id===id),course=o.courses.find(c=>c.id===e.courseId);course.duration='2 meses';course.hours='40';
 a.cohorts.push({id:'review',name:'Secretariado revisão',courseId:e.courseId,period:e.period,start:'2026-09-07',end:'2026-11-30',days:[4],from:'11:00',to:'13:00',room:'Sala 03',trainerId:'f1'});
 assert.deepEqual(cohortErrors(a.cohorts.at(-1),a,o),{});
 a=assignEntry(a,o,id,'review');
 a=saveSession(a,o,{cohortId:'review',date:'2026-09-10',marks:{[id]:'Presente'}},'f1','2026-09-10');
 a=saveAssessment(a,o,{id:'review-grade',cohortId:'review',name:'Avaliação final',date:'2026-09-10',scores:{[id]:18}},'f1','2026-09-10');
 assert.equal(progress(a,e).average,18);
 f=addCharge(f,o,{id:'review-charge',entryId:id,kind:'Inscrição',month:'',amount:1500000,due:'2026-09-10'},'Financeiro');
 f=addPayment(f,{id:'review-payment',chargeId:'review-charge',amount:1500000,date:'2026-09-10',method:'Numerário',reference:'REVIEW-001',actor:'',voidReason:''},'Financeiro','2026-09-10');
 assert.equal(balance(f,f.charges.at(-1)),0);
 f=issueCertificate(f,o,a,id,true,'Secretaria','2026-09-10');
 assert.equal(f.certificates.at(-1).name,o.students.find(s=>s.id===e.studentId).name);
 f=voidPayment(f,'review-payment','Lançamento incorreto','Financeiro');
 assert.equal(balance(f,f.charges.at(-1)),1500000);
 assert.equal(f.certificates.at(-1).average,18);
});
test('deactivating a course preserves editing an existing class but blocks new classes',()=>{
 const o=initialOffice(),a=initialAcademic(),c=a.cohorts[0];o.courses.find(x=>x.id===c.courseId).active=false;
 assert.deepEqual(cohortErrors({...c,room:'Sala 04'},a,o),{});
 assert.ok(cohortErrors({...c,id:'new',name:'Outra turma',from:'11:00',to:'13:00'},a,o).courseId);
});
test('rounded attendance must not qualify a student below the certificate threshold',()=>{
 const o=initialOffice(),a=initialAcademic(),f=initialFinance(),id='PRE-DEMO-004';
 o.courses.find(c=>c.id==='c1-1').hours='40';o.courses.find(c=>c.id==='c1-1').duration='2 meses';
 a.sessions=Array.from({length:99},(_,i)=>({cohortId:'t1',date:String(i),marks:{[id]:i<74?'Presente':'Falta'}}));
 assert.equal(progress(a,o.entries.find(e=>e.id===id)).percent,75);
 assert.ok(eligibility(f,o,a,id).reasons.some(r=>r.includes('Frequência mínima')));
});

