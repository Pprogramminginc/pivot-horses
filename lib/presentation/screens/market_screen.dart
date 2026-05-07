import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/models/horse.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/models/rarity_tier.dart';
import '../../logic/services/stable_capacity_service.dart';
import 'catalog_screen.dart';
import '../widgets/horse_detail_sheet.dart';
import '../widgets/horse_preview.dart';
import '../widgets/horse_story_widgets.dart';
import '../widgets/price_badge.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/section_card.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({
    super.key,
    required this.stableHorses,
    required this.marketHorses,
    required this.currentTime,
    required this.coinBalance,
    required this.onPurchaseHorse,
    required this.stableCount,
    required this.stableCap,
    required this.slotsRemaining,
    required this.stableExpansionTier,
    required this.stableCapacityRenewsAt,
    this.initialTabIndex = 0,
    required this.onPurchaseStoreItem,
  });

  final List<Horse> stableHorses;
  final List<Horse> marketHorses;
  final DateTime currentTime;
  final int coinBalance;
  final void Function(Horse horse, String chosenName, String chosenSex)
  onPurchaseHorse;
  final int stableCount;
  final int stableCap;
  final int slotsRemaining;
  final int stableExpansionTier;
  final DateTime? stableCapacityRenewsAt;
  final int initialTabIndex;
  final ValueChanged<StoreItem> onPurchaseStoreItem;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool _coinsVisible = true;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);
          return SafeArea(
            child: Stack(
              children: [
                Column(
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
                            Tab(text: 'Market'),
                            Tab(text: 'Items'),
                            Tab(text: 'Catalog'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: controller,
                        children: [
                          _MarketListingsPage(
                            marketHorses: widget.marketHorses,
                            currentTime: widget.currentTime,
                            coinBalance: widget.coinBalance,
                            onPurchaseHorse: widget.onPurchaseHorse,
                            stableCount: widget.stableCount,
                            stableCap: widget.stableCap,
                            slotsRemaining: widget.slotsRemaining,
                            stableCapacityRenewsAt:
                                widget.stableCapacityRenewsAt,
                          ),
                          _ItemsStorePage(
                            stableHorses: widget.stableHorses,
                            currentTime: widget.currentTime,
                            coinBalance: widget.coinBalance,
                            stableExpansionTier: widget.stableExpansionTier,
                            stableCap: widget.stableCap,
                            stableCapacityRenewsAt:
                                widget.stableCapacityRenewsAt,
                            onPurchaseStoreItem: widget.onPurchaseStoreItem,
                          ),
                          const CatalogScreen(embedded: true),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 100,
                  right: 12,
                  child: _MarketBalanceBanner(
                    coinBalance: widget.coinBalance,
                    expanded: _coinsVisible,
                    onChanged: (visible) {
                      setState(() {
                        _coinsVisible = visible;
                      });
                    },
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

class _MarketListingsPage extends StatefulWidget {
  const _MarketListingsPage({
    required this.marketHorses,
    required this.currentTime,
    required this.coinBalance,
    required this.onPurchaseHorse,
    required this.stableCount,
    required this.stableCap,
    required this.slotsRemaining,
    required this.stableCapacityRenewsAt,
  });

  final List<Horse> marketHorses;
  final DateTime currentTime;
  final int coinBalance;
  final void Function(Horse horse, String chosenName, String chosenSex)
  onPurchaseHorse;
  final int stableCount;
  final int stableCap;
  final int slotsRemaining;
  final DateTime? stableCapacityRenewsAt;

  @override
  State<_MarketListingsPage> createState() => _MarketListingsPageState();
}

class _MarketListingsPageState extends State<_MarketListingsPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 82, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Market', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'Starter horses now read with a calmer low-value look: grounded coats, simple hair, brown eyes, and cleaner starter presentation while hidden breeding value still matters. Swipe over for the catalog handbook anytime.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Stable Capacity',
            subtitle:
                '${widget.stableCount} / ${widget.stableCap} horses owned',
            compact: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.slotsRemaining > 0
                      ? '${widget.slotsRemaining} slot${widget.slotsRemaining == 1 ? '' : 's'} open for new purchases.'
                      : 'Your stable is at capacity. Trade, sell, or purge a horse before buying again.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _stableRenewalCopy(widget.stableCapacityRenewsAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionCard(
            title: 'Starter Market Rules',
            subtitle: 'How these horses should feel',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MarketLine('1. Every horse keeps a permanent registry ID.'),
                _MarketLine(
                  '2. Starter visuals stay simple, even when genetics are strong.',
                ),
                _MarketLine(
                  '3. Higher prices reflect hidden breeding value, not just surface looks.',
                ),
                _MarketLine(
                  '4. Buyers can rename their horse, but the registry ID always stays the same.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (widget.marketHorses.isEmpty)
            const SectionCard(
              title: 'Market Cleared',
              subtitle: 'No starter horses left right now',
              child: Text(
                'All current starter horses have been purchased. This is where refreshed listings or timed market rotations can appear later.',
              ),
            ),
          ...widget.marketHorses.map(
            (horse) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MarketHorseCard(
                horse: horse,
                coinBalance: widget.coinBalance,
                onPurchaseHorse: widget.onPurchaseHorse,
                canPurchase: widget.slotsRemaining > 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _stableRenewalCopy(DateTime? renewalDate) {
  if (renewalDate == null) {
    return 'Base capacity is permanent. Expanded capacity is monthly and must be renewed from Items.';
  }
  return 'Expanded capacity renews ${_formatStoreDate(renewalDate)}. If it expires, overflow horses are removed from the lowest rated up, related breeding is cleared, and normal purge coins are paid.';
}

String _formatStoreDate(DateTime? date) {
  if (date == null) {
    return 'the renewal date';
  }
  return '${date.month}/${date.day}/${date.year}';
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

class _ItemsStorePage extends StatelessWidget {
  const _ItemsStorePage({
    required this.stableHorses,
    required this.currentTime,
    required this.coinBalance,
    required this.stableExpansionTier,
    required this.stableCap,
    required this.stableCapacityRenewsAt,
    required this.onPurchaseStoreItem,
  });

  final List<Horse> stableHorses;
  final DateTime currentTime;
  final int coinBalance;
  final int stableExpansionTier;
  final int stableCap;
  final DateTime? stableCapacityRenewsAt;
  final ValueChanged<StoreItem> onPurchaseStoreItem;

  @override
  Widget build(BuildContext context) {
    final expansionItems = StoreCatalog.items
        .where((item) => item.isExpansion)
        .toList();
    final regularItems = StoreCatalog.items
        .where((item) => !item.isExpansion)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 82, 20, 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'Buy boosts for breeding timers, stallion recovery, and monthly stable space tiers. Manage owned items from Stable.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Stable Plan',
            subtitle: 'Current capacity: $stableCap horses',
            compact: true,
            child: Text(
              stableExpansionTier == 0
                  ? 'Starter stable active. Buy Tier 1 first to unlock 25 horse slots. Tier 2 unlocks after Tier 1 is active.'
                  : stableExpansionTier == 1
                  ? 'Tier 1 active through ${_formatStoreDate(stableCapacityRenewsAt)}. Tier 2 is now unlocked and raises capacity to 50 horse slots.'
                  : 'Tier 2 active through ${_formatStoreDate(stableCapacityRenewsAt)}. Renew before then to keep all extra slots.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
          Text('Store', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (expansionItems.length >= 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _StableExpansionCard(
                tierOne: expansionItems[0],
                tierTwo: expansionItems[1],
                stableHorses: stableHorses,
                currentTime: currentTime,
                stableCapacityRenewsAt: stableCapacityRenewsAt,
                coinBalance: coinBalance,
                stableExpansionTier: stableExpansionTier,
                onPurchase: onPurchaseStoreItem,
              ),
            ),
          Text('Boosts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...regularItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _StoreItemCard(
                item: item,
                coinBalance: coinBalance,
                stableExpansionTier: stableExpansionTier,
                onPurchase: onPurchaseStoreItem,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StableExpansionCard extends StatefulWidget {
  const _StableExpansionCard({
    required this.tierOne,
    required this.tierTwo,
    required this.stableHorses,
    required this.currentTime,
    required this.stableCapacityRenewsAt,
    required this.coinBalance,
    required this.stableExpansionTier,
    required this.onPurchase,
  });

  final StoreItem tierOne;
  final StoreItem tierTwo;
  final List<Horse> stableHorses;
  final DateTime currentTime;
  final DateTime? stableCapacityRenewsAt;
  final int coinBalance;
  final int stableExpansionTier;
  final ValueChanged<StoreItem> onPurchase;

  @override
  State<_StableExpansionCard> createState() => _StableExpansionCardState();
}

class _StableExpansionCardState extends State<_StableExpansionCard> {
  int _selectedTier = 1;

  @override
  Widget build(BuildContext context) {
    final selectedItem = _selectedTier == 1 ? widget.tierOne : widget.tierTwo;
    final selectedTier = selectedItem.expansionTier!;
    final affectedHorses = _horsesRemovedAtBaseCapacity(widget.stableHorses);
    final alreadyOwnedHigherTier = widget.stableExpansionTier > selectedTier;
    final lockedTier = selectedTier > widget.stableExpansionTier + 1;
    final renewingTier = widget.stableExpansionTier == selectedTier;
    final balanceShortfall = selectedItem.price - widget.coinBalance;
    final canBuy =
        widget.coinBalance >= selectedItem.price &&
        !alreadyOwnedHigherTier &&
        !lockedTier;

    return SectionCard(
      title: 'Stable Expansion',
      subtitle: 'Monthly tiers • choose Tier 1 or Tier 2',
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ExpansionTierTab(
                  label: 'Tier 1',
                  detail: '25 slots',
                  selected: _selectedTier == 1,
                  locked: false,
                  onTap: () => setState(() => _selectedTier = 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ExpansionTierTab(
                  label: 'Tier 2',
                  detail: '50 slots',
                  selected: _selectedTier == 2,
                  locked: widget.stableExpansionTier < 1,
                  onTap: () => setState(() => _selectedTier = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ItemShowcase(item: selectedItem),
          const SizedBox(height: 12),
          Text(
            selectedItem.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (widget.stableExpansionTier > 0 &&
              widget.stableCapacityRenewsAt != null) ...[
            const SizedBox(height: 12),
            _RenewalStatusBanner(
              currentTime: widget.currentTime,
              renewalDate: widget.stableCapacityRenewsAt!,
            ),
          ],
          if (affectedHorses.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CapacityExpirationPreview(affectedHorses: affectedHorses),
          ],
          if (balanceShortfall > 0) ...[
            const SizedBox(height: 12),
            _LowBalanceNotice(shortfall: balanceShortfall),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canBuy
                  ? () async {
                      final confirmed = await _confirmStableExpansionPurchase(
                        context: context,
                        item: selectedItem,
                        isRenewal: renewingTier,
                        affectedHorses: affectedHorses,
                      );
                      if (confirmed && context.mounted) {
                        widget.onPurchase(selectedItem);
                      }
                    }
                  : null,
              icon: Icon(
                lockedTier
                    ? Icons.lock_rounded
                    : alreadyOwnedHigherTier
                    ? Icons.check_rounded
                    : Icons.shopping_bag_rounded,
              ),
              label: Text(
                alreadyOwnedHigherTier
                    ? 'Higher tier active'
                    : lockedTier
                    ? 'Buy Tier 1 first'
                    : renewingTier
                    ? 'Renew Tier $selectedTier • ${selectedItem.price} coins'
                    : 'Buy Tier $selectedTier • ${selectedItem.price} coins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmStableExpansionPurchase({
    required BuildContext context,
    required StoreItem item,
    required bool isRenewal,
    required List<Horse> affectedHorses,
  }) async {
    final tier = item.expansionTier!;
    final payout = affectedHorses.fold<int>(
      0,
      (total, horse) => total + horse.purgePayout,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: AppTheme.surfaceRaised,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.outline),
          ),
          title: Text(
            '${isRenewal ? 'Renew' : 'Buy'} Tier $tier?',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This monthly tier costs ${item.price} coins and lasts 30 days.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (affectedHorses.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'If expansion expires while your roster is over 10 horses, ${affectedHorses.length} lowest-rated horse${affectedHorses.length == 1 ? '' : 's'} would leave for $payout purge coins. Any active breeding tied to them would be cleared.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: AppTheme.secondary),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(isRenewal ? 'Renew' : 'Buy'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }
}

class _LowBalanceNotice extends StatelessWidget {
  const _LowBalanceNotice({required this.shortfall});

  final int shortfall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.tertiary.withValues(alpha: 0.42)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppTheme.tertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Need $shortfall more coins for this tier.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalStatusBanner extends StatelessWidget {
  const _RenewalStatusBanner({
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
    final title = days <= 0
        ? 'Renewal due today'
        : urgent
        ? 'Renew soon'
        : 'Renews in $days day${days == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: urgent ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Row(
        children: [
          Icon(
            urgent ? Icons.warning_amber_rounded : Icons.event_repeat_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title • ${_formatStoreDate(renewalDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityExpirationPreview extends StatelessWidget {
  const _CapacityExpirationPreview({required this.affectedHorses});

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.42)),
      ),
      child: Text(
        'Expiration preview: ${affectedHorses.length} lowest-rated overflow horse${affectedHorses.length == 1 ? '' : 's'} would leave: $previewNames${moreCount > 0 ? ' + $moreCount more' : ''}. Payout: $payout coins.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.mutedInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExpansionTierTab extends StatelessWidget {
  const _ExpansionTierTab({
    required this.label,
    required this.detail,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppTheme.secondary : AppTheme.outline;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.heroGradient : null,
            color: selected
                ? null
                : AppTheme.surfaceRaised.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked) ...[
                const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: AppTheme.mutedInk,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : AppTheme.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? AppTheme.secondary
                            : AppTheme.mutedInk,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
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
}

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.item,
    required this.coinBalance,
    required this.stableExpansionTier,
    required this.onPurchase,
  });

  final StoreItem item;
  final int coinBalance;
  final int stableExpansionTier;
  final ValueChanged<StoreItem> onPurchase;

  @override
  Widget build(BuildContext context) {
    final alreadyOwnedExpansion =
        item.expansionTier != null && stableExpansionTier > item.expansionTier!;
    final lockedExpansion =
        item.expansionTier != null &&
        item.expansionTier! > stableExpansionTier + 1;
    final renewingExpansion =
        item.expansionTier != null &&
        stableExpansionTier == item.expansionTier!;
    final canBuy =
        coinBalance >= item.price && !alreadyOwnedExpansion && !lockedExpansion;

    return SectionCard(
      title: item.title,
      subtitle: item.subtitle,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ItemShowcase(item: item),
          const SizedBox(height: 12),
          Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canBuy ? () => onPurchase(item) : null,
              icon: Icon(
                alreadyOwnedExpansion
                    ? Icons.check_rounded
                    : Icons.shopping_bag_rounded,
              ),
              label: Text(
                alreadyOwnedExpansion
                    ? 'Higher tier active'
                    : lockedExpansion
                    ? 'Buy Tier 1 first'
                    : renewingExpansion
                    ? 'Renew Tier ${item.expansionTier} • ${item.price} coins'
                    : 'Buy • ${item.price} coins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemShowcase extends StatelessWidget {
  const _ItemShowcase({required this.item});

  final StoreItem item;

  @override
  Widget build(BuildContext context) {
    final style = _ItemStageStyle.forItem(item);

    return Container(
      height: 150,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            style.backgroundStart,
            AppTheme.surfaceRaised.withValues(alpha: 0.58),
            style.backgroundEnd,
          ],
          stops: const [0, 0.54, 1],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.accent.withValues(alpha: 0.52)),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            width: 230,
            height: 230,
            right: -82,
            top: -82,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.accent.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            width: 170,
            height: 170,
            left: -66,
            bottom: -82,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.secondaryAccent.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ItemStagePatternPainter(
                accent: style.accent,
                secondaryAccent: style.secondaryAccent,
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 21,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.36),
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(top: 12, left: 12, child: _ItemStageBadge(style: style)),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 18, 30, 22),
            child: Image.asset(
              item.assetPath,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.08),
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

class _ItemStageBadge extends StatelessWidget {
  const _ItemStageBadge({required this.style});

  final _ItemStageStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.accent.withValues(alpha: 0.5)),
      ),
      child: Icon(style.icon, size: 16, color: style.accent),
    );
  }
}

class _ItemStagePatternPainter extends CustomPainter {
  const _ItemStagePatternPainter({
    required this.accent,
    required this.secondaryAccent,
  });

  final Color accent;
  final Color secondaryAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.14)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final sparklePaint = Paint()
      ..color = secondaryAccent.withValues(alpha: 0.28)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (var x = -size.height; x < size.width; x += 34) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        linePaint,
      );
    }

    final points = <Offset>[
      Offset(size.width * 0.74, size.height * 0.30),
      Offset(size.width * 0.18, size.height * 0.38),
      Offset(size.width * 0.83, size.height * 0.70),
    ];

    for (final point in points) {
      canvas.drawLine(
        Offset(point.dx - 5, point.dy),
        Offset(point.dx + 5, point.dy),
        sparklePaint,
      );
      canvas.drawLine(
        Offset(point.dx, point.dy - 5),
        Offset(point.dx, point.dy + 5),
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ItemStagePatternPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.secondaryAccent != secondaryAccent;
  }
}

class _ItemStageStyle {
  const _ItemStageStyle({
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.accent,
    required this.secondaryAccent,
    required this.icon,
  });

  final Color backgroundStart;
  final Color backgroundEnd;
  final Color accent;
  final Color secondaryAccent;
  final IconData icon;

  static _ItemStageStyle forItem(StoreItem item) {
    if (item.isExpansion) {
      return const _ItemStageStyle(
        backgroundStart: Color(0xFF24333A),
        backgroundEnd: Color(0xFF1A1430),
        accent: AppTheme.secondary,
        secondaryAccent: AppTheme.tertiary,
        icon: Icons.auto_awesome_mosaic_rounded,
      );
    }

    return switch (item.type) {
      InventoryItemType.prenatalVitamin => const _ItemStageStyle(
        backgroundStart: Color(0xFF44213E),
        backgroundEnd: Color(0xFF1A2132),
        accent: AppTheme.primary,
        secondaryAccent: AppTheme.tertiary,
        icon: Icons.bolt_rounded,
      ),
      InventoryItemType.carrot => const _ItemStageStyle(
        backgroundStart: Color(0xFF3B2B16),
        backgroundEnd: Color(0xFF182D28),
        accent: AppTheme.tertiary,
        secondaryAccent: AppTheme.secondary,
        icon: Icons.eco_rounded,
      ),
      null => const _ItemStageStyle(
        backgroundStart: Color(0xFF382241),
        backgroundEnd: Color(0xFF132934),
        accent: AppTheme.secondary,
        secondaryAccent: AppTheme.primary,
        icon: Icons.inventory_2_rounded,
      ),
    };
  }
}

class _MarketBalanceBanner extends StatelessWidget {
  const _MarketBalanceBanner({
    required this.coinBalance,
    required this.expanded,
    required this.onChanged,
  });

  final int coinBalance;
  final bool expanded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!expanded),
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -120) {
          onChanged(true);
        } else if (velocity > 120) {
          onChanged(false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: expanded ? 138 : 64,
        height: 64,
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? 12 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
          boxShadow: const [
            BoxShadow(
              color: AppTheme.shadow,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showBalance = expanded && constraints.maxWidth >= 56;

            return Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.monetization_on_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                if (showBalance) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          '$coinBalance',
                          key: ValueKey<int>(coinBalance),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.secondary,
                              ),
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MarketHorseCard extends StatelessWidget {
  const _MarketHorseCard({
    required this.horse,
    required this.coinBalance,
    required this.onPurchaseHorse,
    required this.canPurchase,
  });

  final Horse horse;
  final int coinBalance;
  final void Function(Horse horse, String chosenName, String chosenSex)
  onPurchaseHorse;
  final bool canPurchase;

  @override
  Widget build(BuildContext context) {
    final breedingTier = horse.breedingRarity;
    final visualTier = horse.visualRarity;
    final marePrice = Horse.starterPurchasePrice(
      breed: horse.breed,
      sex: 'Mare',
    );
    final stallionPrice = Horse.starterPurchasePrice(
      breed: horse.breed,
      sex: 'Stallion',
    );

    return SectionCard(
      title: horse.cardTitle,
      subtitle: horse.cardSubtitle,
      compact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MarketStatePill(
                label: 'Ready to register',
                color: AppTheme.secondary,
              ),
              _MarketStatePill(
                label: horse.isFoal ? 'Young line' : 'Starter listing',
                color: AppTheme.primary,
              ),
              _MarketStatePill(
                label: '${horse.geneticProfile.breedingPotential} breeder',
                color: AppTheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RarityBadge(
                tier: breedingTier,
                label: 'Breeding ${breedingTier.label}',
                compact: true,
              ),
              RarityBadge(
                tier: visualTier,
                label: 'Visual ${visualTier.label}',
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 132,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HorsePreview(
                            horse: horse,
                            compact: true,
                            naturalStage: true,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => _showDetails(context),
                            child: const Text('Details'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MarketHorseDetails(
                      horse: horse,
                      breedingTier: breedingTier,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 132,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HorsePreview(
                          horse: horse,
                          compact: true,
                          naturalStage: true,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => _showDetails(context),
                          child: const Text('Details'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MarketHorseDetails(
                      horse: horse,
                      breedingTier: breedingTier,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.panelGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market read',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  horse.starterMarketRead,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Hidden insight: ${horse.hiddenBreedingInsight}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Best use: ${horseBreedingUseLabel(horse)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: canPurchase && coinBalance >= marePrice
                      ? () => _showPurchaseFlow(context, 'Mare')
                      : null,
                  child: Text('Mare • $marePrice'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: canPurchase && coinBalance >= stallionPrice
                      ? () => _showPurchaseFlow(context, 'Stallion')
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondary.withValues(alpha: 0.18),
                    foregroundColor: AppTheme.secondary,
                  ),
                  child: Text('Stallion • $stallionPrice'),
                ),
              ),
            ],
          ),
          if (!canPurchase || coinBalance < marePrice) ...[
            const SizedBox(height: 10),
            Text(
              !canPurchase
                  ? 'Stable full. Trade, sell, or purge a horse to buy another one.'
                  : 'You need at least $marePrice coins to buy this ${horse.breed} as a mare.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => HorseDetailSheet(horse: horse),
    );
  }

  void _showPurchaseFlow(BuildContext context, String chosenSex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return _PurchaseFlowSheet(
          horse: horse,
          chosenSex: chosenSex,
          onConfirmPurchase: onPurchaseHorse,
        );
      },
    );
  }
}

class _PurchaseFlowSheet extends StatefulWidget {
  const _PurchaseFlowSheet({
    required this.horse,
    required this.chosenSex,
    required this.onConfirmPurchase,
  });

  final Horse horse;
  final String chosenSex;
  final void Function(Horse horse, String chosenName, String chosenSex)
  onConfirmPurchase;

  @override
  State<_PurchaseFlowSheet> createState() => _PurchaseFlowSheetState();
}

class _PurchaseFlowSheetState extends State<_PurchaseFlowSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.horse.displayName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchasePrice = Horse.starterPurchasePrice(
      breed: widget.horse.breed,
      sex: widget.chosenSex,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buy ${widget.horse.breed}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Choose the name this owner will use. The horse will keep its breed and registry ID, and this purchase will be registered as a ${widget.chosenSex} for $purchasePrice coins.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'New display name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Registered name: ${widget.horse.registeredName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Selected sex: ${widget.chosenSex}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Market price: $purchasePrice coins',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Breeding retirement: after ${widget.horse.breedingCareerLimitDays} total days',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final chosenName = _controller.text.trim().isEmpty
                      ? widget.horse.displayName
                      : _controller.text.trim();
                  Navigator.of(context).pop();
                  widget.onConfirmPurchase(
                    widget.horse,
                    chosenName,
                    widget.chosenSex,
                  );
                },
                child: Text('Confirm purchase • $purchasePrice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketHorseDetails extends StatelessWidget {
  const _MarketHorseDetails({required this.horse, required this.breedingTier});

  final Horse horse;
  final RarityTier breedingTier;

  @override
  Widget build(BuildContext context) {
    final marePrice = Horse.starterPurchasePrice(
      breed: horse.breed,
      sex: 'Mare',
    );
    final stallionPrice = Horse.starterPurchasePrice(
      breed: horse.breed,
      sex: 'Stallion',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          horse.sex,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        HorseStoryWrap(horse: horse, maxBadges: 4, compact: true),
        const SizedBox(height: 8),
        Text(
          horseVisualRead(horse),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                breedingTier.softColor.withValues(alpha: 0.86),
                AppTheme.surfaceRaised,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: breedingTier.borderColor),
          ),
          child: Text(
            horse.geneticProfile.breedingPotential,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Value class: ${horse.valueClassLabel}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          horse.valueClassRead,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedInk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          horse.starterMarketRead,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          horse.hiddenBreedingInsight,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedInk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        PriceBadge(price: marePrice, tier: breedingTier, compact: true),
        const SizedBox(height: 6),
        Text(
          'Mare starts at $marePrice coins • Stallion starts at $stallionPrice coins',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${horse.breedingDaysRemaining} breeding days left',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MarketStatePill extends StatelessWidget {
  const _MarketStatePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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

class _MarketLine extends StatelessWidget {
  const _MarketLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
