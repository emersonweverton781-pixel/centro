begin;
create table public.centro_access(email text primary key check(email=lower(email)), name text not null, role text not null check(role in ('Administrador','Secretaria','Formador','Financeiro','Aluno')), person_id text, active boolean not null default true);
alter table public.centro_access enable row level security;
create table public.centro_state(section text primary key check(section in ('office','academic','finance')), data jsonb not null, version bigint not null default 0);
alter table public.centro_state enable row level security;
create table public.centro_audit(id bigint generated always as identity primary key, actor uuid, action text not null, created_at timestamptz not null default now());
alter table public.centro_audit enable row level security;
create function public.centro_role() returns text language sql stable security definer set search_path='' as $$
 select a.role from public.centro_access a join auth.users u on lower(u.email)=a.email where u.id=auth.uid() and u.email_confirmed_at is not null and a.active
$$;
create function public.centro_access_save(p_email text,p_name text,p_role text,p_person text,p_active boolean) returns void language plpgsql security definer set search_path='' as $$
begin
 if public.centro_role() is distinct from 'Administrador' then raise exception 'Acesso reservado ao Administrador.'; end if;
 if lower(p_email)=(select lower(email) from auth.users where id=auth.uid()) then raise exception 'Não pode alterar o próprio acesso.'; end if;
 if p_email !~ '^[^ @]+@[^ @]+\.[^ @]+$' or length(trim(p_name))<3 then raise exception 'Nome ou email inválido.'; end if;
 if p_role='Aluno' and not exists(select 1 from public.centro_state, jsonb_array_elements(data->'students') s where section='office' and s->>'id'=p_person) then raise exception 'Associe a ficha do aluno.'; end if;
 insert into public.centro_access values(lower(trim(p_email)),trim(p_name),p_role,nullif(p_person,''),p_active) on conflict(email) do update set name=excluded.name,role=excluded.role,person_id=excluded.person_id,active=excluded.active;
 insert into public.centro_audit(actor,action) values(auth.uid(),'Alterou acesso: '||lower(p_email));
end $$;
create function public.centro_access_list() returns setof public.centro_access language sql stable security definer set search_path='' as $$ select * from public.centro_access where public.centro_role()='Administrador' order by name $$;
create function public.centro_load() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare r text:=public.centro_role(); p public.centro_access; o jsonb; a jsonb; f jsonb; ids jsonb; cohorts jsonb;
begin
 if r is null then raise exception 'Este email ainda não tem acesso ativo. Contacte o Administrador.'; end if;
 select * into p from public.centro_access where email=(select lower(email) from auth.users where id=auth.uid());
 select data into o from public.centro_state where section='office'; select data into a from public.centro_state where section='academic'; select data into f from public.centro_state where section='finance';
 if r in ('Aluno','Formador') then
  if r='Aluno' then select coalesce(jsonb_agg(e->>'id'),'[]') into ids from jsonb_array_elements(o->'entries') e where e->>'studentId'=p.person_id;
  else select coalesce(jsonb_agg(e->>'id'),'[]') into ids from jsonb_array_elements(o->'entries') e where exists(select 1 from jsonb_array_elements(a->'cohorts') c where c->>'trainerId'=p.person_id and a->'assignments'->>(e->>'id')=c->>'id'); end if;
  select coalesce(jsonb_agg(c),'[]') into cohorts from jsonb_array_elements(a->'cohorts') c where (r='Formador' and c->>'trainerId'=p.person_id) or exists(select 1 from jsonb_array_elements_text(ids) i where a->'assignments'->>i=c->>'id');
  o:=jsonb_set(o,'{entries}',(select coalesce(jsonb_agg(e-'paths'-'attachments'-'history'-'submitted'),'[]') from jsonb_array_elements(o->'entries') e where ids ? (e->>'id')));
  o:=jsonb_set(o,'{students}',(select coalesce(jsonb_agg(case when r='Aluno' then s else jsonb_build_object('id',s->>'id','name',s->>'name') end),'[]') from jsonb_array_elements(o->'students') s where exists(select 1 from jsonb_array_elements(o->'entries') e where e->>'studentId'=s->>'id')));
  a:=jsonb_build_object('cohorts',cohorts,'assignments',(select coalesce(jsonb_object_agg(key,value),'{}') from jsonb_each(a->'assignments') where ids ? key),'sessions',(select coalesce(jsonb_agg(jsonb_set(s,'{marks}',(select coalesce(jsonb_object_agg(key,value),'{}') from jsonb_each(s->'marks') where ids ? key))),'[]') from jsonb_array_elements(a->'sessions') s where exists(select 1 from jsonb_array_elements(cohorts) c where c->>'id'=s->>'cohortId')),'assessments',(select coalesce(jsonb_agg(jsonb_set(s,'{scores}',(select coalesce(jsonb_object_agg(key,value),'{}') from jsonb_each(s->'scores') where ids ? key))),'[]') from jsonb_array_elements(a->'assessments') s where exists(select 1 from jsonb_array_elements(cohorts) c where c->>'id'=s->>'cohortId')));
  f:=jsonb_build_object('charges','[]'::jsonb,'payments','[]'::jsonb,'certificates',(select coalesce(jsonb_agg(c),'[]') from jsonb_array_elements(f->'certificates') c where r='Aluno' and ids ? (c->>'entryId')),'minFrequency',f->'minFrequency','minGrade',f->'minGrade');
 elsif r='Financeiro' then
  o:=jsonb_set(o,'{entries}',(select coalesce(jsonb_agg(e-'paths'-'attachments'-'history'-'submitted'),'[]') from jsonb_array_elements(o->'entries') e));
  o:=jsonb_set(o,'{students}',(select coalesce(jsonb_agg(jsonb_build_object('id',s->>'id','name',s->>'name')),'[]') from jsonb_array_elements(o->'students') s));
 end if;
 return jsonb_build_object('role',r,'personId',p.person_id,'name',p.name,'office',o,'academic',a,'finance',f,'versions',(select jsonb_object_agg(section,version) from public.centro_state),'trainers',(select coalesce(jsonb_agg(jsonb_build_object('id',person_id,'name',name)),'[]') from public.centro_access where role='Formador' and active));
