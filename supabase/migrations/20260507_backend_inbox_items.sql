create table if not exists public.inbox_items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null default 'message'
    check (kind in ('message', 'notification')),
  title text not null,
  body text not null default '',
  category text not null default 'General',
  action_label text,
  action_payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists inbox_items_owner_kind_created_idx
on public.inbox_items (owner_id, kind, created_at desc);

create index if not exists inbox_items_owner_unread_idx
on public.inbox_items (owner_id, kind)
where read_at is null;

alter table public.inbox_items enable row level security;

drop policy if exists "inbox items owner read" on public.inbox_items;
create policy "inbox items owner read"
on public.inbox_items
for select
using (auth.uid() = owner_id);

drop policy if exists "inbox items owner update" on public.inbox_items;
create policy "inbox items owner update"
on public.inbox_items
for update
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);
