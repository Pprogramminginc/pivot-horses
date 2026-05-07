import 'horse.dart';
import 'horse_trait.dart';
import 'rarity_tier.dart';

const List<String> coreVisibleTraitTypes = [
  'mane_style',
  'mane_color',
  'tail_style',
  'tail_color',
  'eye_color',
  'markings',
  'body_type',
];

Horse normalizeHorseVisibleTraits(Horse horse) {
  final traitsByType = {for (final trait in horse.traits) trait.type: trait};

  final missingCoreTrait = coreVisibleTraitTypes.any(
    (type) => !traitsByType.containsKey(type),
  );
  if (!missingCoreTrait) {
    return horse;
  }

  final normalizedTraits = <HorseTrait>[
    for (final type in coreVisibleTraitTypes)
      traitsByType[type] ?? _defaultTraitFor(horse, type),
    for (final trait in horse.traits)
      if (!coreVisibleTraitTypes.contains(trait.type)) trait,
  ];

  return horse.copyWith(traits: normalizedTraits);
}

HorseTrait _defaultTraitFor(Horse horse, String type) {
  return switch (type) {
    'mane_style' => const HorseTrait(
      type: 'mane_style',
      option: 'Short',
      rarity: RarityTier.common,
    ),
    'mane_color' => HorseTrait(
      type: 'mane_color',
      option: _defaultHairColor(horse),
      rarity: RarityTier.common,
    ),
    'tail_style' => const HorseTrait(
      type: 'tail_style',
      option: 'Short',
      rarity: RarityTier.common,
    ),
    'tail_color' => HorseTrait(
      type: 'tail_color',
      option: _defaultHairColor(horse),
      rarity: RarityTier.common,
    ),
    'eye_color' => const HorseTrait(
      type: 'eye_color',
      option: 'Brown',
      rarity: RarityTier.common,
    ),
    'markings' => const HorseTrait(
      type: 'markings',
      option: 'None',
      rarity: RarityTier.common,
    ),
    'body_type' => HorseTrait(
      type: 'body_type',
      option: _defaultBodyType(horse),
      rarity: RarityTier.common,
    ),
    _ => HorseTrait(type: type, option: 'Unknown', rarity: RarityTier.common),
  };
}

String _defaultHairColor(Horse horse) {
  final breed = horse.breed.toLowerCase();
  if (breed.contains('percheron')) {
    return 'Black';
  }
  if (breed.contains('arabian')) {
    return 'White';
  }
  return 'Brown';
}

String _defaultBodyType(Horse horse) {
  final breed = horse.breed.toLowerCase();
  if (breed.contains('shetland')) {
    return 'Compact';
  }
  if (breed.contains('percheron')) {
    return 'Hefty';
  }
  if (breed.contains('arabian')) {
    return 'Slim';
  }
  return 'Athletic';
}
