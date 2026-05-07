import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/inbox_item.dart';

class InboxSheet extends StatefulWidget {
  const InboxSheet({
    super.key,
    required this.title,
    required this.emptyTitle,
    required this.emptyBody,
    required this.items,
    required this.onMarkRead,
    required this.onMarkAllRead,
  });

  final String title;
  final String emptyTitle;
  final String emptyBody;
  final List<InboxItem> items;
  final ValueChanged<InboxItem> onMarkRead;
  final VoidCallback onMarkAllRead;

  @override
  State<InboxSheet> createState() => _InboxSheetState();
}

class _InboxSheetState extends State<InboxSheet> {
  late List<InboxItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List<InboxItem>.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((item) => item.isUnread).length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _items.isEmpty
                  ? _InboxEmptyState(
                      title: widget.emptyTitle,
                      body: widget.emptyBody,
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _InboxItemCard(
                          item: _items[index],
                          onMarkRead: _markRead,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _markRead(InboxItem item) {
    if (!item.isUnread) {
      return;
    }
    final readAt = DateTime.now();
    setState(() {
      _items = _items
          .map(
            (candidate) => candidate.id == item.id
                ? candidate.copyWith(readAt: readAt)
                : candidate,
          )
          .toList();
    });
    widget.onMarkRead(item);
  }

  void _markAllRead() {
    final readAt = DateTime.now();
    setState(() {
      _items = _items
          .map((item) => item.isUnread ? item.copyWith(readAt: readAt) : item)
          .toList();
    });
    widget.onMarkAllRead();
  }
}

class _InboxEmptyState extends StatelessWidget {
  const _InboxEmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.ink),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
          ),
        ],
      ),
    );
  }
}

class _InboxItemCard extends StatelessWidget {
  const _InboxItemCard({required this.item, required this.onMarkRead});

  final InboxItem item;
  final ValueChanged<InboxItem> onMarkRead;

  @override
  Widget build(BuildContext context) {
    final accent = item.kind == InboxItemKind.message
        ? AppTheme.secondary
        : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: item.isUnread
              ? accent.withValues(alpha: 0.78)
              : AppTheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (item.isUnread)
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.category,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
          ),
          if (item.isUnread) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onMarkRead(item),
                child: const Text('Mark read'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
