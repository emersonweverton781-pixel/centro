begin;
create table public.centro_certificate_policy(
 id boolean primary key default true check(id), min_frequency numeric not null check(min_frequency between 0 and 100),
 min_grade numeric not null check(min_grade between 0 and 20), confirmed_by uuid, confirmed_at timestamptz
);
insert into public.centro_certificate_policy(id,min_frequency,min_grade) values(true,75,10);
alter table public.centro_certificate_policy enable row level security;
create table public.centro_certificates(
 entry_id text primary key,student_id text not null,token uuid not null unique default gen_random_uuid(),
 reference text not null unique,snapshot jsonb not null,issued_by uuid not null,created_at timestamptz not null default now()
);
alter table public.centro_certificates enable row level security;
revoke all on public.centro_certificate_policy,public.centro_certificates from anon,authenticated;
create sequence public.centro_certificate_number;

create function public.centro_certificate_policy_save(p_frequency numeric,p_grade numeric,p_confirm boolean) returns void language plpgsql security definer set search_path='' as $$
begin
 if public.centro_role() is distinct from 'Administrador' then raise exception 'Apenas o Administrador pode confirmar os critérios.'; end if;
 if p_confirm is distinct from true or p_frequency is null or p_grade is null or p_frequency not between 0 and 100 or p_grade not between 0 and 20 then raise exception 'Confirme critérios válidos: presença de 0 a 100%% e nota de 0 a 20.'; end if;
 update public.centro_certificate_policy set min_frequency=p_frequency,min_grade=p_grade,confirmed_by=auth.uid(),confirmed_at=now() where id;
 insert into public.centro_audit(actor,action) values(auth.uid(),'Confirmou critérios de certificação: '||p_frequency||'% / '||p_grade||'/20');
end $$;

create function public.centro_certificate_list() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare r text:=public.centro_role(); sid text;
begin
 if r is null or r not in ('Administrador','Secretaria','Aluno') then raise exception 'Sem acesso aos certificados.'; end if;
 select a.person_id into sid from public.centro_access a join auth.users u on lower(u.email)=a.email where u.id=auth.uid();
 return jsonb_build_object('policy',(select jsonb_build_object('minFrequency',min_frequency,'minGrade',min_grade,'confirmed',confirmed_at is not null,'confirmedAt',confirmed_at) from public.centro_certificate_policy where id),
 'certificates',(select coalesce(jsonb_agg(snapshot||jsonb_build_object('token',token,'entryId',entry_id,'reference',reference) order by created_at desc),'[]') from public.centro_certificates where r in ('Administrador','Secretaria') or student_id=sid));
end $$;

create function public.centro_certificate_check(p_entry text) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare o jsonb; a jsonb; e jsonb; c jsonb; cohort jsonb; student jsonb; item jsonb; p public.centro_certificate_policy;
 reasons jsonb:='[]'; total integer:=0; present integer:=0; graded integer:=0; sum_grade numeric:=0; freq numeric; avg_grade numeric; missing_marks boolean:=false; missing_scores boolean:=false;
