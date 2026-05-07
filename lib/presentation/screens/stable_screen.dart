import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/breeding_cooldown.dart';
import '../../domain/models/breeding_preview.dart';
import '../../domain/models/horse.dart';
import '../../domain/models/inbox_item.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/models/pregnancy_record.dart';
import '../../logic/services/breeding_preview_service.dart';
import '../../logic/services/stable_capacity_service.dart';
import 'announcements_screen.dart';
import '../widgets/horse_detail_sheet.dart';
import '../widgets/inbox_sheet.dart';
import '../widgets/horse_preview.dart';
import '../widgets/horse_story_widgets.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/section_card.dart';

enum _StableFilter { all, mares, stallions, foals, newborns, mutants, ready }

enum _StableSort { rarity, name, youngest, price }

class StableScreen extends StatefulWidget {
  const StableScreen({
    super.key,
    required this.stableHorses,
    required this.activePregnancies,
    required this.breedingCooldowns,
    required this.currentTime,
    required this.inventory,
    required this.stableCap,
    required this.stableCapacityRenewsAt,
    required this.prenatalBoostedPregnancyIds,
    required this.carrotBoostedHorseIds,
    required this.inboxItems,
    this.latestBornFoal,
    required this.stableAtCapacity,
    required this.onOpenMarketHorses,
    required this.onOpenMarketItems,
    required this.onRenameHorse,
    required this.onPurgeHorse,
    required this.onBirthFoal,
    required this.onUsePrenatalVitamin,
    required this.onUseCarrot,
    required this.onMarkInboxItemRead,
    required this.onMarkInboxKindRead,
    required this.onUpdateHorseVisibility,
  });

  final List<Horse> stableHorses;
  final List<PregnancyRecord> activePregnancies;
  final List<BreedingCooldown> breedingCooldowns;
  final DateTime currentTime;
  final Map<InventoryItemType, int> inventory;
  final int stableCap;
  final DateTime? stableCapacityRenewsAt;
  final Set<String> prenatalBoostedPregnancyIds;
  final Set<String> carrotBoostedHorseIds;
  final List<InboxItem> inboxItems;
  final Horse? latestBornFoal;
  final bool stableAtCapacity;
  final VoidCallback onOpenMarketHorses;
  final VoidCallback onOpenMarketItems;
  final void Function(Horse horse, String newName) onRenameHorse;
  final ValueChanged<Horse> onPurgeHorse;
  final ValueChanged<PregnancyRecord> onBirthFoal;
  final ValueChanged<PregnancyRecord> onUsePrenatalVitamin;
  final ValueChanged<BreedingCooldown> onUseCarrot;
  final ValueChanged<InboxItem> onMarkInboxItemRead;
  final ValueChanged<InboxItemKind> onMarkInboxKindRead;
  final String? Function(
    Horse horse, {
    bool? isPublicListing,
    bool? isFeaturedProfileHorse,
    bool? isListedForSale,
  })
  onUpdateHorseVisibility;

  @override
  State<StableScreen> createState() => _StableScreenState();
}

class _StableScreenState extends State<StableScreen> {
  _StableFilter _activeFilter = _StableFilter.all;
  _StableSort _activeSort = _StableSort.rarity;
  bool _pendingFoalsExpanded = false;
  bool _inventoryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final stableHorses = widget.stableHorses;
    final filteredHorses = _applySort(_applyFilter(stableHorses));
    final activeCooldowns = widget.breedingCooldowns
        .where((cooldown) => cooldown.isActiveAt(widget.currentTime))
        .toList();
    final healingCount = activeCooldowns
        .where((cooldown) => cooldown.reason == 'Healing')
        .length;
    final recoveringCount = activeCooldowns
        .where((cooldown) => cooldown.reason != 'Healing')
        .length;
    final pregnantCount = widget.activePregnancies
        .map((pregnancy) => pregnancy.damId)
        .toSet()
        .length;
    final readyCount = stableHorses
        .where(
          (horse) =>
              horse.isBreedingReady &&
              !widget.activePregnancies.any(
                (record) => record.damId == horse.id,
              ) &&
              !activeCooldowns.any((cooldown) => cooldown.horseId == horse.id),
        )
        .length;

    if (stableHorses.isEmpty) {
      return _StableTabShell(
        stablePage: _EmptyStablePlaceholder(
          onOpenMarketHorses: widget.onOpenMarketHorses,
        ),
        newsPage: const AnnouncementsScreen(embedded: true),
        inboxItems: widget.inboxItems,
        onMarkInboxItemRead: widget.onMarkInboxItemRead,
        onMarkInboxKindRead: widget.onMarkInboxKindRead,
      );
    }

