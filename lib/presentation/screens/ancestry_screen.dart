import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/horse.dart';
import '../widgets/horse_preview.dart';
import '../widgets/section_card.dart';

class AncestryScreen extends StatefulWidget {
  const AncestryScreen({
    super.key,
    required this.stableHorses,
    this.embedded = false,
  });

  final List<Horse> stableHorses;
  final bool embedded;

  @override
  State<AncestryScreen> createState() => _AncestryScreenState();
}

class _AncestryScreenState extends State<AncestryScreen> {
  Horse? _selectedHorse;
  late final ScrollController _scrollController;
  double _focusScale = 0.92;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horses = widget.stableHorses;
    final selectedHorse = _resolveSelectedHorse(horses);

    if (horses.isEmpty) {
      final content = CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SectionCard(
                    title: 'Lineage',
                    subtitle: 'No owned horses yet',
                    child: Text(
                      'Your lineage registry is empty right now. Buy horses from the market first, then their family lines will appear here.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      if (widget.embedded) {
        return content;
      }

      return SafeArea(child: content);
    }

    final content = CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Container(
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
                    'Lineage',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a horse from the registry grid, then inspect its mom and dad with a plain-text trait breakdown.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (selectedHorse != null)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SelectedHorseHeaderDelegate(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _SelectedHorseBanner(
                  horse: selectedHorse,
                  scale: _focusScale,
                ),
              ),
              height: 132,
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  title: 'Owned Horses',
                  subtitle: '${horses.length} in your lineage registry',
                  compact: true,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: horses.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.58,
                        ),
                    itemBuilder: (context, index) {
                      final horse = horses[index];
                      final selected = horse.id == selectedHorse?.id;
                      return _AncestryHorseTile(
                        horse: horse,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            _selectedHorse = horse;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (selectedHorse != null)
                  SectionCard(
                    title: '${selectedHorse.displayName} Line',
                    subtitle:
                        '${selectedHorse.registryId} · Generation ${selectedHorse.generation}',
                    compact: true,
                    child:
                        selectedHorse.damSnapshot == null &&
                            selectedHorse.sireSnapshot == null
                        ? Text(
                            'Starter horse - beginning of a bloodline, this horse has no parents.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          )
                        : Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _ParentLineCard(
                                      title: 'Mom',
                                      horse: selectedHorse.damSnapshot,
                                      accent: AppTheme.primary,
                                      onTap: selectedHorse.damSnapshot == null
                                          ? null
                                          : () => _openLineageSheet(
                                              selectedHorse.damSnapshot!,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ParentLineCard(
                                      title: 'Dad',
                                      horse: selectedHorse.sireSnapshot,
                                      accent: AppTheme.secondary,
                                      onTap: selectedHorse.sireSnapshot == null
                                          ? null
                                          : () => _openLineageSheet(
                                              selectedHorse.sireSnapshot!,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              if (selectedHorse.lineageMemory.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.panelGradient,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppTheme.outline),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hidden ancestry',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.secondary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...selectedHorse.lineageMemory.entries.map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            '${_traitLabel(entry.key)}: ${entry.value.entries.map((trait) => '${trait.key} (${_ancestorDepthLabel(trait.value)})').join(', ')}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return SafeArea(child: content);
  }

  Horse? _resolveSelectedHorse(List<Horse> horses) {
    if (horses.isEmpty) {
      return null;
    }
    if (_selectedHorse == null) {
      return horses.first;
    }
    return _selectedHorse;
  }

  void _openLineageSheet(Horse horse) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LineageDrillDownSheet(initialHorse: horse),
    );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final offset = _scrollController.offset.clamp(0.0, 240.0);
    final nextScale = 0.92 + ((offset / 240.0) * 0.22);
    if ((nextScale - _focusScale).abs() < 0.01) {
      return;
    }
    setState(() {
      _focusScale = nextScale;
    });
  }
}

class _SelectedHorseHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SelectedHorseHeaderDelegate({
    required this.child,
    required this.height,
  });

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SelectedHorseHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _SelectedHorseBanner extends StatelessWidget {
  const _SelectedHorseBanner({required this.horse, required this.scale});

  final Horse horse;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.45),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.shadow,
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 100,
              height: 100,
              child: HorsePreview(horse: horse, compact: true),
            ),
          ),
        ),
      ),
    );
  }
}

