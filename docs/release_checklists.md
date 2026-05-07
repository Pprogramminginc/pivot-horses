# Pivot Horses Release Checklists

Use these checklists for every TestFlight candidate and App Store release.

## 1. Local Build Gate

- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build ios --release`
- [ ] Confirm the build used production `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- [ ] Confirm no local-only test account data is embedded in assets or code.

## 2. Live Supabase Smoke Test

- [ ] Create a fresh Supabase-backed account.
- [ ] Sign out, sign in, and verify the same profile returns.
- [ ] Confirm `profiles` has a unique handle and starting profile state.
- [ ] Open Stable and verify the starter/empty state is understandable.
- [ ] Buy a starter market horse.
- [ ] Confirm `horse_registry` or the reserved ID path generates a unique `PH`
  registry ID.
- [ ] Confirm the stable count, stable cap, and coin balance update.
- [ ] Breed a valid dam/sire pair.
- [ ] Confirm mating timer, pregnancy timer, and cooldowns are visible.
- [ ] Deliver the foal.
- [ ] Confirm foal traits, parent snapshots, registry ID, and newborn reveal.
- [ ] Make a horse public or featured.
- [ ] Confirm social/explore projection updates.
- [ ] List a horse for sale.
- [ ] Purchase a community listing from another test account.
- [ ] Submit feedback from Profile.
- [ ] Confirm `feedback_submissions` receives the row, or fallback lands in
  `client_event_log`.
- [ ] Send a broadcast with `send_broadcast_inbox_item`.
- [ ] Confirm the app inbox receives it and mark-read persists.
- [ ] Kill the app, relaunch, and verify state restoration.
- [ ] Verify recent `client_event_log` entries look useful and not noisy.
- [ ] Verify no unexpected `error_events` were created.

## 3. StoreKit Sandbox Test

- [ ] Confirm App Store Connect has all four product IDs:
  `coins_1100`, `coins_2500`, `coins_5000`, `coins_12000`.
- [ ] Confirm Supabase `coin_pack_catalog` matches the product IDs and coin
  amounts.
- [ ] Sign into a sandbox Apple account on the test device.
- [ ] Open Profile and confirm coin purchases are available.
- [ ] Product lookup returns all four packs.
- [ ] Cancel a purchase and confirm the coin balance does not change.
- [ ] Complete one purchase and confirm the UI shows the new balance.
- [ ] Confirm `verify-coin-purchase` was invoked.
- [ ] Confirm `purchase_receipts.status = 'verified'`.
- [ ] Replay/restore the same transaction and confirm it is idempotent.
- [ ] Force a backend verification failure and confirm no coins are granted.
- [ ] Confirm failed verification creates an `error_events` or warning log row.
- [ ] Test pending/deferred purchase state and confirm the app remains usable.

## 4. First-Session Polish

- [ ] New user can tell what to do first within 10 seconds.
- [ ] Stable empty state points toward Market or first horse acquisition.
- [ ] Market purchase copy explains stable slots and coins clearly.
- [ ] Breed screen explains why a pair is unavailable.
- [ ] Pregnancy and foal delivery states are visually obvious.
- [ ] Profile clearly exposes settings, support, feedback, and coin purchases.
- [ ] No screen has clipped text on narrow iPhone widths.
- [ ] Audio/haptics default feels pleasant and can be disabled.
- [ ] Offline/local fallback copy does not appear in production Supabase builds
  except for true backend failure states.

## 5. Production Visibility

- [ ] Saved query for recent `error_events` by `created_at desc`.
- [ ] Saved query for pending/rejected `purchase_receipts`.
- [ ] Saved query for recent feedback by category.
- [ ] Saved query for support snapshots by support code.
- [ ] App admin account exists in `app_admins`.
- [ ] Recovery function tested against a disposable profile.
- [ ] Support response template includes support code, email, profile ID, and
  approximate event time.

## 6. App Store Submission

- [ ] App icon final.
- [ ] Launch screen final.
- [ ] App name, subtitle, description, keywords, and category final.
- [ ] Support URL live.
- [ ] Privacy policy URL live.
- [ ] Screenshots generated from current build.
- [ ] Age rating complete.
- [ ] Data collection answers match Supabase Auth, purchases, support logs, and
  feedback collection.
- [ ] All four IAP products have names, descriptions, screenshots if required,
  pricing, and review notes.
- [ ] TestFlight tester notes include login/setup instructions.
- [ ] Export compliance answered.
- [ ] Build uploaded and processed in App Store Connect.

## 7. Release Decision

- [ ] Local gate passed.
- [ ] Live Supabase smoke test passed.
- [ ] StoreKit sandbox passed.
- [ ] No open P0/P1 bugs.
- [ ] Known P2 issues are documented.
- [ ] Rollback/recovery plan is written.
- [ ] Final build number recorded.
