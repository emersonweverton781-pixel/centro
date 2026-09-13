import {createClient} from 'npm:@supabase/supabase-js@2.99.2';
const headers={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Content-Type':'application/json'};
const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers});
Deno.serve(async req=>{if(req.method==='OPTIONS')return new Response(null,{headers});if(req.method!=='POST')return reply({error:'Método inválido'},405);try{
 const authorization=req.headers.get('authorization')||'';
 const caller=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_ANON_KEY')!,{global:{headers:{Authorization:authorization}}});
 const {data:{user},error}=await caller.auth.getUser();if(error||!user)return reply({error:'Inicie sessão.'},401);
 const role=await caller.rpc('centro_role');if(role.data!=='Administrador')return reply({error:'Acesso reservado ao Administrador.'},403);
 const {email}=await req.json();if(typeof email!=='string')return reply({error:'Email inválido'},400);
 const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
 const access=await admin.from('centro_access').select('email').eq('email',email.toLowerCase()).eq('active',true).maybeSingle();if(!access.data)return reply({error:'Autorize primeiro o acesso deste email.'},400);
 const options={redirectTo:'https://beza-inovacoes-centro.wbmsmarttech.chatgpt.site/?recuperar=1'};
 let result=await admin.auth.admin.generateLink({type:'invite',email,options});
 if(result.error?.code==='email_exists'||result.error?.message.toLowerCase().includes('already'))result=await admin.auth.admin.generateLink({type:'recovery',email,options});
 if(result.error)return reply({error:'Não foi possível gerar o link. Tente novamente.'},400);
 return reply({url:result.data.properties.action_link});
 }catch{return reply({error:'Não foi possível preparar o acesso.'},400);}});
