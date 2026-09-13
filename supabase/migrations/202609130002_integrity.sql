begin;
create function public.centro_catalog() returns jsonb language sql stable security definer set search_path='' as $$ select coalesce(jsonb_agg(c),'[]') from public.centro_state, jsonb_array_elements(data->'courses') c where section='office' and c->>'active'='true' $$;
grant execute on function public.centro_catalog() to anon,authenticated;
create table public.centro_intake_limits(key text primary key,started timestamptz not null default now(),requests int not null default 1);
alter table public.centro_intake_limits enable row level security;
create function public.centro_intake_check(p_key text) returns boolean language plpgsql security definer set search_path='' as $$
declare n int;
begin
 insert into public.centro_intake_limits(key) values(p_key) on conflict(key) do update set requests=case when centro_intake_limits.started<now()-interval '1 hour' then 1 else centro_intake_limits.requests+1 end,started=case when centro_intake_limits.started<now()-interval '1 hour' then now() else centro_intake_limits.started end returning requests into n;
 return n<=20;
end $$;
revoke all on function public.centro_intake_check(text) from public,anon,authenticated;
grant execute on function public.centro_intake_check(text) to service_role;
create function public.centro_validate_state() returns trigger language plpgsql set search_path='' as $$
declare item jsonb; line jsonb; office jsonb; academic jsonb;
begin
 if new.section='office' then
  if exists(select 1 from jsonb_array_elements(new.data->'students') s group by lower(regexp_replace(s->>'documentNumber','[\s-]','','g')) having count(*)>1) then raise exception 'Documento de identificação duplicado.'; end if;
  if exists(select 1 from jsonb_array_elements(new.data->'entries') e group by e->>'id' having count(*)>1) or exists(select 1 from jsonb_array_elements(new.data->'students') e group by e->>'id' having count(*)>1) then raise exception 'Identificador duplicado.'; end if;
  if exists(select 1 from jsonb_array_elements(new.data->'entries') e where e->>'status' in ('Pendente','Confirmada') group by e->>'studentId',e->>'courseId',e->>'period' having count(*)>1) then raise exception 'Inscrição ativa duplicada.'; end if;
  for item in select value from jsonb_array_elements(new.data->'entries') loop
   if not exists(select 1 from jsonb_array_elements(new.data->'students') s where s->>'id'=item->>'studentId') then raise exception 'Aluno inexistente.'; end if;
  end loop;
 elsif new.section='academic' then
  select data into office from public.centro_state where section='office';
  for item in select value from jsonb_array_elements(new.data->'sessions') union all select value from jsonb_array_elements(new.data->'assessments') loop
   if not exists(select 1 from jsonb_array_elements(new.data->'cohorts') c where c->>'id'=item->>'cohortId' and (item->>'date')::date between (c->>'start')::date and least((c->>'end')::date,current_date)) then raise exception 'Data ou turma inválida.'; end if;
   for line in select jsonb_build_object('id',key,'value',value) from jsonb_each(coalesce(item->'marks',item->'scores')) loop
    if new.data->'assignments'->>(line->>'id') is distinct from item->>'cohortId' then raise exception 'Aluno não pertence à turma.'; end if;
    if item ? 'scores' then if (line->>'value')::numeric not between 0 and 20 then raise exception 'Nota inválida.'; end if;
    elsif line->>'value' not in ('Presente','Falta') then raise exception 'Presença inválida.'; end if;
   end loop;
  end loop;
 elsif new.section='finance' then
  select data into office from public.centro_state where section='office';
  for item in select value from jsonb_array_elements(new.data->'charges') loop
   if (item->>'amount')::bigint<=0 or not exists(select 1 from jsonb_array_elements(office->'entries') e where e->>'id'=item->>'entryId' and e->>'status'='Confirmada') then raise exception 'Cobrança inválida.'; end if;
   if (select coalesce(sum((p->>'amount')::bigint),0) from jsonb_array_elements(new.data->'payments') p where p->>'chargeId'=item->>'id' and coalesce(p->>'voidReason','')='')>(item->>'amount')::bigint then raise exception 'Pagamentos ultrapassam a cobrança.'; end if;
  end loop;
  for item in select value from jsonb_array_elements(new.data->'payments') loop
   if (item->>'amount')::bigint<=0 or (item->>'date')::date>current_date or not exists(select 1 from jsonb_array_elements(new.data->'charges') c where c->>'id'=item->>'chargeId') then raise exception 'Pagamento inválido.'; end if;
  end loop;
 end if;
 return new;
end $$;
create trigger centro_validate before update on public.centro_state for each row execute function public.centro_validate_state();
commit;
