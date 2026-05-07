#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PSQL="/opt/homebrew/opt/libpq/bin/psql"

if [ ! -x "$PSQL" ]; then
  echo "psql was not found at $PSQL"
  echo "Install it with: brew install libpq"
  exit 1
fi

echo "Paste your Supabase PostgreSQL connection string, then press Return."
echo "It should start with postgresql:// and NOT https://"
read -r DATABASE_URL

if [[ "$DATABASE_URL" != postgresql://* && "$DATABASE_URL" != postgres://* ]]; then
  echo "That does not look like a PostgreSQL connection string."
  echo "Use the URI from Supabase Project Settings > Database > Connection string."
  exit 1
fi

if [[ "$DATABASE_URL" == *"@db."*".supabase.co:"* ]]; then
  echo "This looks like Supabase's direct database connection string."
  echo "If it fails with 'Connection refused', copy the Session pooler URI instead:"
  echo "Supabase Dashboard > Connect > Session pooler"
  echo "It usually contains pooler.supabase.com and uses the username postgres.<project-ref>."
fi

"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260426_add_inventory_profile_state.sql
"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260428_add_stable_expansion_renewal.sql
"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260428_game_ready_breeding_timers.sql
"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260429_launch_hardening.sql
"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260429_coin_pack_catalog.sql
"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260429_verified_coin_purchases.sql
"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260429_fix_signup_handle_collisions.sql
"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260429_horse_registry_allocator.sql
"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260507_backend_inbox_items.sql
"$PSQL" "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260507_broadcast_inbox_function.sql

echo "Supabase migrations applied successfully."
