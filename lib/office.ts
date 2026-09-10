import {courseGroups,emptyRegistration,validatePersonal,type Registration,type Documents} from './registration';

export type Course={id:string;name:string;category:string;duration:string;hours:string;price:string;active:boolean};
export type Student=Registration & {id:string};
export type Entry={id:string;studentId:string;courseId:string;requestedCourse?:string;period:string;startDate:string;date:string;status:'Pendente'|'Confirmada'|'Rejeitada';reference:string;reason:string;documents:{photo:boolean;identity:boolean;payment:boolean};attachments?:Documents;history:{action:string;actor:string;date:string}[]};
export type Office={students:Student[];courses:Course[];entries:Entry[]};
export const normalize=(s:string)=>s.normalize('NFD').replace(/[\u0300-\u036f\s-]/g,'').toLowerCase();
export function initialOffice():Office{
 const courses=courseGroups.flatMap((g,gi)=>g.courses.map((name,i)=>({id:`c${gi}-${i}`,name,category:g.name,duration:'',hours:'',price:'',active:true})));
 const names=['Ana Manuel','João Cassoma','Maria Francisco','Pedro Neto','Helena José','Carlos Mateus'];
 const students=names.map((name,i)=>({...emptyRegistration,id:`s${i}`,name,birthDate:`199${i}-03-12`,gender:i%2?'Masculino':'Feminino',nationality:'Angolana',documentNumber:`DEMO${10001+i}`,phone:`90000000${i}`,address:'Morada fictícia · Luanda'}));
 const plans=[['s0','c0-0','Manhã'],['s1','c3-7','Tarde'],['s2','c0-1','Noite'],['s3','c1-1','Manhã'],['s0','c1-1','Fim de semana'],['s4','','Tarde'],['s5','c2-0','Manhã'],['s1','c3-1','Noite']];
 const entries:Entry[]=plans.map(([studentId,courseId,period],i)=>({id:`PRE-DEMO-${String(i+1).padStart(3,'0')}`,studentId,courseId,requestedCourse:!courseId?'Soldadura industrial':undefined,period,startDate:i===1||i===3?'2026-09-07':'2026-10-05',date:`2026-09-0${i+1}T09:00:00`,status:i===1||i===3?'Confirmada':i===6?'Rejeitada':'Pendente',reference:i===1||i===3?`MAT-DEMO-${i+1}`:'',reason:i===6?'Documento de identificação ilegível.':'',documents:{photo:true,identity:true,payment:true},history:[{action:'Pré-inscrição recebida (exemplo)',actor:'Formulário demonstrativo',date:`2026-09-0${i+1}T09:00:00`}]}));
 return {students,courses,entries};
}
export function studentErrors(student:Student,students:Student[]){const errors=validatePersonal(student);if(students.some(s=>s.id!==student.id&&normalize(s.documentNumber)===normalize(student.documentNumber)))errors.documentNumber='Já existe um aluno com este BI/Passaporte. Abre a ficha existente.';return errors;}
export function courseErrors(course:Course,courses:Course[]){const e:Record<string,string>={};if(course.name.trim().length<3||course.name.trim().length>150)e.name='Indica um nome com 3 a 150 caracteres.';if(courses.some(c=>c.id!==course.id&&normalize(c.name)===normalize(course.name)))e.name='Já existe um curso com este nome.';if(!courseGroups.some(g=>g.name===course.category))e.category='Seleciona uma categoria.';if(course.duration.trim().length<2||course.duration.length>80)e.duration='Indica a duração, por exemplo 3 meses.';if(!/^\d+$/.test(course.hours)||Number(course.hours)<1||Number(course.hours)>10000)e.hours='Indica uma carga horária entre 1 e 10 000 horas.';if(!/^\d+(\.\d{1,2})?$/.test(course.price)||Number(course.price)>100000000)e.price='Indica um preço válido em AOA, com até duas casas decimais.';return e;}
export function decideEntry(state:Office,id:string,decision:'Confirmada'|'Rejeitada',reason:string,actor:string,date:string):Office{
 const entry=state.entries.find(e=>e.id===id);if(!entry||entry.status!=='Pendente')throw new Error('Esta inscrição já foi analisada.');
 if(!['Administrador','Secretaria'].includes(actor))throw new Error('Seleciona o perfil de Secretaria ou Administrador.');
 if(decision==='Rejeitada'&&reason.trim().length<5)throw new Error('Indica o motivo da rejeição (pelo menos 5 caracteres).');
 if(decision==='Confirmada'){
  if(!Object.values(entry.documents).every(Boolean))throw new Error('É necessário conferir os três documentos.');
  if(!state.courses.some(c=>c.id===entry.courseId&&c.active))throw new Error('Associa um curso ativo antes de confirmar.');
  if(state.entries.some(e=>e.id!==id&&e.studentId===entry.studentId&&e.courseId===entry.courseId&&e.period===entry.period&&e.status==='Confirmada'))throw new Error('Este aluno já tem uma inscrição confirmada neste curso e período.');
 }
 return {...state,entries:state.entries.map(e=>e.id===id?{...e,status:decision,reason:decision==='Rejeitada'?reason.trim():'',reference:decision==='Confirmada'?`MAT-DEMO-${e.id.replace('PRE-DEMO-','')}`:'',history:[...e.history,{action:decision==='Confirmada'?'Confirmação simulada':`Rejeição simulada: ${reason.trim()}`,actor,date}]}:e)};
}
