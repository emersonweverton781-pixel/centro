import {normalize,studentErrors,type Office,type Student,type Entry} from './office';
import {periods,todayISO,validateDocuments,type Documents} from './registration';
import {validDate} from './academic';
export type EnrolmentDraft={student:Student;existing:boolean;courseId:string;period:string;startDate:string;files:Documents};
export function enrolmentErrors(state:Office,d:EnrolmentDraft,today=todayISO()){
 const errors:Record<string,string>={};
 if(d.existing){if(!state.students.some(s=>s.id===d.student.id))errors.student='Seleciona um aluno registado.';}
 else Object.assign(errors,studentErrors(d.student,state.students));
 const person=d.existing?state.students.find(s=>s.id===d.student.id):state.students.find(s=>normalize(s.documentNumber)===normalize(d.student.documentNumber));
 if(!d.existing&&person)errors.documentNumber='Este BI/Passaporte já está registado. Escolhe Aluno já registado para utilizar a ficha existente.';
 if(!state.courses.some(c=>c.id===d.courseId&&c.active))errors.course='Seleciona um curso ativo.';
 if(!periods.includes(d.period))errors.period='Seleciona um período.';
 if(!validDate(d.startDate)||d.startDate<today)errors.startDate='Escolhe hoje ou uma data futura para o início pretendido.';
 if(person&&state.entries.some(e=>e.studentId===person.id&&e.courseId===d.courseId&&e.period===d.period&&e.status!=='Rejeitada'))errors.duplicate='Este aluno já tem uma inscrição pendente ou confirmada neste curso e período.';
 Object.assign(errors,validateDocuments(d.files));return errors;
}
export function createOfficeEnrolment(state:Office,d:EnrolmentDraft,role:string,id:string,date:string):Office{
 if(!['Administrador','Secretaria'].includes(role))throw new Error('Apenas Administrador e Secretaria podem registar inscrições.');
 const errors=enrolmentErrors(state,d,date.slice(0,10));if(Object.keys(errors).length)throw new Error(Object.values(errors).join(' '));
 if(state.entries.some(e=>e.id===id)||(!d.existing&&state.students.some(s=>s.id===d.student.id)))throw new Error('Registo já criado.');
 const student=d.existing?state.students.find(s=>s.id===d.student.id)!:{...d.student,name:d.student.name.trim(),documentNumber:d.student.documentNumber.trim()};
 const entry:Entry={id,studentId:student.id,courseId:d.courseId,period:d.period,startDate:d.startDate,date,status:'Pendente',reference:'',reason:'',documents:{photo:true,identity:true,payment:true},attachments:{...d.files},history:[{action:'Inscrição criada no atendimento (demonstração)',actor:role,date}]};
 return {...state,students:d.existing?state.students:[...state.students,student],entries:[...state.entries,entry]};
}
