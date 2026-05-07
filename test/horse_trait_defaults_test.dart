import 'package:flutter_test/flutter_test.dart';
import 'package:pivot_horses/domain/models/care_stats.dart';
import 'package:pivot_horses/domain/models/genetic_profile.dart';
import 'package:pivot_horses/domain/models/horse.dart';
import 'package:pivot_horses/domain/models/horse_trait.dart';
import 'package:pivot_horses/domain/models/horse_trait_defaults.dart';
import 'package:pivot_horses/domain/models/rarity_tier.dart';
import 'package:pivot_horses/domain/models/starter_tier.dart';
import 'package:pivot_horses/logic/services/horse_renderer_service.dart';

void main() {
  test('fills missing core visible traits for older horse records', () {
    final horse = _horse(
      traits: const [
        HorseTrait(
          type: 'saddle',
          option: 'Silver',
          rarity: RarityTier.legendary,
        ),
      ],
    );

    final normalized = normalizeHorseVisibleTraits(horse);

    expect(normalized.traitOption('mane_style'), 'Short');
    expect(normalized.traitOption('tail_style'), 'Short');
    expect(normalized.traitOption('tail_color'), 'Brown');
    expect(normalized.traitOption('body_type'), 'Compact');
    expect(normalized.traitOfOrNull('saddle')?.option, 'Silver');
  });

  test('renderer uses an existing tail asset for normalized old records', () {
    final horse = _horse(traits: const []);

    final tailLayer = const HorseRendererService()
        .buildLayers(horse)
        .singleWhere((layer) => layer.slot == 'tail');

    expect(
      tailLayer.assetPath,
      'assets/horses/compiled/tail/tail_short_brown.png',
    );
  });
}

Horse _horse({required List<HorseTrait> traits}) {
  return Horse(
    id: 'horse-old',
    registryId: 'PH-SHE-2004',
    registeredName: 'popito Vale',
    currentName: 'popito Vale',
    breed: 'Shetland Pony',
    sex: 'Mare',
    generation: 1,
    ageDays: 7,
    breedingRetirementDays: Horse.breedingRetirementAgeDays,
    traits: traits,
    starterTier: StarterTier.basic,
    price: 646,
    geneticProfile: const GeneticProfile(
      breedingPotential: 'Developing young line',
      bloodlineScore: 25,
      mutationAffinity: 0.7,
    ),
    careStats: const CareStats(
      hungerLevel: 80,
      happinessLevel: 80,
      energyLevel: 80,
      saltLickEnjoyment: 80,
    ),
    lineageMemory: const {
      'mane_color': {'Brown': 1},
    },
  );
}
