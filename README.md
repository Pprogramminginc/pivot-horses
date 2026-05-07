# Pivot Horses

Pivot Horses is a Flutter iOS horse breeding game with layered horse rendering,
local fallback play, Supabase-backed accounts/community data, StoreKit coin
purchases, inbox/broadcast support, feedback collection, and launch support
logging.

## Current Scope

- Stable management with capacity limits, purge recovery, naming, visibility,
  care boosts, and newborn foal reveal state.
- Breeding flow with mate selection, previewed inheritance, mating timers,
  pregnancy timers, cooldowns, mutant flags, and foal delivery.
- Starter market, store items, coin balance, stable expansion, and StoreKit coin
  pack integration.
- Social/explore surfaces with public horses, featured profile horses, likes,
  follows, and community listings.
- Supabase integration for auth, profiles, horse registry IDs, community
  projection, inbox items, feedback, support snapshots, client event logs, error
  events, purchase receipts, and verified coin grants.
- Audio, haptics, app settings, local persistence, and offline/local account
  fallback.

## Project Layout

- `lib/app`: app bootstrap, backend mode selection, and theme.
- `lib/domain`: horse, trait, rarity, inventory, breeding, inbox, and account
  models.
- `lib/data`: repositories for auth, game state, community, inbox, settings,
  support, and sample data.
- `lib/logic`: horse rendering, breeding preview, registry, audio, and stable
  capacity services.
- `lib/presentation`: screens and widgets for the playable app.
- `supabase/schema_parts`: source SQL fragments for the canonical schema.
- `supabase/migrations`: deployment migrations for production Supabase.
- `supabase/functions`: Edge Functions, including StoreKit purchase
  verification.
- `assets`: horse layers, reference previews, audio, and item art.
- `test`: unit and widget tests for launch-critical behavior.

## Local Development

Install Flutter and CocoaPods, then from this folder:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Without Supabase compile-time values, the app runs in local fallback mode using
`SharedPreferences` accounts and game state.

## Supabase Mode

Pass the live project URL and anon key at build/run time:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

The app checks those values in `lib/app/backend/app_bootstrap.dart`. If both are
present, it initializes Supabase Auth with PKCE; otherwise it uses local mode.

### Database Deployment

Apply migrations in order:

```sh
./apply_supabase_migrations_with_password.sh
```

Then verify the live schema:

```sh
./verify_supabase_migrations_with_password.sh
```

The canonical schema is assembled in `supabase/schema.sql`; tests assert the
launch-critical tables/functions remain present.

### Edge Function Deployment

Deploy purchase verification:

```sh
./deploy_supabase_functions.sh
```

Required function secrets:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- Apple App Store verification credentials required by your App Store Server API
  setup.

## StoreKit Setup

The app expects these non-consumable/consumable coin product IDs from
`AppShell._coinProductIds` and `coin_pack_catalog`:

- `coins_1100`
- `coins_2500`
- `coins_5000`
- `coins_12000`

Before TestFlight, confirm all four products exist in App Store Connect, are
approved or ready for sandbox testing, and match the Supabase coin pack catalog:

- Stable Snack: 1,100 coins
- Breeder Bundle: 2,500 coins
- Barn Vault: 5,000 coins
- Champion Chest: 12,000 coins

## Release Checks

Run the local checks:

```sh
flutter analyze
flutter test
flutter build ios --release
```

Run the live smoke test with Supabase enabled:

1. Create a fresh account.
2. Confirm profile creation and unique handle generation.
3. Buy a starter horse and verify stable count/coin balance.
4. Breed a valid dam/sire pair and confirm mating/pregnancy timers.
5. Deliver a foal and verify registry ID uniqueness.
6. Make a horse public or listed, then verify social/explore projection.
7. Submit feedback and confirm it reaches `feedback_submissions` or the
   fallback `client_event_log`.
8. Send a broadcast inbox item and confirm the user can read/mark it read.
9. Kill and relaunch the app, then confirm local and backend state recover.
10. Sign out and sign back in.

Run the StoreKit sandbox test:

1. Product lookup returns all four coin packs.
2. Cancelled purchase leaves balance unchanged.
3. Successful purchase calls `verify-coin-purchase`.
4. Verified purchase updates Supabase and local coin balance.
5. Duplicate transaction is idempotent and reports `already_processed`.
6. Backend verification failure does not grant coins and logs an error event.
7. Pending/deferred purchase leaves the UI usable and recoverable.

## Production Monitoring

Supabase support tables are the current production visibility path:

- `client_event_log`: normal app events and fallback operational records.
- `error_events`: caught client-side failures with source, message, stack trace,
  and context.
- `support_snapshots`: user-exported support state keyed by support code.
- `feedback_submissions`: structured player feedback.
- `purchase_receipts`: StoreKit transaction records and verification status.
- `support_recovery_audits`: admin recovery trail for profile repair actions.

Before launch, create saved Supabase queries or dashboard views for recent
`error_events`, rejected/pending `purchase_receipts`, and feedback volume.

## App Store Handoff

Prepare these before submission:

- App icon and launch screen reviewed on real devices.
- Privacy policy URL and support URL.
- App Store screenshots for current iPhone sizes.
- Age rating and content declarations.
- IAP metadata for all four coin packs.
- TestFlight build notes with Supabase project, StoreKit sandbox account, and
  smoke-test account instructions.
- Export compliance and data collection answers aligned with Supabase Auth,
  purchases, feedback, and support logs.

## Notes

- Local save state currently supports versions `1` through `6` and writes version
  `6`.
- Future save-state schema changes should add explicit migration tests in
  `test/game_state_repository_migration_test.dart`.
- Do not deploy with local fallback mode by accident; production/TestFlight
  builds should include `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