begin
 if coalesce(public.centro_role(),'') not in ('Administrador','Secretaria') then raise exception 'A análise é reservada à Secretaria e ao Administrador.'; end if;
 select data into o from public.centro_state where section='office'; select data into a from public.centro_state where section='academic';
 select * into p from public.centro_certificate_policy where id;
 select value into e from jsonb_array_elements(o->'entries') where value->>'id'=p_entry;
 select value into c from jsonb_array_elements(o->'courses') where value->>'id'=e->>'courseId';
 select value into student from jsonb_array_elements(o->'students') where value->>'id'=e->>'studentId';
 select value into cohort from jsonb_array_elements(a->'cohorts') where value->>'id'=a->'assignments'->>p_entry;
 if p.confirmed_at is null then reasons:=reasons||jsonb_build_array('O Administrador deve confirmar os critérios de certificação.'); end if;
 if e is null or e->>'status' is distinct from 'Confirmada' then reasons:=reasons||jsonb_build_array('A inscrição deve estar confirmada.'); end if;
 if cohort is null or cohort->>'courseId' is distinct from e->>'courseId' then reasons:=reasons||jsonb_build_array('Associe o formando à turma do curso.');
 elsif nullif(cohort->>'end','') is null or (cohort->>'end')::date>current_date then reasons:=reasons||jsonb_build_array('A data de fim da turma ainda não foi atingida.'); end if;
 if length(trim(coalesce(c->>'duration','')))=0 or coalesce(c->>'hours','') !~ '^[0-9]+([.][0-9]+)?$' then reasons:=reasons||jsonb_build_array('Defina a duração e uma carga horária válida no curso.');
 elsif (c->>'hours')::numeric<=0 then reasons:=reasons||jsonb_build_array('A carga horária deve ser maior que zero.'); end if;
 for item in select value from jsonb_array_elements(a->'sessions') where value->>'cohortId'=cohort->>'id' loop
  total:=total+1;
  if item->'marks'->>p_entry='Presente' then present:=present+1;
  elsif item->'marks'->>p_entry is distinct from 'Falta' then missing_marks:=true; end if;
 end loop;
 for item in select value from jsonb_array_elements(a->'assessments') where value->>'cohortId'=cohort->>'id' loop
  if jsonb_typeof(item->'scores'->p_entry) is distinct from 'number' then missing_scores:=true;
  elsif (item->'scores'->>p_entry)::numeric not between 0 and 20 then missing_scores:=true;
  else graded:=graded+1;sum_grade:=sum_grade+(item->'scores'->>p_entry)::numeric;end if;
 end loop;
 if total=0 then reasons:=reasons||jsonb_build_array('Registe as presenças da turma.');
 else freq:=present::numeric*100/total; if freq<p.min_frequency then reasons:=reasons||jsonb_build_array('Frequência abaixo do mínimo confirmado.');end if;end if;
 if missing_marks then reasons:=reasons||jsonb_build_array('Existem aulas sem presença ou falta registada para este formando.');end if;
 if graded=0 then reasons:=reasons||jsonb_build_array('Registe as notas do formando.');
 else avg_grade:=sum_grade/graded;if avg_grade<p.min_grade then reasons:=reasons||jsonb_build_array('Média abaixo do mínimo confirmado.');end if;end if;
 if missing_scores then reasons:=reasons||jsonb_build_array('Existem avaliações sem uma nota válida para este formando.');end if;
 return jsonb_build_object('reasons',reasons,'name',student->>'name','studentId',e->>'studentId','course',c->>'name','hours',c->>'hours','duration',c->>'duration','cohort',cohort->>'name','startDate',cohort->>'start','endDate',cohort->>'end','matricula',e->>'reference','frequency',freq,'average',avg_grade,'minFrequency',p.min_frequency,'minGrade',p.min_grade,'policyConfirmedAt',p.confirmed_at);
end $$;

create function public.centro_certificate_issue(p_entry text,p_completed boolean) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb; doc public.centro_certificates; ref text;
begin
 if coalesce(public.centro_role(),'') not in ('Administrador','Secretaria') then raise exception 'A emissão é reservada à Secretaria e ao Administrador.';end if;
 if p_completed is distinct from true then raise exception 'Confirme a conclusão da formação.';end if;
 -- Serialize issues with academic/office writes and policy changes. The unique
 -- entry key makes retries return the original certificate, never a second one.
 perform 1 from public.centro_state order by section for update;
 perform 1 from public.centro_certificate_policy where id for update;
 select * into doc from public.centro_certificates where entry_id=p_entry;
 if found then return doc.snapshot||jsonb_build_object('entryId',doc.entry_id,'reference',doc.reference,'token',doc.token);end if;
 result:=public.centro_certificate_check(p_entry);
 if jsonb_array_length(result->'reasons')>0 then raise exception '%',(select string_agg(value,' ') from jsonb_array_elements_text(result->'reasons'));end if;
 ref:='CERT-'||extract(year from current_date)::text||'-'||lpad(nextval('public.centro_certificate_number')::text,6,'0');
 insert into public.centro_certificates(entry_id,student_id,reference,snapshot,issued_by) values(p_entry,result->>'studentId',ref,(result-'reasons'-'studentId')||jsonb_build_object('issued',now(),'status','Concluído'),auth.uid()) returning * into doc;
 insert into public.centro_audit(actor,action) values(auth.uid(),'Confirmou conclusão e emitiu certificado: '||ref);
 return doc.snapshot||jsonb_build_object('entryId',p_entry,'reference',ref,'token',doc.token);
end $$;

create or replace function public.centro_verify(p_token text) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('reference',d.snapshot->>'reference','course',d.snapshot->>'course','period',d.snapshot->>'period','issued',d.snapshot->>'issued','status','Confirmada','kind','Inscrição')
 from public.centro_documents d where d.token::text=lower(p_token)
 and exists(select 1 from public.centro_state s,jsonb_array_elements(s.data->'entries') e where s.section='office' and e->>'id'=d.entry_id and e->>'status'='Confirmada')
 union all
 select jsonb_build_object('reference',c.reference,'course',c.snapshot->>'course','issued',c.snapshot->>'issued','status','Concluído','kind','Certificado','hours',c.snapshot->>'hours')
 from public.centro_certificates c where c.token::text=lower(p_token)
 limit 1
$$;
revoke all on function public.centro_certificate_policy_save(numeric,numeric,boolean),public.centro_certificate_list(),public.centro_certificate_check(text),public.centro_certificate_issue(text,boolean) from public,anon;
grant execute on function public.centro_certificate_policy_save(numeric,numeric,boolean),public.centro_certificate_list(),public.centro_certificate_check(text),public.centro_certificate_issue(text,boolean) to authenticated;
commit;
