#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PSQL="/opt/homebrew/opt/libpq/bin/psql"
HOST="aws-1-us-west-2.pooler.supabase.com"
PORT="5432"
USER="postgres.fxwvhaalmvagjitfwnrg"
DATABASE="postgres"

if [ ! -x "$PSQL" ]; then
  echo "psql was not found at $PSQL"
  echo "Install it with: brew install libpq"
  exit 1
fi

echo "Paste your Supabase DATABASE password, then press Return."
echo "Nothing will appear while you type or paste. That is normal."
read -rs DB_PASSWORD
echo

PGPASSWORD="$DB_PASSWORD" "$PSQL" \
  -h "$HOST" \
  -p "$PORT" \
  -U "$USER" \
  -d "$DATABASE" \
  -v ON_ERROR_STOP=1 <<'SQL'
select
  'stable_expansion_renews_at column' as check_name,
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'stable_expansion_renews_at'
  ) as present;

select
  'resolve_mating_session function' as check_name,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'resolve_mating_session'
  ) as present;

select
  'deliver_pregnancy function' as check_name,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'deliver_pregnancy'
  ) as present;

select
  'timer values in resolve_mating_session' as check_name,
  pg_get_functiondef('public.resolve_mating_session(uuid)'::regprocedure) like '%interval ''4 days''%'
    and pg_get_functiondef('public.resolve_mating_session(uuid)'::regprocedure) like '%interval ''7 days''%'
    and pg_get_functiondef('public.resolve_mating_session(uuid)'::regprocedure) like '%interval ''12 hours''%' as present;

select
  'timer values in deliver_pregnancy' as check_name,
  pg_get_functiondef('public.deliver_pregnancy(uuid)'::regprocedure) like '%interval ''3 days''%' as present;

select
  'purchase_receipts table' as check_name,
  exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'purchase_receipts'
  ) as present;

select
  'support_recovery_audits table' as check_name,
  exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'support_recovery_audits'
  ) as present;

select
  'support_recover_profile_state function' as check_name,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'support_recover_profile_state'
  ) as present;

select
  'coin_packs catalog' as check_name,
  count(*) = 4
    and bool_or(product_id = 'coins_1100' and coin_amount = 1100 and price_cents = 499)
    and bool_or(product_id = 'coins_2500' and coin_amount = 2500 and price_cents = 999)
    and bool_or(product_id = 'coins_5000' and coin_amount = 5000 and price_cents = 1999 and badge = 'Most popular')
    and bool_or(product_id = 'coins_12000' and coin_amount = 12000 and price_cents = 4999 and badge = 'Best value') as present
from public.coin_packs
where product_id in ('coins_1100', 'coins_2500', 'coins_5000', 'coins_12000');

select
  'grant_verified_coin_purchase function' as check_name,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'grant_verified_coin_purchase'
  ) as present;
SQL

echo "Verification complete. Every row above should say present = t."
