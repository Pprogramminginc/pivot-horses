#!/usr/bin/env bash
set -euo pipefail

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI is not installed."
  echo "Install it with: brew install supabase/tap/supabase"
  exit 1
fi

read -r -p "Apple iOS bundle id: " APPLE_BUNDLE_ID
read -r -s -p "Apple app-specific shared secret (press Return to skip): " APPLE_SHARED_SECRET
echo

if [ -z "$APPLE_SHARED_SECRET" ]; then
  supabase secrets set \
    --project-ref fxwvhaalmvagjitfwnrg \
    APPLE_BUNDLE_ID="$APPLE_BUNDLE_ID"
else
  supabase secrets set \
    --project-ref fxwvhaalmvagjitfwnrg \
    APPLE_BUNDLE_ID="$APPLE_BUNDLE_ID" \
    APPLE_SHARED_SECRET="$APPLE_SHARED_SECRET"
fi
