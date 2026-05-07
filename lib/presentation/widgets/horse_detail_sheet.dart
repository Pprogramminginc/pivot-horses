import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/breeding_cooldown.dart';
import '../../domain/models/horse.dart';
import '../../domain/models/horse_trait_defaults.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/models/pregnancy_record.dart';
import 'horse_preview.dart';
import 'horse_story_widgets.dart';
import 'price_badge.dart';
import 'rarity_badge.dart';

class HorseDetailSheet extends StatelessWidget {
  const HorseDetailSheet({
    super.key,
    required this.horse,
    this.currentTime,
    this.activeCooldown,
    this.activePregnancy,
    this.inventory = const <InventoryItemType, int>{},
    this.prenatalAlreadyUsed = false,
    this.carrotAlreadyUsed = false,
    this.tailStyleVisualOverride,
    this.onUsePrenatalVitamin,
    this.onUseCarrot,
    this.onRenameHorse,
    this.onPurgeHorse,
    this.onUpdateHorseVisibility,
  });

  final Horse horse;
  final DateTime? currentTime;
  final BreedingCooldown? activeCooldown;
  final PregnancyRecord? activePregnancy;
  final Map<InventoryItemType, int> inventory;
  final bool prenatalAlreadyUsed;
  final bool carrotAlreadyUsed;
  final String? tailStyleVisualOverride;
  final ValueChanged<PregnancyRecord>? onUsePrenatalVitamin;
  final ValueChanged<BreedingCooldown>? onUseCarrot;
  final void Function(Horse horse, String newName)? onRenameHorse;
  final ValueChanged<Horse>? onPurgeHorse;
  final String? Function(
    Horse horse, {
    bool? isPublicListing,
    bool? isFeaturedProfileHorse,
    bool? isListedForSale,
  })?
  onUpdateHorseVisibility;

  bool get _canShowItemActions {
    final hasPrenatalAction =
        activePregnancy != null && onUsePrenatalVitamin != null;
    final hasCarrotAction =
        activeCooldown != null &&
        activeCooldown!.sex == 'Stallion' &&
        activeCooldown!.reason != 'Healing' &&
        onUseCarrot != null;
    return hasPrenatalAction || hasCarrotAction;
  }

