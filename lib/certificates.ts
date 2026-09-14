import type {DocumentData} from './documents';
export type CertificatePolicy={minFrequency:number;minGrade:number;confirmed:boolean;confirmedAt:string|null};
export type CertificateCheck={reasons:string[];name:string;course:string;hours:string;duration:string;cohort:string;startDate:string;endDate:string;matricula:string;frequency:number|null;average:number|null;minFrequency:number;minGrade:number};
export type IssuedCertificate=Omit<CertificateCheck,'reasons'|'frequency'|'average'>&{entryId:string;reference:string;token:string;issued:string;status:'Concluído';frequency:number;average:number};
export type CertificateListing={policy:CertificatePolicy;certificates:IssuedCertificate[]};
export function certificateDocument(c:IssuedCertificate):DocumentData{
 const date=(value:string)=>new Date(value.slice(0,10)+'T12:00:00').toLocaleDateString('pt-PT');
 return {kind:'Certificado',official:true,verificationToken:c.token,reference:c.reference,name:c.name,course:c.course,issued:date(c.issued),rows:[['Duração e carga horária',`${c.duration} · ${c.hours} horas`],['Período da formação',`${date(c.startDate)} a ${date(c.endDate)}`],['Frequência e média',`${c.frequency.toFixed(2)}% · ${c.average.toFixed(2)}/20`],['Critérios de conclusão',`${c.minFrequency}% de presença e ${c.minGrade}/20 de média`],['Matrícula',c.matricula]],statement:'A BEZA INOVAÇÕES certifica que o formando acima identificado concluiu esta formação, cumprindo os critérios de frequência e aproveitamento confirmados pelo centro.'};
}
