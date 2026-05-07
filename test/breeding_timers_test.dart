import 'package:flutter_test/flutter_test.dart';
import 'package:pivot_horses/domain/models/horse.dart';
import 'package:pivot_horses/logic/services/breeding_preview_service.dart';

void main() {
  test('breeding timers use game-ready durations', () {
    expect(BreedingPreviewService.pregnancyDuration, const Duration(days: 4));
    expect(
      BreedingPreviewService.marePostBirthCooldownDuration,
      const Duration(days: 3),
    );
    expect(BreedingPreviewService.damCooldownDuration, const Duration(days: 7));
    expect(
      BreedingPreviewService.sireCooldownDuration,
      const Duration(hours: 12),
    );
    expect(Horse.breedingReadyAgeDays, 5);
  });
}
