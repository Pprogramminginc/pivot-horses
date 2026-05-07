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

run_migration() {
  local file="$1"
  echo "Applying $file"
  PGPASSWORD="$DB_PASSWORD" "$PSQL" \
    -h "$HOST" \
    -p "$PORT" \
    -U "$USER" \
    -d "$DATABASE" \
    -v ON_ERROR_STOP=1 \
    -f "$file"
}

run_migration supabase/migrations/20260426_add_inventory_profile_state.sql
run_migration supabase/migrations/20260428_add_stable_expansion_renewal.sql
run_migration supabase/migrations/20260428_game_ready_breeding_timers.sql
run_migration supabase/migrations/20260429_launch_hardening.sql
run_migration supabase/migrations/20260429_coin_pack_catalog.sql
run_migration supabase/migrations/20260429_verified_coin_purchases.sql
run_migration supabase/migrations/20260429_fix_signup_handle_collisions.sql
run_migration supabase/migrations/20260429_horse_registry_allocator.sql
run_migration supabase/migrations/20260507_backend_inbox_items.sql
run_migration supabase/migrations/20260507_broadcast_inbox_function.sql

echo "Supabase migrations applied successfully."
