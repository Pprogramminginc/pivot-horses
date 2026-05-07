import 'package:flutter_test/flutter_test.dart';
import 'package:pivot_horses/data/sample/sample_horses.dart';
import 'package:pivot_horses/logic/services/horse_registry_service.dart';

void main() {
  const registry = HorseRegistryService();

  test('starter market registry IDs are simple growing numbers', () {
    final market = registry.assignStarterMarketRegistryIds(
      ownerId: 'owner-alpha',
      horses: starterMarketHorses.take(3),
      startingSequence: 101,
    );

    expect(market.map((horse) => horse.registryId), [
      'PH101',
      'PH102',
      'PH103',
    ]);
    expect(market.map((horse) => horse.registryId).toSet(), hasLength(3));
  });

  test('next available sequence skips existing registry IDs', () {
    final nextSequence = registry.nextAvailableSequence(
      currentSequence: 2000,
      existingRegistryIds: const ['PH2001', 'PH2002'],
      buildRegistryId: (sequence) => registry.foalRegistryId(
        breed: 'Arabian',
        ownerId: 'owner-x',
        sequence: sequence,
      ),
    );

    expect(nextSequence, 2003);
    expect(
      registry.foalRegistryId(
        breed: 'Arabian',
        ownerId: 'owner-x',
        sequence: nextSequence,
      ),
      'PH2003',
    );
  });
}
