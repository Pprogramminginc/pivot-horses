import 'dart:math';

import 'rarity_tier.dart';
import 'care_stats.dart';
import 'genetic_profile.dart';
import 'horse_trait.dart';
import 'starter_tier.dart';

class Horse {
  static const int newbornAgeDays = 1;
  static const int breedingReadyAgeDays = 5;
  static const int breedingRetirementAgeDays = 35;

  const Horse({
    required this.id,
    required this.registryId,
    required this.registeredName,
    required this.currentName,
    required this.breed,
    required this.sex,
    required this.generation,
    required this.ageDays,
    required this.breedingRetirementDays,
    required this.traits,
    required this.starterTier,
    required this.price,
    required this.geneticProfile,
    required this.careStats,
    this.transferCount = 0,
    this.specialTraits = const [],
    this.lineageMemory = const {},
    this.isMutant = false,
    this.isPublicListing = false,
    this.isFeaturedProfileHorse = false,
    this.isListedForSale = false,
    this.damSnapshot,
    this.sireSnapshot,
  });

  final String id;
  final String registryId;
  final String registeredName;
  final String currentName;
  final String breed;
  final String sex;
  final int generation;
  final int ageDays;
  final int breedingRetirementDays;
  final int transferCount;
  final List<HorseTrait> traits;
  final StarterTier starterTier;
  final int price;
  final GeneticProfile geneticProfile;
  final CareStats careStats;
  final List<String> specialTraits;
  final Map<String, Map<String, int>> lineageMemory;
  final bool isMutant;
  final bool isPublicListing;
  final bool isFeaturedProfileHorse;
  final bool isListedForSale;
  final Horse? damSnapshot;
  final Horse? sireSnapshot;

  String get displayName => currentName;
  String get cardTitle => '$breed • $displayName';
  String get cardSubtitle {
    if (isNewborn) {
      return '$registryId · ${isMutant ? 'Mutant ' : ''}Newborn Foal';
    }
    if (isFoal) {
      return '$registryId · Growing Foal';
    }
    return '$registryId · ${starterTier.label}';
  }

  int get breedingCareerLimitDays =>
      min(breedingRetirementDays, breedingRetirementAgeDays);

  bool get isFoal => ageDays < breedingReadyAgeDays;
  bool get isNewborn => ageDays <= newbornAgeDays;
  bool get isBreedingReady => ageDays >= breedingReadyAgeDays && !isRetired;
  bool get hasSpecialVisual =>
      isMutant ||
      specialTraits.any(
        (trait) =>
            trait.toLowerCase() == 'metallic sheen' ||
            trait.toLowerCase() == 'iridescent',
      );

  int get breedingDaysRemaining {
    final remaining = breedingCareerLimitDays - ageDays;
    return remaining > 0 ? remaining : 0;
  }

  bool get isRetired => breedingDaysRemaining == 0;

  RarityTier get highestVisibleRarity {
    return traits
        .map((trait) => trait.rarity)
        .reduce((current, next) => next.rank > current.rank ? next : current);
  }

  int get visibleTraitScore => calculateVisibleTraitScore(traits);

  int get specialTraitScoreBonus => calculateSpecialTraitBonus(specialTraits);

  int get score => calculateOverallScore(
    breedingCoreScore: geneticProfile.bloodlineScore,
    traits: traits,
    specialTraits: specialTraits,
  );

  RarityTier get visualRarity => visualRarityFromTraitScore(visibleTraitScore);

  RarityTier get breedingRarity {
    return rarityFromScore(score);
  }

  bool get isCollectorValueHorse =>
      isMutant ||
      specialTraits.isNotEmpty ||
      traits.any((trait) => trait.type == 'saddle');

  String get valueClassLabel {
    if (isCollectorValueHorse && score >= 70) {
      return 'Collector';
    }
    if (score >= 85) {
      return 'Elite';
    }
    if (score >= 55) {
      return 'Well-Bred';
    }
    return 'Average';
  }

  String get valueClassRead {
    switch (valueClassLabel) {
      case 'Collector':
        return 'Rare collector upside with standout long-term value.';
      case 'Elite':
        return 'Top-end horse with a strong pricing ceiling.';
      case 'Well-Bred':
        return 'Noticeable market value with good breeding upside.';
      case 'Average':
        return 'Useful horse with a modest value band.';
      default:
        return 'Useful horse with a modest value band.';
    }
  }

  bool get hasHiddenBreedingUpside {
    final hasCarrierTrait = traits.any((trait) => trait.type == 'saddle');
    return hasCarrierTrait ||
        breedingRarity.rank > visualRarity.rank ||
        lineageMemory.isNotEmpty;
  }

