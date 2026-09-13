begin;
create table public.centro_documents (
 entry_id text primary key, student_id text not null,
 token uuid not null unique default gen_random_uuid(),
 snapshot jsonb not null, created_at timestamptz not null default now()
);
alter table public.centro_documents enable row level security;
revoke all on public.centro_documents from anon, authenticated;

-- Freeze the approved data once. Subsequent edits to a student's file or course
-- must not change an already issued registration document.
create function public.centro_record_document(e jsonb, o jsonb) returns void
language plpgsql security definer set search_path='' as $$
declare s jsonb; c jsonb; issued text;
begin
 if e->>'status' is distinct from 'Confirmada' then return; end if;
 select value into s from jsonb_array_elements(o->'students') where value->>'id'=e->>'studentId';
 select value into c from jsonb_array_elements(o->'courses') where value->>'id'=e->>'courseId';
 select value->>'date' into issued from jsonb_array_elements(e->'history') where value->>'action'='Confirmada' order by value->>'date' desc limit 1;
 insert into public.centro_documents(entry_id,student_id,snapshot) values(e->>'id',e->>'studentId',
  jsonb_build_object('reference',e->>'reference','name',s->>'name','course',coalesce(c->>'name',e->>'requestedCourse'),
   'period',e->>'period','startDate',e->>'startDate','issued',coalesce(issued,now()::text)))
 on conflict(entry_id) do nothing;
end $$;
revoke all on function public.centro_record_document(jsonb,jsonb) from public,anon,authenticated;
create function public.centro_document_trigger() returns trigger language plpgsql security definer set search_path='' as $$
declare e jsonb;
begin
 if new.section='office' then
  for e in select value from jsonb_array_elements(new.data->'entries') loop
   perform public.centro_record_document(e,new.data);
  end loop;
 end if;
 return new;
end $$;
create trigger centro_documents_after after update on public.centro_state for each row execute function public.centro_document_trigger();
do $$ declare o jsonb; e jsonb; begin
 select data into o from public.centro_state where section='office';
 for e in select value from jsonb_array_elements(o->'entries') loop perform public.centro_record_document(e,o); end loop;
end $$;

create function public.centro_document(p_entry text) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare d public.centro_documents; r text:=public.centro_role();
begin
 select * into d from public.centro_documents where entry_id=p_entry;
 if r in ('Administrador','Secretaria') or (r='Aluno' and exists(select 1 from public.centro_access a join auth.users u on lower(u.email)=a.email where u.id=auth.uid() and a.person_id=d.student_id and a.active)) then
  if d.entry_id is null then raise exception 'Comprovativo ainda indisponível. Confirme a inscrição e atualize os dados.'; end if;
  return d.snapshot||jsonb_build_object('token',d.token);
 end if;
 raise exception 'Sem permissão para consultar este comprovativo.';
end $$;
revoke all on function public.centro_document(text) from public,anon;
grant execute on function public.centro_document(text) to authenticated;

-- The random QR token only reveals registration metadata. No names, phone,
-- identity documents, attachments or download URLs are returned anonymously.
create function public.centro_verify(p_token text) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('reference',d.snapshot->>'reference','course',d.snapshot->>'course','period',d.snapshot->>'period','issued',d.snapshot->>'issued','status','Confirmada')
 from public.centro_documents d where d.token::text=lower(p_token)
 and exists(select 1 from public.centro_state s,jsonb_array_elements(s.data->'entries') e where s.section='office' and e->>'id'=d.entry_id and e->>'status'='Confirmada')
$$;
revoke all on function public.centro_verify(text) from public;
grant execute on function public.centro_verify(text) to anon,authenticated;
commit;
