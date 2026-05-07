import 'package:flutter/material.dart';

enum RarityTier {
  common(label: 'Common', color: 0xFF8A8A8A),
  uncommon(label: 'Uncommon', color: 0xFF7A5230),
  rare(label: 'Rare', color: 0xFF9B111E),
  epic(label: 'Epic', color: 0xFF1F8A8A),
  legendary(label: 'Legendary', color: 0xFFD4A017);

  const RarityTier({required this.label, required this.color});

  final String label;
  final int color;

  Color get valueColor => Color(color);

  Color get softColor => valueColor.withValues(alpha: 0.12);

  Color get borderColor => valueColor.withValues(alpha: 0.42);

  Color get textColor {
    switch (this) {
      case RarityTier.rare:
      case RarityTier.epic:
        return Colors.white;
      case RarityTier.common:
      case RarityTier.uncommon:
      case RarityTier.legendary:
        return const Color(0xFF2D2119);
    }
  }

  int get rank {
    switch (this) {
      case RarityTier.common:
        return 0;
      case RarityTier.uncommon:
        return 1;
      case RarityTier.rare:
        return 2;
      case RarityTier.epic:
        return 3;
      case RarityTier.legendary:
        return 4;
    }
  }
}
