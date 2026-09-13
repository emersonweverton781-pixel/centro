begin;
create sequence public.centro_matricula;
create function public.centro_preserve_history() returns trigger language plpgsql security definer set search_path='' as $$
declare e jsonb; prev jsonb; revised jsonb:='[]';
begin
 if new.section='office' then
  for e in select value from jsonb_array_elements(new.data->'entries') loop
   select value into prev from jsonb_array_elements(old.data->'entries') p where p->>'id'=e->>'id';
   if prev->>'status'='Pendente' and e->>'status' in ('Confirmada','Rejeitada') then
    if e->>'status'='Confirmada' then e:=jsonb_set(e,'{reference}',to_jsonb('MAT-'||extract(year from current_date)::text||'-'||lpad(nextval('public.centro_matricula')::text,6,'0'))); end if;
    e:=jsonb_set(e,'{history}',coalesce(prev->'history','[]')||jsonb_build_array(jsonb_build_object('action',e->>'status','actor',coalesce(public.centro_role(),'Centro'),'date',now())));
   end if;
   revised:=revised||jsonb_build_array(e);
  end loop;
  new.data:=jsonb_set(new.data,'{entries}',revised);
 elsif new.section='finance' then
  for prev in select value from jsonb_array_elements(old.data->'payments') loop
   select value into e from jsonb_array_elements(new.data->'payments') p where p->>'id'=prev->>'id';
   if e is null or (e-'voidReason'-'voidActor'-'voidAt') is distinct from (prev-'voidReason'-'voidActor'-'voidAt') or (coalesce(prev->>'voidReason','')<>'' and e is distinct from prev) then raise exception 'Preserve o pagamento original. Utilize o estorno para corrigir.'; end if;
  end loop;
  for prev in select value from jsonb_array_elements(old.data->'certificates') loop
   if not exists(select 1 from jsonb_array_elements(new.data->'certificates') p where p=prev) then raise exception 'O histórico de certificados deve ser preservado.'; end if;
  end loop;
 end if;
 return new;
end $$;
create trigger centro_history before update on public.centro_state for each row execute function public.centro_preserve_history();
commit;
