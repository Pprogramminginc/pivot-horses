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
