import 'package:flutter_test/flutter_test.dart';
import 'package:pivot_horses/data/repositories/game_state_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'loads supported older save versions instead of wiping progress',
    () async {
      SharedPreferences.setMockInitialValues({});
      const repository = GameStateRepository();
      const accountId = 'acct-save-migration';
      final now = DateTime.utc(2026, 5, 7, 12);

      await repository.saveState(
        accountId,
        PersistedGameState(
          currentTime: now,
          stableHorses: const [],
          marketHorses: const [],
          coinBalance: 4321,
          selectedIndex: 2,
          foalSequence: 2100,
          marketPurchaseSequence: 5100,
          likedHorseIds: const {'horse-1'},
          followedProfileIds: const {'profile-1'},
          communityListings: const [],
          breedingCooldowns: const [],
          activePregnancies: const [],
          inventory: const {},
          stableExpansionTier: 1,
          prenatalBoostedPregnancyIds: const {},
          carrotBoostedHorseIds: const {},
          readStableAlertIds: const {},
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final key = 'pivot_horses.game_state.v1.$accountId';
      final currentRaw = prefs.getString(key);
      expect(currentRaw, isNotNull);

      await prefs.setString(
        key,
        currentRaw!.replaceFirst('"version":6', '"version":5'),
      );

      final loaded = await repository.loadState(accountId);

      expect(loaded, isNotNull);
      expect(loaded!.coinBalance, 4321);
      expect(loaded.selectedIndex, 2);
      expect(loaded.currentTime, now);
      expect(loaded.stableExpansionTier, 1);
      expect(loaded.likedHorseIds, contains('horse-1'));
    },
  );

  test('ignores newer unknown save versions', () async {
    SharedPreferences.setMockInitialValues({
      'pivot_horses.game_state.v1.acct-future':
          '{"version":999,"currentTime":"2026-05-07T12:00:00.000Z"}',
    });

    const repository = GameStateRepository();

    expect(await repository.loadState('acct-future'), isNull);
  });
}
