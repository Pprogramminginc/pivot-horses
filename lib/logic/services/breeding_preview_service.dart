import 'dart:math';

import '../../domain/models/breeding_preview.dart';
import '../../domain/models/care_stats.dart';
import '../../domain/models/genetic_profile.dart';
import '../../domain/models/horse.dart';
import '../../domain/models/horse_trait.dart';
import '../../domain/models/pregnancy_record.dart';
import '../../domain/models/rarity_tier.dart';
import '../../domain/models/starter_tier.dart';

class BreedingPreviewService {
  const BreedingPreviewService();

  static const Duration pregnancyDuration = Duration(days: 4);
  static const Duration damCooldownDuration = Duration(days: 7);
  static const Duration sireCooldownDuration = Duration(hours: 12);
  static const Duration marePostBirthCooldownDuration = Duration(days: 3);
  static const double _baseSaddleFoalChance = 0.08;

  BreedingPreview preview({required Horse dam, required Horse sire}) {
    final mutationChance = _mutationChance(dam, sire);
    final likelyTraits = <String, List<String>>{
      'mane_style': _previewOptions(
        dam: dam,
        sire: sire,
        traitType: 'mane_style',
        carrierOptions: _ancestorOptionsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'mane_style',
        ),
      ),
      'mane_color': _previewOptions(
        dam: dam,
        sire: sire,
        traitType: 'mane_color',
        carrierOptions: _ancestorOptionsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'mane_color',
        ),
      ),
      'tail_style': _previewOptions(
        dam: dam,
        sire: sire,
        traitType: 'tail_style',
        carrierOptions: _ancestorOptionsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'tail_style',
        ),
      ),
      'tail_color': _previewOptions(
        dam: dam,
        sire: sire,
        traitType: 'tail_color',
        carrierOptions: _ancestorOptionsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'tail_color',
        ),
      ),
      'eye_color': _previewOptions(
        dam: dam,
        sire: sire,
        traitType: 'eye_color',
        carrierOptions: _ancestorOptionsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'eye_color',
        ),
      ),
      'markings': _previewOptions(
        dam: dam,
        sire: sire,
        traitType: 'markings',
        carrierOptions: _ancestorOptionsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'markings',
        ),
      ),
      'body_type': _previewOptions(
        dam: dam,
        sire: sire,
        traitType: 'body_type',
        carrierOptions: _ancestorOptionsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'body_type',
        ),
      ),
      if (_traitExistsInLineage(dam, sire, 'saddle'))
        'saddle': _previewOptions(
          dam: dam,
          sire: sire,
          traitType: 'saddle',
          carrierOptions: _ancestorOptionsForTrait(
            dam: dam,
            sire: sire,
            traitType: 'saddle',
          ),
        ),
    };

    final projectedTraitScore = likelyTraits.entries.fold<double>(0, (
      sum,
      entry,
    ) {
      if (entry.value.isEmpty) {
        return sum;
      }
      final traitAverage =
          entry.value
              .map((option) => Horse.traitOptionValueScore(entry.key, option))
              .reduce((left, right) => left + right) /
          entry.value.length;
      return sum + traitAverage;
    });
    final projectedScore =
        ((((dam.geneticProfile.bloodlineScore +
                            sire.geneticProfile.bloodlineScore) /
                        2) *
                    0.7) +
                (projectedTraitScore * 2) +
                (mutationChance * 12))
            .round();
    final projectedRarityLabel = Horse.rarityFromScore(projectedScore).label;

    return BreedingPreview(
      breed: _previewBreedLabel(dam, sire),
      likelyTraits: likelyTraits,
      mutationChance: mutationChance,
      projectedRarityLabel: projectedRarityLabel,
      inheritanceNotes: _buildInheritanceNotes(dam, sire, likelyTraits),
      mutationSummary: _buildMutationSummary(dam, sire, mutationChance),
      raritySummary: _buildRaritySummary(dam, sire, projectedRarityLabel),
      possibleSpecialTraits: _previewSpecialTraits(dam, sire),
    );
  }

  PregnancyRecord createPregnancy({
    required Horse dam,
    required Horse sire,
    required DateTime now,
    required Random random,
    required int sequence,
    required bool isMutant,
    String? registryId,
  }) {
    final foal = generateFoal(
      dam: dam,
      sire: sire,
      random: random,
      sequence: sequence,
      isMutant: isMutant,
      registryId: registryId,
    );
    final unbornName = _buildUnbornName(dam, sire, foal, isMutant);

    return PregnancyRecord(
      id: 'pregnancy_${dam.id}_${sire.id}_$sequence',
      damId: dam.id,
      damName: dam.displayName,
      sireId: sire.id,
      sireName: sire.displayName,
      unbornFoalName: unbornName,
      registryId: foal.registryId,
      breed: foal.breed,
      foal: foal,
      conceivedAt: now,
      dueAt: now.add(pregnancyDuration),
      damCooldownEndsAt: now.add(damCooldownDuration),
      sireCooldownEndsAt: now.add(sireCooldownDuration),
      isMutant: isMutant,
    );
  }

  Horse generateFoal({
    required Horse dam,
    required Horse sire,
    required Random random,
    required int sequence,
    required bool isMutant,
    String? registryId,
  }) {
    final breed = _rollBreed(dam, sire, random);
    final generation = 1;
    final visibleTraits = <HorseTrait>[
      _inheritTrait(
        dam: dam,
        sire: sire,
        traitType: 'mane_style',
        random: random,
        isMutant: isMutant,
        ancestorWeights: _ancestorWeightsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'mane_style',
        ),
      ),
      _inheritTrait(
        dam: dam,
        sire: sire,
        traitType: 'mane_color',
        random: random,
        isMutant: isMutant,
        ancestorWeights: _ancestorWeightsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'mane_color',
        ),
      ),
      _inheritTrait(
        dam: dam,
        sire: sire,
        traitType: 'tail_style',
        random: random,
        isMutant: isMutant,
        ancestorWeights: _ancestorWeightsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'tail_style',
        ),
      ),
      _inheritTrait(
        dam: dam,
        sire: sire,
        traitType: 'tail_color',
        random: random,
        isMutant: isMutant,
        ancestorWeights: _ancestorWeightsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'tail_color',
        ),
      ),
      _inheritTrait(
        dam: dam,
        sire: sire,
        traitType: 'eye_color',
        random: random,
        isMutant: isMutant,
        ancestorWeights: _ancestorWeightsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'eye_color',
        ),
      ),
      _inheritTrait(
        dam: dam,
        sire: sire,
        traitType: 'markings',
        random: random,
        isMutant: isMutant,
        ancestorWeights: _ancestorWeightsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'markings',
        ),
      ),
      _inheritTrait(
        dam: dam,
        sire: sire,
        traitType: 'body_type',
        random: random,
        isMutant: isMutant,
        ancestorWeights: _ancestorWeightsForTrait(
          dam: dam,
          sire: sire,
          traitType: 'body_type',
        ),
      ),
    ];
    final rolledSaddleTrait = _rollSaddleTrait(
      dam: dam,
      sire: sire,
      random: random,
      isMutant: isMutant,
    );
    if (rolledSaddleTrait != null) {
      visibleTraits.add(rolledSaddleTrait);
    }

    final specialTraits = _rollSpecialTraits(
      dam: dam,
      sire: sire,
      foalTraits: visibleTraits,
      random: random,
      isMutant: isMutant,
    );
    final bloodlineScore = _rollBloodlineScore(dam, sire, random, isMutant);
    final mutationAffinity =
        ((dam.geneticProfile.mutationAffinity +
                sire.geneticProfile.mutationAffinity) /
            2) +
        (isMutant ? 0.25 : 0.0);
    final resolvedRegistryId =
        registryId ?? _buildRegistryId(breed: breed, sequence: sequence);
    final registeredName = _buildRegisteredName(
      dam: dam,
      sire: sire,
      foalTraits: visibleTraits,
      isMutant: isMutant,
      random: random,
    );
    final foalSex = random.nextBool() ? 'Mare' : 'Stallion';
    const foalRetirementDays = Horse.breedingRetirementAgeDays;

    return Horse(
      id: 'foal_$sequence',
      registryId: resolvedRegistryId,
      registeredName: registeredName,
      currentName: registeredName,
      breed: breed,
      sex: foalSex,
      generation: generation,
      ageDays: 0,
      breedingRetirementDays: foalRetirementDays,
      traits: visibleTraits,
      starterTier: _starterTierFromScore(bloodlineScore),
      price: Horse.calculateMarketPrice(
        breed: breed,
        sex: foalSex,
        generation: generation,
        ageDays: 0,
        breedingRetirementDays: foalRetirementDays,
        breedingCoreScore: bloodlineScore,
        traits: visibleTraits,
        specialTraits: specialTraits,
        isMutant: isMutant,
      ),
      geneticProfile: GeneticProfile(
        breedingPotential: _breedingPotentialLabel(bloodlineScore, isMutant),
        bloodlineScore: bloodlineScore,
        mutationAffinity: mutationAffinity,
        rareTraitChances: _mergeRareTraitChances(dam, sire, isMutant),
      ),
      careStats: CareStats(
        hungerLevel: 72 + random.nextInt(12),
        happinessLevel: 80 + random.nextInt(14),
        energyLevel: 78 + random.nextInt(18),
        saltLickEnjoyment: 65 + random.nextInt(26),
      ),
      specialTraits: specialTraits,
      lineageMemory: _buildLineageMemory(dam: dam, sire: sire),
      isMutant: isMutant,
      damSnapshot: dam.copyWith(),
      sireSnapshot: sire.copyWith(),
    );
  }

  Horse renameFoal(Horse foal, String chosenName) {
    return foal.copyWith(currentName: chosenName);
  }

  List<String> _previewOptions({
    required Horse dam,
    required Horse sire,
    required String traitType,
    List<String> carrierOptions = const [],
    bool forcePoolOnly = false,
  }) {
    if (forcePoolOnly) {
      return List<String>.from(_traitPool[traitType] ?? const <String>[]);
    }

    final options = <String>{
      if (dam.traitOfOrNull(traitType) case final trait?) trait.option,
      if (sire.traitOfOrNull(traitType) case final trait?) trait.option,
      ...carrierOptions,
    }.where((value) => value != 'None' && value != 'Unknown').toList();

    if (options.isEmpty) {
      final fallback =
          dam.traitOfOrNull(traitType)?.option ??
          sire.traitOfOrNull(traitType)?.option;
      if (fallback != null) {
        options.add(fallback);
      }
    }

    return options.take(3).toList();
  }

  List<String> _previewSpecialTraits(Horse dam, Horse sire) {
    final candidates = <String>{
      ...dam.specialTraits,
      ...sire.specialTraits,
      ...dam.geneticProfile.rareTraitChances.keys,
      ...sire.geneticProfile.rareTraitChances.keys,
    }.where((trait) => _specialTraitPool.contains(_titleCase(trait)));
    return candidates.take(3).toList();
  }

  List<String> _ancestorOptionsForTrait({
    required Horse dam,
    required Horse sire,
    required String traitType,
  }) {
    return _ancestorWeightsForTrait(
      dam: dam,
      sire: sire,
      traitType: traitType,
    ).keys.toList();
  }

  Map<String, double> _ancestorWeightsForTrait({
    required Horse dam,
    required Horse sire,
    required String traitType,
  }) {
    final weighted = <String, double>{};
    _addSnapshotAncestorWeights(weighted, root: dam, traitType: traitType);
    _addSnapshotAncestorWeights(weighted, root: sire, traitType: traitType);

    if (weighted.isEmpty && _lineageMemoryTraits.contains(traitType)) {
      _addLegacyLineageWeights(weighted, horse: dam, traitType: traitType);
      _addLegacyLineageWeights(weighted, horse: sire, traitType: traitType);
    }

    return weighted;
  }

  Map<String, Map<String, int>> _buildLineageMemory({
    required Horse dam,
    required Horse sire,
  }) {
    final memory = <String, Map<String, int>>{};

    for (final traitType in _lineageMemoryTraits) {
      final traitDepths = <String, int>{};

      void include(String option, int depth) {
        if (option == 'Unknown' || option == 'None') {
          return;
        }
        final normalized = _normalizedInheritedOption(traitType, option);
        final current = traitDepths[normalized];
        if (current == null || depth < current) {
          traitDepths[normalized] = depth;
        }
      }

      include(dam.traitOption(traitType), 1);
      include(sire.traitOption(traitType), 1);

      void includeAncestorDepths(Horse horse) {
        for (final entry in horse.lineageTraitDepths(traitType).entries) {
          include(entry.key, entry.value + 1);
        }
      }

      includeAncestorDepths(dam);
      includeAncestorDepths(sire);

      if (traitDepths.isNotEmpty) {
        memory[traitType] = traitDepths;
      }
    }

    return memory;
  }

  List<String> _buildInheritanceNotes(
    Horse dam,
    Horse sire,
    Map<String, List<String>> likelyTraits,
  ) {
    String traitLabel(String key) => key.replaceAll('_', ' ');

    String summarizeParentLead(String traitType) {
      final damOption = dam.traitOfOrNull(traitType)?.option;
      final sireOption = sire.traitOfOrNull(traitType)?.option;
      if (damOption != null && sireOption != null) {
        if (damOption == sireOption) {
          return '${traitLabel(traitType)} is locked strongly because both parents carry $damOption.';
        }
        return '${traitLabel(traitType)} can swing between $damOption from mom and $sireOption from sire.';
      }
      if (damOption != null) {
        return '${traitLabel(traitType)} leans on $damOption from mom, with family rolls still able to widen the result.';
      }
      if (sireOption != null) {
        return '${traitLabel(traitType)} leans on $sireOption from sire, with family rolls still able to widen the result.';
      }
      return '${traitLabel(traitType)} will roll from available family traits if neither parent has a direct visible record.';
    }

    final notes = <String>[
      summarizeParentLead('mane_style'),
      summarizeParentLead('mane_color'),
      summarizeParentLead('tail_style'),
      summarizeParentLead('tail_color'),
      summarizeParentLead('eye_color'),
      'Markings and body type pull from the parent pair first, then rare rolls can widen the result.',
      if (likelyTraits.containsKey('saddle'))
        'Saddle is a legendary inheritance lane here, so this pairing can pass along tack color even though the starter preview art stays unchanged.',
      'Every pairing also has a low but real chance to spark a legendary saddle trait even without an existing carrier in the line.',
    ];

    final carrierSurprise = likelyTraits.entries.firstWhere(
      (entry) => entry.value.length >= 3,
      orElse: () => const MapEntry('', <String>[]),
    );
    if (carrierSurprise.key.isNotEmpty) {
      notes.add(
        '${traitLabel(carrierSurprise.key)} has a surprise lane in play, so the foal can reveal a hidden family option.',
      );
    }
    return notes;
  }

  String _buildMutationSummary(Horse dam, Horse sire, double mutationChance) {
    final percent = (mutationChance * 100).toStringAsFixed(1);
    final affinity =
        ((dam.geneticProfile.mutationAffinity +
                    sire.geneticProfile.mutationAffinity) /
                2)
            .toStringAsFixed(2);
    return 'Mutation sits at $percent% with a blended affinity of $affinity, so rare visuals can still break through after the parent traits lock in.';
  }

  String _buildRaritySummary(
    Horse dam,
    Horse sire,
    String projectedRarityLabel,
  ) {
    final strongestParent = dam.breedingRarity.rank >= sire.breedingRarity.rank
        ? dam
        : sire;
    return '$projectedRarityLabel is the current foal lane, with ${strongestParent.displayName} setting the stronger breeding floor.';
  }

  double _mutationChance(Horse dam, Horse sire) {
    final affinity =
        (dam.geneticProfile.mutationAffinity +
            sire.geneticProfile.mutationAffinity) /
        2;
    final rareBonus =
        (dam.geneticProfile.rareTraitChances.values.fold<double>(
              0,
              (sum, value) => sum + value,
            ) +
            sire.geneticProfile.rareTraitChances.values.fold<double>(
              0,
              (sum, value) => sum + value,
            )) *
        0.12;
    return ((0.045 + ((affinity - 1) * 0.10) + rareBonus).clamp(0.05, 0.24)
            as num)
        .toDouble();
  }

  HorseTrait _inheritTrait({
    required Horse dam,
    required Horse sire,
    required String traitType,
    required Random random,
    bool isMutant = false,
    Map<String, double> ancestorWeights = const {},
    bool forcePoolOnly = false,
  }) {
    final weighted = forcePoolOnly
        ? {
            for (final option in _traitPool[traitType] ?? const <String>[])
              option: 1.0,
          }
        : <String, double>{
            if (dam.traitOfOrNull(traitType) case final trait?)
              _normalizedInheritedOption(traitType, trait.option): 0.30,
            if (sire.traitOfOrNull(traitType) case final trait?)
              _normalizedInheritedOption(traitType, trait.option): 0.30,
            for (final entry in ancestorWeights.entries)
              _normalizedInheritedOption(traitType, entry.key): entry.value,
          };

    if (weighted.isEmpty) {
      final fallbackPool = _traitPool[traitType] ?? const <String>[];
      for (final option in fallbackPool) {
        weighted[option] = 1.0;
      }
    }

    if (isMutant) {
      for (final option in _rareOptions[traitType] ?? const <String>[]) {
        weighted.update(option, (value) => value + 0.22, ifAbsent: () => 0.22);
      }
    }

    final selected = _rollWeightedOption(weighted, random);
    return HorseTrait(
      type: traitType,
      option: selected,
      rarity: _traitRarity(traitType, selected, isMutant: isMutant),
    );
  }

  HorseTrait? _rollSaddleTrait({
    required Horse dam,
    required Horse sire,
    required Random random,
    required bool isMutant,
  }) {
    final ancestorWeights = _ancestorWeightsForTrait(
      dam: dam,
      sire: sire,
      traitType: 'saddle',
    );
    final hasDamSaddle = dam.traitOfOrNull('saddle') != null;
    final hasSireSaddle = sire.traitOfOrNull('saddle') != null;
    final hasLineageSaddle =
        hasDamSaddle || hasSireSaddle || ancestorWeights.isNotEmpty;

    final chance = switch ((hasDamSaddle, hasSireSaddle, hasLineageSaddle)) {
      (true, true, _) => 0.32,
      (true, false, _) || (false, true, _) => 0.20,
      (false, false, true) => 0.12,
      _ => _baseSaddleFoalChance,
    };
    final boostedChance = isMutant ? min(chance + 0.04, 0.30) : chance;
    if (random.nextDouble() >= boostedChance) {
      return null;
    }

    return _inheritTrait(
      dam: dam,
      sire: sire,
      traitType: 'saddle',
      random: random,
      isMutant: isMutant,
      ancestorWeights: ancestorWeights,
      forcePoolOnly: !hasLineageSaddle,
    );
  }

  List<String> _rollSpecialTraits({
    required Horse dam,
    required Horse sire,
    required List<HorseTrait> foalTraits,
    required Random random,
    required bool isMutant,
  }) {
    final selected = <String>{};
    final rareTraitPool = _mergeRareTraitChances(dam, sire, isMutant);

    rareTraitPool.forEach((trait, chance) {
      if (!_specialTraitPool.contains(_titleCase(trait))) {
        return;
      }
      final rollChance = isMutant ? min(chance + 0.16, 0.45) : chance;
      if (random.nextDouble() < rollChance) {
        selected.add(_titleCase(trait));
      }
    });

    if (isMutant) {
      selected.add('Mutant Line');
      if (!selected.any((trait) => trait == 'Iridescent')) {
        selected.add(random.nextBool() ? 'Iridescent' : 'Metallic Sheen');
      }
    }

    return selected.toList();
  }

  Map<String, double> _mergeRareTraitChances(
    Horse dam,
    Horse sire,
    bool isMutant,
  ) {
    final merged = <String, double>{};
    for (final entry in dam.geneticProfile.rareTraitChances.entries) {
      merged[entry.key] = max(merged[entry.key] ?? 0, entry.value);
    }
    for (final entry in sire.geneticProfile.rareTraitChances.entries) {
      merged[entry.key] = max(merged[entry.key] ?? 0, entry.value);
    }
    if (isMutant) {
      merged.updateAll((key, value) => min(value + 0.12, 0.40));
    }
    return merged;
  }

  int _rollBloodlineScore(Horse dam, Horse sire, Random random, bool isMutant) {
    final base =
        ((dam.geneticProfile.bloodlineScore +
                    sire.geneticProfile.bloodlineScore) /
                2)
            .round();
    final variation = random.nextInt(11) - 5;
    final specialBonus = isMutant ? 8 : 0;
    return (base + variation + specialBonus).clamp(35, 98);
  }

  StarterTier _starterTierFromScore(int score) {
    if (score >= 76) {
      return StarterTier.premium;
    }
    if (score >= 56) {
      return StarterTier.promising;
    }
    return StarterTier.basic;
  }

  String _breedingPotentialLabel(int score, bool isMutant) {
    if (isMutant && score >= 80) {
      return 'Mutant bloodline spark';
    }
    if (score >= 82) {
      return 'Elite line carrier';
    }
    if (score >= 70) {
      return 'Rare line blend';
    }
    if (score >= 55) {
      return 'Promising inherited mix';
    }
    return 'Developing young line';
  }

  String _previewBreedLabel(Horse dam, Horse sire) {
    if (dam.breed == sire.breed) {
      return dam.breed;
    }
    return '${dam.breed} / ${sire.breed}';
  }

  String _rollBreed(Horse dam, Horse sire, Random random) {
    if (dam.breed == sire.breed) {
      return dam.breed;
    }
    return random.nextBool() ? dam.breed : sire.breed;
  }

  RarityTier _traitRarity(
    String traitType,
    String option, {
    required bool isMutant,
  }) {
    final rareOptions = _rareOptions[traitType] ?? const <String>[];
    if (isMutant && rareOptions.contains(option)) {
      return RarityTier.legendary;
    }
    return switch (traitType) {
      'mane_style' => switch (option) {
        'Short' => RarityTier.common,
        'Natural' => RarityTier.uncommon,
        'Hawk' || 'Braided' => RarityTier.epic,
        'Long Curly' => RarityTier.rare,
        _ => RarityTier.common,
      },
      'tail_style' => switch (option) {
        'Short' || 'Curly' => RarityTier.common,
        'Natural' => RarityTier.uncommon,
        'Braided' => RarityTier.epic,
        _ => RarityTier.common,
      },
      'eye_color' => switch (option) {
        'Brown' || 'Blue' || 'Green' => RarityTier.common,
        'Hazel' => RarityTier.uncommon,
        'Heterochromia' => RarityTier.legendary,
        _ => RarityTier.common,
      },
      'markings' => switch (option) {
        'Blaze' => RarityTier.rare,
        _ => RarityTier.common,
      },
      'body_type' => switch (option) {
        'Slim' || 'Muscular' => RarityTier.uncommon,
        'Athletic' || 'Compact' || 'Hefty' => RarityTier.rare,
        _ => RarityTier.common,
      },
      'saddle' => RarityTier.legendary,
      _ => RarityTier.common,
    };
  }

  bool _traitExistsInLineage(Horse dam, Horse sire, String traitType) {
    return dam.traitOfOrNull(traitType) != null ||
        sire.traitOfOrNull(traitType) != null ||
        _ancestorWeightsForTrait(
          dam: dam,
          sire: sire,
          traitType: traitType,
        ).isNotEmpty;
  }

  String _rollWeightedOption(Map<String, double> weighted, Random random) {
    final filtered = weighted.entries
        .where((entry) => entry.value > 0)
        .toList();
    final total = filtered.fold<double>(0, (sum, entry) => sum + entry.value);
    var roll = random.nextDouble() * total;
    for (final entry in filtered) {
      roll -= entry.value;
      if (roll <= 0) {
        return entry.key;
      }
    }
    return filtered.last.key;
  }

  String _buildRegistryId({required String breed, required int sequence}) {
    return 'PH$sequence';
  }

  String _buildRegisteredName({
    required Horse dam,
    required Horse sire,
    required List<HorseTrait> foalTraits,
    required bool isMutant,
    required Random random,
  }) {
    final prefixPool = <String>[
      dam.displayName.split(' ').first,
      sire.displayName.split(' ').first,
      foalTraits.firstWhere((trait) => trait.type == 'body_type').option,
      if (isMutant) 'Nova' else 'Silver',
    ];
    final suffixPool = <String>[
      foalTraits.firstWhere((trait) => trait.type == 'mane_style').option,
      'Bloom',
      'Promise',
      'Vale',
      'Song',
    ];
    return '${prefixPool[random.nextInt(prefixPool.length)]} ${suffixPool[random.nextInt(suffixPool.length)]}';
  }

  String _buildUnbornName(Horse dam, Horse sire, Horse foal, bool isMutant) {
    final status = isMutant ? 'Mutant foal' : 'Reserved foal';
    return '$status • ${foal.registeredName}';
  }

  String _titleCase(String value) {
    final words = value.split(' ');
    return words
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _normalizedInheritedOption(String traitType, String option) {
    return switch (traitType) {
      'mane_style' => switch (option) {
        'Medium' || 'Long Curly' => 'Natural',
        _ => option,
      },
      'tail_style' => switch (option) {
        'Full' || 'Long' => 'Natural',
        _ => option,
      },
      _ => option,
    };
  }

  void _addSnapshotAncestorWeights(
    Map<String, double> weighted, {
    required Horse root,
    required String traitType,
  }) {
    for (var generation = 1; generation <= 6; generation++) {
      final ancestors = _ancestorsAtGeneration(root, generation)
          .where(
            (ancestor) =>
                ancestor.traitOption(traitType, fallback: 'Unknown') !=
                'Unknown',
          )
          .where(
            (ancestor) =>
                ancestor.traitOption(traitType, fallback: 'Unknown') != 'None',
          )
          .toList();
      if (ancestors.isEmpty) {
        continue;
      }

      final generationWeight = _sideWeightForGeneration(generation);
      if (generationWeight <= 0) {
        continue;
      }

      final share = generationWeight / ancestors.length;
      for (final ancestor in ancestors) {
        final option = _normalizedInheritedOption(
          traitType,
          ancestor.traitOption(traitType),
        );
        weighted.update(
          option,
          (value) => value + share,
          ifAbsent: () => share,
        );
      }
    }
  }

  void _addLegacyLineageWeights(
    Map<String, double> weighted, {
    required Horse horse,
    required String traitType,
  }) {
    final groupedByDepth = <int, List<String>>{};
    for (final entry in horse.lineageTraitDepths(traitType).entries) {
      groupedByDepth.putIfAbsent(entry.value, () => <String>[]).add(entry.key);
    }

    for (final entry in groupedByDepth.entries) {
      final generationWeight = _sideWeightForGeneration(entry.key);
      if (generationWeight <= 0 || entry.value.isEmpty) {
        continue;
      }
      final share = generationWeight / entry.value.length;
      for (final option in entry.value) {
        final normalized = _normalizedInheritedOption(traitType, option);
        weighted.update(
          normalized,
          (value) => value + share,
          ifAbsent: () => share,
        );
      }
    }
  }

  List<Horse> _ancestorsAtGeneration(Horse horse, int generation) {
    if (generation <= 0) {
      return const <Horse>[];
    }
    if (generation == 1) {
      return [
        if (horse.damSnapshot != null) horse.damSnapshot!,
        if (horse.sireSnapshot != null) horse.sireSnapshot!,
      ];
    }

    return [
      if (horse.damSnapshot != null)
        ..._ancestorsAtGeneration(horse.damSnapshot!, generation - 1),
      if (horse.sireSnapshot != null)
        ..._ancestorsAtGeneration(horse.sireSnapshot!, generation - 1),
    ];
  }

  double _sideWeightForGeneration(int generation) {
    return switch (generation) {
      1 => 0.15,
      2 => 0.05,
      _ => 0.05 / pow(2, generation - 2),
    };
  }
}