end $$;
create function public.centro_save(p_section text,p_version bigint,p_data jsonb) returns bigint language plpgsql security definer set search_path='' as $$
declare r text:=public.centro_role(); old public.centro_state; e jsonb; prev jsonb; c jsonb; own jsonb; load jsonb;
begin
 if r is null or r='Aluno' then raise exception 'Sem permissão para alterar registos.'; end if;
 select * into old from public.centro_state where section=p_section for update;
 if not found or old.version<>p_version then raise exception 'Os dados foram alterados por outro utilizador. Atualize e repita a alteração.'; end if;
 if p_section='office' then
  if r not in ('Administrador','Secretaria') then raise exception 'Sem permissão.'; end if;
  if jsonb_typeof(p_data->'students') is distinct from 'array' or jsonb_typeof(p_data->'courses') is distinct from 'array' or jsonb_typeof(p_data->'entries') is distinct from 'array' then raise exception 'Dados inválidos.'; end if;
  if (select count(*) from jsonb_array_elements(p_data->'entries'))<>(select count(*) from jsonb_array_elements(old.data->'entries')) then raise exception 'Use o formulário de inscrição para adicionar registos.'; end if;
  for e in select value from jsonb_array_elements(p_data->'entries') loop
   select value into prev from jsonb_array_elements(old.data->'entries') where value->>'id'=e->>'id';
   if prev is null or (e->'paths') is distinct from (prev->'paths') or e->>'studentId' is distinct from prev->>'studentId' then raise exception 'Não pode alterar os documentos ou a identidade da inscrição.'; end if;
   if e->>'status' not in ('Pendente','Confirmada','Rejeitada') then raise exception 'Estado inválido.'; end if;
   if prev->>'status'<>'Pendente' and e is distinct from prev then raise exception 'Esta inscrição já foi analisada.'; end if;
   if e->>'status'='Confirmada' and prev->>'status'='Pendente' then
    if not exists(select 1 from jsonb_array_elements(p_data->'courses') x where x->>'id'=e->>'courseId' and x->>'active'='true') then raise exception 'Selecione um curso ativo.'; end if;
    if (select count(*) from storage.objects where bucket_id='centro-documentos' and name in (e->'paths'->>'photo',e->'paths'->>'identity',e->'paths'->>'payment'))<>3 then raise exception 'Fotografia, identificação e comprovativo são obrigatórios.'; end if;
   end if;
   if e->>'status'='Rejeitada' and length(trim(e->>'reason'))<5 then raise exception 'Indique o motivo da rejeição.'; end if;
  end loop;
 elsif p_section='academic' then
  if r not in ('Administrador','Secretaria','Formador') then raise exception 'Sem permissão.'; end if;
  if r='Formador' then
   load:=public.centro_load(); own:=load->'academic';
   if p_data->'cohorts' is distinct from own->'cohorts' or p_data->'assignments' is distinct from own->'assignments' then raise exception 'Não pode alterar turmas ou associações.'; end if;
   for e in select value from jsonb_array_elements(p_data->'sessions') union all select value from jsonb_array_elements(p_data->'assessments') loop
    if not exists(select 1 from jsonb_array_elements(own->'cohorts') c where c->>'id'=e->>'cohortId') then raise exception 'Turma não atribuída.'; end if;
   end loop;
   p_data:=jsonb_set(jsonb_set(old.data,'{sessions}',(select coalesce(jsonb_agg(s),'[]') from jsonb_array_elements(old.data->'sessions') s where not exists(select 1 from jsonb_array_elements(own->'cohorts') c where c->>'id'=s->>'cohortId'))||(p_data->'sessions')),'{assessments}',(select coalesce(jsonb_agg(s),'[]') from jsonb_array_elements(old.data->'assessments') s where not exists(select 1 from jsonb_array_elements(own->'cohorts') c where c->>'id'=s->>'cohortId'))||(p_data->'assessments'));
  end if;
 elsif p_section='finance' then
  if r='Secretaria' then
   if (p_data-'certificates') is distinct from (old.data-'certificates') then raise exception 'Sem permissão financeira.'; end if;
  elsif r not in ('Administrador','Financeiro') then raise exception 'Sem permissão.';
  elsif r='Financeiro' and p_data->'certificates' is distinct from old.data->'certificates' then raise exception 'Emissão reservada à Secretaria.'; end if;
 else raise exception 'Área inválida.'; end if;
 update public.centro_state set data=p_data,version=version+1 where section=p_section;
 insert into public.centro_audit(actor,action) values(auth.uid(),'Guardou '||p_section);
 return old.version+1;