  String get hiddenBreedingInsight {
    if (traits.any((trait) => trait.type == 'saddle')) {
      return 'Legendary saddle genetics are present even if the look stays starter-simple.';
    }
    if (breedingRarity.rank > visualRarity.rank) {
      return 'Quiet carrier read: breeding strength runs deeper than the visible trait read.';
    }
    if (lineageMemory.isNotEmpty) {
      return 'Lineage memory suggests throwback breeding potential in the family line.';
    }
    return 'This horse reads mostly straightforward with value that matches the visible traits.';
  }

  String get starterMarketRead {
    if (hasHiddenBreedingUpside) {
      return 'Simple starter look, hidden breeding upside.';
    }
    return 'Simple starter look with steady straightforward value.';
  }

  String get visualRarityRead {
    return switch (visualRarity) {
      RarityTier.common => 'Looks mostly common on the surface.',
      RarityTier.uncommon => 'Shows a few nicer visible touches.',
      RarityTier.rare => 'Carries visibly strong rarity.',
      RarityTier.epic => 'Looks immediately standout and collectible.',
      RarityTier.legendary =>
        'Top-end visual presentation with premium rarity.',
    };
  }

  String get breedingRarityRead {
    return switch (breedingRarity) {
      RarityTier.common => 'Expected to pass mostly common outcomes.',
      RarityTier.uncommon => 'Has a modest chance to improve a line.',
      RarityTier.rare => 'Can noticeably lift future foal outcomes.',
      RarityTier.epic => 'Strong breeding upside with premium inheritance.',
      RarityTier.legendary =>
        'Exceptional breeding ceiling with rare line potential.',
    };
  }

  int get derivedPrice => calculateMarketPrice(
    breed: breed,
    sex: sex,
    generation: generation,
    ageDays: ageDays,
    breedingRetirementDays: breedingRetirementDays,
    breedingCoreScore: geneticProfile.bloodlineScore,
    traits: traits,
    specialTraits: specialTraits,
    isMutant: isMutant,
  );

  int get purgePayout => calculatePurgePayout(derivedPrice);

  int get quickSellPayout => calculateQuickSellPayout(derivedPrice);

  int get playerSalePrice => derivedPrice;

  int get sellerListingPayout => (derivedPrice * 0.75).round();

  static int traitValueScoreFor(HorseTrait trait) {
    return traitOptionValueScore(trait.type, trait.option, trait.rarity.rank);
  }

  static int traitOptionValueScore(
    String type,
    String option, [
    int rarityFallbackRank = 0,
  ]) {
    final typedScores = _traitValueTable[type];
    if (typedScores != null && typedScores.containsKey(option)) {
      return typedScores[option]!;
    }
    return (rarityFallbackRank + 1).clamp(1, 5);
  }

  static int calculateVisibleTraitScore(Iterable<HorseTrait> traits) {
    return traits.fold<int>(0, (sum, trait) => sum + traitValueScoreFor(trait));
  }

  static int calculateSpecialTraitBonus(Iterable<String> specialTraits) {
    return specialTraits.fold<int>(
      0,
      (sum, trait) => sum + (_specialTraitBonusTable[trait] ?? 0),
    );
  }

  static int calculateOverallScore({
    required int breedingCoreScore,
    required Iterable<HorseTrait> traits,
    Iterable<String> specialTraits = const [],
  }) {
    final traitScore = calculateVisibleTraitScore(traits);
    final specialBonus = calculateSpecialTraitBonus(specialTraits);
    final total =
        (breedingCoreScore * 0.7).round() + (traitScore * 2) + specialBonus;
    return total.clamp(0, 100);
  }

  static int calculateMarketPrice({
    required String breed,
    required String sex,
    required int generation,
    required int ageDays,
    required int breedingRetirementDays,
    required int breedingCoreScore,
    required Iterable<HorseTrait> traits,
    Iterable<String> specialTraits = const [],
    bool isMutant = false,
  }) {
    final totalScore = calculateOverallScore(
      breedingCoreScore: breedingCoreScore,
      traits: traits,
      specialTraits: specialTraits,
    );
    final basePrice = starterPurchasePrice(breed: breed, sex: sex);
    final qualityMultiplier = _qualityMultiplier(totalScore);
    final collectorMultiplier = _collectorMultiplier(
      traits: traits,
      specialTraits: specialTraits,
      isMutant: isMutant,
    );
    final effectiveRetirementDays = max(
      1,
      min(breedingRetirementDays, breedingRetirementAgeDays),
    );
    final ageMultiplier = _ageMultiplier(
      ageDays: ageDays,
      breedingRetirementDays: effectiveRetirementDays,
      hasCollectorValue:
          isMutant ||
          specialTraits.isNotEmpty ||
          traits.any((trait) => trait.type == 'saddle'),
    );
    final generationMultiplier = 1 + ((generation - 1).clamp(0, 4) * 0.08);

    final value =
        basePrice *
        qualityMultiplier *
        collectorMultiplier *
        ageMultiplier *
        generationMultiplier;
    return value.round().clamp(300, 50000);
  }

