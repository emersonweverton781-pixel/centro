export const courseGroups = [
  { name: 'Administrativos', courses: ['Secretariado Executivo e Informatizado com IA', 'Gestão de Recursos Humanos', 'Gestão e Administração de Empresas', 'Higiene e Segurança no Trabalho', 'Operador(a) de Caixa e Técnicas de Vendas', 'Contabilidade Júnior e Sénior', 'Marketing Para Empresas e Pessoal', 'Fiscalidade'] },
  { name: 'Tecnologia', courses: ['Multimídia com IA (Som, Imagem, Áudio)', 'Informática com Inteligência Artificial', 'Marketing Digital e Design Gráfico com IA'] },
  { name: 'Máquinas', courses: ['Empilhadeira', 'Grua Móvel + Empilhadeira', 'Retroescavadeira + Empilhadeira', 'Porta Contentores + Empilhadeira', 'Escavadeira Hidráulica + Empilhadeira', 'Pá Carregadeira + Empilhadeira'] },
  { name: 'Construção', courses: ['SketchUp', 'AutoCAD', 'ArchiCAD', 'Drywall', 'Hidráulica e Canalização', 'Carpintaria', 'Montagem e Manutenção de AC', 'Eletricidade Baixa e Média Tensão'] },
];
export const periods = ['Manhã', 'Tarde', 'Noite', 'Fim de semana'];
export const genders = ['Feminino', 'Masculino', 'Outro', 'Prefiro não indicar'];
export type Registration = { name: string; birthDate: string; gender: string; nationality: string; documentType: string; documentNumber: string; phone: string; address: string; course: string; otherCourse: string; period: string; startDate: string };
export const emptyRegistration: Registration = { name: '', birthDate: '', gender: '', nationality: '', documentType: 'BI', documentNumber: '', phone: '', address: '', course: '', otherCourse: '', period: '', startDate: '' };
export type DocumentKind = 'photo' | 'identity' | 'payment';
export type Documents = Record<DocumentKind, File | null>;
export type Errors = Partial<Record<keyof Registration | DocumentKind | 'review', string>>;
export const MAX_FILE_SIZE = 5 * 1024 * 1024;
export function todayISO(date = new Date()) { return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`; }
function validDate(value: string) { if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false; const d = new Date(value+'T12:00:00Z'); return Number.isFinite(d.getTime()) && d.toISOString().slice(0,10) === value; }
export function validatePersonal(data: Registration, today = todayISO()): Errors {
  const e: Errors = {};
  if (data.name.trim().length < 3 || data.name.trim().length > 150 || !/\p{L}/u.test(data.name)) e.name = 'Indica o teu nome completo (3 a 150 caracteres).';
  if (!validDate(data.birthDate) || data.birthDate >= today) e.birthDate = 'Indica uma data de nascimento válida, anterior a hoje.';
  if (!genders.includes(data.gender)) e.gender = 'Seleciona uma opção.';
  if (data.nationality.trim().length < 2 || data.nationality.trim().length > 80) e.nationality = 'Indica a tua nacionalidade.';
  if (!['BI','Passaporte'].includes(data.documentType)) e.documentType = 'Seleciona BI ou Passaporte.';
  const doc = data.documentNumber.replace(/[\s-]/g,'');
  if (!/^[a-zA-Z0-9]{5,30}$/.test(doc)) e.documentNumber = 'Indica um número de documento válido, com 5 a 30 letras ou números.';
  const phone = data.phone.replace(/[\s()-]/g,'');
  if (!/^\+?\d{9,15}$/.test(phone)) e.phone = 'Indica entre 9 e 15 algarismos, incluindo o indicativo se necessário.';
  if (data.address.trim().length < 5 || data.address.trim().length > 250) e.address = 'Indica a tua morada atual (5 a 250 caracteres).';
  return e;
}
export function validateCourse(data: Registration, today = todayISO()): Errors {
  const e: Errors = {};
  if (!courseGroups.some(g => g.courses.includes(data.course)) && data.course !== 'Outro') e.course = 'Seleciona o curso pretendido.';
  if (data.course === 'Outro' && (data.otherCourse.trim().length < 3 || data.otherCourse.trim().length > 150)) e.otherCourse = 'Indica o nome do curso pretendido (3 a 150 caracteres).';
  if (!periods.includes(data.period)) e.period = 'Seleciona o período que preferes.';
  if (!validDate(data.startDate) || data.startDate < today) e.startDate = 'Escolhe hoje ou uma data futura.';
  return e;
}
export function validateDocuments(files: Documents): Errors {
  const e: Errors = {};
  if (!files.photo) e.photo = 'Adiciona uma fotografia ou utiliza a câmara.';
  if (!files.identity) e.identity = 'Adiciona uma cópia do BI ou Passaporte.';
  if (!files.payment) e.payment = 'O comprovativo de pagamento é obrigatório.';
  return e;
}
export async function validateFile(file: File, kind: DocumentKind): Promise<string | null> {
  if (!file.size) return 'O ficheiro está vazio. Escolhe outro ficheiro.';
  if (file.size > MAX_FILE_SIZE) return 'O ficheiro ultrapassa o limite de 5 MB.';
  const extension = file.name.split('.').pop()?.toLowerCase();
  const allowed = kind === 'photo' ? ['jpg','jpeg','png'] : ['jpg','jpeg','png','pdf'];
  if (!extension || !allowed.includes(extension)) return kind === 'photo' ? 'A fotografia deve estar em JPG ou PNG.' : 'Escolhe um ficheiro JPG, PNG ou PDF.';
  const bytes = new Uint8Array(await file.slice(0,8).arrayBuffer());
  const png = [137,80,78,71,13,10,26,10].every((v,i) => bytes[i] === v);
  const jpg = bytes[0]===255 && bytes[1]===216 && bytes[2]===255;
  const pdf = [37,80,68,70,45].every((v,i)=>bytes[i]===v);
  const format = png ? 'png' : jpg ? 'jpg' : pdf ? 'pdf' : '';
  if (!format || (extension==='jpeg'?'jpg':extension)!==format) return 'O conteúdo não corresponde ao formato indicado. Escolhe um ficheiro válido.';
  if (file.type && file.type !== ({png:'image/png',jpg:'image/jpeg',pdf:'application/pdf'} as Record<string,string>)[format]) return 'O tipo de ficheiro não corresponde ao conteúdo.';
  return null;
}
export function formatDate(value: string) { if (!value) return 'Por indicar'; return value.split('-').reverse().join('/'); }
export function displayCourse(data: Registration) { return data.course === 'Outro' ? data.otherCourse.trim() : data.course; }
