import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/community_listing.dart';
import '../../domain/models/community_profile.dart';
import '../../domain/models/horse.dart';
import '../widgets/horse_preview.dart';
import '../widgets/horse_story_widgets.dart';
import '../widgets/price_badge.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/section_card.dart';

enum _RegistryLocationFilter { all, stable, market }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.stableHorses,
    required this.marketHorses,
    required this.currentUserProfile,
    required this.currentUserPublicHorses,
    required this.communityProfiles,
    required this.communityListings,
    required this.currentTime,
    required this.likedHorseIds,
    required this.followedProfileIds,
    required this.onToggleHorseLike,
    required this.onToggleProfileFollow,
    required this.onPurchaseCommunityHorse,
  });

  final List<Horse> stableHorses;
  final List<Horse> marketHorses;
  final CommunityProfile currentUserProfile;
  final List<Horse> currentUserPublicHorses;
  final List<CommunityProfile> communityProfiles;
  final List<CommunityListing> communityListings;
  final DateTime currentTime;
  final Set<String> likedHorseIds;
  final Set<String> followedProfileIds;
  final ValueChanged<Horse> onToggleHorseLike;
  final ValueChanged<CommunityProfile> onToggleProfileFollow;
  final ValueChanged<CommunityListing> onPurchaseCommunityHorse;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PageController _weeklyHighlightsController = PageController(
    viewportFraction: 0.78,
  );

  String _weeklyHighlightsSignature = '';
  bool _showRareOnly = false;
  bool _showMutantOnly = false;
  bool _showForSaleOnly = false;
  int _weeklyHighlightIndex = 0;
  Timer? _weeklyHighlightTimer;

  @override
  void dispose() {
    _weeklyHighlightTimer?.cancel();
    _weeklyHighlightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicStableHorses = widget.stableHorses
        .where(
          (horse) =>
              horse.isPublicListing ||
              horse.isFeaturedProfileHorse ||
              horse.isListedForSale,
        )
        .toList();
    final allHorses = <String, Horse>{
      for (final horse in publicStableHorses) horse.id: horse,
      for (final horse in widget.marketHorses) horse.id: horse,
      for (final listing in widget.communityListings)
        listing.horse.id: listing.horse,
    }.values.toList();
    final filteredDiscoveryHorses = allHorses
        .where((horse) => _matchesHorseFilters(horse))
        .toList();
    final weeklyHighlights = _buildWeeklyHighlights(filteredDiscoveryHorses);
    _syncWeeklyHighlightsCarousel(weeklyHighlights);
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
                        Tab(text: 'Hub'),
                        Tab(text: 'Profiles'),
                        Tab(text: 'Registry'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: controller,
                    children: [
                      _ExploreWorkspace(
                        likedHorseIds: widget.likedHorseIds,
                        onToggleHorseLike: widget.onToggleHorseLike,
                        onPurchaseCommunityHorse:
                            widget.onPurchaseCommunityHorse,
                        communityListings: widget.communityListings
                            .where(
                              (listing) => _matchesHorseFilters(listing.horse),
                            )
                            .toList(),
                        likedHorses: allHorses
                            .where(
                              (horse) =>
                                  widget.likedHorseIds.contains(horse.id),
                            )
                            .toList(),
                        weeklyHighlights: weeklyHighlights,
                        weeklyHighlightsController: _weeklyHighlightsController,
                        weeklyHighlightIndex: _weeklyHighlightIndex,
                        onWeeklyHighlightChanged: (index) {
                          setState(() {
                            _weeklyHighlightIndex = index;
                          });
                          _restartWeeklyHighlightTimer(weeklyHighlights.length);
                        },
                        showRareOnly: _showRareOnly,
                        showMutantOnly: _showMutantOnly,
                        showForSaleOnly: _showForSaleOnly,
                        onToggleRareOnly: () {
                          setState(() {
                            _showRareOnly = !_showRareOnly;
                          });
                        },
                        onToggleMutantOnly: () {
                          setState(() {
                            _showMutantOnly = !_showMutantOnly;
                          });
                        },
                        onToggleForSaleOnly: () {
                          setState(() {
                            _showForSaleOnly = !_showForSaleOnly;
                          });
                        },
                      ),
                      _FriendSearchPanel(
                        currentUserProfile: widget.currentUserProfile,
                        currentUserPublicHorses: widget.currentUserPublicHorses,
                        profiles: widget.communityProfiles,
                        communityListings: widget.communityListings,
                        followedProfileIds: widget.followedProfileIds,
                        onToggleProfileFollow: widget.onToggleProfileFollow,
                        onToggleHorseLike: widget.onToggleHorseLike,
                        likedHorseIds: widget.likedHorseIds,
                      ),
                      _HorseRegistrySearchPanel(
                        horses: filteredDiscoveryHorses,
                        marketHorses: widget.marketHorses,
                        communityListings: widget.communityListings,
                        likedHorseIds: widget.likedHorseIds,
                        onToggleHorseLike: widget.onToggleHorseLike,
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

  bool _matchesHorseFilters(Horse horse, {bool forceForSale = false}) {
    if ((_showForSaleOnly || forceForSale) &&
        !widget.communityListings.any(
          (listing) => listing.horse.id == horse.id,
        )) {
      return false;
    }
    if (_showRareOnly && horse.breedingRarity.rank < 2) {
      return false;
    }
    if (_showMutantOnly && !horse.isMutant) {
      return false;
    }
    return true;
  }

  List<Horse> _buildWeeklyHighlights(List<Horse> horses) {
    if (horses.isEmpty) {
      return const [];
    }

    final monday = widget.currentTime.subtract(
      Duration(days: widget.currentTime.weekday - 1),
    );
    final seed = (monday.year * 10000) + (monday.month * 100) + monday.day;
    final shuffled = List<Horse>.of(horses)..shuffle(Random(seed));
    return shuffled.take(min(5, shuffled.length)).toList();
  }

  void _syncWeeklyHighlightsCarousel(List<Horse> weeklyHighlights) {
    final signature = weeklyHighlights.map((horse) => horse.id).join('|');
    if (_weeklyHighlightsSignature == signature) {
      return;
    }

    _weeklyHighlightsSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (weeklyHighlights.isEmpty) {
        _weeklyHighlightTimer?.cancel();
        if (_weeklyHighlightIndex != 0) {
          setState(() {
            _weeklyHighlightIndex = 0;
          });
        }
        return;
      }

      final nextIndex = _weeklyHighlightIndex.clamp(
        0,
        weeklyHighlights.length - 1,
      );
      if (_weeklyHighlightsController.hasClients) {
        _weeklyHighlightsController.jumpToPage(nextIndex);
      }
      if (_weeklyHighlightIndex != nextIndex) {
        setState(() {
          _weeklyHighlightIndex = nextIndex;
        });
      }
      _restartWeeklyHighlightTimer(weeklyHighlights.length);
    });
  }

  void _restartWeeklyHighlightTimer(int itemCount) {
    _weeklyHighlightTimer?.cancel();
    if (itemCount <= 1) {
      return;
    }

    _weeklyHighlightTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || !_weeklyHighlightsController.hasClients) {
        return;
      }
      final nextIndex = (_weeklyHighlightIndex + 1) % itemCount;
      _weeklyHighlightsController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }
}