  @override
  Widget build(BuildContext context) {
    final breedingTier = horse.breedingRarity;
    final visibleTier = horse.visualRarity;
    final cooldownValue = activeCooldown != null && currentTime != null
        ? '${activeCooldown!.reason} • ${_formatCooldown(activeCooldown!.remainingAt(currentTime!))}'
        : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.mutedInk.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Horse Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    breedingTier.softColor.withValues(alpha: 0.82),
                    AppTheme.surfaceRaised,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: breedingTier.borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.shadow,
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    horse.cardTitle,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: AppTheme.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    horse.cardSubtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ValueClassBadge(horse: horse),
                      RarityBadge(
                        tier: breedingTier,
                        label: 'Breeding ${breedingTier.label}',
                      ),
                      RarityBadge(
                        tier: visibleTier,
                        label: 'Visual ${visibleTier.label}',
                      ),
                      PriceBadge(price: horse.derivedPrice, tier: breedingTier),
                    ],
                  ),
                  const SizedBox(height: 12),
                  HorseStoryWrap(horse: horse, maxBadges: 5),
                  const SizedBox(height: 14),
                  HorsePreview(
                    horse: horse,
                    tailStyleVisualOverride: tailStyleVisualOverride,
                    cameraTargetOverride: horse.breed == 'Bay'
                        ? '-0.38m 0.30m 0m'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DetailLine(
              label: 'Market value class',
              value: '${horse.valueClassLabel} • ${horse.valueClassRead}',
            ),
            _RarityReadCard(horse: horse),
            _IdentityDetailLine(
              horseId: horse.id,
              registryId: horse.registryId,
              currentName: horse.displayName,
              registeredName: horse.registeredName,
              breed: horse.breed,
              sex: horse.sex,
              generation: horse.generation,
              transfers: horse.transferCount,
              breedingStatus: horse.isRetired
                  ? 'Retired from breeding'
                  : !horse.isBreedingReady
                  ? 'Breed-ready in ${Horse.breedingReadyAgeDays - horse.ageDays} day${Horse.breedingReadyAgeDays - horse.ageDays == 1 ? '' : 's'}'
                  : '${horse.breedingDaysRemaining} breeding days left',
              cooldown: cooldownValue,
              horse: horse,
              onRenameHorse: onRenameHorse,
            ),
            if (_canShowItemActions) ...[
              const SizedBox(height: 6),
              _HorseItemActionsCard(
                horse: horse,
                activePregnancy: activePregnancy,
                activeCooldown: activeCooldown,
                currentTime: currentTime,
                inventory: inventory,
                prenatalAlreadyUsed: prenatalAlreadyUsed,
                carrotAlreadyUsed: carrotAlreadyUsed,
                onUsePrenatalVitamin: onUsePrenatalVitamin,
                onUseCarrot: onUseCarrot,
              ),
            ],
            if (onUpdateHorseVisibility != null) ...[
              const SizedBox(height: 6),
              _MultiplayerVisibilityCard(
                horse: horse,
                onUpdateHorseVisibility: onUpdateHorseVisibility!,
              ),
            ],
            _TraitBreakdownCard(horse: horse),
            const _TraitGlossaryCard(),
            _DetailLine(
              label: 'Bloodline read',
              value: horseProgressSummary(horse),
            ),
            if (onPurgeHorse != null) ...[
              const SizedBox(height: 6),
              _PurgeCard(horse: horse, onPurgeHorse: onPurgeHorse!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValueClassBadge extends StatelessWidget {
  const _ValueClassBadge({required this.horse});

  final Horse horse;

  @override
  Widget build(BuildContext context) {
    final color = switch (horse.valueClassLabel) {
      'Collector' => AppTheme.tertiary,
      'Elite' => AppTheme.primary,
      'Well-Bred' => AppTheme.secondary,
      _ => AppTheme.mutedInk,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        horse.valueClassLabel,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TraitBreakdownCard extends StatelessWidget {
  const _TraitBreakdownCard({required this.horse});

  final Horse horse;

  @override
  Widget build(BuildContext context) {
    final visibleHorse = normalizeHorseVisibleTraits(horse);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Traits',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...visibleHorse.traits.map(
              (trait) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_traitLabel(trait.type).toLowerCase()}: ${trait.option}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (horse.specialTraits.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Special traits',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: horse.specialTraits
                    .map(
                      (trait) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.tertiary.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Text(
                          trait,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (horse.lineageMemory.isNotEmpty) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: () => _showHiddenAncestry(context),
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hidden ancestry',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to view more',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.mutedInk,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showHiddenAncestry(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.mutedInk.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Hidden Ancestry',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.panelGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: horse.lineageMemory.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${_traitLabel(entry.key).toLowerCase()}: ${entry.value.entries.map((trait) => '${trait.key} (${_ancestorDepthLabel(trait.value)})').join(', ')}',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PurgeCard extends StatelessWidget {
  const _PurgeCard({required this.horse, required this.onPurgeHorse});

  final Horse horse;
  final ValueChanged<Horse> onPurgeHorse;

  @override
  Widget build(BuildContext context) {
    final payout = horse.purgePayout;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0x26FF7A59), AppTheme.surfaceRaised],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x66FF7A59)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purge',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFFFB199),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Purging permanently removes this horse from your stable and pays out $payout coins, which is 25% of its current sale value.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _PurgeValuePreview(horse: horse),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _confirmPurge(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0x22FF7A59),
                  foregroundColor: const Color(0xFFFFC9B8),
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text('Purge for $payout coins'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPurge(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppTheme.outline),
          ),
          title: const Text('Purge horse?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently remove ${horse.displayName} from your stable.',
              ),
              const SizedBox(height: 10),
              Text('Current sale value: ${horse.derivedPrice} coins'),
              Text('Purge payout: ${horse.purgePayout} coins'),
              Text('Rating: ${horse.score} • ${horse.breedingRarity.label}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.mutedInk,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Purge'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    Navigator.of(context).pop();
    onPurgeHorse(horse);
  }
}

class _PurgeValuePreview extends StatelessWidget {
  const _PurgeValuePreview({required this.horse});

  final Horse horse;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PurgeValueChip(label: 'Sale value', value: '${horse.derivedPrice}'),
        _PurgeValueChip(label: 'Payout', value: '${horse.purgePayout}'),
        _PurgeValueChip(label: 'Rating', value: '${horse.score}'),
        _PurgeValueChip(label: 'Tier', value: horse.breedingRarity.label),
      ],
    );
  }
}

class _PurgeValueChip extends StatelessWidget {
  const _PurgeValueChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x44FF7A59)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HorseItemActionsCard extends StatefulWidget {
  const _HorseItemActionsCard({
    required this.horse,
    required this.activePregnancy,
    required this.activeCooldown,
    required this.currentTime,
    required this.inventory,
    required this.prenatalAlreadyUsed,
    required this.carrotAlreadyUsed,
    required this.onUsePrenatalVitamin,
    required this.onUseCarrot,
  });

  final Horse horse;
  final PregnancyRecord? activePregnancy;
  final BreedingCooldown? activeCooldown;
  final DateTime? currentTime;
  final Map<InventoryItemType, int> inventory;
  final bool prenatalAlreadyUsed;
  final bool carrotAlreadyUsed;
  final ValueChanged<PregnancyRecord>? onUsePrenatalVitamin;
  final ValueChanged<BreedingCooldown>? onUseCarrot;

  @override
  State<_HorseItemActionsCard> createState() => _HorseItemActionsCardState();
}

class _HorseItemActionsCardState extends State<_HorseItemActionsCard> {
  late int _prenatalCount;
  late int _carrotCount;
  late bool _prenatalAlreadyUsed;
  late bool _carrotAlreadyUsed;
  PregnancyRecord? _activePregnancy;
  BreedingCooldown? _activeCooldown;

  @override
  void initState() {
    super.initState();
    _syncLocalState();
  }

  @override
  void didUpdateWidget(covariant _HorseItemActionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inventory != widget.inventory ||
        oldWidget.prenatalAlreadyUsed != widget.prenatalAlreadyUsed ||
        oldWidget.carrotAlreadyUsed != widget.carrotAlreadyUsed ||
        oldWidget.activePregnancy != widget.activePregnancy ||
        oldWidget.activeCooldown != widget.activeCooldown) {
      _syncLocalState();
    }
  }

  void _syncLocalState() {
    _prenatalCount = widget.inventory[InventoryItemType.prenatalVitamin] ?? 0;
    _carrotCount = widget.inventory[InventoryItemType.carrot] ?? 0;
    _prenatalAlreadyUsed = widget.prenatalAlreadyUsed;
    _carrotAlreadyUsed = widget.carrotAlreadyUsed;
    _activePregnancy = widget.activePregnancy;
    _activeCooldown = widget.activeCooldown;
  }

  @override
  Widget build(BuildContext context) {
    final pregnancy = _activePregnancy;
    final cooldown = _activeCooldown;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use Item',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (pregnancy != null && widget.onUsePrenatalVitamin != null) ...[
              const SizedBox(height: 10),
              _HorseItemActionRow(
                icon: Icons.medication_rounded,
                title: 'Prenatal vitamin',
                subtitle:
                    'Pregnancy due ${pregnancy.birthCountdownLabelAt(widget.currentTime ?? DateTime.now())}',
                count: _prenatalCount,
                alreadyUsed: _prenatalAlreadyUsed,
                unavailableText: _prenatalCount <= 0
                    ? 'No prenatal vitamins owned'
                    : _prenatalAlreadyUsed
                    ? 'Already used for this pregnancy'
                    : null,
                onUse: _prenatalCount > 0 && !_prenatalAlreadyUsed
                    ? () => _usePrenatalVitamin(pregnancy)
                    : null,
              ),
            ],
            if (cooldown != null &&
                cooldown.sex == 'Stallion' &&
                cooldown.reason != 'Healing' &&
                widget.onUseCarrot != null) ...[
              const SizedBox(height: 10),
              _HorseItemActionRow(
                icon: Icons.spa_rounded,
                title: 'Carrot',
                subtitle:
                    '${cooldown.reason} • ${_formatCooldown(cooldown.remainingAt(widget.currentTime ?? DateTime.now()))}',
                count: _carrotCount,
                alreadyUsed: _carrotAlreadyUsed,
                unavailableText: _carrotCount <= 0
                    ? 'No carrots owned'
                    : _carrotAlreadyUsed
                    ? 'Already used this cooldown'
                    : null,
                onUse: _carrotCount > 0 && !_carrotAlreadyUsed
                    ? () => _useCarrot(cooldown)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _usePrenatalVitamin(PregnancyRecord pregnancy) {
    widget.onUsePrenatalVitamin!(pregnancy);
    final now = widget.currentTime ?? DateTime.now();
    final remaining = pregnancy.dueAt.difference(now);
    final boostedDueAt = remaining <= Duration.zero
        ? pregnancy.dueAt
        : now.add(Duration(seconds: remaining.inSeconds ~/ 2));
    setState(() {
      _prenatalCount = (_prenatalCount - 1).clamp(0, 1000000);
      _prenatalAlreadyUsed = true;
      _activePregnancy = PregnancyRecord(
        id: pregnancy.id,
        damId: pregnancy.damId,
        damName: pregnancy.damName,
        sireId: pregnancy.sireId,
        sireName: pregnancy.sireName,
        unbornFoalName: pregnancy.unbornFoalName,
        registryId: pregnancy.registryId,
        breed: pregnancy.breed,
        foal: pregnancy.foal,
        conceivedAt: pregnancy.conceivedAt,
        dueAt: boostedDueAt,
        damCooldownEndsAt: pregnancy.damCooldownEndsAt,
        sireCooldownEndsAt: pregnancy.sireCooldownEndsAt,
        isMutant: pregnancy.isMutant,
      );
    });
  }

  void _useCarrot(BreedingCooldown cooldown) {
    widget.onUseCarrot!(cooldown);
    final now = widget.currentTime ?? DateTime.now();
    final remaining = cooldown.endsAt.difference(now);
    final boostedEndsAt = remaining <= Duration.zero
        ? cooldown.endsAt
        : now.add(Duration(seconds: remaining.inSeconds ~/ 2));
    setState(() {
      _carrotCount = (_carrotCount - 1).clamp(0, 1000000);
      _carrotAlreadyUsed = true;
      _activeCooldown = BreedingCooldown(
        horseId: cooldown.horseId,
        horseName: cooldown.horseName,
        sex: cooldown.sex,
        reason: cooldown.reason,
        endsAt: boostedEndsAt,
      );
    });
  }
}

class _HorseItemActionRow extends StatelessWidget {
  const _HorseItemActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.alreadyUsed,
    required this.onUse,
    this.unavailableText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final bool alreadyUsed;
  final VoidCallback? onUse;
  final String? unavailableText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title • $count owned',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                if (unavailableText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    unavailableText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.tertiary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onUse,
            child: Text(alreadyUsed ? 'Used' : 'Use'),
          ),
        ],
      ),
    );
  }
}

class _MultiplayerVisibilityCard extends StatefulWidget {
  const _MultiplayerVisibilityCard({
    required this.horse,
    required this.onUpdateHorseVisibility,
  });

  final Horse horse;
  final String? Function(
    Horse horse, {
    bool? isPublicListing,
    bool? isFeaturedProfileHorse,
    bool? isListedForSale,
  })
  onUpdateHorseVisibility;

  @override
  State<_MultiplayerVisibilityCard> createState() =>
      _MultiplayerVisibilityCardState();
}

class _MultiplayerVisibilityCardState
    extends State<_MultiplayerVisibilityCard> {
  late bool _isPublicListing;
  late bool _isFeaturedProfileHorse;
  late bool _isListedForSale;

  @override
  void initState() {
    super.initState();
    _syncFromHorse();
  }

  @override
  void didUpdateWidget(covariant _MultiplayerVisibilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horse.id != widget.horse.id ||
        oldWidget.horse.isPublicListing != widget.horse.isPublicListing ||
        oldWidget.horse.isFeaturedProfileHorse !=
            widget.horse.isFeaturedProfileHorse ||
        oldWidget.horse.isListedForSale != widget.horse.isListedForSale) {
      _syncFromHorse();
    }
  }

  void _syncFromHorse() {
    _isPublicListing = widget.horse.isPublicListing;
    _isFeaturedProfileHorse = widget.horse.isFeaturedProfileHorse;
    _isListedForSale = widget.horse.isListedForSale;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withValues(alpha: 0.16),
              AppTheme.surfaceRaised,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player Profile Controls',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Decide which horses show on your public profile, which ones get featured, and which ones are listed for formula-priced player sales.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _VisibilityToggle(
              label: 'Public stable',
              value: _isPublicListing,
              onChanged: (value) => _applyChange(
                context,
                isPublicListing: value,
                ifTurningOffPublicAlsoDisableListing: true,
              ),
            ),
            _VisibilityToggle(
              label: 'Featured horse',
              value: _isFeaturedProfileHorse,
              onChanged: (value) => _applyChange(
                context,
                isFeaturedProfileHorse: value,
                ifTurningOnFeaturedAlsoEnablePublic: true,
              ),
            ),
            _VisibilityToggle(
              label: 'List for sale',
              value: _isListedForSale,
              onChanged: (value) => _applyChange(
                context,
                isListedForSale: value,
                ifTurningOnListingAlsoEnablePublic: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Player sale price: ${widget.horse.playerSalePrice} coins • Seller payout: ${widget.horse.sellerListingPayout} coins',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyChange(
    BuildContext context, {
    bool? isPublicListing,
    bool? isFeaturedProfileHorse,
    bool? isListedForSale,
    bool ifTurningOnListingAlsoEnablePublic = false,
    bool ifTurningOnFeaturedAlsoEnablePublic = false,
    bool ifTurningOffPublicAlsoDisableListing = false,
  }) {
    final nextPublic =
        ifTurningOnListingAlsoEnablePublic && isListedForSale == true
        ? true
        : ifTurningOnFeaturedAlsoEnablePublic && isFeaturedProfileHorse == true
        ? true
        : ifTurningOffPublicAlsoDisableListing && isPublicListing == false
        ? false
        : isPublicListing ?? _isPublicListing;
    final nextListed =
        ifTurningOffPublicAlsoDisableListing && isPublicListing == false
        ? false
        : isListedForSale ?? _isListedForSale;
    final nextFeatured = isFeaturedProfileHorse ?? _isFeaturedProfileHorse;

    setState(() {
      _isPublicListing = nextPublic;
      _isFeaturedProfileHorse = nextPublic ? nextFeatured : false;
      _isListedForSale = nextPublic ? nextListed : false;
    });

    final error = widget.onUpdateHorseVisibility(
      widget.horse,
      isPublicListing: nextPublic,
      isFeaturedProfileHorse: isFeaturedProfileHorse,
      isListedForSale: nextListed,
    );
    if (error != null) {
      setState(_syncFromHorse);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.secondary,
      activeTrackColor: AppTheme.secondary.withValues(alpha: 0.36),
    );
  }
}

String _ancestorDepthLabel(int depth) {
  return switch (depth) {
    1 => 'parent',
    2 => 'grandparent',
    3 => 'great-grandparent',
    4 => '2x great-grandparent',
    _ => '${depth - 2}x removed',
  };
}

String _traitLabel(String type) {
  return type
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _IdentityDetailLine extends StatefulWidget {
  const _IdentityDetailLine({
    required this.horseId,
    required this.registryId,
    required this.currentName,
    required this.registeredName,
    required this.breed,
    required this.sex,
    required this.generation,
    required this.transfers,
    required this.breedingStatus,
    required this.horse,
    this.cooldown,
    this.onRenameHorse,
  });

  final String horseId;
  final String registryId;
  final String currentName;
  final String registeredName;
  final String breed;
  final String sex;
  final int generation;
  final int transfers;
  final String breedingStatus;
  final Horse horse;
  final String? cooldown;
  final void Function(Horse horse, String newName)? onRenameHorse;

  @override
  State<_IdentityDetailLine> createState() => _IdentityDetailLineState();
}

class _IdentityDetailLineState extends State<_IdentityDetailLine> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  widget.registryId,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Tooltip(
                  message: _copied ? 'Copied' : 'Copy horse ID',
                  child: InkWell(
                    onTap: () => _copyHorseIds(context),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: _copied ? 10 : 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (_copied ? AppTheme.secondary : AppTheme.primary)
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              (_copied ? AppTheme.secondary : AppTheme.primary)
                                  .withValues(alpha: 0.36),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: _copied
                            ? Row(
                                key: const ValueKey('copied'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copied',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.secondary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              )
                            : const Icon(
                                Icons.copy_rounded,
                                key: ValueKey('copy'),
                                size: 15,
                                color: AppTheme.primary,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  widget.currentName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.onRenameHorse != null)
                  Tooltip(
                    message: 'Edit horse name',
                    child: InkWell(
                      onTap: () => _showRenameSheet(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.36),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 15,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Registered as ${widget.registeredName}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _IdentityPill(label: widget.breed),
                _IdentityPill(label: widget.sex),
                _IdentityPill(label: 'Generation ${widget.generation}'),
                _IdentityPill(label: 'Transfers ${widget.transfers}'),
                _IdentityPill(label: widget.breedingStatus),
                if (widget.cooldown != null)
                  _IdentityPill(label: widget.cooldown!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameSheet(BuildContext context) async {
    final renamed = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _RenameHorseSheet(initialName: widget.currentName);
      },
    );

    if (renamed == null ||
        renamed.isEmpty ||
        renamed == widget.currentName ||
        !context.mounted) {
      return;
    }
    widget.onRenameHorse?.call(widget.horse, renamed);
  }

  Future<void> _copyHorseIds(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text: 'Horse ID: ${widget.horseId}\nRegistry ID: ${widget.registryId}',
      ),
    );
    if (!context.mounted) {
      return;
    }
    setState(() {
      _copied = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _copied = false;
      });
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Horse IDs copied.')));
  }
}

class _RenameHorseSheet extends StatefulWidget {
  const _RenameHorseSheet({required this.initialName});

  final String initialName;

  @override
  State<_RenameHorseSheet> createState() => _RenameHorseSheetState();
}

class _RenameHorseSheetState extends State<_RenameHorseSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppTheme.outline)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.mutedInk.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Horse Name',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(_controller.text.trim());
  }
}

String _formatCooldown(Duration duration) {
  if (duration <= Duration.zero) {
    return '0:00';
  }

  var totalMinutes = duration.inMinutes;
  if (duration.inSeconds % 60 != 0) {
    totalMinutes += 1;
  }

  final days = totalMinutes ~/ Duration.minutesPerDay;
  final hours =
      (totalMinutes % Duration.minutesPerDay) ~/ Duration.minutesPerHour;
  final minutes = totalMinutes % Duration.minutesPerHour;

  final hourText = hours.toString().padLeft(2, '0');
  final minuteText = minutes.toString().padLeft(2, '0');
  if (days > 0) {
    return '$days:$hourText:$minuteText';
  }
  return '$hourText:$minuteText';
}

class _IdentityPill extends StatelessWidget {
  const _IdentityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _RarityReadCard extends StatelessWidget {
  const _RarityReadCard({required this.horse});

  final Horse horse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rarity read',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Visual ${horse.visualRarity.label}: ${horse.visualRarityRead}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Breeding ${horse.breedingRarity.label}: ${horse.breedingRarityRead}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Hidden breeding insight',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              horse.hiddenBreedingInsight,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraitGlossaryCard extends StatelessWidget {
  const _TraitGlossaryCard();

  @override
  Widget build(BuildContext context) {
    final glossaryRows = const [
      'Common: everyday trait with low market impact.',
      'Uncommon: a nicer step up, but still regularly seen.',
      'Rare: valuable visible or breeding lift.',
      'Epic: standout premium trait with stronger upside.',
      'Legendary: top-end collector or inheritance trait.',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trait glossary',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...glossaryRows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  row,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
