import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('supabase schema includes launch-critical stable expansion fields', () {
    final schema = read('supabase/schema.sql');
    final renewalMigration = read(
      'supabase/migrations/20260428_add_stable_expansion_renewal.sql',
    );

    expect(schema, contains('stable_expansion_renews_at'));
    expect(renewalMigration, contains('stable_expansion_renews_at'));
  });

  test('supabase breeding functions use game-ready timers', () {
    final schema = read('supabase/schema.sql');
    final timerMigration = read(
      'supabase/migrations/20260428_game_ready_breeding_timers.sql',
    );

    for (final sql in [schema, timerMigration]) {
      expect(sql, contains("interval '4 days'"));
      expect(sql, contains("interval '3 days'"));
      expect(sql, contains("interval '12 hours'"));
      expect(sql, isNot(contains("interval '30 seconds'")));
    }
  });

  test(
    'supabase schema includes launch hardening tables and recovery guard',
    () {
      final schema = read('supabase/schema.sql');
      final launchHardeningMigration = read(
        'supabase/migrations/20260429_launch_hardening.sql',
      );

      for (final sql in [schema, launchHardeningMigration]) {
        expect(
          sql,
          contains('create table if not exists public.purchase_receipts'),
        );
        expect(sql, contains('create table if not exists public.app_admins'));
        expect(
          sql,
          contains('create table if not exists public.support_recovery_audits'),
        );
        expect(
          sql,
          contains(
            'create or replace function public.support_recover_profile_state',
          ),
        );
        expect(sql, contains('Admin access required'));
      }
    },
  );

  test('supabase schema includes live coin pack catalog', () {
    final schema = read('supabase/schema.sql');
    final coinPackMigration = read(
      'supabase/migrations/20260429_coin_pack_catalog.sql',
    );

    for (final sql in [schema, coinPackMigration]) {
      expect(sql, contains("'coins_1100', 'Stable Snack', 1100, 499"));
      expect(sql, contains("'coins_2500', 'Breeder Bundle', 2500, 999"));
      expect(
        sql,
        contains(
          "'coins_5000', 'Barn Vault', 5000, 1999, 'USD', 'Most popular'",
        ),
      );
      expect(
        sql,
        contains(
          "'coins_12000', 'Champion Chest', 12000, 4999, 'USD', 'Best value'",
        ),
      );
    }
  });

  test('supabase schema gates verified coin grants behind service role', () {
    final schema = read('supabase/schema.sql');
    final verifiedPurchaseMigration = read(
      'supabase/migrations/20260429_verified_coin_purchases.sql',
    );

    for (final sql in [schema, verifiedPurchaseMigration]) {
      expect(
        sql,
        contains(
          'create or replace function public.grant_verified_coin_purchase',
        ),
      );
      expect(
        sql,
        contains('coin_balance = coin_balance + pack_row.coin_amount'),
      );
      expect(sql, contains('from public, anon, authenticated'));
      expect(sql, contains('to service_role'));
    }
  });

  test('supabase signup trigger handles duplicate display-name handles', () {
    final schema = read('supabase/schema.sql');
    final signupFixMigration = read(
      'supabase/migrations/20260429_fix_signup_handle_collisions.sql',
    );

    for (final sql in [schema, signupFixMigration]) {
      expect(sql, contains('set search_path = public, auth'));
      expect(
        sql,
        contains(
          "if exists (select 1 from public.profiles where handle = profile_handle) then",
        ),
      );
      expect(
        sql,
        contains(
          "profile_handle := base_handle || substr(replace(new.id::text, '-', ''), 1, 8);",
        ),
      );
    }
  });

  test('supabase reserves simple globally unique horse registry IDs', () {
    final schema = read('supabase/schema.sql');
    final registryMigration = read(
      'supabase/migrations/20260429_horse_registry_allocator.sql',
    );

    for (final sql in [schema, registryMigration]) {
      expect(
        sql,
        contains(
          'create sequence if not exists public.horse_registry_number_seq',
        ),
      );
      expect(
        sql,
        contains('create or replace function public.reserve_horse_registry_id'),
      );
      expect(sql, contains("candidate := 'PH' || nextval"));
      expect(
        sql,
        contains(
          'grant execute on function public.reserve_horse_registry_id() to authenticated',
        ),
      );
    }
  });
}