class _AncestryHorseTile extends StatelessWidget {
  const _AncestryHorseTile({
    required this.horse,
    required this.selected,
    required this.onTap,
  });

  final Horse horse;
  final bool selected;
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
              horse.breedingRarity.softColor.withValues(
                alpha: selected ? 0.96 : 0.82,
              ),
              AppTheme.surfaceRaised,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppTheme.secondary
                : horse.breedingRarity.borderColor,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: AppTheme.shadow,
                    blurRadius: 16,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Transform.translate(
          offset: Offset(0, selected ? -6 : 0),
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
                  color: selected ? AppTheme.secondary : Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentLineCard extends StatelessWidget {
  const _ParentLineCard({
    required this.title,
    required this.horse,
    required this.accent,
    this.onTap,
  });

  final String title;
  final Horse? horse;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: horse == null
            ? Column(
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
                  Text(
                    'No recorded parent.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (onTap != null)
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  HorsePreview(horse: horse!, compact: true),
                  const SizedBox(height: 10),
                  Text(
                    horse!.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${horse!.registryId} · ${horse!.breed}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Tap to inspect this parent\'s line',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ...horse!.traits.map(
                    (trait) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${_traitLabel(trait.type)}: ${trait.option}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LineageDrillDownSheet extends StatefulWidget {
  const _LineageDrillDownSheet({required this.initialHorse});

  final Horse initialHorse;

  @override
  State<_LineageDrillDownSheet> createState() => _LineageDrillDownSheetState();
}

class _LineageDrillDownSheetState extends State<_LineageDrillDownSheet> {
  late List<Horse> _history;

  @override
  void initState() {
    super.initState();
    _history = [widget.initialHorse];
  }

  @override
  Widget build(BuildContext context) {
    final currentHorse = _history.last;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.scaffoldGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_history.length > 1)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _history.removeLast();
                        });
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Path',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedInk,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _historyBreadcrumb,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${currentHorse.displayName} Line',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${currentHorse.registryId} · Generation ${currentHorse.generation}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
              ),
              const SizedBox(height: 18),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.secondary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 112,
                      height: 112,
                      child: HorsePreview(horse: currentHorse, compact: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (currentHorse.damSnapshot == null &&
                  currentHorse.sireSnapshot == null)
                SectionCard(
                  title: 'Lineage',
                  subtitle: 'This branch stops here',
                  compact: true,
                  child: Text(
                    'This horse has no recorded parents in the lineage tree.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              else
                SectionCard(
                  title: 'Parents',
                  subtitle: 'Tap either side to continue up the family line',
                  compact: true,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ParentLineCard(
                              title: 'Mom',
                              horse: currentHorse.damSnapshot,
                              accent: AppTheme.primary,
                              onTap: currentHorse.damSnapshot == null
                                  ? null
                                  : () {
                                      setState(() {
                                        _history = [
                                          ..._history,
                                          currentHorse.damSnapshot!,
                                        ];
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ParentLineCard(
                              title: 'Dad',
                              horse: currentHorse.sireSnapshot,
                              accent: AppTheme.secondary,
                              onTap: currentHorse.sireSnapshot == null
                                  ? null
                                  : () {
                                      setState(() {
                                        _history = [
                                          ..._history,
                                          currentHorse.sireSnapshot!,
                                        ];
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                      if (currentHorse.lineageMemory.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.panelGradient,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.outline),
                          ),
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
                              const SizedBox(height: 8),
                              ...currentHorse.lineageMemory.entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '${_traitLabel(entry.key)}: ${entry.value.entries.map((trait) => '${trait.key} (${_ancestorDepthLabel(trait.value)})').join(', ')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get _historyBreadcrumb {
    if (_history.length == 1) {
      return _history.first.displayName;
    }

    final segments = <String>[_history.first.displayName];
    for (var i = 1; i < _history.length; i++) {
      final previous = _history[i - 1];
      final current = _history[i];
      final relation = previous.damSnapshot?.id == current.id ? 'Mom' : 'Dad';
      segments
        ..add(relation)
        ..add(current.displayName);
    }
    return segments.join(' > ');
  }
}

String _traitLabel(String key) => key.replaceAll('_', ' ');

String _ancestorDepthLabel(int depth) {
  return switch (depth) {
    1 => 'parent',
    2 => 'grandparent',
    3 => 'great-grandparent',
    4 => '2x great-grandparent',
    _ => '${depth - 2}x removed',
  };
}
