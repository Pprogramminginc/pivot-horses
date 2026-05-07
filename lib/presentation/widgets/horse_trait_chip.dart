import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/horse_trait.dart';

class HorseTraitChip extends StatelessWidget {
  const HorseTraitChip({super.key, required this.trait, this.compact = false});

  final HorseTrait trait;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rarityColor = trait.rarity.valueColor;

    return Container(
      constraints: BoxConstraints(minWidth: compact ? 124 : 156),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceRaised, rarityColor.withValues(alpha: 0.12)],
        ),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.45),
          width: compact ? 1.2 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: compact ? 0.05 : 0.08),
            blurRadius: compact ? 8 : 12,
            offset: Offset(0, compact ? 2 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 8 : 10,
                height: compact ? 8 : 10,
                decoration: BoxDecoration(
                  color: rarityColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: compact ? 5 : 6),
              Text(
                trait.rarity.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: rarityColor,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : null,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 5 : 8),
          Text(
            trait.type.replaceAll('_', ' '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedInk,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            trait.option,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 13 : null,
            ),
          ),
        ],
      ),
    );
  }
}
