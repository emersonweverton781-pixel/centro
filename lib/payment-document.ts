import type {DocumentData} from './documents';
import type {Office} from './office';
import {formatMoney,type Finance} from './finance';
export type PaymentDocument={reference:string;token:string;name:string;course:string;matricula:string;kind:string;month:string;amount:number;paymentDate:string;method:string;movementReference:string;issued:string;voidReason:string;voidAt:string|null};
export function paymentDocument(p:PaymentDocument):DocumentData{
 const date=(v:string)=>new Date(v.slice(0,10)+'T12:00:00').toLocaleDateString('pt-PT');
 return {kind:'Pagamento',official:true,voided:!!p.voidReason,verificationToken:p.token,reference:p.reference,name:p.name,course:p.course,issued:date(p.issued),rows:[['Matrícula',p.matricula],['Cobrança',p.kind+(p.month?' · '+p.month:'')],['Valor registado',formatMoney(p.amount)],['Data do pagamento',date(p.paymentDate)],['Método',p.method],['Referência do movimento',p.movementReference],...(p.voidReason?[['Motivo do estorno',p.voidReason] as [string,string]]:[])],statement:p.voidReason?'ESTORNADO — este registo deixou de contar como pagamento. O documento é conservado apenas para histórico.':'Comprovativo interno do pagamento registado pelo centro. Consulte o QR para verificar o estado atual deste registo.'};
}
export function studentLedger(state:Finance,office:Office,studentId:string){
 const ids=new Set(office.entries.filter(e=>e.studentId===studentId).map(e=>e.id));
 const charges=state.charges.filter(c=>ids.has(c.entryId));const chargeIds=new Set(charges.map(c=>c.id));
 const payments=state.payments.filter(p=>chargeIds.has(p.chargeId)).slice().sort((a,b)=>b.date.localeCompare(a.date));
 const charged=charges.reduce((sum,c)=>sum+c.amount,0),received=payments.filter(p=>!p.voidReason).reduce((sum,p)=>sum+p.amount,0);
 return {charges,payments,charged,received,balance:charged-received};
}
