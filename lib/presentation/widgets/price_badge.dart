import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/rarity_tier.dart';

class PriceBadge extends StatelessWidget {
  const PriceBadge({
    super.key,
    required this.price,
    required this.tier,
    this.compact = false,
  });

  final int price;
  final RarityTier tier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tier.valueColor.withValues(alpha: 0.95),
            Color.lerp(tier.valueColor, AppTheme.tertiary, 0.35)!,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: tier.valueColor.withValues(alpha: 0.22),
            blurRadius: compact ? 10 : 14,
            offset: Offset(0, compact ? 4 : 6),
          ),
        ],
      ),
      child: Text(
        '$price coins',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: tier.textColor,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 14 : 16,
        ),
      ),
    );
  }
}
