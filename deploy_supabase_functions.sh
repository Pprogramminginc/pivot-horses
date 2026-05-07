#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI is not installed."
  echo "Install it with: brew install supabase/tap/supabase"
  exit 1
fi

supabase functions deploy verify-coin-purchase --project-ref fxwvhaalmvagjitfwnrg
