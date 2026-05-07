import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../data/sample/trait_catalog.dart';
import '../../domain/models/rarity_tier.dart';
import '../widgets/section_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final PageController _pageController;
  late final List<_CatalogPageData> _pages;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = [
      const _CatalogPageData(
        title: 'Index',
        subtitle: 'Guide map',
        icon: Icons.menu_book_rounded,
      ),
      const _CatalogPageData(
        title: 'Horse Terms',
        subtitle: 'Mares, stallions, foals, and core stable language',
        icon: Icons.info_outline_rounded,
      ),
      const _CatalogPageData(
        title: 'Rarity Guide',
        subtitle: 'Color language for horse cards and charts',
        icon: Icons.auto_awesome_rounded,
      ),
      const _CatalogPageData(
        title: 'Breed Releases',
        subtitle: 'Current plan',
        icon: Icons.pets_rounded,
      ),
      const _CatalogPageData(
        title: 'Monthly Rules',
        subtitle: 'Stable capacity renewals and overflow payouts',
        icon: Icons.event_repeat_rounded,
      ),
      ...traitCatalog.entries.map(
        (entry) => _CatalogPageData(
          title: entry.key,
          subtitle: 'Current trait pool',
          icon: _iconForSection(entry.key),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _CatalogPageShell(
                  pageTitle: 'Your Catalog Handbook',
                  current: index,
                  total: _pages.length,
                  title: _pages[index].title,
                  subtitle: _pages[index].subtitle,
                  child: _buildPage(index),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _CatalogFooterNav(
            current: _currentPage,
            total: _pages.length,
            onPrevious: _currentPage == 0
                ? null
                : () => _jumpToPage(_currentPage - 1),
            onIndex: _currentPage == 0 ? null : () => _jumpToPage(0),
            onNext: _currentPage == _pages.length - 1
                ? null
                : () => _jumpToPage(_currentPage + 1),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return SafeArea(child: content);
  }

  Widget _buildPage(int index) {
    if (index == 0) {
      return _CatalogIndexPage(pages: _pages, onSelect: _jumpToPage);
    }
    if (index == 1) {
      return const _HorseTermsPage();
    }
    if (index == 2) {
      return const _RarityGuidePage();
    }
    if (index == 3) {
      return const _BreedReleasePage();
    }
    if (index == 4) {
      return const _MonthlyRulesPage();
    }

    final sectionEntry = traitCatalog.entries.elementAt(index - 5);
    return _TraitSectionPage(
      title: sectionEntry.key,
      items: sectionEntry.value,
      icon: _pages[index].icon,
    );
  }
}

class _CatalogPageShell extends StatelessWidget {
  const _CatalogPageShell({
    required this.pageTitle,
    required this.current,
    required this.total,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String pageTitle;
  final int current;
  final int total;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pageTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: AppTheme.panelGradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${current + 1}/$total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CatalogIndexPage extends StatelessWidget {
  const _CatalogIndexPage({required this.pages, required this.onSelect});

  final List<_CatalogPageData> pages;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Guide Index',
          subtitle: 'Tap any chapter or just swipe right to start reading',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse the catalog to understand your horse, its traits, and how each part of the breeding system works. You can jump straight to a chapter from here or keep swiping page by page.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              ...List.generate(pages.length - 1, (offset) {
                final pageIndex = offset + 1;
                final page = pages[pageIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onSelect(pageIndex),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.panelGradient,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(page.icon, color: AppTheme.secondary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  page.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  page.subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppTheme.mutedInk),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppTheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _HorseTermsPage extends StatelessWidget {
  const _HorseTermsPage();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Horse Terms',
      subtitle: 'Quick glossary for how horses are described in the game',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CatalogLine(
            'Mare: an adult female horse. In the app, mares are one half of your breeding pair and may carry their own trait combinations.',
          ),
          _CatalogLine(
            'Stallion: an adult male horse. Stallions pair with mares to produce foals and contribute their visible and hidden traits.',
          ),
          _CatalogLine(
            'Foal: a young horse. Foals are the offspring result you are trying to predict when you compare breeding combinations.',
          ),
          _CatalogLine(
            'Breeding rarity: the rarity tier tied to the horse’s hidden breeding value and long-term usefulness in pairings.',
          ),
          _CatalogLine(
            'Visual rarity: the rarity tier tied to the horse’s visible trait total, such as mane style, eye color, markings, and body type.',
          ),
        ],
      ),
    );
  }
}

class _RarityGuidePage extends StatelessWidget {
  const _RarityGuidePage();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Rarity Guide',
      subtitle: 'Color language for horse cards and charts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _RarityBadge(tier: RarityTier.common),
              _RarityBadge(tier: RarityTier.uncommon),
              _RarityBadge(tier: RarityTier.rare),
              _RarityBadge(tier: RarityTier.epic),
              _RarityBadge(tier: RarityTier.legendary),
            ],
          ),
          const SizedBox(height: 16),
          const _CatalogLine(
            'Common is the floor tier for simple starter traits and more ordinary lineups.',
          ),
          const _CatalogLine(
            'Uncommon marks a small upgrade in visible trait quality or breeding depth.',
          ),
          const _CatalogLine(
            'Rare marks stronger visible traits or a healthier overall breeding total.',
          ),
          const _CatalogLine(
            'Epic means the horse is carrying a high-value build, either visually, genetically, or both.',
          ),
          const _CatalogLine(
            'Legendary is reserved for top-end total scores and the strongest breeding outcomes.',
          ),
        ],
      ),
    );
  }
}

