import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/breeding_cooldown.dart';
import '../../domain/models/horse.dart';
import '../../domain/models/mating_session.dart';
import '../../domain/models/pregnancy_record.dart';
import '../../logic/services/breeding_preview_service.dart';
import 'ancestry_screen.dart';
import '../widgets/horse_preview.dart';
import '../widgets/section_card.dart';

class BreedScreen extends StatefulWidget {
  const BreedScreen({
    super.key,
    required this.stableHorses,
    required this.marketHorses,
    required this.activePregnancies,
    required this.activeMating,
    required this.currentTime,
    required this.selectedDamId,
    required this.selectedSireId,
    required this.breedingCooldowns,
    required this.onSelectDam,
    required this.onSelectSire,
    required this.onConfirmMating,
    required this.onAdvanceTime,
    required this.stableCount,
    required this.stableCap,
    required this.stableAtCapacity,
  });

  final List<Horse> stableHorses;
  final List<Horse> marketHorses;
  final List<PregnancyRecord> activePregnancies;
  final MatingSession? activeMating;
  final DateTime currentTime;
  final String? selectedDamId;
  final String? selectedSireId;
  final List<BreedingCooldown> breedingCooldowns;
  final ValueChanged<Horse> onSelectDam;
  final ValueChanged<Horse> onSelectSire;
  final void Function(Horse dam, Horse sire) onConfirmMating;
  final void Function(Duration delta) onAdvanceTime;
  final int stableCount;
  final int stableCap;
  final bool stableAtCapacity;

  @override
  State<BreedScreen> createState() => _BreedScreenState();
}

