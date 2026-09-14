import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import ts from 'typescript';
const js=ts.transpileModule(await readFile(new URL('../lib/certificates.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {certificateDocument}=await import('data:text/javascript;base64,'+Buffer.from(js).toString('base64'));
test('certificate PDF uses issued data, criteria, date and verification token',()=>{
 const c={reference:'CERT-2026-000007',token:'a6c12113-df77-4406-a0ad-9e32f8826b75',name:'Ana',course:'Curso',issued:'2026-09-14T23:59:00Z',startDate:'2026-07-01',endDate:'2026-08-31',hours:'80',duration:'2 meses',frequency:95,average:16.5,minFrequency:80,minGrade:12,matricula:'MAT-2026-000003'};
 const d=certificateDocument(c);
 assert.equal(d.official,true);assert.equal(d.kind,'Certificado');assert.equal(d.reference,c.reference);assert.equal(d.verificationToken,c.token);assert.equal(d.issued,'14/09/2026');
 assert.deepEqual(d.rows.find(r=>r[0]==='Critérios de conclusão'),['Critérios de conclusão','80% de presença e 12/20 de média']);
 assert.deepEqual(d.rows.find(r=>r[0]==='Frequência e média'),['Frequência e média','95.00% · 16.50/20']);
 assert.match(d.statement,/concluiu/);assert.doesNotMatch(d.statement,/simulação|fictício/);
});
