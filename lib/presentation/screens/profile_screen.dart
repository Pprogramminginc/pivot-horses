import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../widgets/section_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.username,
    required this.coinBalance,
    required this.stableCount,
    required this.marketCount,
    required this.hasActivePregnancy,
    required this.hasActiveMating,
    required this.foalCount,
    required this.email,
    required this.profileId,
    required this.backendConnected,
    required this.coinPurchasesAvailable,
    required this.coinPurchasePending,
    required this.onOpenSettings,
    required this.onBuyCoins,
    required this.onSubmitFeedback,
    required this.onCopyStableId,
    required this.onSignOut,
  });

  final String username;
  final String email;
  final String profileId;
  final int coinBalance;
  final int stableCount;
  final int marketCount;
  final bool hasActivePregnancy;
  final bool hasActiveMating;
  final int foalCount;
  final bool backendConnected;
  final bool coinPurchasesAvailable;
  final bool coinPurchasePending;
  final VoidCallback onOpenSettings;
  final void Function(String productId) onBuyCoins;
  final Future<void> Function({
    required String category,
    required String message,
  })
  onSubmitFeedback;
  final Future<void> Function() onCopyStableId;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.of(context).padding.bottom + 128,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Profile', style: theme.textTheme.headlineMedium),
                ),
                IconButton.filledTonal(
                  tooltip: 'Settings',
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.42),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.secondary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stable owner profile',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ProfileChip(
                        label: 'Coin balance',
                        value: '$coinBalance',
                        color: AppTheme.tertiary,
                      ),
                      _ProfileChip(
                        label: 'Stable horses',
                        value: '$stableCount',
                        color: AppTheme.secondary,
                      ),
                      _ProfileChip(
                        label: 'Foals raised',
                        value: '$foalCount',
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Coin Wallet',
              subtitle: 'Top up when you want more market flexibility',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coins are used for horse purchases, future breeding boosts, and premium stable actions.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth >= 420
                          ? (constraints.maxWidth - 10) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _CoinPackCard(
                              label: 'Stable Snack',
                              coins: 1100,
                              cost: 4,
                              enabled:
                                  coinPurchasesAvailable &&
                                  !coinPurchasePending,
                              onBuy: () => onBuyCoins('coins_1100'),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _CoinPackCard(
                              label: 'Breeder Bundle',
                              coins: 2500,
                              cost: 9,
                              enabled:
                                  coinPurchasesAvailable &&
                                  !coinPurchasePending,
                              onBuy: () => onBuyCoins('coins_2500'),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _CoinPackCard(
                              label: 'Barn Vault',
                              coins: 5000,
                              cost: 19,
                              badge: 'Most popular',
                              enabled:
                                  coinPurchasesAvailable &&
                                  !coinPurchasePending,
                              onBuy: () => onBuyCoins('coins_5000'),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _CoinPackCard(
                              label: 'Champion Chest',
                              coins: 12000,
                              cost: 49,
                              badge: 'Best value',
                              enabled:
                                  coinPurchasesAvailable &&
                                  !coinPurchasePending,
                              onBuy: () => onBuyCoins('coins_12000'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Stable Snapshot',
              subtitle: 'Quick account-at-a-glance',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SummaryPill(
                        label: 'Market listings',
                        value: '$marketCount',
                      ),
                      _SummaryPill(
                        label: 'Pregnancy',
                        value: hasActivePregnancy ? 'Active' : 'Idle',
                      ),
                      _SummaryPill(
                        label: 'Mating bay',
                        value: hasActiveMating ? 'Busy' : 'Ready',
                      ),
                      _SummaryPill(
                        label: 'Collector tier',
                        value: stableCount >= 5 ? 'Growing' : 'Starter',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onCopyStableId,
                      icon: const Icon(Icons.copy_all_rounded),
                      label: const Text('Copy Stable ID'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use your stable ID when contacting support about your account.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Contact & Support',
              subtitle: 'Send feedback, ideas, or problem reports',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContactSupportForm(
                    backendConnected: backendConnected,
                    onSubmit: onSubmitFeedback,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SummaryPill(label: 'Email', value: email),
                      _SummaryPill(
                        label: 'Player ID',
                        value: _compactId(profileId),
                      ),
                      _SummaryPill(
                        label: 'Support',
                        value: backendConnected ? 'Ready' : 'Offline',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Useful Shortcuts',
              subtitle: 'Helpful profile-space reminders',
              compact: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ProfileLine(
                    '1. Keep an eye on your coin balance before shopping the market.',
                  ),
                  _ProfileLine(
                    '2. Use the Breed tab to track 4 day pregnancies, 3 day mare recovery, and 12 hour stallion recovery.',
                  ),
                  _ProfileLine(
                    '3. Watch your stable count as foals mature into your breeding roster.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onSignOut,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0x22FF7A59),
                  foregroundColor: const Color(0xFFFFC9B8),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compactId(String value) {
    if (value.length <= 12) {
      return value;
    }
    return '${value.substring(0, 8)}…${value.substring(value.length - 4)}';
  }
}

class _ContactSupportForm extends StatefulWidget {
  const _ContactSupportForm({
    required this.backendConnected,
    required this.onSubmit,
  });

  final bool backendConnected;
  final Future<void> Function({
    required String category,
    required String message,
  })
  onSubmit;

  @override
  State<_ContactSupportForm> createState() => _ContactSupportFormState();
}

class _ContactSupportFormState extends State<_ContactSupportForm> {
  static const List<String> _categories = [
    'Feedback',
    'Suggestion',
    'Report a Problem',
    'Other',
  ];

  final TextEditingController _messageController = TextEditingController();
  String _category = _categories.first;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < 8) {
      setState(() {
        _errorText = 'Add a little more detail before sending.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(category: _category, message: message);
      if (!mounted) {
        return;
      }
      _messageController.clear();
      setState(() {
        _category = _categories.first;
      });
    } catch (_) {
      // The parent shows the failure snackbar.
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProblemReport = _category == 'Report a Problem';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.backendConnected
              ? 'Send a note without leaving the app. Problem reports include account and stable details automatically so support can help faster.'
              : 'Messages can be written here, but sending needs support to be online.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(
            labelText: 'Type',
            prefixIcon: Icon(Icons.tune_rounded),
          ),
          dropdownColor: AppTheme.surfaceRaised,
          items: _categories
              .map(
                (category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ),
              )
              .toList(),
          onChanged: _isSubmitting
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _category = value;
                  });
                },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageController,
          enabled: !_isSubmitting,
          minLines: 4,
          maxLines: 6,
          maxLength: 600,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: isProblemReport
                ? 'What happened?'
                : 'What should we know?',
            hintText: isProblemReport
                ? 'Describe the issue and what you were doing.'
                : 'Share feedback, a suggestion, or anything else.',
            alignLabelWithHint: true,
            errorText: _errorText,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 72),
              child: Icon(Icons.chat_bubble_outline_rounded),
            ),
          ),
          onChanged: (_) {
            if (_errorText == null) {
              return;
            }
            setState(() {
              _errorText = null;
            });
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isSubmitting ? 'Sending' : 'Send Message'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isProblemReport
              ? 'Problem reports include a support code and recent gameplay snapshot automatically.'
              : 'Messages include your player ID so they are easier to follow up on.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.mutedInk),
        ),
      ],
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPackCard extends StatelessWidget {
  const _CoinPackCard({
    required this.label,
    required this.coins,
    required this.cost,
    required this.enabled,
    required this.onBuy,
    this.badge,
  });

  final String label;
  final int coins;
  final int cost;
  final bool enabled;
  final VoidCallback onBuy;
  final String? badge;

  @override
  Widget build(BuildContext context) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                _CoinPackBadge(label: badge!),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$coins coins',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.tertiary),
          ),
          const SizedBox(height: 4),
          Text(
            '\$$cost.99',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedInk),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: enabled ? onBuy : null,
              child: Text(enabled ? 'Buy Coins' : 'Store Unavailable'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPackBadge extends StatelessWidget {
  const _CoinPackBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedInk,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