  static int starterPurchasePrice({
    required String breed,
    required String sex,
  }) {
    final normalizedBreed = breed.toLowerCase();
    final mareBase = switch (normalizedBreed) {
      final b when b.contains('arabian') => 1500,
      final b when b.contains('percheron') => 1300,
      final b when b.contains('appaloosa') => 1100,
      final b when b.contains('paint') => 1000,
      final b when b.contains('shetland') => 750,
      final b
          when b == 'bay' || b.contains('bay ') || b.contains('bay brown') =>
        600,
      _ => 900,
    };
    return sex == 'Stallion' ? mareBase * 2 : mareBase;
  }

  static int calculatePurgePayout(int marketPrice) {
    return (marketPrice * _purgePayoutRate).round();
  }

  static int calculateQuickSellPayout(int marketPrice) {
    return (marketPrice * _quickSellPayoutRate).round();
  }

  static RarityTier rarityFromScore(int score) {
    if (score >= 85) return RarityTier.legendary;
    if (score >= 70) return RarityTier.epic;
    if (score >= 55) return RarityTier.rare;
    if (score >= 40) return RarityTier.uncommon;
    return RarityTier.common;
  }

  static RarityTier visualRarityFromTraitScore(int traitScore) {
    if (traitScore >= 19) return RarityTier.legendary;
    if (traitScore >= 17) return RarityTier.epic;
    if (traitScore >= 14) return RarityTier.rare;
    if (traitScore >= 10) return RarityTier.uncommon;
    return RarityTier.common;
  }

  Horse copyWith({
    String? id,
    String? currentName,
    String? registryId,
    String? registeredName,
    String? breed,
    String? sex,
    int? generation,
    int? ageDays,
    int? breedingRetirementDays,
    int? transferCount,
    int? price,
    List<HorseTrait>? traits,
    StarterTier? starterTier,
    GeneticProfile? geneticProfile,
    CareStats? careStats,
    List<String>? specialTraits,
    Map<String, Map<String, int>>? lineageMemory,
    bool? isMutant,
    bool? isPublicListing,
    bool? isFeaturedProfileHorse,
    bool? isListedForSale,
    Horse? damSnapshot,
    Horse? sireSnapshot,
  }) {
    return Horse(
      id: id ?? this.id,
      registryId: registryId ?? this.registryId,
      registeredName: registeredName ?? this.registeredName,
      currentName: currentName ?? this.currentName,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      generation: generation ?? this.generation,
      ageDays: ageDays ?? this.ageDays,
      breedingRetirementDays:
          breedingRetirementDays ?? this.breedingRetirementDays,
      traits: traits ?? this.traits,
      starterTier: starterTier ?? this.starterTier,
      price: price ?? this.price,
      geneticProfile: geneticProfile ?? this.geneticProfile,
      careStats: careStats ?? this.careStats,
      transferCount: transferCount ?? this.transferCount,
      specialTraits: specialTraits ?? this.specialTraits,
      lineageMemory: lineageMemory ?? this.lineageMemory,
      isMutant: isMutant ?? this.isMutant,
      isPublicListing: isPublicListing ?? this.isPublicListing,
      isFeaturedProfileHorse:
          isFeaturedProfileHorse ?? this.isFeaturedProfileHorse,
      isListedForSale: isListedForSale ?? this.isListedForSale,
      damSnapshot: damSnapshot ?? this.damSnapshot,
      sireSnapshot: sireSnapshot ?? this.sireSnapshot,
    );
  }

  HorseTrait traitOf(String type) {
    return traits.firstWhere((trait) => trait.type == type);
  }

  HorseTrait? traitOfOrNull(String type) {
    for (final trait in traits) {
      if (trait.type == type) {
        return trait;
      }
    }
    return null;
  }

  String traitOption(String type, {String fallback = 'Unknown'}) {
    return traitOfOrNull(type)?.option ?? fallback;
  }

  Map<String, int> lineageTraitDepths(String traitType) {
    final depths = <String, int>{};
    final rawDepths = lineageMemory[traitType] ?? const <String, int>{};
    for (final entry in rawDepths.entries) {
      if (entry.key == 'Unknown' || entry.key == 'None') {
        continue;
      }
      depths[entry.key] = entry.value;
    }
    return depths;
  }
}

