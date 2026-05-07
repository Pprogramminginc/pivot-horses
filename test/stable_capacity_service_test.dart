import 'package:flutter_test/flutter_test.dart';
import 'package:pivot_horses/data/sample/sample_horses.dart';
import 'package:pivot_horses/domain/models/horse.dart';
import 'package:pivot_horses/logic/services/stable_capacity_service.dart';

void main() {
  List<Horse> stableRoster(int count) {
    return List.generate(count, (index) {
      final horse = starterMarketHorses[index % starterMarketHorses.length];
      return horse.copyWith(
        id: '${horse.id}_capacity_$index',
        registryId: '${horse.registryId}-$index',
        currentName: '${horse.currentName} $index',
      );
    });
  }

  test(
    'expired capacity removes lowest-rated overflow horses and pays purge value',
    () {
      final stableHorses = stableRoster(12);
      final expectedRemoved = List<Horse>.from(stableHorses)
        ..sort((left, right) {
          final scoreCompare = left.score.compareTo(right.score);
          if (scoreCompare != 0) {
            return scoreCompare;
          }
          final priceCompare = left.derivedPrice.compareTo(right.derivedPrice);
          if (priceCompare != 0) {
            return priceCompare;
          }
          return left.displayName.compareTo(right.displayName);
        });
      final expectedRemovedIds = expectedRemoved
          .take(2)
          .map((horse) => horse.id)
          .toSet();
      final expectedPayout = expectedRemoved
          .take(2)
          .fold<int>(0, (total, horse) => total + horse.purgePayout);

      final result = expireStableCapacity(stableHorses);

      expect(result.removedHorseIds, expectedRemovedIds);
      expect(result.keptHorses, hasLength(baseStableCap));
      expect(result.payout, expectedPayout);
    },
  );

  test('expired capacity keeps roster intact when at base capacity', () {
    final stableHorses = stableRoster(baseStableCap);
    final result = expireStableCapacity(stableHorses);

    expect(result.removedHorses, isEmpty);
    expect(result.keptHorses, stableHorses);
    expect(result.payout, 0);
  });
}
