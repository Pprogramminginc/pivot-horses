-- Community and market schema.
-- Apply after 00_base.sql.

create table if not exists public.horse_listings (
  id uuid primary key default gen_random_uuid(),
  horse_id uuid unique not null references public.horses(id) on delete cascade,
  seller_id uuid not null references public.profiles(id) on delete cascade,
  buyer_price integer not null,
  seller_payout integer not null,
  status text not null default 'open',
  created_at timestamptz not null default timezone('utc', now()),
  sold_at timestamptz
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followee_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (follower_id, followee_id),
  constraint follows_not_self check (follower_id <> followee_id)
);

create table if not exists public.horse_likes (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  horse_id uuid not null references public.horses(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (profile_id, horse_id)
);

alter table public.horse_listings enable row level security;
alter table public.follows enable row level security;
alter table public.horse_likes enable row level security;

drop policy if exists "listings public read" on public.horse_listings;
create policy "listings public read"
on public.horse_listings
for select
using (status = 'open' or auth.uid() = seller_id);

drop policy if exists "listings seller write" on public.horse_listings;
create policy "listings seller write"
on public.horse_listings
for all
using (auth.uid() = seller_id)
with check (auth.uid() = seller_id);

drop policy if exists "follows public read" on public.follows;
create policy "follows public read"
on public.follows
for select
using (true);

drop policy if exists "follows owner write" on public.follows;
create policy "follows owner write"
on public.follows
for all
using (auth.uid() = follower_id)
with check (auth.uid() = follower_id);

drop policy if exists "likes public read" on public.horse_likes;
create policy "likes public read"
on public.horse_likes
for select
using (true);

drop policy if exists "likes owner write" on public.horse_likes;
create policy "likes owner write"
on public.horse_likes
for all
using (auth.uid() = profile_id)
with check (auth.uid() = profile_id);

create or replace function public.purchase_horse_listing(target_listing_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  buyer_id uuid := auth.uid();
  listing_row public.horse_listings%rowtype;
  horse_row public.horses%rowtype;
  buyer_balance integer;
begin
  if buyer_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into listing_row
  from public.horse_listings
  where id = target_listing_id
    and status = 'open'
  for update;

  if not found then
    raise exception 'Listing not found or no longer open';
  end if;

  if listing_row.seller_id = buyer_id then
    raise exception 'You cannot buy your own listing';
  end if;

  select *
  into horse_row
  from public.horses
  where id = listing_row.horse_id
  for update;

  select coin_balance
  into buyer_balance
  from public.profiles
  where id = buyer_id
  for update;

  if buyer_balance is null then
    raise exception 'Buyer profile not found';
  end if;

  if buyer_balance < listing_row.buyer_price then
    raise exception 'Insufficient coin balance';
  end if;

  update public.profiles
  set coin_balance = coin_balance - listing_row.buyer_price,
      updated_at = timezone('utc', now())
  where id = buyer_id;

  update public.profiles
  set coin_balance = coin_balance + listing_row.seller_payout,
      updated_at = timezone('utc', now())
  where id = listing_row.seller_id;

  update public.horses
  set owner_id = buyer_id,
      transfer_count = horse_row.transfer_count + 1,
      is_public_listing = false,
      is_featured_profile_horse = false,
      is_listed_for_sale = false,
      updated_at = timezone('utc', now())
  where id = horse_row.id;

  update public.horse_listings
  set status = 'sold',
      sold_at = timezone('utc', now())
  where id = listing_row.id;

  return jsonb_build_object(
    'horse_id', horse_row.id,
    'registry_id', horse_row.registry_id,
    'buyer_coin_balance', buyer_balance - listing_row.buyer_price,
    'seller_payout', listing_row.seller_payout
  );
end;
$$;

grant execute on function public.purchase_horse_listing(uuid) to authenticated;
