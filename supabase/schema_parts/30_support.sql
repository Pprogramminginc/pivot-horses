create table if not exists public.client_event_log (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null,
  status text not null default 'info',
  message text not null,
  context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.error_events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  source text not null,
  message text not null,
  stack_trace text,
  context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.support_snapshots (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  support_code text not null unique,
  snapshot_summary text not null default '',
  snapshot_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.feedback_submissions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  email text not null default '',
  display_name text not null default '',
  category text not null default 'Suggestion',
  message text not null,
  context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

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

create index if not exists client_event_log_owner_created_idx
on public.client_event_log (owner_id, created_at desc);

create index if not exists error_events_owner_created_idx
on public.error_events (owner_id, created_at desc);

create index if not exists support_snapshots_owner_created_idx
on public.support_snapshots (owner_id, created_at desc);

create index if not exists feedback_submissions_owner_created_idx
on public.feedback_submissions (owner_id, created_at desc);

create index if not exists feedback_submissions_category_created_idx
on public.feedback_submissions (category, created_at desc);

create index if not exists inbox_items_owner_kind_created_idx
on public.inbox_items (owner_id, kind, created_at desc);

create index if not exists inbox_items_owner_unread_idx
on public.inbox_items (owner_id, kind)
where read_at is null;

alter table public.client_event_log enable row level security;
alter table public.error_events enable row level security;
alter table public.support_snapshots enable row level security;
alter table public.feedback_submissions enable row level security;
alter table public.inbox_items enable row level security;

drop policy if exists "client event log owner only" on public.client_event_log;
create policy "client event log owner only"
on public.client_event_log
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "error events owner only" on public.error_events;
create policy "error events owner only"
on public.error_events
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "support snapshots owner only" on public.support_snapshots;
create policy "support snapshots owner only"
on public.support_snapshots
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "feedback submissions owner only" on public.feedback_submissions;
create policy "feedback submissions owner only"
on public.feedback_submissions
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

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

create table if not exists public.purchase_receipts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null default 'ios',
  product_id text not null,
  transaction_id text not null,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'rejected')),
  purchased_amount integer not null default 0,
  price_cents integer not null default 0,
  currency text not null default 'USD',
  raw_receipt_hash text,
  context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  verified_at timestamptz,
  unique (platform, transaction_id)
);

