import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/horse.dart';

class HorseStoryWrap extends StatelessWidget {
  const HorseStoryWrap({
    super.key,
    required this.horse,
    this.maxBadges = 4,
    this.compact = false,
    this.includeBreederProfile = true,
  });

  final Horse horse;
  final int maxBadges;
  final bool compact;
  final bool includeBreederProfile;

  @override
  Widget build(BuildContext context) {
    final badges = horseStoryBadges(
      horse,
      includeBreederProfile: includeBreederProfile,
    ).take(maxBadges);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges
          .map(
            (badge) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 7 : 8,
              ),
              decoration: BoxDecoration(
                color: badge.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badge.color.withValues(alpha: 0.42)),
              ),
              child: Text(
                badge.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class HorseStoryBadge {
  const HorseStoryBadge({required this.label, required this.color});

  final String label;
  final Color color;
}

List<HorseStoryBadge> horseStoryBadges(
  Horse horse, {
  bool includeBreederProfile = true,
}) {
  final badges = <HorseStoryBadge>[
    if (includeBreederProfile)
      HorseStoryBadge(
        label: horse.geneticProfile.breedingPotential,
        color: AppTheme.secondary,
      ),
    HorseStoryBadge(
      label: horse.generation <= 1 && horse.damSnapshot == null
          ? 'Foundation line'
          : 'Gen ${horse.generation}',
      color: AppTheme.primary,
    ),
    if (horse.isMutant)
      const HorseStoryBadge(label: 'Mutant bloodline', color: AppTheme.primary),
    if (horse.hasSpecialVisual)
      const HorseStoryBadge(label: 'Collector coat', color: AppTheme.tertiary),
    if (horse.specialTraits.isNotEmpty)
      HorseStoryBadge(
        label: horse.specialTraits.first,
        color: AppTheme.tertiary,
      ),
    if (horse.lineageMemory.isNotEmpty)
      const HorseStoryBadge(
        label: 'Heritage traits',
        color: AppTheme.secondary,
      ),
    if (horse.isRetired)
      const HorseStoryBadge(label: 'Retired', color: AppTheme.tertiary),
    if (horse.transferCount > 0)
      HorseStoryBadge(
        label: horse.transferCount == 1
            ? '1 transfer'
            : '${horse.transferCount} transfers',
        color: AppTheme.secondary,
      ),
    HorseStoryBadge(
      label: horse.sex == 'Mare' ? 'Broodmare lane' : 'Sire lane',
      color: AppTheme.mutedInk,
    ),
  ];

  final seen = <String>{};
  return badges.where((badge) => seen.add(badge.label)).toList();
}

String horseProgressSummary(Horse horse) {
  final rarityRead =
      '${horse.breedingRarity.label.toLowerCase()} breeding value with ${horse.visualRarity.label.toLowerCase()} visible appeal';
  final lineRead = horse.generation <= 1 && horse.damSnapshot == null
      ? 'This horse stands near the front of a fresh family line.'
      : horse.generation >= 4
      ? 'This horse comes from a deeper-established bloodline.'
      : 'This horse already sits inside a growing bloodline.';
  final ancestryRead = horse.lineageMemory.isNotEmpty
      ? ' Hidden ancestry memory is already tracking inherited traits behind the scenes.'
      : '';
  final mutationRead = horse.isMutant
      ? ' The mutant tag makes it a premium collector branch.'
      : horse.hasSpecialVisual
      ? ' Special visuals make it read like a collector piece.'
      : '';
  final retirementRead = horse.isRetired
      ? ' This horse has aged out of breeding and now carries a retired emblem.'
      : horse.isBreedingReady
      ? ' It is old enough to breed right now.'
      : ' It is still maturing toward breeding age.';
  return '${horse.displayName} carries $rarityRead. $lineRead$ancestryRead$mutationRead$retirementRead';
}

String horseVisualRead(Horse horse) {
  return '${horse.traitOption('eye_color', fallback: 'Brown')} eyes, ${horse.traitOption('mane_color', fallback: 'Brown').toLowerCase()} ${horse.traitOption('mane_style', fallback: 'Natural').toLowerCase()} mane, ${horse.traitOption('tail_color', fallback: 'Brown').toLowerCase()} ${horse.traitOption('tail_style', fallback: 'Natural').toLowerCase()} tail.';
}

String horseBreedingUseLabel(Horse horse) {
  if (horse.sex == 'Mare') {
    return 'Best for building a broodmare branch and tracking foal lines.';
  }
  return 'Best for adding a sire branch to future pairings and comparisons.';
}
