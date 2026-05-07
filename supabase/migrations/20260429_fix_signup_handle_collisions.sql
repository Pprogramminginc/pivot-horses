create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  profile_display_name text;
  base_handle text;
  profile_handle text;
  profile_email text;
begin
  profile_email := coalesce(new.email, new.id::text || '@pivot.local');
  profile_display_name := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    split_part(profile_email, '@', 1),
    'Player'
  );
  base_handle := '@' || lower(
    regexp_replace(profile_display_name, '[^a-zA-Z0-9]+', '', 'g')
  );
  if base_handle = '@' then
    base_handle := '@player';
  end if;
  profile_handle := base_handle;

  if exists (select 1 from public.profiles where handle = profile_handle) then
    profile_handle := base_handle || substr(replace(new.id::text, '-', ''), 1, 8);
  end if;

  insert into public.profiles (
    id,
    email,
    display_name,
    handle,
    stable_name,
    favorite_breed,
    accent_value,
    coin_balance
  )
  values (
    new.id,
    profile_email,
    profile_display_name,
    profile_handle,
    profile_display_name || ' Stable',
    'Arabian',
    15003876,
    7000
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
