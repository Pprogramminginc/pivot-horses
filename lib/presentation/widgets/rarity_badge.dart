import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/rarity_tier.dart';

class RarityBadge extends StatelessWidget {
  const RarityBadge({
    super.key,
    required this.tier,
    this.label,
    this.compact = false,
  });

  final RarityTier tier;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              tier.valueColor,
              Colors.black,
              0.58,
            )!.withValues(alpha: 0.96),
            Color.lerp(tier.valueColor, AppTheme.surfaceSoft, 0.72)!,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: tier.borderColor),
        boxShadow: [
          BoxShadow(
            color: tier.valueColor.withValues(alpha: 0.16),
            blurRadius: compact ? 10 : 14,
            offset: Offset(0, compact ? 4 : 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 8 : 10,
            height: compact ? 8 : 10,
            decoration: BoxDecoration(
              color: tier.valueColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Flexible(
            child: Text(
              label ?? tier.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tier.textColor == const Color(0xFF2D2119)
                    ? const Color(0xFFFFF5E7)
                    : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 12 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