double _qualityMultiplier(int totalScore) {
  if (totalScore < 40) {
    return _interpolate(totalScore, 0, 39, 0.85, 1.05);
  }
  if (totalScore < 55) {
    return _interpolate(totalScore, 40, 54, 1.10, 1.45);
  }
  if (totalScore < 70) {
    return _interpolate(totalScore, 55, 69, 1.60, 2.20);
  }
  if (totalScore < 85) {
    return _interpolate(totalScore, 70, 84, 2.40, 3.60);
  }
  return _interpolate(totalScore, 85, 100, 4.00, 6.00);
}

double _collectorMultiplier({
  required Iterable<HorseTrait> traits,
  required Iterable<String> specialTraits,
  required bool isMutant,
}) {
  var multiplier = 1.0;
  var hasSaddle = false;
  var hasVisualCollector = false;
  for (final trait in traits) {
    if (trait.type == 'saddle') {
      multiplier += 0.15;
      hasSaddle = true;
    }
  }

  for (final trait in specialTraits) {
    switch (trait) {
      case 'Metallic Sheen':
        multiplier += 0.22;
        hasVisualCollector = true;
      case 'Iridescent':
        multiplier += 0.40;
        hasVisualCollector = true;
      case 'Mutant Line':
        multiplier += 1.10;
        hasVisualCollector = true;
    }
  }

  if (hasSaddle && hasVisualCollector) {
    multiplier += 0.12;
  }
  if (isMutant) {
    multiplier += 0.35;
  }
  return multiplier;
}

double _ageMultiplier({
  required int ageDays,
  required int breedingRetirementDays,
  required bool hasCollectorValue,
}) {
  if (ageDays <= 30) {
    return 0.88;
  }

  if (ageDays <= 60) {
    return _interpolate(ageDays, 31, 60, 0.92, 1.0);
  }

  final primeEnd = (breedingRetirementDays * 0.60).round().clamp(
    60,
    breedingRetirementDays > 0 ? breedingRetirementDays : 60,
  );
  if (ageDays <= primeEnd) {
    return 1.0;
  }

  final declineFloor = hasCollectorValue ? 0.65 : 0.45;
  final declineSpan = (breedingRetirementDays - primeEnd).clamp(1, 100000);
  final progress = ((ageDays - primeEnd) / declineSpan).clamp(0.0, 1.0);
  final atRetirement = 1.0 - ((1.0 - declineFloor) * progress);

  if (ageDays <= breedingRetirementDays) {
    return atRetirement;
  }

  final retirementWindow = (breedingRetirementDays * 0.40).round().clamp(
    30,
    240,
  );
  final retirementProgress =
      ((ageDays - breedingRetirementDays) / retirementWindow).clamp(0.0, 1.0);
  final lateLifeFloor = hasCollectorValue ? 0.55 : 0.28;
  return atRetirement - ((atRetirement - lateLifeFloor) * retirementProgress);
}

double _interpolate(int value, int min, int max, double start, double end) {
  if (max <= min) {
    return end;
  }
  final progress = ((value - min) / (max - min)).clamp(0.0, 1.0);
  return start + ((end - start) * progress);
}

const Map<String, Map<String, int>> _traitValueTable = {
  'mane_style': {
    'Natural': 2,
    'Short': 1,
    'Medium': 2,
    'Braided': 4,
    'Long Curly': 4,
    'Hawk': 4,
  },
  'mane_color': {'Brown': 1, 'Black': 2, 'White': 2},
  'tail_style': {
    'Natural': 2,
    'Short': 1,
    'Full': 2,
    'Long': 2,
    'Curly': 3,
    'Braided': 4,
  },
  'tail_color': {'Brown': 1, 'Black': 2, 'White': 2},
  'eye_color': {
    'Brown': 1,
    'Blue': 1,
    'Hazel': 2,
    'Amber': 4,
    'Green': 1,
    'Heterochromia': 5,
  },
  'markings': {'None': 1, 'Star': 2, 'Stripe': 2, 'Blaze': 3},
  'body_type': {
    'Slim': 2,
    'Muscular': 2,
    'Athletic': 3,
    'Compact': 3,
    'Hefty': 4,
  },
  'saddle': {'Black': 5, 'Red': 5, 'Sandy': 5, 'Silver': 5},
};

const Map<String, int> _specialTraitBonusTable = {
  'Metallic Sheen': 6,
  'Iridescent': 8,
  'Mutant Line': 10,
};

const double _purgePayoutRate = 0.25;
const double _quickSellPayoutRate = 0.35;
