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
