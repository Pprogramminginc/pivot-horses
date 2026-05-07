create sequence if not exists public.horse_registry_number_seq
start with 101
increment by 1;

create or replace function public.reserve_horse_registry_id()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  candidate text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  loop
    candidate := 'PH' || nextval('public.horse_registry_number_seq')::text;
    exit when not exists (
      select 1
      from public.horses
      where registry_id = candidate
    )
    and not exists (
      select 1
      from public.pregnancies
      where registry_id = candidate
        and delivered_at is null
    );
  end loop;

  return candidate;
end;
$$;

grant execute on function public.reserve_horse_registry_id() to authenticated;