class _ExploreSearchField extends StatelessWidget {
  const _ExploreSearchField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppTheme.secondary),
        filled: true,
        fillColor: AppTheme.surfaceRaised.withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppTheme.outline.withValues(alpha: 0.8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppTheme.outline.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppTheme.secondary),
        ),
      ),
    );
  }
}

class _ExploreWorkspace extends StatelessWidget {
  const _ExploreWorkspace({
    required this.likedHorseIds,
    required this.onToggleHorseLike,
    required this.onPurchaseCommunityHorse,
    required this.communityListings,
    required this.likedHorses,
    required this.weeklyHighlights,
    required this.weeklyHighlightsController,
    required this.weeklyHighlightIndex,
    required this.onWeeklyHighlightChanged,
    required this.showRareOnly,
    required this.showMutantOnly,
    required this.showForSaleOnly,
    required this.onToggleRareOnly,
    required this.onToggleMutantOnly,
    required this.onToggleForSaleOnly,
  });

  final Set<String> likedHorseIds;
  final ValueChanged<Horse> onToggleHorseLike;
  final ValueChanged<CommunityListing> onPurchaseCommunityHorse;
  final List<CommunityListing> communityListings;
  final List<Horse> likedHorses;
  final List<Horse> weeklyHighlights;
  final PageController weeklyHighlightsController;
  final int weeklyHighlightIndex;
  final ValueChanged<int> onWeeklyHighlightChanged;
  final bool showRareOnly;
  final bool showMutantOnly;
  final bool showForSaleOnly;
  final VoidCallback onToggleRareOnly;
  final VoidCallback onToggleMutantOnly;
  final VoidCallback onToggleForSaleOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Community Hub', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'Browse player sale listings, follow public profiles, and keep track of horses you want to come back to.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.mutedInk,
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Community Highlights',
            subtitle:
                'Public horses and sale listings rotating through this week',
            compact: true,
            child: SizedBox(
              height: 268,
              child: weeklyHighlights.isEmpty
                  ? const _EmptyState(
                      message:
                          'No weekly highlights match the current filter combo.',
                    )
                  : PageView.builder(
                      controller: weeklyHighlightsController,
                      padEnds: weeklyHighlights.length > 1,
                      itemCount: weeklyHighlights.length,
                      onPageChanged: onWeeklyHighlightChanged,
                      itemBuilder: (context, index) {
                        final horse = weeklyHighlights[index];
                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.fromLTRB(
                            6,
                            index == weeklyHighlightIndex ? 0 : 10,
                            6,
                            index == weeklyHighlightIndex ? 0 : 10,
                          ),
                          child: AnimatedScale(
                            scale: index == weeklyHighlightIndex ? 1 : 0.94,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            child: _WeeklyHorseCard(
                              horse: horse,
                              isLiked: likedHorseIds.contains(horse.id),
                              onToggleLike: () => onToggleHorseLike(horse),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Community Filters',
            subtitle:
                'Tune the hub before you browse listings and public horses',
            compact: true,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FilterChip(
                  label: 'Rare',
                  selected: showRareOnly,
                  onTap: onToggleRareOnly,
                ),
                _FilterChip(
                  label: 'Mutant',
                  selected: showMutantOnly,
                  onTap: onToggleMutantOnly,
                ),
                _FilterChip(
                  label: 'For Sale Only',
                  selected: showForSaleOnly,
                  onTap: onToggleForSaleOnly,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Watchlist',
            subtitle:
                '${likedHorses.length} saved horse${likedHorses.length == 1 ? '' : 's'} on your shelf',
            compact: true,
            child: likedHorses.isEmpty
                ? const _EmptyState(
                    message:
                        'Tap the thumbs-up on any horse in Explore to save it here.',
                  )
                : SizedBox(
                    height: 252,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: likedHorses.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final horse = likedHorses[index];
                        return SizedBox(
                          width: 206,
                          child: _WeeklyHorseCard(
                            horse: horse,
                            isLiked: true,
                            onToggleLike: () => onToggleHorseLike(horse),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Live Player Listings',
            subtitle:
                '${communityListings.length} formula-priced horse${communityListings.length == 1 ? '' : 's'} available right now',
            compact: true,
            child: communityListings.isEmpty
                ? const _EmptyState(
                    message:
                        'There are no community listings that match the current filters.',
                  )
                : Column(
                    children: communityListings
                        .take(5)
                        .map(
                          (listing) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ForSaleHorseCard(
                              listing: listing,
                              isLiked: likedHorseIds.contains(listing.horse.id),
                              onToggleLike: () =>
                                  onToggleHorseLike(listing.horse),
                              onPurchase: () =>
                                  onPurchaseCommunityHorse(listing),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.secondary.withValues(alpha: 0.18)
              : AppTheme.surfaceRaised.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.secondary : AppTheme.outline,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.profile,
    required this.publicHorseCount,
    required this.isFollowed,
    required this.isCurrentUser,
    required this.onTap,
    required this.onToggleFollow,
  });

  final CommunityProfile profile;
  final int publicHorseCount;
  final bool isFollowed;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.panelGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: profile.accent.withValues(alpha: 0.18),
              child: Text(
                profile.initials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: profile.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.stableName} · Loves ${profile.favoriteBreed}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: profile.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$publicHorseCount public',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: isCurrentUser ? null : onToggleFollow,
                  style: FilledButton.styleFrom(
                    backgroundColor: isCurrentUser
                        ? AppTheme.surfaceRaised.withValues(alpha: 0.56)
                        : profile.accent.withValues(alpha: 0.18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    isCurrentUser
                        ? 'You'
                        : isFollowed
                        ? 'Following'
                        : 'Follow',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultHorseCard extends StatelessWidget {
  const _SearchResultHorseCard({
    required this.horse,
    required this.locationLabel,
    required this.isLiked,
    required this.onToggleLike,
  });

  final Horse horse;
  final String locationLabel;
  final bool isLiked;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: HorsePreview(
              horse: horse,
              compact: true,
              naturalStage: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  horse.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${horse.registryId} · $locationLabel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                HorseStoryWrap(
                  horse: horse,
                  maxBadges: 3,
                  compact: true,
                  includeBreederProfile: false,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    RarityBadge(
                      tier: horse.breedingRarity,
                      label: horse.breedingRarity.label,
                      compact: true,
                    ),
                    if (horse.isMutant) const _MiniTag(label: 'Mutant'),
                    if (locationLabel == 'Community sale' ||
                        locationLabel == 'Starter market')
                      PriceBadge(
                        price: horse.derivedPrice,
                        tier: horse.breedingRarity,
                      ),
                  ],
                ),
              ],
            ),
          ),
          _LikeButton(isLiked: isLiked, onPressed: onToggleLike),
        ],
      ),
    );
  }
}

class _WeeklyHorseCard extends StatelessWidget {
  const _WeeklyHorseCard({
    required this.horse,
    required this.isLiked,
    required this.onToggleLike,
  });

  final Horse horse;
  final bool isLiked;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 128,
            child: HorsePreview(
              horse: horse,
              compact: true,
              naturalStage: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  horse.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _LikeButton(isLiked: isLiked, onPressed: onToggleLike),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            horse.registryId,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.secondary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ForSaleHorseCard extends StatelessWidget {
  const _ForSaleHorseCard({
    required this.listing,
    required this.isLiked,
    required this.onToggleLike,
    required this.onPurchase,
  });

  final CommunityListing listing;
  final bool isLiked;
  final VoidCallback onToggleLike;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final horse = listing.horse;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: HorsePreview(
              horse: horse,
              compact: true,
              naturalStage: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  horse.cardTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${listing.sellerHandle} · ${listing.sellerStableName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                HorseStoryWrap(horse: horse, maxBadges: 3, compact: true),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PriceBadge(
                      price: horse.derivedPrice,
                      tier: horse.breedingRarity,
                    ),
                    RarityBadge(
                      tier: horse.visualRarity,
                      label: horse.visualRarity.label,
                      compact: true,
                    ),
                    if (horse.isMutant) const _MiniTag(label: 'Mutant'),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: onPurchase,
                  child: Text('Buy for ${horse.playerSalePrice}'),
                ),
              ],
            ),
          ),
          _LikeButton(isLiked: isLiked, onPressed: onToggleLike),
        ],
      ),
    );
  }
}

class _FriendProfileSheet extends StatelessWidget {
  const _FriendProfileSheet({
    required this.profile,
    required this.publicHorses,
    required this.isCurrentUser,
    required this.isFollowed,
    required this.onToggleFollow,
    required this.onToggleHorseLike,
    required this.likedHorseIds,
  });

  final CommunityProfile profile;
  final List<Horse> publicHorses;
  final bool isCurrentUser;
  final bool isFollowed;
  final VoidCallback onToggleFollow;
  final ValueChanged<Horse> onToggleHorseLike;
  final Set<String> likedHorseIds;

  @override
  Widget build(BuildContext context) {
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: profile.accent.withValues(alpha: 0.2),
                    child: Text(
                      profile.initials,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: profile.accent,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.handle,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCurrentUser)
                    FilledButton.tonal(
                      onPressed: onToggleFollow,
                      style: FilledButton.styleFrom(
                        backgroundColor: profile.accent.withValues(alpha: 0.18),
                      ),
                      child: Text(isFollowed ? 'Following' : 'Follow'),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ProfileStat(label: 'Stable', value: profile.stableName),
                  _ProfileStat(
                    label: 'Breed Focus',
                    value: profile.favoriteBreed,
                  ),
                  _ProfileStat(
                    label: 'Followers',
                    value: '${profile.followerCount}',
                  ),
                  _ProfileStat(
                    label: 'Weekly Posts',
                    value: '${profile.weeklyPosts}',
                  ),
                  _ProfileStat(label: 'Joined', value: profile.joinedLabel),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                profile.bio,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
              ),
              const SizedBox(height: 18),
              Text(
                'Public Stable',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (publicHorses.isEmpty)
                const _EmptyState(
                  message: 'This profile does not have any public horses yet.',
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: publicHorses.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final horse = publicHorses[index];
                      return SizedBox(
                        width: 180,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.panelGradient,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: HorsePreview(
                                  horse: horse,
                                  compact: true,
                                  naturalStage: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      horse.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                  ),
                                  _LikeButton(
                                    isLiked: likedHorseIds.contains(horse.id),
                                    onPressed: () => onToggleHorseLike(horse),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                horse.registryId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.tertiary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.isLiked, required this.onPressed});

  final bool isLiked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: isLiked
            ? AppTheme.secondary.withValues(alpha: 0.22)
            : AppTheme.surfaceRaised.withValues(alpha: 0.72),
      ),
      icon: Icon(
        isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_off_alt_rounded,
        color: isLiked ? AppTheme.secondary : Colors.white,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _FriendSearchPanel extends StatefulWidget {
  const _FriendSearchPanel({
    required this.currentUserProfile,
    required this.currentUserPublicHorses,
    required this.profiles,
    required this.communityListings,
    required this.followedProfileIds,
    required this.onToggleProfileFollow,
    required this.onToggleHorseLike,
    required this.likedHorseIds,
  });

  final CommunityProfile currentUserProfile;
  final List<Horse> currentUserPublicHorses;
  final List<CommunityProfile> profiles;
  final List<CommunityListing> communityListings;
  final Set<String> followedProfileIds;
  final ValueChanged<CommunityProfile> onToggleProfileFollow;
  final ValueChanged<Horse> onToggleHorseLike;
  final Set<String> likedHorseIds;

  @override
  State<_FriendSearchPanel> createState() => _FriendSearchPanelState();
}

class _FriendSearchPanelState extends State<_FriendSearchPanel> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String? _favoriteBreed;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = [widget.currentUserProfile, ...widget.profiles];
    final breedOptions =
        profiles.map((profile) => profile.favoriteBreed).toSet().toList()
          ..sort();
    final matches = profiles.where((profile) {
      if (_favoriteBreed != null && profile.favoriteBreed != _favoriteBreed) {
        return false;
      }
      if (_query.isEmpty) {
        return true;
      }
      final query = _query.toLowerCase();
      return profile.name.toLowerCase().contains(query) ||
          profile.handle.toLowerCase().contains(query) ||
          profile.favoriteBreed.toLowerCase().contains(query) ||
          profile.stableName.toLowerCase().contains(query) ||
          profile.bio.toLowerCase().contains(query);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Public Profiles',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Search public player profiles by owner name, handle, breed focus, or stable name.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Find Profiles',
            subtitle: 'Tap a public profile to open its stable sheet',
            compact: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExploreSearchField(
                  controller: _controller,
                  hintText:
                      'Search public profiles by name, handle, breed, or stable',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (value) {
                    setState(() {
                      _query = value.trim();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SearchScopeChip(
                      label: 'All breeds',
                      selected: _favoriteBreed == null,
                      onTap: () {
                        setState(() {
                          _favoriteBreed = null;
                        });
                      },
                    ),
                    ...breedOptions.map(
                      (breed) => _SearchScopeChip(
                        label: breed,
                        selected: _favoriteBreed == breed,
                        onTap: () {
                          setState(() {
                            _favoriteBreed = breed;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (matches.isEmpty)
            const _EmptyState(
              message: 'No public profiles match that search right now.',
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.34),
                  ),
                ),
                child: Text(
                  'Profiles marked public can be followed, opened, and used as the source for formula-priced horse listings.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ...matches.map(
              (profile) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FriendCard(
                  profile: profile,
                  publicHorseCount: profile.id == widget.currentUserProfile.id
                      ? widget.currentUserPublicHorses.length
                      : widget.communityListings
                            .where(
                              (listing) =>
                                  listing.sellerProfileId == profile.id,
                            )
                            .length,
                  isFollowed: widget.followedProfileIds.contains(profile.id),
                  isCurrentUser: profile.id == widget.currentUserProfile.id,
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      final publicHorses =
                          profile.id == widget.currentUserProfile.id
                          ? widget.currentUserPublicHorses
                          : widget.communityListings
                                .where(
                                  (listing) =>
                                      listing.sellerProfileId == profile.id,
                                )
                                .map((listing) => listing.horse)
                                .toList();
                      return _FriendProfileSheet(
                        profile: profile,
                        publicHorses: publicHorses,
                        isCurrentUser:
                            profile.id == widget.currentUserProfile.id,
                        isFollowed: widget.followedProfileIds.contains(
                          profile.id,
                        ),
                        onToggleFollow: () =>
                            widget.onToggleProfileFollow(profile),
                        onToggleHorseLike: widget.onToggleHorseLike,
                        likedHorseIds: widget.likedHorseIds,
                      );
                    },
                  ),
                  onToggleFollow: () => widget.onToggleProfileFollow(profile),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HorseRegistrySearchPanel extends StatefulWidget {
  const _HorseRegistrySearchPanel({
    required this.horses,
    required this.marketHorses,
    required this.communityListings,
    required this.likedHorseIds,
    required this.onToggleHorseLike,
  });

  final List<Horse> horses;
  final List<Horse> marketHorses;
  final List<CommunityListing> communityListings;
  final Set<String> likedHorseIds;
  final ValueChanged<Horse> onToggleHorseLike;

  @override
  State<_HorseRegistrySearchPanel> createState() =>
      _HorseRegistrySearchPanelState();
}

class _HorseRegistrySearchPanelState extends State<_HorseRegistrySearchPanel> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  _RegistryLocationFilter _locationFilter = _RegistryLocationFilter.all;
  String? _breedFilter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketHorseIds = widget.marketHorses.map((horse) => horse.id).toSet();
    final communityHorseIds = widget.communityListings
        .map((listing) => listing.horse.id)
        .toSet();
    final breedOptions =
        widget.horses.map((horse) => horse.breed).toSet().toList()..sort();
    final matches =
        widget.horses.where((horse) {
          final isMarketHorse = marketHorseIds.contains(horse.id);
          final isCommunityHorse = communityHorseIds.contains(horse.id);
          if (_locationFilter == _RegistryLocationFilter.market &&
              !isMarketHorse &&
              !isCommunityHorse) {
            return false;
          }
          if (_locationFilter == _RegistryLocationFilter.stable &&
              (isMarketHorse || isCommunityHorse)) {
            return false;
          }
          if (_breedFilter != null && horse.breed != _breedFilter) {
            return false;
          }
          return _query.isEmpty || _horseMatchesSearch(horse, _query);
        }).toList()..sort(
          (left, right) => _compareHorseSearchResults(
            left,
            right,
            query: _query,
            leftIsMarket: marketHorseIds.contains(left.id),
            rightIsMarket: marketHorseIds.contains(right.id),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Horse',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Look up registry IDs and horse names across the current Explore pool.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Find A Horse',
            subtitle: 'Search by I.D., current name, or registered name',
            compact: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExploreSearchField(
                  controller: _controller,
                  hintText: 'Try PH-1001, Arabian, mutant, or a horse name',
                  prefixIcon: Icons.tag_rounded,
                  onChanged: (value) {
                    setState(() {
                      _query = value.trim();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SearchScopeChip(
                      label: 'All horses',
                      selected: _locationFilter == _RegistryLocationFilter.all,
                      onTap: () {
                        setState(() {
                          _locationFilter = _RegistryLocationFilter.all;
                        });
                      },
                    ),
                    _SearchScopeChip(
                      label: 'Stable',
                      selected:
                          _locationFilter == _RegistryLocationFilter.stable,
                      onTap: () {
                        setState(() {
                          _locationFilter = _RegistryLocationFilter.stable;
                        });
                      },
                    ),
                    _SearchScopeChip(
                      label: 'For sale',
                      selected:
                          _locationFilter == _RegistryLocationFilter.market,
                      onTap: () {
                        setState(() {
                          _locationFilter = _RegistryLocationFilter.market;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _breedFilter,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceRaised,
                  decoration: InputDecoration(
                    labelText: 'Breed filter',
                    filled: true,
                    fillColor: AppTheme.surfaceRaised.withValues(alpha: 0.72),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppTheme.outline.withValues(alpha: 0.8),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppTheme.outline.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All breeds'),
                    ),
                    ...breedOptions.map(
                      (breed) => DropdownMenuItem<String?>(
                        value: breed,
                        child: Text(breed),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _breedFilter = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (matches.isEmpty)
            const _EmptyState(message: 'No horse matched that registry search.')
          else
            ...matches
                .take(12)
                .map(
                  (horse) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SearchResultHorseCard(
                      horse: horse,
                      isLiked: widget.likedHorseIds.contains(horse.id),
                      onToggleLike: () {
                        widget.onToggleHorseLike(horse);
                        setState(() {});
                      },
                      locationLabel:
                          widget.communityListings.any(
                            (listing) => listing.horse.id == horse.id,
                          )
                          ? 'Community sale'
                          : widget.marketHorses.any(
                              (marketHorse) => marketHorse.id == horse.id,
                            )
                          ? 'Starter market'
                          : horse.isPublicListing ||
                                horse.isFeaturedProfileHorse
                          ? 'Public stable'
                          : 'In your stable',
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SearchScopeChip extends StatelessWidget {
  const _SearchScopeChip({
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
              : AppTheme.surfaceRaised.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.secondary : AppTheme.outline,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            color: selected ? AppTheme.secondary : Colors.white,
          ),
        ),
      ),
    );
  }
}

bool _horseMatchesSearch(Horse horse, String rawQuery) {
  final query = rawQuery.toLowerCase().trim();
  final normalizedQuery = _normalizeSearch(query);
  final searchFields = [
    horse.registryId,
    horse.displayName,
    horse.registeredName,
    horse.breed,
    horse.sex,
    horse.geneticProfile.breedingPotential,
    ...horse.specialTraits,
    ...horse.traits.map((trait) => '${trait.type} ${trait.option}'),
  ];

  return searchFields.any((field) {
    final lower = field.toLowerCase();
    return lower.contains(query) ||
        (normalizedQuery.isNotEmpty &&
            _normalizeSearch(field).contains(normalizedQuery));
  });
}

int _compareHorseSearchResults(
  Horse left,
  Horse right, {
  required String query,
  required bool leftIsMarket,
  required bool rightIsMarket,
}) {
  final scoreCompare = _horseSearchScore(
    right,
    query,
    isMarket: rightIsMarket,
  ).compareTo(_horseSearchScore(left, query, isMarket: leftIsMarket));
  if (scoreCompare != 0) {
    return scoreCompare;
  }
  return left.displayName.toLowerCase().compareTo(
    right.displayName.toLowerCase(),
  );
}

int _horseSearchScore(Horse horse, String rawQuery, {required bool isMarket}) {
  var score = 0;
  final query = rawQuery.toLowerCase().trim();
  final normalizedQuery = _normalizeSearch(query);
  final normalizedRegistry = _normalizeSearch(horse.registryId);
  final lowerName = horse.displayName.toLowerCase();
  final lowerRegistered = horse.registeredName.toLowerCase();
  final lowerBreed = horse.breed.toLowerCase();

  if (query.isEmpty) {
    return (horse.breedingRarity.rank * 100) +
        (horse.visualRarity.rank * 20) +
        (isMarket ? 5 : 0);
  }

  if (normalizedRegistry == normalizedQuery) {
    score += 600;
  } else if (normalizedRegistry.startsWith(normalizedQuery)) {
    score += 450;
  } else if (normalizedRegistry.contains(normalizedQuery)) {
    score += 320;
  }

  if (lowerName == query) {
    score += 380;
  } else if (lowerName.startsWith(query)) {
    score += 280;
  } else if (lowerName.contains(query)) {
    score += 210;
  }

  if (lowerRegistered == query) {
    score += 240;
  } else if (lowerRegistered.contains(query)) {
    score += 160;
  }

  if (lowerBreed == query) {
    score += 180;
  } else if (lowerBreed.contains(query)) {
    score += 110;
  }

  if (horse.specialTraits.any((trait) => trait.toLowerCase().contains(query))) {
    score += 90;
  }

  if (horse.isMutant && query.contains('mut')) {
    score += 60;
  }

  score += (horse.breedingRarity.rank * 24) + (horse.visualRarity.rank * 12);
  if (isMarket) {
    score += 8;
  }
  return score;
}

String _normalizeSearch(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
