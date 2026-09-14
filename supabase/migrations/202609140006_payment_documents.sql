begin;
create sequence public.centro_payment_document_number;
create table public.centro_payment_documents(
 payment_id text primary key, reference text not null unique, token uuid not null unique default gen_random_uuid(),
 snapshot jsonb not null, void_reason text not null default '', void_at timestamptz,
 created_at timestamptz not null default now()
);
alter table public.centro_payment_documents enable row level security;
revoke all on public.centro_payment_documents from anon,authenticated;

create function public.centro_finance_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare p jsonb; prev jsonb; c jsonb; revised jsonb:='[]';
begin
 if new.section<>'finance' then return new;end if;
 if jsonb_typeof(new.data->'charges') is distinct from 'array' or jsonb_typeof(new.data->'payments') is distinct from 'array' then raise exception 'Dados financeiros inválidos.';end if;
 for c in select value from jsonb_array_elements(old.data->'charges') loop
  if not exists(select 1 from jsonb_array_elements(new.data->'charges') x where x=c) then raise exception 'Preserve a cobrança original e o histórico financeiro.';end if;
 end loop;
 if exists(select 1 from jsonb_array_elements(new.data->'charges') x group by x->>'id' having count(*)>1) or exists(select 1 from jsonb_array_elements(new.data->'payments') x group by x->>'id' having count(*)>1) then raise exception 'Identificador financeiro duplicado.';end if;
 if exists(select 1 from jsonb_array_elements(new.data->'charges') x group by x->>'entryId',x->>'kind',case when x->>'kind'='Propina' then x->>'month' else '' end having count(*)>1) then raise exception 'Já existe uma cobrança para esta inscrição e período.';end if;
 if exists(select 1 from jsonb_array_elements(new.data->'payments') x where coalesce(x->>'voidReason','')='' group by lower(trim(x->>'reference')) having count(*)>1) then raise exception 'Referência de pagamento duplicada.';end if;
 for c in select value from jsonb_array_elements(new.data->'charges') loop
  if coalesce(c->>'id','')='' or coalesce(c->>'amount','') !~ '^[0-9]+$' or (c->>'amount')::numeric not between 1 and 10000000000 or coalesce(c->>'kind','') not in ('Inscrição','Propina') or coalesce(c->>'due','') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then raise exception 'Cobrança inválida.';end if;
  perform (c->>'due')::date;
  if c->>'kind'='Propina' and coalesce(c->>'month','') !~ '^[0-9]{4}-(0[1-9]|1[0-2])$' then raise exception 'Mês da propina inválido.';end if;
 end loop;
 for p in select value from jsonb_array_elements(new.data->'payments') loop
  select value into prev from jsonb_array_elements(old.data->'payments') where value->>'id'=p->>'id';
  if coalesce(p->>'id','')='' or coalesce(p->>'amount','') !~ '^[0-9]+$' or (p->>'amount')::numeric not between 1 and 10000000000 or length(trim(coalesce(p->>'reference',''))) not between 3 and 100 or coalesce(p->>'method','') not in ('Transferência bancária','Depósito bancário','Numerário','Multicaixa') or coalesce(p->>'date','') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then raise exception 'Pagamento inválido.';end if;
  if (p->>'date')::date>current_date then raise exception 'O pagamento não pode ter uma data futura.';end if;
  if prev is null then
   if coalesce(p->>'voidReason','')<>'' then raise exception 'Registe o pagamento antes de estornar.';end if;
   p:=(p-'voidActor'-'voidAt')||jsonb_build_object('actor',public.centro_role(),'voidReason','');
  elsif coalesce(prev->>'voidReason','')='' and coalesce(p->>'voidReason','')<>'' then
   if length(trim(p->>'voidReason')) not between 5 and 500 then raise exception 'Indique o motivo do estorno (5 a 500 caracteres).';end if;
   p:=p||jsonb_build_object('voidReason',trim(p->>'voidReason'),'voidActor',public.centro_role(),'voidAt',now());
   insert into public.centro_audit(actor,action) values(auth.uid(),'Estornou pagamento: '||(p->>'id'));
  end if;
  revised:=revised||jsonb_build_array(p);
 end loop;
 new.data:=jsonb_set(new.data,'{payments}',revised);
 return new;
end $$;
create trigger centro_finance_guard before update on public.centro_state for each row execute function public.centro_finance_guard();