create table if not exists public.app_admins (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  note text not null default '',
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.support_recovery_audits (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  admin_user_id uuid not null references public.profiles(id) on delete restrict,
  support_code text,
  action text not null default 'profile_state_recovery',
  before_state jsonb not null default '{}'::jsonb,
  after_state jsonb not null default '{}'::jsonb,
  note text not null default '',
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists purchase_receipts_owner_created_idx
on public.purchase_receipts (owner_id, created_at desc);

create index if not exists purchase_receipts_status_created_idx
on public.purchase_receipts (status, created_at desc);

create index if not exists support_recovery_audits_owner_created_idx
on public.support_recovery_audits (owner_id, created_at desc);

create index if not exists support_recovery_audits_admin_created_idx
on public.support_recovery_audits (admin_user_id, created_at desc);

alter table public.purchase_receipts enable row level security;
alter table public.app_admins enable row level security;
alter table public.support_recovery_audits enable row level security;

drop policy if exists "purchase receipts owner insert" on public.purchase_receipts;
create policy "purchase receipts owner insert"
on public.purchase_receipts
for insert
with check (auth.uid() = owner_id);

drop policy if exists "purchase receipts owner read" on public.purchase_receipts;
create policy "purchase receipts owner read"
on public.purchase_receipts
for select
using (auth.uid() = owner_id);

drop policy if exists "app admins can read self" on public.app_admins;
create policy "app admins can read self"
on public.app_admins
for select
using (auth.uid() = user_id);

drop policy if exists "support recovery audits admin read" on public.support_recovery_audits;
create policy "support recovery audits admin read"
on public.support_recovery_audits
for select
using (
  auth.uid() = admin_user_id
  or exists (
    select 1
    from public.app_admins
    where user_id = auth.uid()
  )
);

create or replace function public.support_recover_profile_state(
  target_owner_id uuid,
  support_code text default null,
  coin_balance_delta integer default 0,
  replacement_inventory jsonb default null,
  stable_expansion_tier_value integer default null,
  stable_expansion_renews_at_value text default null,
  note text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid := auth.uid();
  before_profile jsonb;
  after_profile jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.app_admins
    where user_id = actor_id
  ) then
    raise exception 'Admin access required';
  end if;

  select jsonb_build_object(
    'coin_balance', coin_balance,
    'inventory', inventory,
    'stable_expansion_tier', stable_expansion_tier,
    'stable_expansion_renews_at', stable_expansion_renews_at,
    'prenatal_boosted_pregnancy_ids', prenatal_boosted_pregnancy_ids,
    'carrot_boosted_horse_ids', carrot_boosted_horse_ids
  )
  into before_profile
  from public.profiles
  where id = target_owner_id
  for update;

  if before_profile is null then
    raise exception 'Profile not found';
  end if;

  update public.profiles
  set
    coin_balance = greatest(0, coin_balance + coin_balance_delta),
    inventory = coalesce(replacement_inventory, inventory),
    stable_expansion_tier = coalesce(
      stable_expansion_tier_value,
      stable_expansion_tier
    ),
    stable_expansion_renews_at = coalesce(
      stable_expansion_renews_at_value,
      stable_expansion_renews_at
    ),
    updated_at = timezone('utc', now())
  where id = target_owner_id
  returning jsonb_build_object(
    'coin_balance', coin_balance,
    'inventory', inventory,
    'stable_expansion_tier', stable_expansion_tier,
    'stable_expansion_renews_at', stable_expansion_renews_at,
    'prenatal_boosted_pregnancy_ids', prenatal_boosted_pregnancy_ids,
    'carrot_boosted_horse_ids', carrot_boosted_horse_ids
  )
  into after_profile;

  insert into public.support_recovery_audits (
    owner_id,
    admin_user_id,
    support_code,
    before_state,
    after_state,
    note
  )
  values (
    target_owner_id,
    actor_id,
    support_code,
    before_profile,
    after_profile,
    coalesce(note, '')
  );

  return jsonb_build_object(
    'owner_id', target_owner_id,
    'before_state', before_profile,
    'after_state', after_profile
  );
end;
$$;

grant execute on function public.support_recover_profile_state(
  uuid,
  text,
  integer,
  jsonb,
  integer,
  text,
  text
) to authenticated;

create table if not exists public.coin_packs (
  product_id text primary key,
  display_name text not null,
  coin_amount integer not null check (coin_amount > 0),
  price_cents integer not null check (price_cents > 0),
  currency text not null default 'USD',
  badge text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.coin_packs enable row level security;

drop policy if exists "coin packs public read" on public.coin_packs;
create policy "coin packs public read"
on public.coin_packs
for select
using (is_active);

insert into public.coin_packs (
  product_id,
  display_name,
  coin_amount,
  price_cents,
  currency,
  badge,
  sort_order,
  is_active
)
values
  ('coins_1100', 'Stable Snack', 1100, 499, 'USD', null, 10, true),
  ('coins_2500', 'Breeder Bundle', 2500, 999, 'USD', null, 20, true),
  ('coins_5000', 'Barn Vault', 5000, 1999, 'USD', 'Most popular', 30, true),
  ('coins_12000', 'Champion Chest', 12000, 4999, 'USD', 'Best value', 40, true)
on conflict (product_id) do update
set
  display_name = excluded.display_name,
  coin_amount = excluded.coin_amount,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  badge = excluded.badge,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active,
  updated_at = timezone('utc', now());

create or replace function public.grant_verified_coin_purchase(
  target_owner_id uuid,
  target_product_id text,
  target_transaction_id text,
  target_platform text default 'ios',
  target_raw_receipt_hash text default null,
  verification_context jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  pack_row public.coin_packs%rowtype;
  receipt_row public.purchase_receipts%rowtype;
  next_balance integer;
begin
  select *
  into pack_row
  from public.coin_packs
  where product_id = target_product_id
    and is_active;

  if not found then
    raise exception 'Unknown or inactive coin pack';
  end if;

  select *
  into receipt_row
  from public.purchase_receipts
  where platform = target_platform
    and transaction_id = target_transaction_id
  for update;

  if found then
    if receipt_row.owner_id <> target_owner_id then
      raise exception 'Purchase transaction belongs to another owner';
    end if;

    if receipt_row.product_id <> target_product_id then
      raise exception 'Purchase transaction product mismatch';
    end if;

    if receipt_row.status = 'verified' then
      select coin_balance
      into next_balance
      from public.profiles
      where id = target_owner_id;

      return jsonb_build_object(
        'already_processed', true,
        'coin_amount', pack_row.coin_amount,
        'coin_balance', next_balance,
        'receipt_id', receipt_row.id
      );
    end if;

    update public.purchase_receipts
    set
      status = 'verified',
      purchased_amount = pack_row.coin_amount,
      price_cents = pack_row.price_cents,
      currency = pack_row.currency,
      raw_receipt_hash = target_raw_receipt_hash,
      context = coalesce(context, '{}'::jsonb) || coalesce(verification_context, '{}'::jsonb),
      verified_at = timezone('utc', now())
    where id = receipt_row.id
    returning *
    into receipt_row;
  else
    insert into public.purchase_receipts (
      owner_id,
      platform,
      product_id,
      transaction_id,
      status,
      purchased_amount,
      price_cents,
      currency,
      raw_receipt_hash,
      context,
      verified_at
    )
    values (
      target_owner_id,
      target_platform,
      target_product_id,
      target_transaction_id,
      'verified',
      pack_row.coin_amount,
      pack_row.price_cents,
      pack_row.currency,
      target_raw_receipt_hash,
      coalesce(verification_context, '{}'::jsonb),
      timezone('utc', now())
    )
    returning *
    into receipt_row;
  end if;

  update public.profiles
  set
    coin_balance = coin_balance + pack_row.coin_amount,
    updated_at = timezone('utc', now())
  where id = target_owner_id
  returning coin_balance
  into next_balance;

  return jsonb_build_object(
    'already_processed', false,
    'coin_amount', pack_row.coin_amount,
    'coin_balance', next_balance,
    'receipt_id', receipt_row.id
  );
end;
$$;

revoke all on function public.grant_verified_coin_purchase(
  uuid,
  text,
  text,
  text,
  text,
  jsonb
) from public, anon, authenticated;

grant execute on function public.grant_verified_coin_purchase(
  uuid,
  text,
  text,
  text,
  text,
  jsonb
) to service_role;
