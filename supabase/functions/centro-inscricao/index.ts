import {createClient} from 'npm:@supabase/supabase-js@2.99.2';
import {validatePersonal,validateCourse,validateFile,type Registration,type DocumentKind} from '../../../lib/registration.ts';
const headers={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Content-Type':'application/json'};
const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers});
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response(null,{headers});
 if(req.method!=='POST')return reply({error:'Método não permitido.'},405);
 if(Number(req.headers.get('content-length'))>16*1024*1024)return reply({error:'Limite de ficheiros excedido.'},413);
 const client=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
 const uploaded:string[]=[];let committing=false;
 try{
  const ip=req.headers.get('x-forwarded-for')?.split(',')[0]||'unknown';const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(ip)))).map(b=>b.toString(16).padStart(2,'0')).join('');const limit=await client.rpc('centro_intake_check',{p_key:hash});if(limit.error||!limit.data)return reply({error:'Limite temporário de envios. Tente mais tarde ou contacte a Secretaria.'},429);const form=await req.formData();const person=JSON.parse(String(form.get('person'))) as Registration;const id=String(form.get('requestId'));
  if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id))return reply({error:'Pedido inválido.'},400);
  const errors={...validatePersonal(person),...validateCourse({...person,course:'Outro',otherCourse:person.course==='Outro'?person.otherCourse:person.course})};if(Object.keys(errors).length)return reply({error:Object.values(errors)[0]},400);
  const files={} as Record<DocumentKind,File>;for(const kind of ['photo','identity','payment'] as DocumentKind[]){const file=form.get(kind);if(!(file instanceof File))return reply({error:'Fotografia, BI/Passaporte e comprovativo de pagamento são obrigatórios.'},400);const error=await validateFile(file,kind);if(error)return reply({error},400);files[kind]=file;}
  const paths:Record<string,string>={};const folder=crypto.randomUUID();
  for(const [kind,file] of Object.entries(files)){const path=folder+'/'+kind+'.'+file.name.split('.').pop()!.toLowerCase();const {error}=await client.storage.from('centro-documentos').upload(path,file,{contentType:file.type||'application/octet-stream',upsert:false});if(error)throw error;uploaded.push(path);paths[kind]=path;}
  committing=true;const {data,error}=await client.rpc('centro_receive',{p_id:id,p_person:person,p_paths:paths});if(error){if(error.code)committing=false;throw error;}
  return reply({reference:data,status:'Pendente'});
 }catch(e){if(uploaded.length&&!committing)await client.storage.from('centro-documentos').remove(uploaded);return reply({error:e instanceof Error?e.message:'Não foi possível guardar a inscrição. Tente novamente.'},400);}
});