create function public.centro_record_payment_document(p jsonb,f jsonb,o jsonb) returns void language plpgsql security definer set search_path='' as $$
declare c jsonb; e jsonb; s jsonb; course jsonb;
begin
 select value into c from jsonb_array_elements(f->'charges') where value->>'id'=p->>'chargeId';
 select value into e from jsonb_array_elements(o->'entries') where value->>'id'=c->>'entryId';
 select value into s from jsonb_array_elements(o->'students') where value->>'id'=e->>'studentId';
 select value into course from jsonb_array_elements(o->'courses') where value->>'id'=e->>'courseId';
 if c is null or e is null or s is null then raise exception 'Pagamento sem cobrança ou aluno associado.';end if;
 if not exists(select 1 from public.centro_payment_documents where payment_id=p->>'id') then
  insert into public.centro_payment_documents(payment_id,reference,snapshot) values(p->>'id','PAG-'||extract(year from current_date)::text||'-'||lpad(nextval('public.centro_payment_document_number')::text,6,'0'),
   jsonb_build_object('name',s->>'name','course',coalesce(course->>'name',e->>'requestedCourse'),'matricula',e->>'reference','kind',c->>'kind','month',c->>'month','amount',p->'amount','paymentDate',p->>'date','method',p->>'method','movementReference',p->>'reference','issued',now()));
 end if;
 if coalesce(p->>'voidReason','')<>'' then
  update public.centro_payment_documents set void_reason=p->>'voidReason',void_at=nullif(p->>'voidAt','')::timestamptz where payment_id=p->>'id' and void_reason='';
 end if;
end $$;
revoke all on function public.centro_record_payment_document(jsonb,jsonb,jsonb) from public,anon,authenticated;
create function public.centro_payment_document_trigger() returns trigger language plpgsql security definer set search_path='' as $$
declare p jsonb; o jsonb;
begin
 if new.section='finance' then
  select data into o from public.centro_state where section='office';
  for p in select value from jsonb_array_elements(new.data->'payments') loop perform public.centro_record_payment_document(p,new.data,o);end loop;
 end if;
 return new;
end $$;
create trigger centro_payment_documents_after after update on public.centro_state for each row execute function public.centro_payment_document_trigger();
do $$ declare f jsonb;o jsonb;p jsonb;begin
 select data into f from public.centro_state where section='finance';select data into o from public.centro_state where section='office';
 for p in select value from jsonb_array_elements(f->'payments') loop perform public.centro_record_payment_document(p,f,o);end loop;
end $$;

create function public.centro_payment_document(p_payment text) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare d public.centro_payment_documents;
begin
 if coalesce(public.centro_role(),'') not in ('Administrador','Financeiro') then raise exception 'Sem permissão para consultar comprovativos financeiros.';end if;
 select * into d from public.centro_payment_documents where payment_id=p_payment;
 if not found then raise exception 'Comprovativo indisponível. Atualize os dados depois de guardar o pagamento.';end if;
 return d.snapshot||jsonb_build_object('reference',d.reference,'token',d.token,'voidReason',d.void_reason,'voidAt',d.void_at);
end $$;
revoke all on function public.centro_payment_document(text) from public,anon;
grant execute on function public.centro_payment_document(text) to authenticated;

create or replace function public.centro_verify(p_token text) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('reference',d.snapshot->>'reference','course',d.snapshot->>'course','period',d.snapshot->>'period','issued',d.snapshot->>'issued','status','Confirmada','kind','Inscrição')
 from public.centro_documents d where d.token::text=lower(p_token)
 and exists(select 1 from public.centro_state s,jsonb_array_elements(s.data->'entries') e where s.section='office' and e->>'id'=d.entry_id and e->>'status'='Confirmada')
 union all
 select jsonb_build_object('reference',c.reference,'course',c.snapshot->>'course','issued',c.snapshot->>'issued','status','Concluído','kind','Certificado','hours',c.snapshot->>'hours') from public.centro_certificates c where c.token::text=lower(p_token)
 union all
 select jsonb_build_object('reference',p.reference,'issued',p.snapshot->>'issued','status',case when p.void_reason='' then 'Registado' else 'Estornado' end,'kind','Pagamento') from public.centro_payment_documents p where p.token::text=lower(p_token)
 limit 1
$$;
commit;
