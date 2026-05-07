import 'rarity_tier.dart';

class HorseTrait {
  const HorseTrait({
    required this.type,
    required this.option,
    required this.rarity,
  });

  final String type;
  final String option;
  final RarityTier rarity;
}