    final mares = stableHorses.where((horse) => horse.sex == 'Mare').toList();
    final stallions = stableHorses
        .where((horse) => horse.sex == 'Stallion')
        .toList();
    final mostValuableHorse = List<Horse>.from(stableHorses)
      ..sort((a, b) => b.derivedPrice.compareTo(a.derivedPrice));
    final featureHorse = mostValuableHorse.first;
    final dam = mares.isNotEmpty ? mares.first : stableHorses.first;
    final sire = stallions.isNotEmpty
        ? stallions.first
        : stableHorses.length > 1
        ? stableHorses[1]
        : stableHorses.first;
    final preview = const BreedingPreviewService().preview(
      dam: dam,
      sire: sire,
    );

    return _StableTabShell(
      inboxItems: widget.inboxItems,
      onMarkInboxItemRead: widget.onMarkInboxItemRead,
      onMarkInboxKindRead: widget.onMarkInboxKindRead,
      stablePage: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.outline),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.shadow,
                    blurRadius: 28,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pivot Horses',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your stable is now a working roster: sort the bloodlines, jump between mares and stallions faster, and keep foals from getting buried.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HighlightChip(
                        label: '${stableHorses.length} total horses',
                        color: AppTheme.primary,
                      ),
                      _HighlightChip(
                        label:
                            '${stableHorses.where((horse) => horse.isFoal).length} foals',
                        color: AppTheme.secondary,
                      ),
                      _HighlightChip(
                        label:
                            '${stableHorses.where((horse) => horse.isMutant).length} mutants',
                        color: AppTheme.tertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _InventorySection(
              stableHorses: widget.stableHorses,
              currentTime: widget.currentTime,
              inventory: widget.inventory,
              stableCap: widget.stableCap,
              stableCapacityRenewsAt: widget.stableCapacityRenewsAt,
              expanded: _inventoryExpanded,
              onOpenMarketItems: widget.onOpenMarketItems,
              onToggle: () {
                setState(() {
                  _inventoryExpanded = !_inventoryExpanded;
                });
              },
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Stable Tools',
              subtitle: 'Filter and sort your roster fast',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _StableFilter.values
                        .map(
                          (filter) => _RosterFilterChip(
                            label: _filterLabel(filter),
                            selected: filter == _activeFilter,
                            onTap: () {
                              setState(() {
                                _activeFilter = filter;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.panelGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_StableSort>(
                        value: _activeSort,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceRaised,
                        style: Theme.of(context).textTheme.bodyLarge,
                        items: _StableSort.values
                            .map(
                              (sort) => DropdownMenuItem<_StableSort>(
                                value: sort,
                                child: Text(_sortLabel(sort)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _activeSort = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${filteredHorses.length} horses shown in ${_filterLabel(_activeFilter).toLowerCase()} view.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CooldownSummaryPill(
                        label: 'Ready',
                        value: '$readyCount',
                        color: AppTheme.secondary,
                      ),
                      _CooldownSummaryPill(
                        label: 'Pregnant',
                        value: '$pregnantCount',
                        color: AppTheme.secondary,
                      ),
                      _CooldownSummaryPill(
                        label: 'Healing',
                        value: '$healingCount',
                        color: AppTheme.primary,
                      ),
                      _CooldownSummaryPill(
                        label: 'Recovering',
                        value: '$recoveringCount',
                        color: AppTheme.tertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Owned Horses',
              subtitle: '${filteredHorses.length} matching your current view',
              compact: true,
              child: filteredHorses.isEmpty
                  ? Text(
                      'No horses match this filter yet. Try a different roster view.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredHorses.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.58,
                              ),
                          itemBuilder: (context, index) {
                            final horse = filteredHorses[index];
                            return _OwnedHorseTile(
                              horse: horse,
                              onTap: () => _showDetails(context, horse),
                            );
                          },
                        );
                      },
                    ),
            ),
            if (widget.activePregnancies.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'Pending Foals',
                subtitle:
                    '${widget.activePregnancies.length} awaiting birth • ${_pendingFoalsExpanded ? 'Tap to collapse' : 'Tap to expand'}',
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _pendingFoalsExpanded = !_pendingFoalsExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.panelGradient,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _pendingFoalsExpanded
                                    ? 'Hide pending foal cards'
                                    : 'Show pending foal cards',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Icon(
                              _pendingFoalsExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: AppTheme.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_pendingFoalsExpanded) ...[
                      const SizedBox(height: 10),
                      Column(
                        children: widget.activePregnancies
                            .map(
                              (record) => Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      record == widget.activePregnancies.last
                                      ? 0
                                      : 10,
                                ),
                                child: _PendingFoalSummaryCard(
                                  record: record,
                                  currentTime: widget.currentTime,
                                  stableAtCapacity: widget.stableAtCapacity,
                                  onBirthFoal: () => widget.onBirthFoal(record),
                                  onTap: () =>
                                      _showPendingFoalCard(context, record),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (activeCooldowns.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionCard(
                title: 'Cooldowns',
                subtitle: '${activeCooldowns.length} active recovery timer(s)',
                compact: true,
                child: Column(
                  children: activeCooldowns
                      .map(
                        (cooldown) => Padding(
                          padding: EdgeInsets.only(
                            bottom: cooldown == activeCooldowns.last ? 0 : 10,
                          ),
                          child: _CooldownCard(
                            cooldown: cooldown,
                            currentTime: widget.currentTime,
                            carrotAvailable:
                                (widget.inventory[InventoryItemType.carrot] ??
                                    0) >
                                0,
                            carrotUsed: widget.carrotBoostedHorseIds.contains(
                              cooldown.horseId,
                            ),
                            onUseCarrot: () => widget.onUseCarrot(cooldown),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SectionCard(
              title: 'Most Valuable',
              subtitle: featureHorse.displayName,
              compact: true,
              child: _HeroHorsePanel(horse: featureHorse),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Birth Log',
              subtitle: 'Newest foals in your stable',
              compact: true,
              child: _BirthLogPanel(
                horses: stableHorses,
                latestBornFoal: widget.latestBornFoal,
                onOpenHorse: (horse) => _showDetails(context, horse),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Foal Outlook',
              subtitle: '${dam.displayName} × ${sire.displayName}',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap to read the projected foal notes, rarity outlook, and mutation chance for this pairing.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _showFoalOutlook(
                        context,
                        dam: dam,
                        sire: sire,
                        preview: preview,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Open foal outlook'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      newsPage: const AnnouncementsScreen(embedded: true),
    );
  }

  List<Horse> _applyFilter(List<Horse> horses) {
    switch (_activeFilter) {
      case _StableFilter.all:
        return List<Horse>.from(horses);
      case _StableFilter.mares:
        return horses.where((horse) => horse.sex == 'Mare').toList();
      case _StableFilter.stallions:
        return horses.where((horse) => horse.sex == 'Stallion').toList();
      case _StableFilter.foals:
        return horses.where((horse) => horse.isFoal).toList();
      case _StableFilter.newborns:
        return horses.where((horse) => horse.isNewborn).toList();
      case _StableFilter.mutants:
        return horses.where((horse) => horse.isMutant).toList();
      case _StableFilter.ready:
        return horses.where((horse) => horse.isBreedingReady).toList();
    }
  }

  List<Horse> _applySort(List<Horse> horses) {
    final sorted = List<Horse>.from(horses);
    switch (_activeSort) {
      case _StableSort.rarity:
        sorted.sort((a, b) {
          final rarityCompare = b.breedingRarity.rank.compareTo(
            a.breedingRarity.rank,
          );
          if (rarityCompare != 0) return rarityCompare;
          return a.displayName.compareTo(b.displayName);
        });
      case _StableSort.name:
        sorted.sort((a, b) => a.displayName.compareTo(b.displayName));
      case _StableSort.youngest:
        sorted.sort((a, b) => a.ageDays.compareTo(b.ageDays));
      case _StableSort.price:
        sorted.sort((a, b) => b.derivedPrice.compareTo(a.derivedPrice));
    }
    return sorted;
  }

  String _filterLabel(_StableFilter filter) {
    switch (filter) {
      case _StableFilter.all:
        return 'All';
      case _StableFilter.mares:
        return 'Mares';
      case _StableFilter.stallions:
        return 'Stallions';
      case _StableFilter.foals:
        return 'Foals';
      case _StableFilter.newborns:
        return 'Newborns';
      case _StableFilter.mutants:
        return 'Mutants';
      case _StableFilter.ready:
        return 'Ready';
    }
  }

  String _sortLabel(_StableSort sort) {
    switch (sort) {
      case _StableSort.rarity:
        return 'Sort by breeding rarity';
      case _StableSort.name:
        return 'Sort by name';
      case _StableSort.youngest:
        return 'Sort by youngest';
      case _StableSort.price:
        return 'Sort by value';
    }
  }

  void _showDetails(BuildContext context, Horse horse) {
    final activePregnancy = widget.activePregnancies
        .cast<PregnancyRecord?>()
        .firstWhere(
          (pregnancy) => pregnancy?.damId == horse.id,
          orElse: () => null,
        );
    final activeCooldown = widget.breedingCooldowns
        .cast<BreedingCooldown?>()
        .firstWhere(
          (cooldown) =>
              cooldown?.horseId == horse.id &&
              cooldown!.isActiveAt(widget.currentTime),
          orElse: () => null,
        );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => HorseDetailSheet(
        horse: horse,
        currentTime: widget.currentTime,
        activeCooldown: activeCooldown,
        activePregnancy: activePregnancy,
        inventory: widget.inventory,
        prenatalAlreadyUsed: activePregnancy == null
            ? false
            : widget.prenatalBoostedPregnancyIds.contains(activePregnancy.id),
        carrotAlreadyUsed: activeCooldown == null
            ? false
            : widget.carrotBoostedHorseIds.contains(activeCooldown.horseId),
        onUsePrenatalVitamin: widget.onUsePrenatalVitamin,
        onUseCarrot: widget.onUseCarrot,
        onRenameHorse: widget.onRenameHorse,
        onPurgeHorse: widget.onPurgeHorse,
        onUpdateHorseVisibility: widget.onUpdateHorseVisibility,
      ),
    );
  }

  void _showFoalOutlook(
    BuildContext context, {
    required Horse dam,
    required Horse sire,
    required BreedingPreview preview,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.9,
        minChildSize: 0.45,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Foal Outlook',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '${dam.displayName} × ${sire.displayName}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
              ),
              const SizedBox(height: 16),
              SectionCard(
                compact: true,
                title: 'Projected Read',
                subtitle: 'Current pairing notes',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicted foal breed: ${preview.breed}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ...preview.inheritanceNotes.map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          note,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RarityBadge(
                      tier: dam.breedingRarity,
                      label: 'Hidden breeding ${dam.breedingRarity.label}',
                      compact: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hidden breeding value: ${dam.geneticProfile.breedingPotential}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.mutationSummary,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.raritySummary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPendingFoalCard(BuildContext context, PregnancyRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.84,
        maxChildSize: 0.94,
        minChildSize: 0.55,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: _PendingFoalCardSheet(
            record: record,
            currentTime: widget.currentTime,
            stableAtCapacity: widget.stableAtCapacity,
            onBirthFoal: () {
              Navigator.of(context).pop();
              widget.onBirthFoal(record);
            },
          ),
        ),
      ),
    );
  }
}

class _StableTabShell extends StatelessWidget {
  const _StableTabShell({
    required this.stablePage,
    required this.newsPage,
    required this.inboxItems,
    required this.onMarkInboxItemRead,
    required this.onMarkInboxKindRead,
  });

  final Widget stablePage;
  final Widget newsPage;
  final List<InboxItem> inboxItems;
  final ValueChanged<InboxItem> onMarkInboxItemRead;
  final ValueChanged<InboxItemKind> onMarkInboxKindRead;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceRaised.withValues(
                              alpha: 0.72,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.outline),
                          ),
                          child: TabBar(
                            controller: controller,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              gradient: AppTheme.heroGradient,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.secondary),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppTheme.mutedInk,
                            labelStyle: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                            tabs: const [
                              Tab(text: 'Stable'),
                              Tab(text: 'News'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StableHeaderIconButton(
                        icon: Icons.mail_outline_rounded,
                        tooltip: 'Messages',
                        unreadCount: _unreadCount(InboxItemKind.message),
                        onPressed: () => _openInboxSheet(
                          context,
                          kind: InboxItemKind.message,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StableHeaderIconButton(
                        icon: Icons.notifications_none_rounded,
                        tooltip: 'Alerts',
                        unreadCount: _unreadCount(InboxItemKind.notification),
                        onPressed: () => _openInboxSheet(
                          context,
                          kind: InboxItemKind.notification,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: controller,
                    children: [stablePage, newsPage],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _unreadCount(InboxItemKind kind) {
    return inboxItems
        .where((item) => item.kind == kind && item.isUnread)
        .length;
  }

  void _openInboxSheet(BuildContext context, {required InboxItemKind kind}) {
    final items = inboxItems.where((item) => item.kind == kind).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.72,
        child: InboxSheet(
          title: kind == InboxItemKind.message ? 'Messages' : 'Stable Alerts',
          emptyTitle: kind == InboxItemKind.message
              ? 'No messages yet'
              : 'No stable alerts yet',
          emptyBody: kind == InboxItemKind.message
              ? 'Backend messages from Pivot will show here.'
              : 'Timer, birth, healing, and recovery alerts will show here.',
          items: items,
          onMarkRead: onMarkInboxItemRead,
          onMarkAllRead: () => onMarkInboxKindRead(kind),
        ),
      ),
    );
  }
}

class _StableHeaderIconButton extends StatelessWidget {
  const _StableHeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.unreadCount,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.outline),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 21, color: AppTheme.ink),
                if (unreadCount > 0)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStablePlaceholder extends StatelessWidget {
  const _EmptyStablePlaceholder({required this.onOpenMarketHorses});

  final VoidCallback onOpenMarketHorses;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.outline),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.shadow,
                  blurRadius: 28,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pivot Horses',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your stable is empty right now. You can absolutely keep it that way, or pick up a new horse from the market whenever you want.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HighlightChip(
                      label: '0 total horses',
                      color: AppTheme.primary,
                    ),
                    _HighlightChip(label: '0 foals', color: AppTheme.secondary),
                    _HighlightChip(
                      label: '0 mutants',
                      color: AppTheme.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionCard(
            compact: true,
            title: 'Stable Empty',
            subtitle: 'No owned horses right now',
            child: Text(
              'Purging your last horse is allowed. This stable can stay empty until you decide to buy or breed again.',
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onOpenMarketHorses,
            icon: const Icon(Icons.storefront_rounded),
            label: const Text('Open Horse Market'),
          ),
        ],
      ),
    );
  }
}

class _InventorySection extends StatelessWidget {
  const _InventorySection({
    required this.stableHorses,
    required this.currentTime,
    required this.inventory,
    required this.stableCap,
    required this.stableCapacityRenewsAt,
    required this.expanded,
    required this.onOpenMarketItems,
    required this.onToggle,
  });

  final List<Horse> stableHorses;
  final DateTime currentTime;
  final Map<InventoryItemType, int> inventory;
  final int stableCap;
  final DateTime? stableCapacityRenewsAt;
  final bool expanded;
  final VoidCallback onOpenMarketItems;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final prenatalCount = inventory[InventoryItemType.prenatalVitamin] ?? 0;
    final carrotCount = inventory[InventoryItemType.carrot] ?? 0;
    final affectedHorses = _horsesRemovedAtBaseCapacity(stableHorses);
    return SectionCard(
      title: 'Inventory',
      subtitle: expanded
          ? 'Tap to collapse owned items'
          : 'Tap to view owned items',
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.panelGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InventoryPill(
                          icon: Icons.medication_rounded,
                          label: 'Prenatal',
                          value: '$prenatalCount',
                          color: AppTheme.tertiary,
                        ),
                        _InventoryPill(
                          icon: Icons.spa_rounded,
                          label: 'Carrots',
                          value: '$carrotCount',
                          color: AppTheme.primary,
                        ),
                        _InventoryPill(
                          icon: Icons.house_siding_rounded,
                          label: 'Cap',
                          value: '$stableCap',
                          color: AppTheme.secondary,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.secondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            _InventoryDetailRow(
              icon: Icons.medication_rounded,
              title: 'Prenatal vitamins',
              count: prenatalCount,
              description:
                  'Open a pregnant mare detail sheet to cut that pregnancy timer in half.',
              color: AppTheme.tertiary,
            ),
            const SizedBox(height: 10),
            _InventoryDetailRow(
              icon: Icons.spa_rounded,
              title: 'Carrots',
              count: carrotCount,
              description:
                  'Open a recovering stallion detail sheet to cut his cooldown in half.',
              color: AppTheme.primary,
            ),
            const SizedBox(height: 10),
            _InventoryDetailRow(
              icon: Icons.house_siding_rounded,
              title: 'Stable capacity',
              count: stableCap,
              description: _stableCapacityDescription(),
              color: AppTheme.secondary,
            ),
            if (stableCapacityRenewsAt != null) ...[
              const SizedBox(height: 10),
              _StableRenewalStatusRow(
                currentTime: currentTime,
                renewalDate: stableCapacityRenewsAt!,
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenMarketItems,
                icon: const Icon(Icons.storefront_rounded),
                label: Text(
                  stableCapacityRenewsAt == null
                      ? 'View stable expansions'
                      : 'Renew stable expansion',
                ),
              ),
            ),
            if (affectedHorses.isNotEmpty) ...[
              const SizedBox(height: 10),
              _StableCapacityPreviewRow(affectedHorses: affectedHorses),
            ],
          ],
        ],
      ),
    );
  }

  String _stableCapacityDescription() {
    final renewalDate = stableCapacityRenewsAt;
    if (renewalDate == null) {
      return 'Base capacity is permanent. Monthly expansion tiers are renewed from Market.';
    }
    return 'Renews ${renewalDate.month}/${renewalDate.day}/${renewalDate.year}. If it expires, capacity returns to 10 and the lowest-rated overflow horses leave for normal purge coin payouts.';
  }
}

class _StableRenewalStatusRow extends StatelessWidget {
  const _StableRenewalStatusRow({
    required this.currentTime,
    required this.renewalDate,
  });

  final DateTime currentTime;
  final DateTime renewalDate;

  @override
  Widget build(BuildContext context) {
    final days = _daysUntil(currentTime, renewalDate);
    final urgent = days <= 3;
    final color = urgent ? AppTheme.tertiary : AppTheme.secondary;
    final label = days <= 0
        ? 'Renewal due today'
        : urgent
        ? 'Renew soon'
        : 'Renews in $days day${days == 1 ? '' : 's'}';

    return _InventoryNoticeRow(
      icon: urgent ? Icons.warning_amber_rounded : Icons.event_repeat_rounded,
      title: label,
      description:
          '${renewalDate.month}/${renewalDate.day}/${renewalDate.year}. Renew before expiration to keep expanded capacity.',
      color: color,
    );
  }
}

class _StableCapacityPreviewRow extends StatelessWidget {
  const _StableCapacityPreviewRow({required this.affectedHorses});

  final List<Horse> affectedHorses;

  @override
  Widget build(BuildContext context) {
    final payout = affectedHorses.fold<int>(
      0,
      (total, horse) => total + horse.purgePayout,
    );
    final previewNames = affectedHorses
        .take(3)
        .map((horse) => horse.displayName)
        .join(', ');
    final moreCount = affectedHorses.length - 3;

    return _InventoryNoticeRow(
      icon: Icons.manage_search_rounded,
      title: 'Expiration preview',
      description:
          '$previewNames${moreCount > 0 ? ' + $moreCount more' : ''} would leave first for $payout purge coins. Related breeding would be cleared.',
      color: AppTheme.primary,
    );
  }
}

class _InventoryNoticeRow extends StatelessWidget {
  const _InventoryNoticeRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int _daysUntil(DateTime currentTime, DateTime targetDate) {
  final currentDay = DateTime(
    currentTime.year,
    currentTime.month,
    currentTime.day,
  );
  final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
  return targetDay.difference(currentDay).inDays;
}

List<Horse> _horsesRemovedAtBaseCapacity(List<Horse> stableHorses) {
  return horsesRemovedForExpiredCapacity(stableHorses);
}

class _InventoryDetailRow extends StatelessWidget {
  const _InventoryDetailRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final int count;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title • $count',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryPill extends StatelessWidget {
  const _InventoryPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingFoalSummaryCard extends StatelessWidget {
  const _PendingFoalSummaryCard({
    required this.record,
    required this.currentTime,
    required this.stableAtCapacity,
    required this.onBirthFoal,
    required this.onTap,
  });

  final PregnancyRecord record;
  final DateTime currentTime;
  final bool stableAtCapacity;
  final VoidCallback onBirthFoal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final birthReady = !record.dueAt.isAfter(currentTime);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
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
              spacing: 8,
              runSpacing: 8,
              children: [
                _FoalPill(
                  label:
                      'Birth in ${record.birthCountdownLabelAt(currentTime)}',
                  color: AppTheme.secondary,
                ),
                if (record.isMutant)
                  const _FoalPill(
                    label: 'Mutant outcome',
                    color: AppTheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Mom: ${record.damName}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Sire: ${record.sireName}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  color: AppTheme.secondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap to open the full foal card',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (birthReady) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: stableAtCapacity ? null : onBirthFoal,
                  icon: const Icon(Icons.celebration_rounded),
                  label: Text(
                    stableAtCapacity
                        ? 'Birth foal • stable full'
                        : 'Birth foal',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingFoalCardSheet extends StatelessWidget {
  const _PendingFoalCardSheet({
    required this.record,
    required this.currentTime,
    required this.stableAtCapacity,
    required this.onBirthFoal,
  });

  final PregnancyRecord record;
  final DateTime currentTime;
  final bool stableAtCapacity;
  final VoidCallback onBirthFoal;

  @override
  Widget build(BuildContext context) {
    final damSnapshot = record.foal.damSnapshot;
    final sireSnapshot = record.foal.sireSnapshot;
    final birthReady = !record.dueAt.isAfter(currentTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${record.breed} • Pending Foal • ${record.unbornFoalName}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          '${record.registryId} · awaiting birth',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FoalPill(
                    label:
                        'Birth in ${record.birthCountdownLabelAt(currentTime)}',
                    color: AppTheme.secondary,
                  ),
                  if (record.isMutant)
                    const _FoalPill(
                      label: 'Mutant outcome',
                      color: AppTheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3A153E),
                      Color(0xFF1D1B38),
                      Color(0xFF102636),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: -18,
                      left: -12,
                      child: const _FoalPreviewGlow(
                        size: 168,
                        colors: [Color(0x5532F6FF), Color(0x0032F6FF)],
                      ),
                    ),
                    Positioned(
                      right: -24,
                      bottom: -30,
                      child: const _FoalPreviewGlow(
                        size: 194,
                        colors: [Color(0x55FF5CCF), Color(0x00FF5CCF)],
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0.0, 0.62),
                            radius: 0.9,
                            colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 26,
                      top: 28,
                      child: const _FoalPreviewSparkle(size: 10),
                    ),
                    Positioned(
                      right: 34,
                      top: 44,
                      child: const _FoalPreviewSparkle(size: 7),
                    ),
                    Positioned(
                      left: 58,
                      bottom: 64,
                      child: const _FoalPreviewSparkle(size: 6),
                    ),
                    Positioned(
                      right: 72,
                      bottom: 82,
                      child: const _FoalPreviewSparkle(size: 8),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x11000000),
                              Color(0x00000000),
                              Color(0x33000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 22,
                      right: 22,
                      bottom: 18,
                      child: const _FoalPreviewPedestal(),
                    ),
                    ModelViewer(
                      src:
                          'assets/horses/reference/variants/pph_foil_unborn.glb',
                      poster:
                          'assets/horses/reference/previews/pph_foil_unborn.png',
                      alt: 'Pending foal model',
                      backgroundColor: Colors.transparent,
                      autoRotate: true,
                      cameraControls: false,
                      disablePan: true,
                      shadowIntensity: 0.8,
                      shadowSoftness: 0.9,
                      interactionPrompt: InteractionPrompt.none,
                      cameraOrbit: '-90deg 75deg 5.2m',
                      minCameraOrbit: 'auto auto 4.8m',
                      maxCameraOrbit: 'auto auto 5.6m',
                      cameraTarget: '-0.2m 0.9m 0m',
                      fieldOfView: '26deg',
                      exposure: 1.1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '${record.unbornFoalName} was created by ${record.damName} and ${record.sireName}. The foal already has locked genetics before birth.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (birthReady) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: stableAtCapacity ? null : onBirthFoal,
              icon: const Icon(Icons.celebration_rounded),
              label: Text(
                stableAtCapacity ? 'Birth foal • stable full' : 'Birth foal',
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FoalParentTag(
                label: 'Mom ${record.damName}',
                color: AppTheme.tertiary,
                onTap: damSnapshot == null
                    ? null
                    : () => _showParentPreview(context, damSnapshot),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FoalParentTag(
                label: 'Sire ${record.sireName}',
                color: AppTheme.secondary,
                onTap: sireSnapshot == null
                    ? null
                    : () => _showParentPreview(context, sireSnapshot),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Current read: ${record.foal.traitOption('body_type', fallback: 'Athletic').toLowerCase()} frame, ${record.foal.traitOption('mane_style', fallback: 'Natural').toLowerCase()} mane, ${record.foal.traitOption('eye_color', fallback: 'Brown').toLowerCase()} eyes.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondary),
        ),
      ],
    );
  }

  void _showParentPreview(BuildContext context, Horse parent) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) =>
          HorseDetailSheet(horse: parent, currentTime: currentTime),
    );
  }
}

class _CooldownCard extends StatelessWidget {
  const _CooldownCard({
    required this.cooldown,
    required this.currentTime,
    required this.carrotAvailable,
    required this.carrotUsed,
    required this.onUseCarrot,
  });

  final BreedingCooldown cooldown;
  final DateTime currentTime;
  final bool carrotAvailable;
  final bool carrotUsed;
  final VoidCallback onUseCarrot;

  @override
  Widget build(BuildContext context) {
    final remaining = cooldown.endsAt.difference(currentTime);
    final remainingLabel = remaining.isNegative
        ? 'Ready now'
        : '${remaining.inHours}h ${(remaining.inMinutes % 60).toString().padLeft(2, '0')}m';
    final canUseCarrot =
        carrotAvailable && !carrotUsed && cooldown.reason != 'Healing';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cooldown.horseName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cooldown.reason} • $remainingLabel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(
            onPressed: canUseCarrot ? onUseCarrot : null,
            child: Text(carrotUsed ? 'Boosted' : 'Carrot'),
          ),
        ],
      ),
    );
  }
}

class _CooldownSummaryPill extends StatelessWidget {
  const _CooldownSummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _BirthLogPanel extends StatelessWidget {
  const _BirthLogPanel({
    required this.horses,
    required this.latestBornFoal,
    required this.onOpenHorse,
  });

  final List<Horse> horses;
  final Horse? latestBornFoal;
  final ValueChanged<Horse> onOpenHorse;

  @override
  Widget build(BuildContext context) {
    final recentFoals = horses.where((horse) => horse.isFoal).toList()
      ..sort((a, b) {
        final ageCompare = a.ageDays.compareTo(b.ageDays);
        if (ageCompare != 0) return ageCompare;
        return b.derivedPrice.compareTo(a.derivedPrice);
      });
    final featuredFoals = recentFoals.take(3).toList();

    if (featuredFoals.isEmpty) {
      return Text(
        'No foals have landed yet. Once your first birth happens, this panel will track the freshest young bloodlines.',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: featuredFoals.map((horse) {
        final isLatest = latestBornFoal?.id == horse.id;
        return Padding(
          padding: EdgeInsets.only(
            bottom: horse == featuredFoals.last ? 0 : 10,
          ),
          child: InkWell(
            onTap: () => onOpenHorse(horse),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.panelGradient,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: HorsePreview(horse: horse, compact: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          horse.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          horse.cardSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.mutedInk),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (isLatest)
                              const _FoalPill(
                                label: 'Newest arrival',
                                color: AppTheme.secondary,
                              ),
                            _FoalPill(
                              label: horse.valueClassLabel,
                              color: AppTheme.tertiary,
                            ),
                            _FoalPill(
                              label: 'Breeding ${horse.breedingRarity.label}',
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          horse.hiddenBreedingInsight,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.mutedInk),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FoalPill extends StatelessWidget {
  const _FoalPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FoalPreviewGlow extends StatelessWidget {
  const _FoalPreviewGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _FoalPreviewSparkle extends StatelessWidget {
  const _FoalPreviewSparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _FoalPreviewPedestal extends StatelessWidget {
  const _FoalPreviewPedestal();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x55C3D8FF), Color(0x223C4E74), Color(0x00414B62)],
          ),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoalParentTag extends StatelessWidget {
  const _FoalParentTag({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.58)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.visibility_outlined, color: color, size: 16),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

class _HeroHorsePanel extends StatelessWidget {
  const _HeroHorsePanel({required this.horse});

  final Horse horse;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppTheme.heroGradient,
        border: Border.all(color: AppTheme.outline),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.shadow,
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: horse.breedingRarity.softColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: horse.breedingRarity.borderColor),
                  ),
                  child: Text(
                    horse.starterTier.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  horse.sex,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            HorseStoryWrap(horse: horse, maxBadges: 4, compact: true),
            const SizedBox(height: 10),
            HorsePreview(horse: horse, forceStatic: true),
          ],
        ),
      ),
    );
  }
}

class _OwnedHorseTile extends StatelessWidget {
  const _OwnedHorseTile({required this.horse, required this.onTap});

  final Horse horse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              horse.breedingRarity.softColor.withValues(alpha: 0.82),
              AppTheme.surfaceRaised,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: horse.breedingRarity.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: HorsePreview(horse: horse, compact: true)),
            const SizedBox(height: 4),
            Text(
              horse.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RosterFilterChip extends StatelessWidget {
  const _RosterFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.secondary.withValues(alpha: 0.18)
              : AppTheme.surfaceRaised.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.secondary.withValues(alpha: 0.6)
                : AppTheme.outline,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