const Map<String, List<String>> _traitPool = {
  'mane_style': ['Short', 'Natural', 'Hawk', 'Braided'],
  'mane_color': ['Brown', 'Black', 'White'],
  'tail_style': ['Short', 'Natural', 'Curly', 'Braided'],
  'tail_color': ['Brown', 'Black', 'White'],
  'eye_color': ['Brown', 'Hazel', 'Blue', 'Green', 'Heterochromia'],
  'markings': ['None', 'Star', 'Stripe', 'Blaze'],
  'body_type': ['Slim', 'Athletic', 'Muscular', 'Compact', 'Hefty'],
  'saddle': ['Black', 'Red', 'Sandy', 'Silver'],
};

const Map<String, List<String>> _rareOptions = {
  'mane_style': ['Hawk', 'Braided'],
  'tail_style': ['Braided'],
  'eye_color': ['Heterochromia'],
  'markings': ['Blaze'],
  'body_type': ['Athletic', 'Compact', 'Hefty'],
  'saddle': ['Black', 'Red', 'Sandy', 'Silver'],
};

const Set<String> _specialTraitPool = {
  'Metallic Sheen',
  'Iridescent',
  'Mutant Line',
};

const Set<String> _lineageMemoryTraits = {
  'mane_style',
  'mane_color',
  'tail_style',
  'tail_color',
  'eye_color',
  'markings',
  'body_type',
  'saddle',
};