class _BreedScreenState extends State<BreedScreen> {
  bool _showDebugTime = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceRaised.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: TabBar(
                      controller: controller,
                      isScrollable: true,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.secondary),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.mutedInk,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                      labelStyle: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                      tabs: const [
                        Tab(text: 'Breed'),
                        Tab(text: 'Lineage'),
                        Tab(text: 'Compare'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: controller,
                    children: [
                      _BreedingWorkspace(
                        stableHorses: widget.stableHorses,
                        activePregnancies: widget.activePregnancies,
                        activeMating: widget.activeMating,
                        currentTime: widget.currentTime,
                        selectedDamId: widget.selectedDamId,
                        selectedSireId: widget.selectedSireId,
                        breedingCooldowns: widget.breedingCooldowns,
                        onSelectDam: widget.onSelectDam,
                        onSelectSire: widget.onSelectSire,
                        onConfirmMating: widget.onConfirmMating,
                        onAdvanceTime: widget.onAdvanceTime,
                        stableCount: widget.stableCount,
                        stableCap: widget.stableCap,
                        stableAtCapacity: widget.stableAtCapacity,
                        showDebugTime: _showDebugTime,
                        onToggleDebugTime: () {
                          setState(() {
                            _showDebugTime = !_showDebugTime;
                          });
                        },
                      ),
                      AncestryScreen(
                        stableHorses: widget.stableHorses,
                        embedded: true,
                      ),
                      _CompatibilityWorkspace(
                        stableHorses: widget.stableHorses,
                        marketHorses: widget.marketHorses,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BreedingWorkspace extends StatelessWidget {
  const _BreedingWorkspace({
    required this.stableHorses,
    required this.activePregnancies,
    required this.activeMating,
    required this.currentTime,
    required this.selectedDamId,
    required this.selectedSireId,
    required this.breedingCooldowns,
    required this.onSelectDam,
    required this.onSelectSire,
    required this.onConfirmMating,
    required this.onAdvanceTime,
    required this.stableCount,
    required this.stableCap,
    required this.stableAtCapacity,
    required this.showDebugTime,
    required this.onToggleDebugTime,
  });

  final List<Horse> stableHorses;
  final List<PregnancyRecord> activePregnancies;
  final MatingSession? activeMating;
  final DateTime currentTime;
  final String? selectedDamId;
  final String? selectedSireId;
  final List<BreedingCooldown> breedingCooldowns;
  final ValueChanged<Horse> onSelectDam;
  final ValueChanged<Horse> onSelectSire;
  final void Function(Horse dam, Horse sire) onConfirmMating;
  final void Function(Duration delta) onAdvanceTime;
  final int stableCount;
  final int stableCap;
  final bool stableAtCapacity;
  final bool showDebugTime;
  final VoidCallback onToggleDebugTime;

  @override
  Widget build(BuildContext context) {
    final mares = stableHorses.where((horse) => horse.sex == 'Mare').toList()
      ..sort(_compareHorseNamesNaturally);
    final stallions =
        stableHorses.where((horse) => horse.sex == 'Stallion').toList()
          ..sort(_compareHorseNamesNaturally);

    if (stableHorses.isEmpty) {
      return Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 132),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breed',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Start by buying your first horses from the market. You need at least one mare and one stallion before you can create a pairing.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
                ),
                const SizedBox(height: 10),
                Text(
                  'Stable capacity: $stableCount/$stableCap',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                const SectionCard(
                  title: 'No Stable Horses Yet',
                  subtitle: 'Choose your first pair from Market',
                  child: Text(
                    'Breeding stays locked until you own horses. Buy a mare for 750 coins and a stallion for 1500 coins, then come back here to choose exactly which pair you want to breed.',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (mares.isEmpty || stallions.isEmpty) {
      final missingLabel = mares.isEmpty ? 'mare' : 'stallion';
      return Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 132),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breed',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose the horses you want to breed once you own both parent types.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
                ),
                const SizedBox(height: 10),
                Text(
                  'Stable capacity: $stableCount/$stableCap',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                SectionCard(
                  title: 'Missing Parent Type',
                  subtitle: 'You need one mare and one stallion',
                  child: Text(
                    'Your stable is missing a $missingLabel. Buy one from the market, then come back here and pick the exact pair you want to breed.',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final dam = mares.firstWhere(
      (horse) => horse.id == selectedDamId,
      orElse: () => mares.isNotEmpty ? mares.first : stableHorses.first,
    );
    final sire = stallions.firstWhere(
      (horse) => horse.id == selectedSireId,
      orElse: () => stallions.isNotEmpty
          ? stallions.first
          : stableHorses.length > 1
          ? stableHorses[1]
          : stableHorses.first,
    );
    final preview = const BreedingPreviewService().preview(
      dam: dam,
      sire: sire,
    );
    final damPregnancy = activePregnancies.cast<PregnancyRecord?>().firstWhere(
      (pregnancy) => pregnancy?.damId == dam.id,
      orElse: () => null,
    );
    final damCooldown = _activeCooldownFor(dam.id);
    final sireCooldown = _activeCooldownFor(sire.id);
    final damBirthReady =
        damPregnancy != null && !damPregnancy.dueAt.isAfter(currentTime);
    final damCanBreed =
        dam.isBreedingReady && damCooldown == null && damPregnancy == null;
    final sireCanBreed = sire.isBreedingReady && sireCooldown == null;
    final matingCountdown = activeMating?.remainingAt(currentTime);
    final overdueBirths = activePregnancies
        .where((pregnancy) => !pregnancy.dueAt.isAfter(currentTime))
        .length;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 132),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Breed', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                'Pair your mare and stallion, lock in the match, and swipe over to Lineage anytime to inspect bloodlines.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
              ),
              const SizedBox(height: 10),
              Text(
                'Stable capacity: $stableCount/$stableCap',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: stableAtCapacity
                      ? AppTheme.primary
                      : AppTheme.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        activePregnancies.isEmpty
                            ? activeMating == null
                                  ? 'Foals start at day 1, become breed-ready at day 5, and retire from breeding after day 35.'
                                  : '${activeMating!.damName} and ${activeMating!.sireName} are currently mating. Countdown: ${_formatDuration(matingCountdown!)}.'
                            : overdueBirths > 0 && stableAtCapacity
                            ? '$overdueBirths foal${overdueBirths == 1 ? '' : 's'} are ready for birth, but your stable is full. Make room to deliver them.'
                            : '${activePregnancies.length} pending foal${activePregnancies.length == 1 ? '' : 's'} are on 4 day pregnancy timers. Mares recover for 3 days after the due time, and stallions recover for 12 hours.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Active Pairing',
                subtitle: '${dam.displayName} × ${sire.displayName}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose parents',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ParentSelector(
                            title: 'Mare',
                            horses: mares,
                            selectedHorseId: dam.id,
                            onSelected: onSelectDam,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ParentSelector(
                            title: 'Stallion',
                            horses: stallions,
                            selectedHorseId: sire.id,
                            accent: AppTheme.secondary,
                            onSelected: onSelectSire,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ParentPanel(
                            label: 'Mom',
                            horse: dam,
                            cooldownLabel: damCooldown != null
                                ? _formatDuration(
                                    damCooldown.remainingAt(currentTime),
                                  )
                                : null,
                            statusNote: activeMating?.damId == dam.id
                                ? 'Mating now'
                                : damBirthReady
                                ? stableAtCapacity
                                      ? 'Healing • waiting for stable space'
                                      : 'Healing • ready for birth'
                                : damPregnancy != null
                                ? 'Pregnant • due in ${damPregnancy.birthCountdownLabelAt(currentTime)}'
                                : !dam.isBreedingReady
                                ? 'Breed-ready at day ${Horse.breedingReadyAgeDays}'
                                : dam.isRetired
                                ? 'Retired at day ${Horse.breedingRetirementAgeDays}'
                                : damCooldown?.reason,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ParentPanel(
                            label: 'Sire',
                            horse: sire,
                            cooldownLabel: sireCooldown != null
                                ? _formatDuration(
                                    sireCooldown.remainingAt(currentTime),
                                  )
                                : null,
                            cooldownAccent: AppTheme.secondary,
                            statusNote: activeMating?.sireId == sire.id
                                ? 'Mating now'
                                : !sire.isBreedingReady
                                ? 'Breed-ready at day ${Horse.breedingReadyAgeDays}'
                                : sire.isRetired
                                ? 'Retired at day ${Horse.breedingRetirementAgeDays}'
                                : sireCooldown?.reason,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            activeMating == null && damCanBreed && sireCanBreed
                            ? () => onConfirmMating(dam, sire)
                            : null,
                        icon: Icon(
                          activeMating == null
                              ? Icons.favorite_rounded
                              : Icons.hourglass_top_rounded,
                        ),
                        label: Text(
                          activeMating != null
                              ? 'Mating in progress • ${_formatDuration(matingCountdown!)}'
                              : damPregnancy != null
                              ? damBirthReady
                                    ? stableAtCapacity
                                          ? 'Birth pending • make stable space'
                                          : 'Birth foal is ready'
                                    : 'Selected mare is pregnant'
                              : !dam.isBreedingReady || !sire.isBreedingReady
                              ? 'Parents must reach day ${Horse.breedingReadyAgeDays}'
                              : dam.isRetired || sire.isRetired
                              ? 'Selected parent is retired'
                              : damCooldown != null || sireCooldown != null
                              ? 'Selected parent is cooling down'
                              : 'Start breeding',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Foal forecast',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Projected breed: ${preview.breed}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    ...preview.likelyTraits.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${entry.key.replaceAll('_', ' ')}: ${entry.value.join(' / ')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...preview.inheritanceNotes.map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ForecastCallout(text: note),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preview.mutationSummary,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview.raritySummary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (preview.possibleSpecialTraits.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Possible special traits: ${preview.possibleSpecialTraits.join(', ')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Retry chance after mating completes: 10.0%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Breeding Rules',
                subtitle: 'How the unborn card behaves',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _BreedLine(
                      '1. Foals start at day 1 and become breed-ready on day 5.',
                    ),
                    _BreedLine(
                      '2. Each completed breeding attempt puts the stallion on a 12 hour recovery timer.',
                    ),
                    _BreedLine(
                      '3. Pregnancies last 4 days. Mare recovery begins at the foal due time and lasts 3 days, even if you wait to press Birth foal.',
                    ),
                    _BreedLine(
                      '4. Horses retire from breeding after day 35 and earn a retired emblem.',
                    ),
                    _BreedLine(
                      '5. 10% of completed matings create a mutant unborn foal with boosted rare-trait rolls.',
                    ),
                    _BreedLine(
                      '6. The remaining 10% fail and require another attempt.',
                    ),
                    _BreedLine(
                      '7. Successful pairings create pending foals in Stable, where they wait until you press Birth foal.',
                    ),
                    _BreedLine(
                      '8. You can keep breeding while full, but overdue foals wait for an open stable slot before you can press Birth foal.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          bottom: 24,
          child: _DebugTimeDrawer(
            currentTime: currentTime,
            isExpanded: showDebugTime,
            onToggle: onToggleDebugTime,
            onAdvanceTime: onAdvanceTime,
          ),
        ),
      ],
    );
  }

  BreedingCooldown? _activeCooldownFor(String horseId) {
    for (final cooldown in breedingCooldowns) {
      if (cooldown.horseId == horseId && cooldown.isActiveAt(currentTime)) {
        return cooldown;
      }
    }
    return null;
  }
}

class _DebugTimeDrawer extends StatelessWidget {
  const _DebugTimeDrawer({
    required this.currentTime,
    required this.isExpanded,
    required this.onToggle,
    required this.onAdvanceTime,
  });

  final DateTime currentTime;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(Duration delta) onAdvanceTime;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: isExpanded ? Offset.zero : const Offset(0.86, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.surfaceRaised.withValues(alpha: 0.96),
              AppTheme.surface.withValues(alpha: 0.94),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          border: Border.all(color: AppTheme.outline.withValues(alpha: 0.7)),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.shadow,
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onToggle,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Container(
                  width: 36,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    border: Border(
                      right: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.chevron_right_rounded
                            : Icons.chevron_left_rounded,
                        color: AppTheme.secondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 196,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cool Down Time',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatClock(currentTime),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TimeChip(
                            label: '+3m',
                            onTap: () =>
                                onAdvanceTime(const Duration(minutes: 3)),
                          ),
                          _TimeChip(
                            label: '+10m',
                            onTap: () =>
                                onAdvanceTime(const Duration(minutes: 10)),
                          ),
                          _TimeChip(
                            label: '+1d',
                            onTap: () => onAdvanceTime(const Duration(days: 1)),
                          ),
                          _TimeChip(
                            label: '+7d',
                            onTap: () => onAdvanceTime(const Duration(days: 7)),
                          ),
                          _TimeChip(
                            label: '+14d',
                            onTap: () =>
                                onAdvanceTime(const Duration(days: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatClock(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ParentPanel extends StatelessWidget {
  const _ParentPanel({
    required this.label,
    required this.horse,
    this.cooldownLabel,
    this.cooldownAccent = AppTheme.primary,
    this.statusNote,
  });

  final String label;
  final Horse horse;
  final String? cooldownLabel;
  final Color cooldownAccent;
  final String? statusNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          HorsePreview(horse: horse, compact: true),
          const SizedBox(height: 10),
          Text(
            horse.displayName,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            horse.cardSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (statusNote != null) ...[
            const SizedBox(height: 8),
            Text(
              statusNote!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.tertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (cooldownLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              'Cooldown: $cooldownLabel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cooldownAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParentSelector extends StatelessWidget {
  const _ParentSelector({
    required this.title,
    required this.horses,
    required this.selectedHorseId,
    required this.onSelected,
    this.accent = AppTheme.primary,
  });

  final String title;
  final List<Horse> horses;
  final String selectedHorseId;
  final Color accent;
  final ValueChanged<Horse> onSelected;

  @override
  Widget build(BuildContext context) {
    return _HorseDropdownSelectorField(
      label: title,
      accent: accent,
      horses: horses,
      selectedHorseId: selectedHorseId,
      onChanged: onSelected,
    );
  }
}

class _HorseDropdownSelectorField extends StatelessWidget {
  const _HorseDropdownSelectorField({
    required this.label,
    required this.accent,
    required this.horses,
    required this.selectedHorseId,
    required this.onChanged,
  });

  final String label;
  final Color accent;
  final List<Horse> horses;
  final String? selectedHorseId;
  final ValueChanged<Horse> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedHorseId,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceRaised,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceRaised.withValues(alpha: 0.72),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.outline.withValues(alpha: 0.8),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.outline.withValues(alpha: 0.8),
              ),
            ),
          ),
          iconEnabledColor: accent,
          items: horses
              .map(
                (horse) => DropdownMenuItem<String>(
                  value: horse.id,
                  child: Text(
                    horse.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => horses
              .map(
                (horse) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    horse.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (horseId) {
            final selected = horses.cast<Horse?>().firstWhere(
              (horse) => horse?.id == horseId,
              orElse: () => null,
            );
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      ],
    );
  }
}

int _compareHorseNamesNaturally(Horse a, Horse b) {
  final aParts = _naturalSortParts(a.displayName);
  final bParts = _naturalSortParts(b.displayName);
  final length = aParts.length < bParts.length ? aParts.length : bParts.length;

  for (var i = 0; i < length; i++) {
    final aPart = aParts[i];
    final bPart = bParts[i];
    final aIsNumber = int.tryParse(aPart);
    final bIsNumber = int.tryParse(bPart);

    if (aIsNumber != null && bIsNumber != null) {
      final compare = aIsNumber.compareTo(bIsNumber);
      if (compare != 0) {
        return compare;
      }
      continue;
    }

    final compare = aPart.compareTo(bPart);
    if (compare != 0) {
      return compare;
    }
  }

  return aParts.length.compareTo(bParts.length);
}

List<String> _naturalSortParts(String value) {
  return RegExp(
    r'\d+|\D+',
  ).allMatches(value.toLowerCase()).map((match) => match.group(0)!).toList();
}

String _formatDuration(Duration duration) {
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

class _BreedLine extends StatelessWidget {
  const _BreedLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _CompatibilityWorkspace extends StatefulWidget {
  const _CompatibilityWorkspace({
    required this.stableHorses,
    required this.marketHorses,
  });

  final List<Horse> stableHorses;
  final List<Horse> marketHorses;

  @override
  State<_CompatibilityWorkspace> createState() =>
      _CompatibilityWorkspaceState();
}

class _CompatibilityWorkspaceState extends State<_CompatibilityWorkspace> {
  final TextEditingController _leftRegistryController = TextEditingController();
  final TextEditingController _rightRegistryController =
      TextEditingController();

  String? _leftStableHorseId;
  String? _rightStableHorseId;
  Horse? _leftHorse;
  Horse? _rightHorse;
  String? _leftLookupMessage;
  String? _rightLookupMessage;

  @override
  void initState() {
    super.initState();
    _seedSelections();
  }

  @override
  void didUpdateWidget(covariant _CompatibilityWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stableHorses != widget.stableHorses ||
        oldWidget.marketHorses != widget.marketHorses) {
      _reconcileSelections();
    }
  }

  @override
  void dispose() {
    _leftRegistryController.dispose();
    _rightRegistryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allGameHorses = _allGameHorses;
    final stableHorses = List<Horse>.of(widget.stableHorses)
      ..sort(_compareHorseNamesNaturally);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compatibility',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Compare any two horses side by side. Pick them from your stable or type a registry ID from anywhere in the current game.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Choose Horses',
            subtitle:
                '${widget.stableHorses.length} stable horses · ${allGameHorses.length} current horses searchable by I.D.',
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackSelectors = constraints.maxWidth < 640;
                    final children = [
                      _CompatibilitySelectorCard(
                        title: 'Horse A',
                        accent: AppTheme.primary,
                        stableHorses: stableHorses,
                        selectedStableHorseId: _leftStableHorseId,
                        registryController: _leftRegistryController,
                        lookupMessage: _leftLookupMessage,
                        onStableChanged: _selectLeftFromStable,
                        onLookup: () => _lookupLeftHorseByRegistry(
                          _leftRegistryController.text,
                        ),
                      ),
                      _CompatibilitySelectorCard(
                        title: 'Horse B',
                        accent: AppTheme.secondary,
                        stableHorses: stableHorses,
                        selectedStableHorseId: _rightStableHorseId,
                        registryController: _rightRegistryController,
                        lookupMessage: _rightLookupMessage,
                        onStableChanged: _selectRightFromStable,
                        onLookup: () => _lookupRightHorseByRegistry(
                          _rightRegistryController.text,
                        ),
                      ),
                    ];

                    if (stackSelectors) {
                      return Column(
                        children: [
                          children[0],
                          const SizedBox(height: 12),
                          children[1],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 12),
                        Expanded(child: children[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Any pairing works here: mare vs mare, stallion vs stallion, or any mixed comparison.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_leftHorse != null && _rightHorse != null) ...[
            SectionCard(
              title: 'Quick Read',
              subtitle: 'Shared traits and differences at a glance',
              compact: true,
              child: _CompatibilitySummary(
                leftHorse: _leftHorse!,
                rightHorse: _rightHorse!,
              ),
            ),
            const SizedBox(height: 18),
          ],
          SectionCard(
            title: 'Side-By-Side Compare',
            subtitle: _comparisonSubtitle,
            compact: true,
            child: _leftHorse == null || _rightHorse == null
                ? const _CompatibilityEmptyState()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CompatibilityHorseCard(
                          title: 'Horse A',
                          horse: _leftHorse!,
                          accent: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompatibilityHorseCard(
                          title: 'Horse B',
                          horse: _rightHorse!,
                          accent: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Horse> get _allGameHorses {
    final horsesByRegistry = <String, Horse>{};
    for (final horse in [...widget.marketHorses, ...widget.stableHorses]) {
      horsesByRegistry[horse.registryId.toLowerCase()] = horse;
    }
    return horsesByRegistry.values.toList();
  }

  String get _comparisonSubtitle {
    if (_leftHorse == null || _rightHorse == null) {
      return 'Select two horses to open the comparison view';
    }
    return '${_leftHorse!.displayName} vs ${_rightHorse!.displayName}';
  }

  void _seedSelections() {
    final stableHorses = widget.stableHorses;
    if (stableHorses.isEmpty) {
      return;
    }

    _leftHorse = stableHorses.first;
    _leftStableHorseId = stableHorses.first.id;
    _leftRegistryController.text = stableHorses.first.registryId;

    final secondHorse = stableHorses.length > 1
        ? stableHorses[1]
        : stableHorses.first;
    _rightHorse = secondHorse;
    _rightStableHorseId = secondHorse.id;
    _rightRegistryController.text = secondHorse.registryId;
  }

  void _reconcileSelections() {
    final allGameHorses = _allGameHorses;
    final stableHorses = widget.stableHorses;

    Horse? resolveCurrent(Horse? horse) {
      if (horse == null) {
        return null;
      }
      for (final candidate in allGameHorses) {
        if (candidate.id == horse.id ||
            candidate.registryId == horse.registryId) {
          return candidate;
        }
      }
      return null;
    }

    setState(() {
      _leftHorse =
          resolveCurrent(_leftHorse) ??
          (stableHorses.isNotEmpty ? stableHorses.first : null);
      _rightHorse =
          resolveCurrent(_rightHorse) ??
          (stableHorses.length > 1
              ? stableHorses[1]
              : stableHorses.isNotEmpty
              ? stableHorses.first
              : null);

      _leftStableHorseId =
          stableHorses.any((horse) => horse.id == _leftHorse?.id)
          ? _leftHorse?.id
          : null;
      _rightStableHorseId =
          stableHorses.any((horse) => horse.id == _rightHorse?.id)
          ? _rightHorse?.id
          : null;

      if (_leftHorse != null) {
        _leftRegistryController.text = _leftHorse!.registryId;
      }
      if (_rightHorse != null) {
        _rightRegistryController.text = _rightHorse!.registryId;
      }
    });
  }

  void _selectLeftFromStable(String? horseId) {
    final horse = widget.stableHorses.cast<Horse?>().firstWhere(
      (candidate) => candidate?.id == horseId,
      orElse: () => null,
    );
    if (horse == null) {
      return;
    }
    setState(() {
      _leftHorse = horse;
      _leftStableHorseId = horse.id;
      _leftRegistryController.text = horse.registryId;
      _leftLookupMessage = null;
    });
  }

  void _selectRightFromStable(String? horseId) {
    final horse = widget.stableHorses.cast<Horse?>().firstWhere(
      (candidate) => candidate?.id == horseId,
      orElse: () => null,
    );
    if (horse == null) {
      return;
    }
    setState(() {
      _rightHorse = horse;
      _rightStableHorseId = horse.id;
      _rightRegistryController.text = horse.registryId;
      _rightLookupMessage = null;
    });
  }

  void _lookupLeftHorseByRegistry(String value) {
    final horse = _findHorseByRegistry(value);
    setState(() {
      if (horse == null) {
        _leftLookupMessage = 'No horse found for that registry I.D.';
        return;
      }
      _leftHorse = horse;
      _leftStableHorseId =
          widget.stableHorses.any((item) => item.id == horse.id)
          ? horse.id
          : null;
      _leftRegistryController.text = horse.registryId;
      _leftLookupMessage = '${horse.displayName} loaded for comparison.';
    });
  }

  void _lookupRightHorseByRegistry(String value) {
    final horse = _findHorseByRegistry(value);
    setState(() {
      if (horse == null) {
        _rightLookupMessage = 'No horse found for that registry I.D.';
        return;
      }
      _rightHorse = horse;
      _rightStableHorseId =
          widget.stableHorses.any((item) => item.id == horse.id)
          ? horse.id
          : null;
      _rightRegistryController.text = horse.registryId;
      _rightLookupMessage = '${horse.displayName} loaded for comparison.';
    });
  }

  Horse? _findHorseByRegistry(String rawValue) {
    final query = rawValue.trim().toLowerCase();
    if (query.isEmpty) {
      return null;
    }
    for (final horse in _allGameHorses) {
      if (horse.registryId.toLowerCase() == query) {
        return horse;
      }
    }
    return null;
  }
}

class _CompatibilitySelectorCard extends StatelessWidget {
  const _CompatibilitySelectorCard({
    required this.title,
    required this.accent,
    required this.stableHorses,
    required this.selectedStableHorseId,
    required this.registryController,
    required this.lookupMessage,
    required this.onStableChanged,
    required this.onLookup,
  });

  final String title;
  final Color accent;
  final List<Horse> stableHorses;
  final String? selectedStableHorseId;
  final TextEditingController registryController;
  final String? lookupMessage;
  final ValueChanged<String?> onStableChanged;
  final VoidCallback onLookup;

  @override
  Widget build(BuildContext context) {
    final isError =
        lookupMessage != null &&
        lookupMessage!.toLowerCase().contains('no horse found');
    return Container(
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
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'From your stable',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _HorseDropdownSelectorField(
            label: 'Stable horse',
            accent: accent,
            horses: stableHorses,
            selectedHorseId: selectedStableHorseId,
            onChanged: (horse) => onStableChanged(horse.id),
          ),
          const SizedBox(height: 14),
          Text(
            'Or enter registry I.D.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: registryController,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'PH-1001',
                    filled: true,
                    fillColor: AppTheme.surfaceRaised.withValues(alpha: 0.72),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.outline.withValues(alpha: 0.8),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.outline.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: onLookup, child: const Text('Load')),
            ],
          ),
          if (lookupMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              lookupMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isError ? AppTheme.primary : AppTheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompatibilityHorseCard extends StatelessWidget {
  const _CompatibilityHorseCard({
    required this.title,
    required this.horse,
    required this.accent,
  });

  final String title;
  final Horse horse;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          HorsePreview(horse: horse, compact: true),
          const SizedBox(height: 10),
          Text(
            horse.displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${horse.registryId} · ${horse.breed}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 4),
          Text(
            horse.sex,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...horse.traits.map(
            (trait) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${_compatibilityTraitLabel(trait.type)}: ${trait.option}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _compatibilityTraitLabel(String key) => key.replaceAll('_', ' ');

class _CompatibilitySummary extends StatelessWidget {
  const _CompatibilitySummary({
    required this.leftHorse,
    required this.rightHorse,
  });

  final Horse leftHorse;
  final Horse rightHorse;

  @override
  Widget build(BuildContext context) {
    final sharedTraits = <String>[];
    final differentTraits = <String>[];

    for (final leftTrait in leftHorse.traits) {
      final rightTrait = rightHorse.traitOfOrNull(leftTrait.type);
      if (rightTrait == null) {
        continue;
      }
      final label = _compatibilityTraitLabel(leftTrait.type);
      if (leftTrait.option == rightTrait.option) {
        sharedTraits.add('$label: ${leftTrait.option}');
      } else {
        differentTraits.add(
          '$label: ${leftHorse.displayName} has ${leftTrait.option}, ${rightHorse.displayName} has ${rightTrait.option}',
        );
      }
    }

    final relationshipNotes = <String>[
      leftHorse.breed == rightHorse.breed
          ? 'Same breed: both are ${leftHorse.breed}.'
          : 'Different breeds: ${leftHorse.breed} vs ${rightHorse.breed}.',
      leftHorse.sex == rightHorse.sex
          ? 'Same sex matchup: both are ${leftHorse.sex.toLowerCase()}s.'
          : 'Mixed pairing: ${leftHorse.sex.toLowerCase()} and ${rightHorse.sex.toLowerCase()}.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...relationshipNotes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ComparisonNote(text: note),
          ),
        ),
        _ComparisonGroup(
          title: 'Shared Traits',
          values: sharedTraits.isEmpty
              ? const ['No matching visible traits between these two horses.']
              : sharedTraits.take(4).toList(),
          accent: AppTheme.secondary,
        ),
        const SizedBox(height: 12),
        _ComparisonGroup(
          title: 'Key Differences',
          values: differentTraits.isEmpty
              ? const ['These horses match on every visible recorded trait.']
              : differentTraits.take(4).toList(),
          accent: AppTheme.primary,
        ),
      ],
    );
  }
}

class _ComparisonGroup extends StatelessWidget {
  const _ComparisonGroup({
    required this.title,
    required this.values,
    required this.accent,
  });

  final String title;
  final List<String> values;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...values.map(
            (value) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonNote extends StatelessWidget {
  const _ComparisonNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.mutedInk,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CompatibilityEmptyState extends StatelessWidget {
  const _CompatibilityEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        'Choose two horses from your stable or load them by registry I.D. to compare them side by side.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ForecastCallout extends StatelessWidget {
  const _ForecastCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
