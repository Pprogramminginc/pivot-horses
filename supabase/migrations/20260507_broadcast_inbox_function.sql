create or replace function public.send_broadcast_inbox_item(
  item_kind text,
  item_title text,
  item_body text,
  item_category text default 'Announcement',
  item_action_label text default null,
  item_action_payload jsonb default '{}'::jsonb
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid := auth.uid();
  inserted_count integer := 0;
begin
  if actor_id is null then
    if current_user not in ('postgres', 'supabase_admin') then
      raise exception 'Authentication required';
    end if;
  elsif not exists (
    select 1
    from public.app_admins
    where user_id = actor_id
  ) then
    raise exception 'Admin access required';
  end if;

  if item_kind not in ('message', 'notification') then
    raise exception 'item_kind must be message or notification';
  end if;

  if nullif(trim(item_title), '') is null then
    raise exception 'item_title is required';
  end if;

  insert into public.inbox_items (
    owner_id,
    kind,
    title,
    body,
    category,
    action_label,
    action_payload
  )
  select
    id,
    item_kind,
    trim(item_title),
    coalesce(item_body, ''),
    coalesce(nullif(trim(item_category), ''), 'Announcement'),
    nullif(trim(item_action_label), ''),
    coalesce(item_action_payload, '{}'::jsonb)
  from public.profiles;

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

grant execute on function public.send_broadcast_inbox_item(
  text,
  text,
  text,
  text,
  text,
  jsonb
) to authenticated;
