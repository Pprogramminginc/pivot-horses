import '../../domain/models/horse.dart';

const int baseStableCap = 10;

class StableCapacityExpirationResult {
  const StableCapacityExpirationResult({
    required this.keptHorses,
    required this.removedHorses,
    required this.payout,
  });

  final List<Horse> keptHorses;
  final List<Horse> removedHorses;
  final int payout;

  Set<String> get removedHorseIds =>
      removedHorses.map((horse) => horse.id).toSet();
}

StableCapacityExpirationResult expireStableCapacity(List<Horse> stableHorses) {
  final removedHorses = horsesRemovedForExpiredCapacity(stableHorses);
  final removedIds = removedHorses.map((horse) => horse.id).toSet();
  final keptHorses = stableHorses
      .where((horse) => !removedIds.contains(horse.id))
      .toList();
  final payout = removedHorses.fold<int>(
    0,
    (total, horse) => total + horse.purgePayout,
  );

  return StableCapacityExpirationResult(
    keptHorses: keptHorses,
    removedHorses: removedHorses,
    payout: payout,
  );
}

List<Horse> horsesRemovedForExpiredCapacity(List<Horse> stableHorses) {
  final overflow = stableHorses.length - baseStableCap;
  if (overflow <= 0) {
    return const [];
  }

  final horsesByLowestRating = List<Horse>.from(stableHorses)
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
  return horsesByLowestRating.take(overflow).toList();
}
