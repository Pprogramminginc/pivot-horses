#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

SUPABASE_URL="https://fxwvhaalmvagjitfwnrg.supabase.co"

echo "Paste your Supabase anon/publishable key, then press Return."
echo "This is safe for the app; do not paste the database password here."
read -r SUPABASE_ANON_KEY

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