class _BreedReleasePage extends StatelessWidget {
  const _BreedReleasePage();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Breed Releases',
      subtitle: 'Current plan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CatalogLine(
            'Starter Stock is the onboarding pool for simple-looking market horses.',
          ),
          _CatalogLine('Arabian is already represented in the sample stable.'),
          _CatalogLine(
            'Future updates can drop new breeds by adding data entries and trait weight rules, not by rebuilding the app.',
          ),
        ],
      ),
    );
  }
}

class _MonthlyRulesPage extends StatelessWidget {
  const _MonthlyRulesPage();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Monthly Rules',
      subtitle: 'How stable capacity renewals work',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CatalogLine(
            'Base stable capacity is permanent and holds 10 horses.',
          ),
          _CatalogLine(
            'Stable Expansion Tier 1 and Tier 2 are monthly tiers purchased from Market Items.',
          ),
          _CatalogLine('Tier 2 unlocks only after Tier 1 has been purchased.'),
          _CatalogLine(
            'If an expanded tier expires, capacity returns to 10 and overflow horses are removed from the lowest rated upward.',
          ),
          _CatalogLine(
            'Each removed horse pays the same coin amount it would have paid from a normal purge.',
          ),
          _CatalogLine(
            'Any active breeding, pregnancy, or cooldown tied to a removed horse is cleared with that horse.',
          ),
        ],
      ),
    );
  }
}

class _TraitSectionPage extends StatelessWidget {
  const _TraitSectionPage({
    required this.title,
    required this.items,
    required this.icon,
  });

  final String title;
  final Map<String, List<String>> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      subtitle: 'Current trait pool',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.panelGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppTheme.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Swipe again to keep reading, or use the chapter controls at the bottom to move around the handbook.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppTheme.panelGradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.value.join(', '),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogFooterNav extends StatelessWidget {
  const _CatalogFooterNav({
    required this.current,
    required this.total,
    required this.onPrevious,
    required this.onIndex,
    required this.onNext,
  });

  final int current;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onIndex;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CatalogNavButton(
          icon: Icons.arrow_back_rounded,
          onPressed: onPrevious,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Center(
            child: Wrap(
              spacing: 6,
              children: List.generate(total, (index) {
                final active = index == current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFB8792C)
                        : const Color(0xFFD8C5AE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CatalogNavButton(icon: Icons.grid_view_rounded, onPressed: onIndex),
        const SizedBox(width: 12),
        _CatalogNavButton(
          icon: Icons.arrow_forward_rounded,
          onPressed: onNext,
          filled: true,
        ),
      ],
    );
  }
}

class _CatalogNavButton extends StatelessWidget {
  const _CatalogNavButton({
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = filled
        ? FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          );

    final child = Icon(icon, size: 22);

    return filled
        ? FilledButton(onPressed: onPressed, style: buttonStyle, child: child)
        : OutlinedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: child,
          );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.tier});

  final RarityTier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tier.valueColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tier.valueColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: tier.valueColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tier.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tier.valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogLine extends StatelessWidget {
  const _CatalogLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _CatalogPageData {
  const _CatalogPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

IconData _iconForSection(String title) {
  switch (title) {
    case 'Coat':
      return Icons.palette_outlined;
    case 'Mane':
      return Icons.air_rounded;
    case 'Tail':
      return Icons.timeline_rounded;
    case 'Eyes':
      return Icons.visibility_outlined;
    case 'Markings':
      return Icons.brush_outlined;
    case 'Body':
      return Icons.fitness_center_outlined;
    case 'Facial Features':
      return Icons.face_retouching_natural_outlined;
    case 'Bonus':
      return Icons.stars_rounded;
    default:
      return Icons.book_outlined;
  }
}
