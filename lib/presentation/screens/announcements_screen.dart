import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../widgets/section_card.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key, this.embedded = false});

  final bool embedded;

  static const List<_ReleaseNote> _comingSoon = [
    _ReleaseNote(
      title: 'Expanded Horse Registry',
      status: 'Coming soon',
      dateLabel: 'Planned',
      body:
          'Cleaner lifetime horse IDs, stronger search, and better registry tracking for every stable.',
      icon: Icons.tag_rounded,
      color: AppTheme.secondary,
    ),
    _ReleaseNote(
      title: 'Seasonal Breed Drops',
      status: 'Coming soon',
      dateLabel: 'Upcoming',
      body:
          'Limited-time breed releases with curated trait pools, collectible looks, and new breeding goals.',
      icon: Icons.auto_awesome_rounded,
      color: AppTheme.primary,
    ),
    _ReleaseNote(
      title: 'Stable Events',
      status: 'Coming soon',
      dateLabel: 'In planning',
      body:
          'Short challenges built around breeding, care, market finds, and showcase-ready horses.',
      icon: Icons.emoji_events_rounded,
      color: AppTheme.tertiary,
    ),
  ];

  static const List<_ReleaseNote> _recentUpdates = [
    _ReleaseNote(
      title: 'Unique Horse IDs',
      status: 'Updated',
      dateLabel: 'Now live',
      body:
          'New horses receive simple permanent IDs like PH101, PH102, and PH2001 with duplicate checks.',
      icon: Icons.verified_rounded,
      color: AppTheme.secondary,
    ),
    _ReleaseNote(
      title: 'Live Account Fixes',
      status: 'Updated',
      dateLabel: 'Now live',
      body:
          'Account creation is more reliable when display names or handles overlap.',
      icon: Icons.lock_open_rounded,
      color: AppTheme.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, embedded ? 6 : 18, 20, 28),
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
                Text('Announcements', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'New releases, stable updates, and what is coming soon for Pivot Horses.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.mutedInk,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _NewsChip(label: 'Coming soon'),
                    _NewsChip(label: 'Release notes'),
                    _NewsChip(label: 'Stable updates'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Coming Soon',
            subtitle: 'Next releases in the works',
            child: Column(
              children: [
                for (var i = 0; i < _comingSoon.length; i++) ...[
                  _AnnouncementTile(note: _comingSoon[i]),
                  if (i != _comingSoon.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Latest Updates',
            subtitle: 'Recent app improvements',
            compact: true,
            child: Column(
              children: [
                for (var i = 0; i < _recentUpdates.length; i++) ...[
                  _AnnouncementTile(note: _recentUpdates[i], compact: true),
                  if (i != _recentUpdates.length - 1)
                    Divider(
                      height: 18,
                      color: AppTheme.outline.withValues(alpha: 0.65),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back',
                  ),
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.note, this.compact = false});

  final _ReleaseNote note;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: compact ? 0.54 : 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: note.color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: note.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(note.icon, color: note.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _StatusPill(label: note.status, color: note.color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.dateLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedInk,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NewsChip extends StatelessWidget {
  const _NewsChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
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

class _ReleaseNote {
  const _ReleaseNote({
    required this.title,
    required this.status,
    required this.dateLabel,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String status;
  final String dateLabel;
  final String body;
  final IconData icon;
  final Color color;
}
