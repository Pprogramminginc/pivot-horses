import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pivot_horses/domain/models/care_stats.dart';
import 'package:pivot_horses/domain/models/genetic_profile.dart';
import 'package:pivot_horses/domain/models/horse.dart';
import 'package:pivot_horses/domain/models/horse_trait.dart';
import 'package:pivot_horses/domain/models/rarity_tier.dart';
import 'package:pivot_horses/domain/models/starter_tier.dart';
import 'package:pivot_horses/logic/services/breeding_preview_service.dart';

void main() {
  group('ancestor inheritance weights', () {
    test('grandparent mane color lands around the 15 percent side bucket', () {
      const service = BreedingPreviewService();
      final random = Random(42);
      final dam = _horse(
        id: 'dam',
        sex: 'Mare',
        maneColor: 'Brown',
        lineageMemory: const {
          'mane_color': {'White': 1},
        },
      );
      final sire = _horse(id: 'sire', sex: 'Stallion', maneColor: 'Black');

      const trials = 20000;
      var inheritedGrandparentColor = 0;
      for (var i = 0; i < trials; i++) {
        final foal = service.generateFoal(
          dam: dam,
          sire: sire,
          random: random,
          sequence: i,
          isMutant: false,
        );
        if (foal.traitOption('mane_color') == 'White') {
          inheritedGrandparentColor++;
        }
      }

      final rate = inheritedGrandparentColor / trials;
      expect(rate, closeTo(0.15 / (0.30 + 0.30 + 0.15), 0.015));
    });

    test(
      'great-grandparent mane color lands around the 5 percent side bucket',
      () {
        const service = BreedingPreviewService();
        final random = Random(84);
        final dam = _horse(
          id: 'dam',
          sex: 'Mare',
          maneColor: 'Brown',
          lineageMemory: const {
            'mane_color': {'White': 2},
          },
        );
        final sire = _horse(id: 'sire', sex: 'Stallion', maneColor: 'Black');

        const trials = 20000;
        var inheritedGreatGrandparentColor = 0;
        for (var i = 0; i < trials; i++) {
          final foal = service.generateFoal(
            dam: dam,
            sire: sire,
            random: random,
            sequence: i,
            isMutant: false,
          );
          if (foal.traitOption('mane_color') == 'White') {
            inheritedGreatGrandparentColor++;
          }
        }

        final rate = inheritedGreatGrandparentColor / trials;
        expect(rate, closeTo(0.05 / (0.30 + 0.30 + 0.05), 0.012));
      },
    );

    test('mixed breeds roll close to 50/50 between both parents', () {
      const service = BreedingPreviewService();
      final random = Random(126);
      final dam = _horse(
        id: 'dam',
        sex: 'Mare',
        breed: 'Arabian',
        maneColor: 'Brown',
      );
      final sire = _horse(
        id: 'sire',
        sex: 'Stallion',
        breed: 'Percheron',
        maneColor: 'Black',
      );

      const trials = 20000;
      var arabianFoals = 0;
      for (var i = 0; i < trials; i++) {
        final foal = service.generateFoal(
          dam: dam,
          sire: sire,
          random: random,
          sequence: i,
          isMutant: false,
        );
        if (foal.breed == 'Arabian') {
          arabianFoals++;
        }
      }

      final rate = arabianFoals / trials;
      expect(rate, closeTo(0.5, 0.02));
    });

    test('preview notes tolerate parents with partial visible traits', () {
      const service = BreedingPreviewService();
      final dam = _horse(id: 'dam', sex: 'Mare', maneColor: 'Brown').copyWith(
        traits: _horse(
          id: 'dam-traits',
          sex: 'Mare',
          maneColor: 'Brown',
        ).traits.where((trait) => trait.type != 'tail_style').toList(),
      );
      final sire = _horse(id: 'sire', sex: 'Stallion', maneColor: 'Black')
          .copyWith(
            traits: _horse(
              id: 'sire-traits',
              sex: 'Stallion',
              maneColor: 'Black',
            ).traits.where((trait) => trait.type != 'eye_color').toList(),
          );

      final preview = service.preview(dam: dam, sire: sire);

      expect(preview.inheritanceNotes, isNotEmpty);
      expect(preview.likelyTraits['tail_style'], contains('Natural'));
      expect(preview.likelyTraits['eye_color'], contains('Brown'));
    });
  });
}

Horse _horse({
  required String id,
  required String sex,
  required String maneColor,
  String breed = 'Bay',
  Map<String, Map<String, int>> lineageMemory = const {},
}) {
  return Horse(
    id: id,
    registryId: 'REG-$id',
    registeredName: id,
    currentName: id,
    breed: breed,
    sex: sex,
    generation: 1,
    ageDays: 40,
    breedingRetirementDays: 365,
    traits: [
      const HorseTrait(
        type: 'mane_style',
        option: 'Natural',
        rarity: RarityTier.common,
      ),
      HorseTrait(
        type: 'mane_color',
        option: maneColor,
        rarity: RarityTier.common,
      ),
      const HorseTrait(
        type: 'tail_style',
        option: 'Natural',
        rarity: RarityTier.common,
      ),
      HorseTrait(
        type: 'tail_color',
        option: maneColor,
        rarity: RarityTier.common,
      ),
      const HorseTrait(
        type: 'eye_color',
        option: 'Brown',
        rarity: RarityTier.common,
      ),
      const HorseTrait(
        type: 'markings',
        option: 'None',
        rarity: RarityTier.common,
      ),
      const HorseTrait(
        type: 'body_type',
        option: 'Athletic',
        rarity: RarityTier.rare,
      ),
    ],
    starterTier: StarterTier.basic,
    price: 1000,
    geneticProfile: const GeneticProfile(
      breedingPotential: 'Test',
      bloodlineScore: 50,
      mutationAffinity: 1.0,
    ),
    careStats: const CareStats(
      hungerLevel: 80,
      happinessLevel: 80,
      energyLevel: 80,
      saltLickEnjoyment: 80,
    ),
    lineageMemory: lineageMemory,
  );
}