end $$;
create function public.centro_receive(p_id uuid,p_person jsonb,p_paths jsonb) returns text language plpgsql security definer set search_path='' as $$
declare o jsonb; person jsonb; sid text; cid text; eid text:='PRE-'||upper(p_id::text); item jsonb;
begin
 select data into o from public.centro_state where section='office' for update;
 if exists(select 1 from jsonb_array_elements(o->'entries') e where e->>'id'=eid) then return eid; end if;
 if (select count(*) from storage.objects where bucket_id='centro-documentos' and name in (p_paths->>'photo',p_paths->>'identity',p_paths->>'payment'))<>3 then raise exception 'Anexe os três documentos.'; end if;
 select value into person from jsonb_array_elements(o->'students') s where lower(regexp_replace(s->>'documentNumber','[\s-]','','g'))=lower(regexp_replace(p_person->>'documentNumber','[\s-]','','g'));
 sid:=coalesce(person->>'id',gen_random_uuid()::text);
 select c->>'id' into cid from jsonb_array_elements(o->'courses') c where c->>'name'=p_person->>'course' and c->>'active'='true';
 if cid is null and p_person->>'course'<>'Outro' then raise exception 'Este curso já não está disponível.'; end if;
 if exists(select 1 from jsonb_array_elements(o->'entries') e where e->>'studentId'=sid and e->>'courseId'=coalesce(cid,'') and e->>'period'=p_person->>'period' and e->>'status' in ('Pendente','Confirmada')) then raise exception 'Já existe uma inscrição ativa para este documento, curso e período. Contacte a Secretaria.'; end if;
 if person is null then o:=jsonb_set(o,'{students}',(o->'students')||jsonb_build_array(p_person||jsonb_build_object('id',sid))); end if;
 item:=jsonb_build_object('id',eid,'studentId',sid,'courseId',coalesce(cid,''),'requestedCourse',p_person->>'otherCourse','period',p_person->>'period','startDate',p_person->>'startDate','date',now(),'status','Pendente','reference','','reason','','paths',p_paths,'submitted',p_person,'documents',jsonb_build_object('photo',true,'identity',true,'payment',true),'history',jsonb_build_array(jsonb_build_object('action','Inscrição recebida com documentos','actor','Receção de inscrições','date',now())));
 update public.centro_state set data=jsonb_set(o,'{entries}',(o->'entries')||jsonb_build_array(item)),version=version+1 where section='office';
 insert into public.centro_audit(action) values('Recebeu '||eid);
 return eid;
end $$;
revoke all on function public.centro_receive(uuid,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.centro_receive(uuid,jsonb,jsonb) to service_role;
revoke all on function public.centro_save(text,bigint,jsonb), public.centro_load(),public.centro_access_save(text,text,text,text,boolean),public.centro_access_list() from public,anon;
grant execute on function public.centro_save(text,bigint,jsonb), public.centro_load(),public.centro_access_save(text,text,text,text,boolean),public.centro_access_list() to authenticated;
insert into public.centro_access values('waldob.manuel2007@gmail.com','Waldob Manuel','Administrador',null,true);
insert into public.centro_state(section,data) values('office','{"students":[],"courses":[],"entries":[]}'),('academic','{"cohorts":[],"assignments":{},"sessions":[],"assessments":[]}'),('finance','{"charges":[],"payments":[],"certificates":[],"minFrequency":75,"minGrade":10}');
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('centro-documentos','centro-documentos',false,5242880,array['image/jpeg','image/png','application/pdf']);
create policy centro_document_read on storage.objects for select to authenticated using(bucket_id='centro-documentos' and public.centro_role() in ('Administrador','Secretaria'));
commit;
