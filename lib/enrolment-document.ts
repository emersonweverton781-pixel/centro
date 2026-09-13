import type {DocumentData} from './documents';
export type ApprovedDocument={reference:string;name:string;course:string;period:string;startDate:string;issued:string;token:string};
export type Verification=Pick<ApprovedDocument,'reference'|'course'|'period'|'issued'>&{status:'Confirmada'};
export function approvedDocument(d:ApprovedDocument):DocumentData {
 const date=(value:string)=>new Date(value.slice(0,10)+'T12:00:00').toLocaleDateString('pt-PT');
 return {kind:'Inscrição',official:true,verificationToken:d.token,reference:d.reference,name:d.name,course:d.course,issued:date(d.issued),rows:[['Matrícula',d.reference],['Período',d.period],['Início pretendido',date(d.startDate)]],statement:'A inscrição foi confirmada pela Secretaria. Apresente este comprovativo no arranque do curso. A data de início deverá ser confirmada com o centro.'};
}
export function whatsappURL(phone:string,message:string){
 let digits=phone.replace(/[\s()+.-]/g,'');
 if(digits.startsWith('00'))digits=digits.slice(2);
 if(/^9\d{8}$/.test(digits))digits='244'+digits;
 if(!/^[1-9]\d{7,14}$/.test(digits))return null;
 return 'https://wa.me/'+digits+'?text='+encodeURIComponent(message);
}
