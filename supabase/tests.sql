begin;
do $$
declare uid uuid:=gen_random_uuid(); result jsonb; n bigint;
begin
 if has_function_privilege('anon','public.centro_load()','execute') then raise exception 'Anonymous read permitted'; end if;
 if has_function_privilege('authenticated','public.centro_receive(uuid,jsonb,jsonb)','execute') then raise exception 'Intake bypass permitted'; end if;
 insert into auth.users(id,email,email_confirmed_at) values(uid,'etapa7-test@example.invalid',now());
 insert into public.centro_access values('etapa7-test@example.invalid','Teste transacional','Administrador',null,true);
 perform set_config('request.jwt.claim.sub',uid::text,true);
 result:=public.centro_load(); if result->>'role'<>'Administrador' or jsonb_array_length(result->'office'->'courses')<>25 then raise exception 'Admin/catalog failed'; end if;
 n:=public.centro_save('office',(result->'versions'->>'office')::bigint,result->'office');
 begin perform public.centro_save('office',n-1,result->'office'); raise exception 'Conflict not blocked'; exception when raise_exception then if sqlerrm='Conflict not blocked' then raise; end if; end;
 update public.centro_access set role='Aluno',person_id='unlinked' where email='etapa7-test@example.invalid';
 result:=public.centro_load();if result->'office'->'students'<>'[]'::jsonb or result->'office'->'entries'<>'[]'::jsonb then raise exception 'Student isolation failed'; end if;
 begin perform public.centro_save('office',n,result->'office');raise exception 'Student write permitted';exception when raise_exception then if sqlerrm='Student write permitted' then raise; end if;end;
 update public.centro_access set role='Formador',person_id='unlinked' where email='etapa7-test@example.invalid';
 result:=public.centro_load();if result->'academic'->'cohorts'<>'[]'::jsonb then raise exception 'Teacher isolation failed'; end if;
 update public.centro_access set active=false where email='etapa7-test@example.invalid';
 if public.centro_role() is not null then raise exception 'Suspended account allowed'; end if;
 raise notice 'PASS: anonymous access, intake privilege, administrator, concurrency, student isolation, student write, trainer isolation, suspension';
end $$;
rollback;
