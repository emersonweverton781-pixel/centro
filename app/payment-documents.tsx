'use client';
import {useState} from 'react';
import {Button} from '@/components/ui/button';
import {Select,SelectTrigger,SelectValue,SelectContent,SelectItem} from '@/components/ui/select';
import {rpc} from '@/lib/supabase';
import {paymentDocument,studentLedger,type PaymentDocument} from '@/lib/payment-document';
import type {DocumentData} from '@/lib/documents';
import type {Office} from '@/lib/office';
import {formatMoney,paid,balance,type Finance} from '@/lib/finance';
import DocumentViewer from './document-viewer';
export function PaymentDocumentButton({paymentId}:{paymentId:string}){
 const [document,setDocument]=useState<DocumentData|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState('');
 async function open(){setBusy(true);setError('');try{setDocument(paymentDocument(await rpc<PaymentDocument>('centro_payment_document',{p_payment:paymentId})));}catch(e){setError((e as Error).message);}finally{setBusy(false);}}
 return <><Button type="button" variant="outline" disabled={busy} onClick={open}>{busy?'A consultar…':'Comprovativo PDF'}</Button>{error&&<p role="alert" className="office-error">{error} Tente novamente.</p>}{document&&<DocumentViewer data={document} close={()=>setDocument(null)}/>}</>;
}
export function StudentLedger({office,state}:{office:Office;state:Finance}){
 const [studentId,setStudentId]=useState('');const ledger=studentLedger(state,office,studentId);
 const course=(entryId:string)=>office.courses.find(c=>c.id===office.entries.find(e=>e.id===entryId)?.courseId)?.name||'Curso';
 return <section className="office-surface" style={{padding:24}}><h2>Extrato por aluno</h2><p>Todas as cobranças e pagamentos do aluno, incluindo pagamentos parciais e estornos.</p><label className="office-filter"><span>Aluno</span><Select value={studentId||null} onValueChange={v=>{if(v)setStudentId(v);}}><SelectTrigger aria-label="Selecionar aluno para extrato"><SelectValue placeholder="Seleciona um aluno"/></SelectTrigger><SelectContent>{office.students.map(s=><SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}</SelectContent></Select></label>{studentId?<><div className="office-summary"><div><span>Total cobrado</span><strong>{formatMoney(ledger.charged)}</strong></div><div><span>Recebido</span><strong>{formatMoney(ledger.received)}</strong></div><div><span>Saldo em falta</span><strong>{formatMoney(ledger.balance)}</strong></div></div><h3>Cobranças</h3>{ledger.charges.length?ledger.charges.map(c=><article className="office-detail-section" key={c.id}><strong>{course(c.entryId)} · {c.kind}{c.month?' · '+c.month:''}</strong><p>Valor: {formatMoney(c.amount)} · Pago: {formatMoney(paid(state,c.id))} · Em falta: {formatMoney(balance(state,c))}</p></article>):<p>Não existem cobranças para este aluno.</p>}<h3>Histórico de pagamentos</h3>{ledger.payments.length?ledger.payments.map(p=><article className="office-detail-section" key={p.id}><strong>{new Date(p.date+'T12:00:00').toLocaleDateString('pt-PT')} · {formatMoney(p.amount)}</strong><p>{p.method} · {p.reference}</p><p className={p.voidReason?'office-error':''}>{p.voidReason?'Estornado: '+p.voidReason:'Registado'}</p><PaymentDocumentButton paymentId={p.id}/></article>):<p>Não existem pagamentos para este aluno.</p>}</>:<p>Selecione um aluno para consultar o extrato completo, sem os filtros de data e curso acima.</p>}</section>;
}
