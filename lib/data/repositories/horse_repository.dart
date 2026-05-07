import 'dart:math';

import '../../domain/models/horse.dart';
import '../../domain/models/horse_trait.dart';
import '../../domain/models/rarity_tier.dart';
import '../sample/sample_horses.dart';

class HorseRepository {
  const HorseRepository();

  static const double _starterSaddleChance = 0.08;
  static const List<String> _saddleOptions = [
    'Black',
    'Red',
    'Sandy',
    'Silver',
  ];

  List<Horse> loadStable() {
    return const [];
  }

  List<Horse> loadStarterMarket() {
    final random = Random();
    return starterMarketHorses
        .map(normalizeStarterMarketHorse)
        .map((horse) => _withStarterSaddleRoll(horse, random))
        .toList();
  }

  Horse normalizeStarterMarketHorse(Horse horse) {
    return horse.copyWith(
      traits: horse.traits.map((trait) {
        if (trait.type == 'mane_style') {
          return const HorseTrait(
            type: 'mane_style',
            option: 'Short',
            rarity: RarityTier.common,
          );
        }
        if (trait.type == 'tail_style') {
          return const HorseTrait(
            type: 'tail_style',
            option: 'Short',
            rarity: RarityTier.common,
          );
        }
        if (trait.type == 'eye_color') {
          return const HorseTrait(
            type: 'eye_color',
            option: 'Brown',
            rarity: RarityTier.common,
          );
        }
        return trait;
      }).toList(),
    );
  }

  Horse _withStarterSaddleRoll(Horse horse, Random random) {
    if (horse.traitOfOrNull('saddle') != null) {
      return horse;
    }
    if (random.nextDouble() >= _starterSaddleChance) {
      return horse;
    }

    final saddle = HorseTrait(
      type: 'saddle',
      option: _saddleOptions[random.nextInt(_saddleOptions.length)],
      rarity: RarityTier.legendary,
    );
    return horse.copyWith(traits: [...horse.traits, saddle]);
  }
}
