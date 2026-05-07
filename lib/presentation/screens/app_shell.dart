import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../app/theme/app_theme.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/game_state_repository.dart';
import '../../data/repositories/horse_repository.dart';
import '../../data/repositories/inbox_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/support_repository.dart';
import '../../domain/models/breeding_cooldown.dart';
import '../../domain/models/community_listing.dart';
import '../../domain/models/community_profile.dart';
import '../../domain/models/horse.dart';
import '../../domain/models/inbox_item.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/models/local_account.dart';
import '../../domain/models/mating_session.dart';
import '../../domain/models/pregnancy_record.dart';
import '../../logic/services/breeding_preview_service.dart';
import '../../logic/services/game_audio_service.dart';
import '../../logic/services/horse_registry_service.dart';
import '../../logic/services/stable_capacity_service.dart';
import '../widgets/horse_preview.dart';
import '../widgets/horse_trait_chip.dart';
import '../widgets/price_badge.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/section_card.dart';
import 'breed_screen.dart';
import 'explore_screen.dart';
import 'market_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'stable_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.account, required this.onSignOut});

  final LocalAccount account;
  final Future<void> Function() onSignOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  static const Set<String> _coinProductIds = <String>{
    'coins_1100',
    'coins_2500',
    'coins_5000',
    'coins_12000',
  };

  final HorseRepository _horseRepository = const HorseRepository();
  final CommunityRepository _communityRepository = const CommunityRepository();
  final GameStateRepository _gameStateRepository = const GameStateRepository();
  final SettingsRepository _settingsRepository = const SettingsRepository();
  final SupportRepository _supportRepository = const SupportRepository();
  final InboxRepository _inboxRepository = const InboxRepository();
  final BreedingPreviewService _breedingService =
      const BreedingPreviewService();
  final HorseRegistryService _registryService = const HorseRegistryService();
  final GameAudioService _audioService = GameAudioService();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Random _random = Random();
  final Set<String> _serverReservedRegistryIds = <String>{};

  List<CommunityProfile> _communityProfiles = const [];
  List<Horse> _stableHorses = const [];
  List<Horse> _marketHorses = const [];
  List<CommunityListing> _communityListings = const [];
  List<InboxItem> _inboxItems = const [];
  List<PregnancyRecord> _activePregnancies = const [];
  MatingSession? _activeMating;
  Horse? _latestBornFoal;
  Timer? _timelineTicker;
  DateTime _now = DateTime.now();
  int _selectedIndex = 0;
  int _foalSequence = 2000;
  int _marketPurchaseSequence = 5000;
  int _marketInitialTabIndex = 0;
  bool _birthRevealQueued = false;
  int _coinBalance = 7000;
  String? _selectedDamId;
  String? _selectedSireId;
  final Set<String> _likedHorseIds = <String>{};
  final Set<String> _followedProfileIds = <String>{};
  final Map<InventoryItemType, int> _inventory = <InventoryItemType, int>{};
  final Set<String> _prenatalBoostedPregnancyIds = <String>{};
  final Set<String> _carrotBoostedHorseIds = <String>{};
  final Set<String> _readStableAlertIds = <String>{};
  final List<InboxItem> _completedStableAlerts = <InboxItem>[];
  List<BreedingCooldown> _breedingCooldowns = const [];
  int _stableExpansionTier = 0;
  DateTime? _stableExpansionRenewsAt;
  bool _isHydrating = true;
  bool _isResolvingServerMating = false;
  bool _isDeliveringServerPregnancy = false;
  bool _coinPurchasesAvailable = false;
  bool _isPurchasingCoins = false;
  Map<String, ProductDetails> _coinProducts = const {};
  StreamSubscription<List<PurchaseDetails>>? _coinPurchaseSubscription;
  AppSettings _settings = AppSettings.defaults();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _coinPurchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handleCoinPurchaseUpdates,
      onError: (Object error, StackTrace stackTrace) {
        _logErrorEvent(
          source: 'coin_purchase_stream',
          message: 'Coin purchase stream failed.',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    unawaited(_loadCoinProducts());
    unawaited(_restoreSettingsAndStartAudio());
    _restoreGameState();
    _timelineTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isHydrating) {
        return;
      }
      _advanceTimeline(DateTime.now());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistGameState();
    _timelineTicker?.cancel();
    final coinPurchaseSubscription = _coinPurchaseSubscription;
    if (coinPurchaseSubscription != null) {
      unawaited(coinPurchaseSubscription.cancel());
    }
    unawaited(_audioService.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_audioService.pauseBackground());
      _persistGameState();
      unawaited(_syncCommunityStableProjection(showErrors: false));
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_audioService.resumeBackground());
    }
  }

  void _playSound(GameSound sound) {
    if (_settings.hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
    unawaited(_audioService.play(sound));
  }

  Future<void> _restoreSettingsAndStartAudio() async {
    final settings = await _settingsRepository.loadSettings(widget.account.id);
    if (mounted) {
      setState(() {
        _settings = settings;
      });
    } else {
      _settings = settings;
    }
    await _audioService.initialize();
    await _applyAudioSettings(settings);
    await _audioService.startBackground();
  }

  Future<void> _applyAudioSettings(AppSettings settings) {
    return _audioService.configure(
      audioEnabled: settings.audioEnabled,
      effectsEnabled: settings.effectsEnabled,
      backgroundEnabled: settings.backgroundAudioEnabled,
      masterVolume: settings.masterVolume,
      effectsVolume: settings.effectsVolume,
      backgroundVolume: settings.backgroundVolume,
    );
  }

  void _handleSettingsChanged(AppSettings settings) {
    setState(() {
      _settings = settings;
    });
    unawaited(_applyAudioSettings(settings));
    unawaited(_settingsRepository.saveSettings(widget.account.id, settings));
    if (settings.hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _openSettings() {
    _playSound(GameSound.uiClick);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppTheme.scaffoldGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SettingsScreen(
              initialSettings: _settings,
              onSettingsChanged: _handleSettingsChanged,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isHydrating) {
      return Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.secondary),
          ),
        ),
      );
    }

    final stableSlotsRemaining = (_stableHorseCap - _stableHorses.length).clamp(
      0,
      _stableHorseCap,
    );
    final stableAtCapacity = _stableHorses.length >= _stableHorseCap;
    final currentUserProfile = _buildCurrentUserProfile();
    final publicStableHorses = _stableHorses
        .where(
          (horse) =>
              horse.isPublicListing ||
              horse.isFeaturedProfileHorse ||
              horse.isListedForSale,
        )
        .toList();
    final inboxItems = [
      ..._inboxItems.where((item) => item.kind == InboxItemKind.message),
      ..._buildStableAlertItems(_now),
    ];
    final screens = [
      StableScreen(
        stableHorses: _stableHorses,
        activePregnancies: _activePregnancies,
        breedingCooldowns: _breedingCooldowns,
        currentTime: _now,
        inventory: Map<InventoryItemType, int>.from(_inventory),
        stableCap: _stableHorseCap,
        stableCapacityRenewsAt: _stableExpansionRenewsAt,
        prenatalBoostedPregnancyIds: Set<String>.from(
          _prenatalBoostedPregnancyIds,
        ),
        carrotBoostedHorseIds: Set<String>.from(_carrotBoostedHorseIds),
        inboxItems: inboxItems,
        latestBornFoal: _latestBornFoal?.isNewborn == true
            ? _latestBornFoal
            : null,
        stableAtCapacity: stableAtCapacity,
        onOpenMarketItems: _openMarketItems,
        onRenameHorse: _handleRenameHorse,
        onPurgeHorse: _handlePurgeHorse,
        onBirthFoal: _handleBirthFoal,
        onUsePrenatalVitamin: _handleUsePrenatalVitamin,
        onUseCarrot: _handleUseCarrot,
        onMarkInboxItemRead: _handleMarkInboxItemRead,
        onMarkInboxKindRead: _handleMarkInboxKindRead,
        onUpdateHorseVisibility: _handleUpdateHorseVisibility,
        onOpenMarketHorses: _openMarketHorses,
      ),
      BreedScreen(
        stableHorses: _stableHorses,
        marketHorses: _marketHorses,
        activePregnancies: _activePregnancies,
        activeMating: _activeMating,
        currentTime: _now,
        selectedDamId: _selectedDamId,
        selectedSireId: _selectedSireId,
        breedingCooldowns: _breedingCooldowns,
        onSelectDam: _handleSelectDam,
        onSelectSire: _handleSelectSire,
        onConfirmMating: _handleStartMating,
        onAdvanceTime: _advanceBy,
        stableCount: _stableHorses.length,
        stableCap: _stableHorseCap,
        stableAtCapacity: stableAtCapacity,
      ),
      ExploreScreen(
        stableHorses: _stableHorses,
        marketHorses: _marketHorses,
        currentUserProfile: currentUserProfile,
        currentUserPublicHorses: publicStableHorses,
        communityProfiles: _communityProfiles,
        communityListings: _communityListings,
        currentTime: _now,
        likedHorseIds: _likedHorseIds,
        followedProfileIds: _followedProfileIds,
        onToggleHorseLike: _handleToggleHorseLike,
        onToggleProfileFollow: _handleToggleProfileFollow,
        onPurchaseCommunityHorse: _handlePurchaseCommunityHorse,
      ),
      MarketScreen(
        key: ValueKey<int>(_marketInitialTabIndex),
        stableHorses: _stableHorses,
        marketHorses: _marketHorses,
        currentTime: _now,
        coinBalance: _coinBalance,
        onPurchaseHorse: _handlePurchase,
        stableCount: _stableHorses.length,
        stableCap: _stableHorseCap,
        slotsRemaining: stableSlotsRemaining,
        stableExpansionTier: _stableExpansionTier,
        stableCapacityRenewsAt: _stableExpansionRenewsAt,
        initialTabIndex: _marketInitialTabIndex,
        onPurchaseStoreItem: _handlePurchaseStoreItem,
      ),
      ProfileScreen(
        username: widget.account.displayName,
        email: widget.account.email,
        profileId: widget.account.id,
        coinBalance: _coinBalance,
        stableCount: _stableHorses.length,
        marketCount: _marketHorses.length,
        hasActivePregnancy: _activePregnancies.isNotEmpty,
        hasActiveMating: _activeMating != null,
        foalCount: _stableHorses.where((horse) => horse.isFoal).length,
        backendConnected: _supportRepository.isSupabaseAvailable,
        coinPurchasesAvailable:
            _supportRepository.isSupabaseAvailable && _coinPurchasesAvailable,
        coinPurchasePending: _isPurchasingCoins,
        onOpenSettings: _openSettings,
        onBuyCoins: _handleBuyCoins,
        onSubmitFeedback: _handleSubmitFeedback,
        onCopyStableId: _handleCopyStableId,
        onSignOut: widget.onSignOut,
      ),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              left: -40,
              child: _BackdropOrb(
                size: 240,
                colors: [Color(0x55FF5C8A), Color(0x00FF5C8A)],
              ),
            ),
            const Positioned(
              top: 180,
              right: -70,
              child: _BackdropOrb(
                size: 260,
                colors: [Color(0x4059F0E4), Color(0x0059F0E4)],
              ),
            ),
            const Positioned(
              bottom: -120,
              left: 40,
              child: _BackdropOrb(
                size: 280,
                colors: [Color(0x33FFC857), Color(0x00FFC857)],
              ),
            ),
            screens[_selectedIndex],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xCC331D3B), Color(0xE61A111F)],
              ),
              border: Border.all(color: AppTheme.outline),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                if (index != _selectedIndex) {
                  _playSound(GameSound.uiClick);
                }
                setState(() {
                  _selectedIndex = index;
                  if (index == 3) {
                    _marketInitialTabIndex = 0;
                  }
                });
                _persistGameState();
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Stable',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Breed',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: 'Social',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: 'Market',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openMarketItems() {
    _playSound(GameSound.uiClick);
    setState(() {
      _selectedIndex = 3;
      _marketInitialTabIndex = 1;
    });
    _persistGameState();
  }

  void _openMarketHorses() {
    _playSound(GameSound.uiClick);
    setState(() {
      _selectedIndex = 3;
      _marketInitialTabIndex = 0;
    });
    _persistGameState();
  }

  void _handlePurchase(Horse horse, String chosenName, String chosenSex) async {
    if (!_canAddHorseToStable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_stableCapacityMessage)));
      return;
    }

    final purchasePrice = Horse.starterPurchasePrice(
      breed: horse.breed,
      sex: chosenSex,
    );
    if (_coinBalance < purchasePrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need $purchasePrice coins to buy a $chosenSex. Current balance: $_coinBalance coins.',
          ),
        ),
      );
      return;
    }

    _marketPurchaseSequence += 1;
    final registryId = await _reserveHorseRegistryId(
      fallback: _registryService.starterMarketRegistryId(
        ownerId: widget.account.id,
        sequence: _marketPurchaseSequence,
      ),
    );
    if (registryId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A unique horse ID could not be reserved yet. Please try again.',
          ),
        ),
      );
      return;
    }
    final purchasedHorse = horse.copyWith(
      id: 'owned_${horse.id}_$_marketPurchaseSequence',
      registryId: registryId,
      currentName: chosenName,
      sex: chosenSex,
      price: purchasePrice,
      transferCount: horse.transferCount + 1,
    );
    final wasLikedInMarket = _likedHorseIds.contains(horse.id);

    if (!mounted) {
      return;
    }
    setState(() {
      _coinBalance -= purchasePrice;
      _marketHorses = _marketHorses
          .where((marketHorse) => marketHorse.id != horse.id)
          .toList();
      _stableHorses = [..._stableHorses, purchasedHorse];
      if (wasLikedInMarket) {
        _likedHorseIds
          ..remove(horse.id)
          ..add(purchasedHorse.id);
      }
      _syncBreedingSelections();
      _selectedIndex = 3;
    });
    _persistGameState();
    unawaited(_syncCommunityStableProjection());
    _playSound(GameSound.uiClick);
    _logClientEvent(
      eventType: 'horse_purchased',
      message: 'Starter market horse purchased.',
      context: {
        'horse_id': purchasedHorse.id,
        'registry_id': purchasedHorse.registryId,
        'price': purchasePrice,
        'remaining_balance': _coinBalance,
      },
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${purchasedHorse.displayName} joined your stable for $purchasePrice coins. Balance: $_coinBalance coins.',
        ),
      ),
    );
  }

  Future<void> _loadCoinProducts() async {
    late final bool isAvailable;
    try {
      isAvailable = await _inAppPurchase.isAvailable();
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _coinPurchasesAvailable = false;
        _coinProducts = const {};
      });
      _logErrorEvent(
        source: 'coin_products_load',
        message: 'Unable to check StoreKit availability.',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    if (!mounted) {
      return;
    }
    if (!isAvailable) {
      setState(() {
        _coinPurchasesAvailable = false;
        _coinProducts = const {};
      });
      _logClientEvent(
        eventType: 'coin_products_unavailable',
        status: 'warning',
        message: 'StoreKit coin products are unavailable.',
      );
      return;
    }

    late final ProductDetailsResponse response;
    try {
      response = await _inAppPurchase.queryProductDetails(_coinProductIds);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() {
        _coinPurchasesAvailable = false;
        _coinProducts = const {};
      });
      _logErrorEvent(
        source: 'coin_products_load',
        message: 'Unable to load StoreKit coin products.',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    if (!mounted) {
      return;
    }
    final products = {
      for (final product in response.productDetails) product.id: product,
    };
    setState(() {
      _coinProducts = products;
      _coinPurchasesAvailable =
          products.length == _coinProductIds.length && response.error == null;
    });

    if (response.error != null || response.notFoundIDs.isNotEmpty) {
      _logClientEvent(
        eventType: 'coin_products_load_warning',
        status: 'warning',
        message: 'Some StoreKit coin products could not be loaded.',
        context: {
          'not_found_ids': response.notFoundIDs,
          'error': response.error?.message,
        },
      );
    }
  }

  Future<void> _handleBuyCoins(String productId) async {
    if (!_supportRepository.isSupabaseAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coin purchases need Supabase to be online.'),
        ),
      );
      return;
    }

    if (_isPurchasingCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A coin purchase is already pending.')),
      );
      return;
    }

    var product = _coinProducts[productId];
    if (!_coinPurchasesAvailable || product == null) {
      await _loadCoinProducts();
      if (!mounted) {
        return;
      }
      product = _coinProducts[productId];
    }

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Coin packs are not available yet. Confirm the products are active in App Store Connect.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPurchasingCoins = true;
    });

    final started = await _inAppPurchase.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!mounted) {
      return;
    }
    if (!started) {
      setState(() {
        _isPurchasingCoins = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The coin purchase could not start.')),
      );
    }
  }

  Future<void> _handleCoinPurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      if (!_coinProductIds.contains(purchase.productID)) {
        continue;
      }

      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) {
          setState(() {
            _isPurchasingCoins = true;
          });
        }
        continue;
      }

      try {
        if (purchase.status == PurchaseStatus.error) {
          _logClientEvent(
            eventType: 'coin_purchase_failed',
            status: 'error',
            message: purchase.error?.message ?? 'Coin purchase failed.',
            context: {
              'product_id': purchase.productID,
              'purchase_id': purchase.purchaseID,
              'error_code': purchase.error?.code,
            },
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  purchase.error?.message ?? 'Coin purchase failed.',
                ),
              ),
            );
          }
        } else if (purchase.status == PurchaseStatus.canceled) {
          _logClientEvent(
            eventType: 'coin_purchase_canceled',
            message: 'Coin purchase was canceled.',
            context: {'product_id': purchase.productID},
          );
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _verifyAndDeliverCoinPurchase(purchase);
        }
      } catch (error, stackTrace) {
        _logErrorEvent(
          source: 'coin_purchase_verification',
          message: 'Coin purchase verification failed.',
          error: error,
          stackTrace: stackTrace,
          context: {
            'product_id': purchase.productID,
            'purchase_id': purchase.purchaseID,
            'status': purchase.status.name,
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Coin purchase could not be verified. Please contact support if you were charged.',
              ),
            ),
          );
        }
      } finally {
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
        if (mounted) {
          setState(() {
            _isPurchasingCoins = false;
          });
        }
      }
    }
  }

  Future<void> _verifyAndDeliverCoinPurchase(PurchaseDetails purchase) async {
    final transactionId = purchase.purchaseID;
    if (transactionId == null || transactionId.isEmpty) {
      throw StateError('Coin purchase is missing a transaction id.');
    }

    final result = await _supportRepository.verifyCoinPurchase(
      productId: purchase.productID,
      transactionId: transactionId,
      source: purchase.verificationData.source,
      serverVerificationData: purchase.verificationData.serverVerificationData,
      localVerificationData: purchase.verificationData.localVerificationData,
    );

    if (result == null) {
      throw StateError('Coin purchase verification did not return a result.');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _coinBalance = result.coinBalance;
      _selectedIndex = 4;
    });
    _persistGameState();
    unawaited(_syncCommunityStableProjection(refreshSnapshot: false));
    _playSound(GameSound.uiClick);
    _logClientEvent(
      eventType: 'coins_purchased',
      message: 'Verified coin pack purchased.',
      context: {
        'amount': result.coinAmount,
        'new_balance': result.coinBalance,
        'product_id': purchase.productID,
        'transaction_id': transactionId,
        'already_processed': result.alreadyProcessed,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.alreadyProcessed
              ? 'This coin purchase was already added. Balance: ${result.coinBalance} coins.'
              : 'Purchased ${result.coinAmount} coins. Balance: ${result.coinBalance} coins.',
        ),
      ),
    );
  }

  void _handlePurchaseStoreItem(StoreItem item) {
    if (item.isExpansion) {
      final tier = item.expansionTier!;
      if (tier < _stableExpansionTier) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A higher stable tier is already active.'),
          ),
        );
        return;
      }
      if (tier > _stableExpansionTier + 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buy stable expansion tiers in order.')),
        );
        return;
      }
    }

    if (_coinBalance < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need ${item.price} coins for ${item.title}. Current balance: $_coinBalance coins.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _coinBalance -= item.price;
      if (item.isExpansion) {
        _stableExpansionTier = item.expansionTier!;
        _stableExpansionRenewsAt = _now.add(const Duration(days: 30));
      } else if (item.type != null) {
        _inventory[item.type!] = (_inventory[item.type!] ?? 0) + item.quantity;
      }
    });
    _persistGameState();
    _playSound(GameSound.uiClick);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isExpansion
              ? '${item.title} active through ${_formatShortDate(_stableExpansionRenewsAt!)}. Stable capacity is now $_stableHorseCap horses.'
              : '${item.title} added to inventory. Balance: $_coinBalance coins.',
        ),
      ),
    );
  }

  void _handleUsePrenatalVitamin(PregnancyRecord pregnancy) {
    final available = _inventory[InventoryItemType.prenatalVitamin] ?? 0;
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buy prenatal vitamins first.')),
      );
      return;
    }
    if (_prenatalBoostedPregnancyIds.contains(pregnancy.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This pregnancy already received a prenatal vitamin.'),
        ),
      );
      return;
    }
    final remaining = pregnancy.dueAt.difference(_now);
    if (remaining <= Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That foal is already ready for birth.')),
      );
      return;
    }

    final boostedPregnancy = PregnancyRecord(
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
      dueAt: _now.add(Duration(seconds: remaining.inSeconds ~/ 2)),
      damCooldownEndsAt: pregnancy.damCooldownEndsAt,
      sireCooldownEndsAt: pregnancy.sireCooldownEndsAt,
      isMutant: pregnancy.isMutant,
    );

    setState(() {
      _inventory[InventoryItemType.prenatalVitamin] = available - 1;
      if (_inventory[InventoryItemType.prenatalVitamin] == 0) {
        _inventory.remove(InventoryItemType.prenatalVitamin);
      }
      _prenatalBoostedPregnancyIds.add(pregnancy.id);
      _activePregnancies = _activePregnancies
          .map(
            (record) => record.id == pregnancy.id ? boostedPregnancy : record,
          )
          .toList();
    });
    _persistGameState();
    _playSound(GameSound.uiClick);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${pregnancy.unbornFoalName} received a prenatal vitamin. Birth timer cut in half.',
        ),
      ),
    );
  }

  void _handleUseCarrot(BreedingCooldown cooldown) {
    final available = _inventory[InventoryItemType.carrot] ?? 0;
    if (available <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Buy carrots first.')));
      return;
    }
    if (cooldown.reason == 'Healing' || cooldown.sex != 'Stallion') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carrots can only boost stallion recovery cooldowns.'),
        ),
      );
      return;
    }
    if (_carrotBoostedHorseIds.contains(cooldown.horseId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This stallion already had a carrot this cooldown.'),
        ),
      );
      return;
    }
    final remaining = cooldown.endsAt.difference(_now);
    if (remaining <= Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That cooldown is already finished.')),
      );
      return;
    }

    final boostedCooldown = BreedingCooldown(
      horseId: cooldown.horseId,
      horseName: cooldown.horseName,
      sex: cooldown.sex,
      reason: cooldown.reason,
      endsAt: _now.add(Duration(seconds: remaining.inSeconds ~/ 2)),
    );

    setState(() {
      _inventory[InventoryItemType.carrot] = available - 1;
      if (_inventory[InventoryItemType.carrot] == 0) {
        _inventory.remove(InventoryItemType.carrot);
      }
      _carrotBoostedHorseIds.add(cooldown.horseId);
      _breedingCooldowns = _breedingCooldowns
          .map(
            (record) =>
                record.horseId == cooldown.horseId ? boostedCooldown : record,
          )
          .toList();
    });
    _persistGameState();
    _playSound(GameSound.uiClick);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${cooldown.horseName} ate a carrot. Stallion cooldown cut in half.',
        ),
      ),
    );
  }

  void _handleMarkInboxItemRead(InboxItem item) {
    if (!item.isUnread) {
      return;
    }
    if (_isStableAlert(item)) {
      setState(() {
        _readStableAlertIds.add(item.id);
        for (var index = 0; index < _completedStableAlerts.length; index += 1) {
          if (_completedStableAlerts[index].id == item.id) {
            _completedStableAlerts[index] = _completedStableAlerts[index]
                .copyWith(readAt: DateTime.now());
          }
        }
      });
      _persistGameState();
      return;
    }
    final readAt = DateTime.now();
    setState(() {
      _inboxItems = _inboxItems
          .map(
            (candidate) => candidate.id == item.id
                ? candidate.copyWith(readAt: readAt)
                : candidate,
          )
          .toList();
    });
    unawaited(
      _inboxRepository.markRead(
        ownerId: widget.account.id,
        itemId: item.id,
        readAt: readAt,
      ),
    );
  }

  void _handleMarkInboxKindRead(InboxItemKind kind) {
    final readAt = DateTime.now();
    var changed = false;
    setState(() {
      if (kind == InboxItemKind.notification) {
        for (final item in _buildStableAlertItems(readAt)) {
          if (item.isUnread) {
            _readStableAlertIds.add(item.id);
            changed = true;
          }
        }
        for (var index = 0; index < _completedStableAlerts.length; index += 1) {
          final item = _completedStableAlerts[index];
          if (item.isUnread) {
            _readStableAlertIds.add(item.id);
            _completedStableAlerts[index] = item.copyWith(readAt: readAt);
            changed = true;
          }
        }
      }
      _inboxItems = _inboxItems.map((item) {
        if (item.kind != kind || !item.isUnread) {
          return item;
        }
        changed = true;
        return item.copyWith(readAt: readAt);
      }).toList();
    });
    if (!changed) {
      return;
    }
    _persistGameState();
    unawaited(
      _inboxRepository.markAllRead(
        ownerId: widget.account.id,
        kind: kind,
        readAt: readAt,
      ),
    );
  }

  bool _isStableAlert(InboxItem item) {
    return item.kind == InboxItemKind.notification &&
        item.actionPayload['source'] == 'stable_alert';
  }

  List<InboxItem> _buildStableAlertItems(DateTime asOf) {
    final alerts = <InboxItem>[
      ..._completedStableAlerts.where(_isEnabledStableAlert),
      if (_activeMating case final mating?)
        if (_settings.breedingTimerAlerts &&
            mating.endsAt.isAfter(asOf) &&
            mating.endsAt.difference(asOf) <= const Duration(minutes: 30))
          _stableAlert(
            id: 'stable_alert_mating_${mating.id}_soon',
            title: 'Breeding timer ending soon',
            body:
                'Your current pairing has ${_compactDuration(mating.endsAt.difference(asOf))} left.',
            category: 'Breeding',
            createdAt: asOf,
            alertType: 'breeding_timer',
          ),
      for (final pregnancy in _activePregnancies)
        if (!pregnancy.dueAt.isAfter(asOf) && _settings.birthReadyAlerts)
          _stableAlert(
            id: 'stable_alert_pregnancy_${pregnancy.id}_ready',
            title: 'Foal waiting to be born',
            body:
                '${pregnancy.unbornFoalName} is ready. Open Stable to welcome the foal.',
            category: 'Foal ready',
            createdAt: pregnancy.dueAt,
            alertType: 'birth_ready',
          )
        else if (_settings.pregnancyDueSoonAlerts &&
            pregnancy.dueAt.difference(asOf) <= const Duration(hours: 12))
          _stableAlert(
            id: 'stable_alert_pregnancy_${pregnancy.id}_soon',
            title: 'Birth timer ending soon',
            body:
                '${pregnancy.unbornFoalName} is due in ${_compactDuration(pregnancy.dueAt.difference(asOf))}.',
            category: 'Pregnancy',
            createdAt: asOf,
            alertType: 'pregnancy_due_soon',
          ),
      for (final cooldown in _breedingCooldowns)
        if (cooldown.isActiveAt(asOf) &&
            (cooldown.reason == 'Healing'
                ? _settings.healingCompleteAlerts
                : _settings.recoveryCompleteAlerts) &&
            cooldown.endsAt.difference(asOf) <= const Duration(hours: 12))
          _stableAlert(
            id: 'stable_alert_cooldown_${cooldown.horseId}_${cooldown.endsAt.millisecondsSinceEpoch}_soon',
            title: cooldown.reason == 'Healing'
                ? 'Mare healing almost complete'
                : 'Recovery almost complete',
            body:
                '${cooldown.horseName} has ${_compactDuration(cooldown.endsAt.difference(asOf))} left.',
            category: cooldown.reason == 'Healing' ? 'Healing' : 'Recovery',
            createdAt: asOf,
            alertType: cooldown.reason == 'Healing'
                ? 'healing_complete'
                : 'recovery_complete',
          ),
    ];

    alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return alerts;
  }

  InboxItem _stableAlert({
    required String id,
    required String title,
    required String body,
    required String category,
    required DateTime createdAt,
    required String alertType,
  }) {
    final readAt = _readStableAlertIds.contains(id) ? createdAt : null;
    return InboxItem(
      id: id,
      ownerId: widget.account.id,
      kind: InboxItemKind.notification,
      title: title,
      body: body,
      category: category,
      createdAt: createdAt,
      readAt: readAt,
      actionPayload: {'source': 'stable_alert', 'alert_type': alertType},
    );
  }

  bool _isEnabledStableAlert(InboxItem item) {
    return _isStableAlertTypeEnabled(
      item.actionPayload['alert_type'] as String?,
    );
  }

  bool _isStableAlertTypeEnabled(String? alertType) {
    return switch (alertType) {
      'breeding_timer' => _settings.breedingTimerAlerts,
      'birth_ready' => _settings.birthReadyAlerts,
      'pregnancy_due_soon' => _settings.pregnancyDueSoonAlerts,
      'healing_complete' => _settings.healingCompleteAlerts,
      'recovery_complete' => _settings.recoveryCompleteAlerts,
      _ => true,
    };
  }

  String _compactDuration(Duration duration) {
    if (duration <= Duration.zero) {
      return '0m';
    }
    if (duration.inDays > 0) {
      final hours = duration.inHours % 24;
      return hours == 0
          ? '${duration.inDays}d'
          : '${duration.inDays}d ${hours}h';
    }
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      return minutes == 0
          ? '${duration.inHours}h'
          : '${duration.inHours}h ${minutes}m';
    }
    return '${duration.inMinutes.clamp(1, 59)}m';
  }

  void _handleStartMating(Horse dam, Horse sire) async {
    if (_activeMating != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Finish the current mating timer before starting another pairing.',
          ),
        ),
      );
      return;
    }

    final damAlreadyPregnant = _activePregnancies.any(
      (pregnancy) => pregnancy.damId == dam.id,
    );
    if (damAlreadyPregnant) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${dam.displayName} is already pregnant and cannot breed again until after birth.',
          ),
        ),
      );
      return;
    }

    final damCooldown = _breedingCooldowns.where(
      (cooldown) => cooldown.horseId == dam.id && cooldown.isActiveAt(_now),
    );
    final sireCooldown = _breedingCooldowns.where(
      (cooldown) => cooldown.horseId == sire.id && cooldown.isActiveAt(_now),
    );
    if (!dam.isBreedingReady ||
        !sire.isBreedingReady ||
        dam.isRetired ||
        sire.isRetired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Both selected horses must be breed-ready and not retired.',
          ),
        ),
      );
      return;
    }
    if (damCooldown.isNotEmpty || sireCooldown.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'One of the selected horses is still cooling down from breeding.',
          ),
        ),
      );
      return;
    }

    MatingSession? mating;
    if (_communityRepository.isSupabaseAvailable) {
      final nextSequence = _nextAvailableFoalSequence(dam.breed);
      final registryId = await _reserveHorseRegistryId(
        fallback: _registryService.foalRegistryId(
          breed: dam.breed,
          ownerId: widget.account.id,
          sequence: nextSequence,
        ),
      );
      if (registryId == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A unique foal ID could not be reserved yet. Please try again.',
            ),
          ),
        );
        return;
      }
      try {
        final stableSynced = await _syncCommunityStableProjection(
          showErrors: true,
          refreshSnapshot: false,
        );
        if (!stableSynced) {
          return;
        }
        final syncedDam = _stableHorses.firstWhere(
          (horse) => horse.id == dam.id,
          orElse: () => dam,
        );
        final syncedSire = _stableHorses.firstWhere(
          (horse) => horse.id == sire.id,
          orElse: () => sire,
        );
        final standardPregnancy = _breedingService.createPregnancy(
          dam: syncedDam,
          sire: syncedSire,
          now: _now,
          random: Random(_now.microsecondsSinceEpoch ^ nextSequence),
          sequence: nextSequence,
          isMutant: false,
          registryId: registryId,
        );
        final mutantPregnancy = _breedingService.createPregnancy(
          dam: syncedDam,
          sire: syncedSire,
          now: _now,
          random: Random(
            (_now.microsecondsSinceEpoch >> 2) ^ (nextSequence * 31),
          ),
          sequence: nextSequence,
          isMutant: true,
          registryId: registryId,
        );
        mating = await _communityRepository.startMatingSession(
          dam: syncedDam,
          sire: syncedSire,
          standardPregnancy: standardPregnancy,
          mutantPregnancy: mutantPregnancy,
        );
        _foalSequence = nextSequence;
      } catch (error, stackTrace) {
        _logErrorEvent(
          source: 'start_mating_session',
          message: 'This pairing could not be started on the server.',
          error: error,
          stackTrace: stackTrace,
          context: {'dam_id': dam.id, 'sire_id': sire.id},
        );
        if (!mounted) {
          return;
        }
        final message = _breedingStartFailureMessage(error);
        if (message ==
            'Finish the current mating timer before starting another pairing.') {
          await _refreshOwnedStateFromServer();
        }
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
    } else {
      mating = _createLocalMatingSession(dam, sire);
    }

    if (mating == null) {
      return;
    }

    setState(() {
      _activeMating = mating;
    });
    _persistGameState();
    _playSound(GameSound.breedingStart);
    _logClientEvent(
      eventType: 'mating_started',
      message: 'Breeding timer started.',
      context: {
        'dam_id': dam.id,
        'dam_name': dam.displayName,
        'sire_id': sire.id,
        'sire_name': sire.displayName,
        'mating_id': mating.id,
      },
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${dam.displayName} and ${sire.displayName} started mating. The outcome will appear as soon as the pairing timer resolves.',
        ),
      ),
    );
  }

  MatingSession _createLocalMatingSession(Horse dam, Horse sire) {
    return MatingSession(
      id: 'local_mating_${dam.id}_${sire.id}_${_now.millisecondsSinceEpoch}',
      damId: dam.id,
      damName: dam.displayName,
      sireId: sire.id,
      sireName: sire.displayName,
      startedAt: _now,
      endsAt: _now.add(const Duration(seconds: 5)),
    );
  }

  bool _isLocalMatingSession(MatingSession mating) {
    return mating.id.startsWith('local_mating_');
  }

  bool _isLocalPregnancyRecord(PregnancyRecord pregnancy) {
    return pregnancy.id.startsWith('pregnancy_');
  }

  String _breedingStartFailureMessage(Object error) {
    final errorText = error.toString();
    const serverMessages = <String, String>{
      'Dam not found in your stable':
          'The mare is not synced to your online stable yet. Try again after sync finishes.',
      'Sire not found in your stable':
          'The stallion is not synced to your online stable yet. Try again after sync finishes.',
      'There is already an active mating session':
          'Finish the current mating timer before starting another pairing.',
      'Dam is already pregnant':
          'This mare is already pregnant and cannot breed again until after birth.',
      'One of the selected horses is still on cooldown':
          'One of the selected horses is still cooling down from breeding.',
    };
    for (final entry in serverMessages.entries) {
      if (errorText.contains(entry.key)) {
        return entry.value;
      }
    }
    if (errorText.contains('horses_registry_id_key') ||
        errorText.contains('duplicate key')) {
      return 'That horse ID is already used on the server. Sync needs a fresh unique PH number before breeding can start.';
    }
    return 'This pairing could not be started on the server yet. Please try again.';
  }

  void _handleSelectDam(Horse dam) {
    setState(() {
      _selectedDamId = dam.id;
    });
    _persistGameState();
    _playSound(GameSound.uiClick);
  }

  void _handleSelectSire(Horse sire) {
    setState(() {
      _selectedSireId = sire.id;
    });
    _persistGameState();
    _playSound(GameSound.uiClick);
  }

  void _handleToggleHorseLike(Horse horse) async {
    final shouldLike = !_likedHorseIds.contains(horse.id);
    setState(() {
      if (!shouldLike) {
        _likedHorseIds.remove(horse.id);
      } else {
        _likedHorseIds.add(horse.id);
      }
    });
    _persistGameState();
    _playSound(GameSound.uiClick);
    try {
      await _communityRepository.toggleHorseLike(
        profileId: widget.account.id,
        horse: horse,
        shouldLike: shouldLike,
      );
    } catch (error, stackTrace) {
      _logErrorEvent(
        source: 'toggle_horse_like',
        message: 'The server could not update the liked horse state.',
        error: error,
        stackTrace: stackTrace,
        context: {'horse_id': horse.id, 'should_like': shouldLike},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (shouldLike) {
          _likedHorseIds.remove(horse.id);
        } else {
          _likedHorseIds.add(horse.id);
        }
      });
      _persistGameState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update that like right now.')),
      );
    }
  }

  void _handleToggleProfileFollow(CommunityProfile profile) async {
    final shouldFollow = !_followedProfileIds.contains(profile.id);
    setState(() {
      if (!shouldFollow) {
        _followedProfileIds.remove(profile.id);
      } else {
        _followedProfileIds.add(profile.id);
      }
    });
    _persistGameState();
    _playSound(GameSound.uiClick);
    try {
      await _communityRepository.toggleFollow(
        followerId: widget.account.id,
        followeeId: profile.id,
        shouldFollow: shouldFollow,
      );
      await _refreshCommunitySnapshot();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (shouldFollow) {
          _followedProfileIds.remove(profile.id);
        } else {
          _followedProfileIds.add(profile.id);
        }
      });
      _persistGameState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update that follow right now.'),
        ),
      );
    }
  }

  void _handlePurchaseCommunityHorse(CommunityListing listing) async {
    if (listing.sellerProfileId == widget.account.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That is your own listing. Update it from Stable instead of buying it.',
          ),
        ),
      );
      return;
    }

    if (!_canAddHorseToStable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_stableCapacityMessage)));
      return;
    }

    final purchasePrice = listing.horse.playerSalePrice;
    if (_coinBalance < purchasePrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need $purchasePrice coins to buy ${listing.horse.displayName}. Current balance: $_coinBalance coins.',
          ),
        ),
      );
      return;
    }

    CommunityPurchaseResult? purchaseResult;
    try {
      purchaseResult = await _communityRepository.purchaseListing(
        listingId: listing.id,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This live sale could not be completed yet. Refresh and try again.',
          ),
        ),
      );
      return;
    }

    _marketPurchaseSequence += 1;
    final purchasedHorse = listing.horse.copyWith(
      id: 'owned_${listing.horse.id}_$_marketPurchaseSequence',
      transferCount: listing.horse.transferCount + 1,
      isListedForSale: false,
      isPublicListing: false,
      isFeaturedProfileHorse: false,
    );

    final nextCoinBalance =
        purchaseResult?.buyerCoinBalance ?? (_coinBalance - purchasePrice);
    setState(() {
      _coinBalance = nextCoinBalance;
      _communityListings = _communityListings
          .where((entry) => entry.id != listing.id)
          .toList();
      _stableHorses = [..._stableHorses, purchasedHorse];
      _likedHorseIds.remove(listing.horse.id);
      _syncBreedingSelections();
    });
    _persistGameState();
    await _syncCommunityStableProjection(showErrors: false);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${purchasedHorse.displayName} was bought from ${listing.sellerName} for $purchasePrice coins.',
        ),
      ),
    );
  }

  String? _validateHorseListingEligibility(Horse horse) {
    final isPregnant = _activePregnancies.any(
      (pregnancy) => pregnancy.damId == horse.id,
    );
    final isInActiveMating =
        _activeMating?.damId == horse.id || _activeMating?.sireId == horse.id;
    final hasCooldown = _breedingCooldowns.any(
      (cooldown) => cooldown.horseId == horse.id && cooldown.isActiveAt(_now),
    );
    if (isPregnant) {
      return '${horse.displayName} cannot be listed while pregnant.';
    }
    if (isInActiveMating) {
      return '${horse.displayName} cannot be listed during an active mating.';
    }
    if (hasCooldown) {
      return '${horse.displayName} cannot be listed while on breeding cooldown.';
    }
    return null;
  }

  String? _handleUpdateHorseVisibility(
    Horse horse, {
    bool? isPublicListing,
    bool? isFeaturedProfileHorse,
    bool? isListedForSale,
  }) {
    final currentHorse = _stableHorses.cast<Horse?>().firstWhere(
      (entry) => entry?.id == horse.id,
      orElse: () => null,
    );
    if (currentHorse == null) {
      return 'Horse not found in stable.';
    }

    final nextListedForSale = isListedForSale ?? currentHorse.isListedForSale;
    if (nextListedForSale) {
      final listingError = _validateHorseListingEligibility(currentHorse);
      if (listingError != null) {
        return listingError;
      }
    }

    final nextFeatured =
        isFeaturedProfileHorse ?? currentHorse.isFeaturedProfileHorse;
    final nextPublic = nextListedForSale
        ? true
        : nextFeatured
        ? true
        : (isPublicListing ?? currentHorse.isPublicListing);
    final updatedHorse = currentHorse.copyWith(
      isPublicListing: nextPublic,
      isFeaturedProfileHorse: nextPublic ? nextFeatured : false,
      isListedForSale: nextPublic ? nextListedForSale : false,
    );

    setState(() {
      _stableHorses = _stableHorses
          .map((entry) => entry.id == updatedHorse.id ? updatedHorse : entry)
          .toList();
      _communityListings = [
        ..._communityListings.where(
          (listing) => listing.horse.id != updatedHorse.id,
        ),
        if (updatedHorse.isListedForSale)
          CommunityListing(
            id: 'listing_${updatedHorse.id}',
            sellerProfileId: widget.account.id,
            sellerName: widget.account.displayName,
            sellerHandle: _accountHandle,
            sellerStableName: '${widget.account.displayName} Stable',
            horse: updatedHorse,
            sellerPayout: updatedHorse.sellerListingPayout,
          ),
      ];
    });
    _persistGameState();
    unawaited(_syncCommunityStableProjection());
    return null;
  }

  void _handlePurgeHorse(Horse horse) {
    final isInActivePregnancy = _activePregnancies.any(
      (pregnancy) =>
          pregnancy.damId == horse.id || pregnancy.sireId == horse.id,
    );
    final isInActiveMating =
        _activeMating?.damId == horse.id || _activeMating?.sireId == horse.id;

    if (isInActivePregnancy || isInActiveMating) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${horse.displayName} is tied to an active breeding flow and cannot be purged right now.',
          ),
        ),
      );
      return;
    }

    final matchingHorse = _stableHorses.cast<Horse?>().firstWhere(
      (item) => item?.id == horse.id,
      orElse: () => null,
    );
    if (matchingHorse == null) {
      return;
    }

    final payout = matchingHorse.purgePayout;
    setState(() {
      _stableHorses = _stableHorses
          .where((stableHorse) => stableHorse.id != matchingHorse.id)
          .toList();
      _communityListings = _communityListings
          .where((listing) => listing.horse.id != matchingHorse.id)
          .toList();
      _likedHorseIds.remove(matchingHorse.id);
      _breedingCooldowns = _breedingCooldowns
          .where((cooldown) => cooldown.horseId != matchingHorse.id)
          .toList();
      if (_latestBornFoal?.id == matchingHorse.id) {
        _latestBornFoal = null;
      }
      _coinBalance += payout;
      _syncBreedingSelections();
      _selectedIndex = 0;
    });
    _persistGameState();
    unawaited(_syncCommunityStableProjection());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Purged ${matchingHorse.displayName} for $payout coins. New balance: $_coinBalance coins.',
        ),
      ),
    );
  }

  void _handleRenameHorse(Horse horse, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final matchingHorse = _stableHorses.cast<Horse?>().firstWhere(
      (item) => item?.id == horse.id,
      orElse: () => null,
    );
    if (matchingHorse == null || matchingHorse.currentName == trimmed) {
      return;
    }

    final renamedHorse = matchingHorse.copyWith(currentName: trimmed);
    setState(() {
      _stableHorses = _stableHorses
          .map(
            (stableHorse) =>
                stableHorse.id == renamedHorse.id ? renamedHorse : stableHorse,
          )
          .toList();
      _communityListings = _communityListings
          .map(
            (listing) => listing.horse.id == renamedHorse.id
                ? listing.copyWith(horse: renamedHorse)
                : listing,
          )
          .toList();
      if (_latestBornFoal?.id == renamedHorse.id) {
        _latestBornFoal = renamedHorse;
      }
    });
    _persistGameState();
    unawaited(_syncCommunityStableProjection());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Renamed ${matchingHorse.displayName} to ${renamedHorse.displayName}. Registry ID ${renamedHorse.registryId} stayed the same.',
        ),
      ),
    );
  }

  void _syncBreedingSelections() {
    final mares = _stableHorses.where((horse) => horse.sex == 'Mare').toList();
    final stallions = _stableHorses
        .where((horse) => horse.sex == 'Stallion')
        .toList();

    if (mares.isNotEmpty) {
      final hasSelectedDam = mares.any((horse) => horse.id == _selectedDamId);
      _selectedDamId = hasSelectedDam ? _selectedDamId : mares.first.id;
    } else {
      _selectedDamId = null;
    }

    if (stallions.isNotEmpty) {
      final hasSelectedSire = stallions.any(
        (horse) => horse.id == _selectedSireId,
      );
      _selectedSireId = hasSelectedSire ? _selectedSireId : stallions.first.id;
    } else {
      _selectedSireId = null;
    }
  }

  void _advanceBy(Duration delta) {
    _advanceTimeline(_now.add(delta));
    _persistGameState();
  }

  void _advanceTimeline(DateTime targetTime) {
    if (!targetTime.isAfter(_now)) {
      return;
    }

    var cursor = _now;
    while (true) {
      DateTime? nextEvent;
      if (_activeMating != null) {
        nextEvent = _activeMating!.endsAt;
      }

      if (nextEvent == null || nextEvent.isAfter(targetTime)) {
        break;
      }

      _ageHorseCollections(nextEvent.difference(cursor).inDays);
      cursor = nextEvent;
      if (_activeMating != null && !_activeMating!.endsAt.isAfter(cursor)) {
        if (_communityRepository.isSupabaseAvailable) {
          break;
        }
        _resolveMatingOutcome(cursor);
        continue;
      }
    }

    _ageHorseCollections(targetTime.difference(cursor).inDays);
    _captureCompletedCooldownAlerts(targetTime);

    setState(() {
      _breedingCooldowns = _breedingCooldowns
          .where((cooldown) => cooldown.isActiveAt(targetTime))
          .toList();
      _now = targetTime;
    });
    _enforceStableExpansionRenewal(targetTime);
    _syncOverdueMareRecoveryCooldowns(targetTime);
    if (_communityRepository.isSupabaseAvailable &&
        _activeMating != null &&
        !_activeMating!.endsAt.isAfter(targetTime)) {
      unawaited(_resolveServerMatingOutcome());
    }
  }

  void _ageHorseCollections(int days) {
    if (days <= 0) {
      return;
    }

    _stableHorses = _stableHorses
        .map((horse) => horse.copyWith(ageDays: horse.ageDays + days))
        .toList();
    _marketHorses = _marketHorses
        .map((horse) => horse.copyWith(ageDays: horse.ageDays + days))
        .toList();
    final updatedNow = _now.add(Duration(days: days));
    _captureCompletedCooldownAlerts(updatedNow);
    _breedingCooldowns = _breedingCooldowns
        .where((cooldown) => cooldown.isActiveAt(updatedNow))
        .toList();
    _carrotBoostedHorseIds.removeWhere(
      (horseId) =>
          !_breedingCooldowns.any((cooldown) => cooldown.horseId == horseId),
    );
    _prenatalBoostedPregnancyIds.removeWhere(
      (pregnancyId) =>
          !_activePregnancies.any((pregnancy) => pregnancy.id == pregnancyId),
    );
    if (_latestBornFoal != null) {
      _latestBornFoal = _stableHorses.firstWhere(
        (horse) => horse.id == _latestBornFoal!.id,
        orElse: () => _latestBornFoal!,
      );
    }
  }

  void _captureCompletedCooldownAlerts(DateTime asOf) {
    final completedCooldowns = _breedingCooldowns
        .where((cooldown) => !cooldown.isActiveAt(asOf))
        .toList();
    for (final cooldown in completedCooldowns) {
      if (cooldown.reason == 'Healing' && !_settings.healingCompleteAlerts) {
        continue;
      }
      if (cooldown.reason != 'Healing' && !_settings.recoveryCompleteAlerts) {
        continue;
      }
      final id =
          'stable_alert_cooldown_${cooldown.horseId}_${cooldown.endsAt.millisecondsSinceEpoch}_done';
      if (_completedStableAlerts.any((item) => item.id == id)) {
        continue;
      }
      _completedStableAlerts.add(
        _stableAlert(
          id: id,
          title: cooldown.reason == 'Healing'
              ? 'Mare healing complete'
              : 'Recovery complete',
          body: '${cooldown.horseName} is ready again.',
          category: cooldown.reason == 'Healing' ? 'Healing' : 'Recovery',
          createdAt: cooldown.endsAt,
          alertType: cooldown.reason == 'Healing'
              ? 'healing_complete'
              : 'recovery_complete',
        ),
      );
    }
    if (completedCooldowns.isNotEmpty) {
      _persistGameState();
    }
  }

  void _resolveMatingOutcome(DateTime resolvedAt) {
    final activeMating = _activeMating;
    if (activeMating == null) {
      return;
    }

    final dam = _stableHorses.firstWhere(
      (horse) => horse.id == activeMating.damId,
    );
    final sire = _stableHorses.firstWhere(
      (horse) => horse.id == activeMating.sireId,
    );
    final roll = _random.nextInt(100);
    final isStandard = roll < 80;
    final isMutant = roll >= 80 && roll < 90;
    final sireCooldown = BreedingCooldown(
      horseId: sire.id,
      horseName: sire.displayName,
      sex: sire.sex,
      reason: 'Sire recovery',
      endsAt: resolvedAt.add(BreedingPreviewService.sireCooldownDuration),
    );

    if (isStandard || isMutant) {
      _foalSequence = _nextAvailableFoalSequence(dam.breed);
      final registryId = _registryService.foalRegistryId(
        breed: dam.breed,
        ownerId: widget.account.id,
        sequence: _foalSequence,
      );
      final pregnancy = _breedingService.createPregnancy(
        dam: dam,
        sire: sire,
        now: resolvedAt,
        random: _random,
        sequence: _foalSequence,
        isMutant: isMutant,
        registryId: registryId,
      );

      setState(() {
        _activeMating = null;
        _activePregnancies = [..._activePregnancies, pregnancy];
        _breedingCooldowns = [
          ..._breedingCooldowns.where(
            (cooldown) => cooldown.horseId != sire.id,
          ),
          sireCooldown,
        ];
        _carrotBoostedHorseIds.remove(sire.id);
      });
      _persistGameState();
      unawaited(_syncCommunityStableProjection(showErrors: false));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMutant
                ? 'The pairing produced a mutant pending foal. You can track it from Stable until birth.'
                : 'The pairing succeeded. The pending foal is now waiting in Stable.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _activeMating = null;
      _breedingCooldowns = [
        ..._breedingCooldowns.where((cooldown) => cooldown.horseId != sire.id),
        sireCooldown,
      ];
      _carrotBoostedHorseIds.remove(sire.id);
    });
    _persistGameState();
    unawaited(_syncCommunityStableProjection(showErrors: false));
    _playSound(GameSound.foalBirth);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This mating did not take. No foal was created, so you will need to try again.',
        ),
      ),
    );
  }

  void _resolveBirth(PregnancyRecord pregnancy, DateTime resolvedAt) {
    final foal = pregnancy.foal.copyWith(ageDays: Horse.newbornAgeDays);
    final recoveryEndsAt = pregnancy.dueAt.add(
      BreedingPreviewService.marePostBirthCooldownDuration,
    );
    final shouldKeepHealingCooldown = recoveryEndsAt.isAfter(resolvedAt);
    setState(() {
      _activePregnancies = _activePregnancies
          .where((record) => record.id != pregnancy.id)
          .toList();
      _prenatalBoostedPregnancyIds.remove(pregnancy.id);
      _latestBornFoal = foal;
      _stableHorses = [foal, ..._stableHorses];
      _breedingCooldowns = [
        ..._breedingCooldowns.where(
          (cooldown) => cooldown.horseId != pregnancy.damId,
        ),
        if (shouldKeepHealingCooldown)
          BreedingCooldown(
            horseId: pregnancy.damId,
            horseName: pregnancy.damName,
            sex: 'Mare',
            reason: 'Healing',
            endsAt: recoveryEndsAt,
          ),
      ];
      _selectedIndex = 0;
      _now = resolvedAt;
    });
    _persistGameState();
    unawaited(_syncCommunityStableProjection(showErrors: false));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${foal.registeredName} has been born and moved into your stable.',
        ),
      ),
    );

    _queueBirthReveal(pregnancy, foal);
  }

  void _handleBirthFoal(PregnancyRecord pregnancy) {
    if (_stableHorses.length >= _stableHorseCap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your stable is full. Make room before delivering this foal.',
          ),
        ),
      );
      return;
    }

    if (pregnancy.dueAt.isAfter(_now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pregnancy.unbornFoalName} is still growing. Wait until the birth timer finishes.',
          ),
        ),
      );
      return;
    }

    if (_communityRepository.isSupabaseAvailable &&
        !_isLocalPregnancyRecord(pregnancy)) {
      unawaited(_deliverServerPregnancy(pregnancy));
      return;
    }

    _resolveBirth(pregnancy, _now);
  }

  void _syncOverdueMareRecoveryCooldowns(DateTime asOf) {
    final overduePregnancies = _activePregnancies
        .where((pregnancy) => !pregnancy.dueAt.isAfter(asOf))
        .toList();
    if (overduePregnancies.isEmpty) {
      return;
    }

    final updatedCooldowns = [
      ..._breedingCooldowns.where((cooldown) {
        final isOverdueDam = overduePregnancies.any(
          (pregnancy) => pregnancy.damId == cooldown.horseId,
        );
        return !isOverdueDam;
      }),
    ];

    for (final pregnancy in overduePregnancies) {
      final recoveryEndsAt = pregnancy.dueAt.add(
        BreedingPreviewService.marePostBirthCooldownDuration,
      );
      if (!recoveryEndsAt.isAfter(asOf)) {
        continue;
      }
      updatedCooldowns.add(
        BreedingCooldown(
          horseId: pregnancy.damId,
          horseName: pregnancy.damName,
          sex: 'Mare',
          reason: 'Healing',
          endsAt: recoveryEndsAt,
        ),
      );
    }

    setState(() {
      _breedingCooldowns = updatedCooldowns;
    });
    _persistGameState();
    unawaited(_syncCommunityStableProjection(showErrors: false));
  }

  Future<void> _resolveServerMatingOutcome() async {
    final activeMating = _activeMating;
    if (activeMating == null || _isResolvingServerMating) {
      return;
    }
    if (_isLocalMatingSession(activeMating)) {
      _resolveMatingOutcome(_now);
      return;
    }

    _isResolvingServerMating = true;
    try {
      await _communityRepository.resolveMatingSession(
        sessionId: activeMating.id,
      );
      await _refreshOwnedStateFromServer();
      if (!mounted) {
        return;
      }

      final matchedPregnancy = _activePregnancies
          .cast<PregnancyRecord?>()
          .firstWhere(
            (pregnancy) =>
                pregnancy?.damId == activeMating.damId &&
                pregnancy?.sireId == activeMating.sireId,
            orElse: () => null,
          );
      _logClientEvent(
        eventType: 'mating_resolved',
        message: matchedPregnancy == null
            ? 'Mating resolved with no pregnancy.'
            : matchedPregnancy.isMutant
            ? 'Mating resolved with mutant pregnancy.'
            : 'Mating resolved with pregnancy.',
        context: {
          'mating_id': activeMating.id,
          'pregnancy_id': matchedPregnancy?.id,
          'is_mutant': matchedPregnancy?.isMutant ?? false,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            matchedPregnancy == null
                ? 'This mating did not take. No foal was created, so you will need to try again.'
                : matchedPregnancy.isMutant
                ? 'The server recorded a mutant pending foal. You can track it from Stable until birth.'
                : 'The server recorded a successful pairing. The pending foal is now waiting in Stable.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logErrorEvent(
        source: 'resolve_mating_session',
        message: 'The server could not resolve the mating session.',
        error: error,
        stackTrace: stackTrace,
        context: {'mating_id': activeMating.id},
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The server could not resolve that breeding outcome yet. Please try again in a moment.',
          ),
        ),
      );
    } finally {
      _isResolvingServerMating = false;
    }
  }

  Future<void> _deliverServerPregnancy(PregnancyRecord pregnancy) async {
    if (_isDeliveringServerPregnancy) {
      return;
    }

    _isDeliveringServerPregnancy = true;
    try {
      await _communityRepository.deliverPregnancy(pregnancyId: pregnancy.id);
      await _refreshOwnedStateFromServer();
      if (!mounted) {
        return;
      }

      final foal = _stableHorses.cast<Horse?>().firstWhere(
        (horse) => horse?.registryId == pregnancy.registryId,
        orElse: () => null,
      );
      if (foal != null) {
        setState(() {
          _latestBornFoal = foal;
          _selectedIndex = 0;
        });
        _playSound(GameSound.foalBirth);
        _queueBirthReveal(pregnancy, foal);
      }
      _logClientEvent(
        eventType: 'pregnancy_delivered',
        message: 'Pregnancy delivered into stable.',
        context: {
          'pregnancy_id': pregnancy.id,
          'foal_registry_id': foal?.registryId ?? pregnancy.registryId,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${foal?.registeredName ?? pregnancy.registryId} has been delivered into your stable.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logErrorEvent(
        source: 'deliver_pregnancy',
        message: 'The server could not deliver the pregnancy.',
        error: error,
        stackTrace: stackTrace,
        context: {'pregnancy_id': pregnancy.id},
      );
      if (!mounted) {
        return;
      }
      final stillPendingLocally = _activePregnancies.any(
        (record) => record.id == pregnancy.id,
      );
      if (stillPendingLocally && !pregnancy.dueAt.isAfter(_now)) {
        _resolveBirth(pregnancy, _now);
        final synced = await _syncCommunityStableProjection(
          showErrors: true,
          refreshSnapshot: false,
        );
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              synced
                  ? '${pregnancy.unbornFoalName} was delivered and synced after the server birth path failed.'
                  : '${pregnancy.unbornFoalName} was delivered on this device. Server sync is still pending.',
            ),
          ),
        );
        return;
      }

      _playSound(GameSound.messageSent);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That foal could not be delivered on the server right now. Please try again.',
          ),
        ),
      );
    } finally {
      _isDeliveringServerPregnancy = false;
    }
  }

  void _queueBirthReveal(PregnancyRecord pregnancy, Horse foal) {
    if (_birthRevealQueued) {
      return;
    }

    _birthRevealQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _BirthRevealSheet(
            foal: foal,
            pregnancy: pregnancy,
            onConfirmName: (chosenName) {
              final trimmed = chosenName.trim();
              if (trimmed.isEmpty) {
                return;
              }

              final renamed = _breedingService.renameFoal(foal, trimmed);
              setState(() {
                _stableHorses = _stableHorses
                    .map((horse) => horse.id == foal.id ? renamed : horse)
                    .toList();
                _latestBornFoal = renamed;
              });
              _persistGameState();
              unawaited(
                _syncCommunityStableProjection(
                  showErrors: false,
                  refreshSnapshot: false,
                ),
              );
            },
          );
        },
      );

      _birthRevealQueued = false;
    });
  }

  bool get _canAddHorseToStable {
    return _stableHorses.length < _stableHorseCap;
  }

  int get _stableHorseCap {
    return switch (_stableExpansionTier) {
      0 => 10,
      1 => 25,
      _ => 50,
    };
  }

  String get _stableCapacityMessage {
    return 'Your stable is full at $_stableHorseCap horses. Trade, sell, purge, or renew a monthly expansion before buying another one.';
  }

  String _formatShortDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _enforceStableExpansionRenewal(
    DateTime targetTime, {
    bool showMessage = true,
  }) {
    final renewalDue = _stableExpansionRenewsAt;
    if (_stableExpansionTier <= 0 ||
        renewalDue == null ||
        targetTime.isBefore(renewalDue)) {
      return;
    }

    final expirationResult = expireStableCapacity(_stableHorses);
    final removedIds = expirationResult.removedHorseIds;
    final removedActiveFlow = expirationResult.removedHorses.any(
      (horse) =>
          _activePregnancies.any(
            (pregnancy) =>
                pregnancy.damId == horse.id || pregnancy.sireId == horse.id,
          ) ||
          _activeMating?.damId == horse.id ||
          _activeMating?.sireId == horse.id,
    );

    setState(() {
      _stableExpansionTier = 0;
      _stableExpansionRenewsAt = null;
      _stableHorses = expirationResult.keptHorses;
      _communityListings = _communityListings
          .where((listing) => !removedIds.contains(listing.horse.id))
          .toList();
      _likedHorseIds.removeWhere(removedIds.contains);
      _breedingCooldowns = _breedingCooldowns
          .where((cooldown) => !removedIds.contains(cooldown.horseId))
          .toList();
      _activePregnancies = _activePregnancies
          .where(
            (pregnancy) =>
                !removedIds.contains(pregnancy.damId) &&
                !removedIds.contains(pregnancy.sireId),
          )
          .toList();
      if (_activeMating != null &&
          (removedIds.contains(_activeMating!.damId) ||
              removedIds.contains(_activeMating!.sireId))) {
        _activeMating = null;
      }
      if (_latestBornFoal != null && removedIds.contains(_latestBornFoal!.id)) {
        _latestBornFoal = null;
      }
      _coinBalance += expirationResult.payout;
      _syncBreedingSelections();
      _pruneLikedHorseIds();
    });

    _persistGameState();
    unawaited(_syncCommunityStableProjection());

    if (!showMessage || !mounted) {
      return;
    }
    final removedCount = expirationResult.removedHorses.length;
    final message = removedCount == 0
        ? 'Your monthly stable expansion expired. Capacity returned to 10 horses.'
        : 'Your monthly stable expansion expired. $removedCount lowest-rated horse${removedCount == 1 ? '' : 's'} left your stable for ${expirationResult.payout} purge coins.${removedActiveFlow ? ' Any breeding tied to those horses was also cleared.' : ''}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restoreGameState() async {
    final savedState = await _gameStateRepository.loadState(widget.account.id);
    if (!mounted) {
      return;
    }

    final restoredState = savedState ?? _buildInitialState();
    final localStableHorses = List<Horse>.from(restoredState.stableHorses);
    final localIdsByRegistry = {
      for (final horse in localStableHorses) horse.registryId: horse.id,
    };
    var resolvedStableHorses = localStableHorses;
    var resolvedCoinBalance = restoredState.coinBalance;
    var resolvedPregnancies = List<PregnancyRecord>.from(
      restoredState.activePregnancies,
    );
    var resolvedBreedingCooldowns = List<BreedingCooldown>.from(
      restoredState.breedingCooldowns,
    );
    var resolvedActiveMating = restoredState.activeMating;
    var resolvedCommunityListings = restoredState.communityListings;
    var resolvedCommunityProfiles = const <CommunityProfile>[];
    var resolvedInboxItems = const <InboxItem>[];
    var resolvedLikedHorseIds = Set<String>.from(restoredState.likedHorseIds);
    var resolvedFollowedProfileIds = Set<String>.from(
      restoredState.followedProfileIds,
    );
    var resolvedInventory = Map<InventoryItemType, int>.from(
      restoredState.inventory,
    );
    var resolvedStableExpansionTier = restoredState.stableExpansionTier;
    var resolvedStableExpansionRenewsAt = restoredState.stableExpansionRenewsAt;
    var resolvedPrenatalBoostedPregnancyIds = Set<String>.from(
      restoredState.prenatalBoostedPregnancyIds,
    );
    var resolvedCarrotBoostedHorseIds = Set<String>.from(
      restoredState.carrotBoostedHorseIds,
    );
    var resolvedReadStableAlertIds = Set<String>.from(
      restoredState.readStableAlertIds,
    );

    if (_communityRepository.isSupabaseAvailable) {
      try {
        await _communityRepository.syncCurrentUserProfile(widget.account);
        final remoteState = await _communityRepository.loadOwnedGameState(
          ownerId: widget.account.id,
          localIdsByRegistry: localIdsByRegistry,
        );
        if (remoteState != null) {
          resolvedCoinBalance = remoteState.coinBalance;
          resolvedActiveMating = remoteState.activeMating;
          resolvedInventory = Map<InventoryItemType, int>.from(
            remoteState.inventory,
          );
          resolvedStableExpansionTier = remoteState.stableExpansionTier;
          resolvedStableExpansionRenewsAt =
              remoteState.stableExpansionRenewsAt ??
              resolvedStableExpansionRenewsAt;
          resolvedPrenatalBoostedPregnancyIds = Set<String>.from(
            remoteState.prenatalBoostedPregnancyIds,
          );
          resolvedCarrotBoostedHorseIds = Set<String>.from(
            remoteState.carrotBoostedHorseIds,
          );
          if (remoteState.hasOwnedProgress) {
            resolvedStableHorses = remoteState.stableHorses;
            resolvedPregnancies = remoteState.activePregnancies;
            resolvedBreedingCooldowns = remoteState.breedingCooldowns;
          } else if (localStableHorses.isNotEmpty ||
              restoredState.activePregnancies.isNotEmpty ||
              restoredState.breedingCooldowns.isNotEmpty) {
            await _communityRepository.syncOwnedGameState(
              owner: widget.account,
              stableHorses: localStableHorses,
              activePregnancies: restoredState.activePregnancies,
              breedingCooldowns: restoredState.breedingCooldowns,
              coinBalance: restoredState.coinBalance,
              inventory: restoredState.inventory,
              stableExpansionTier: restoredState.stableExpansionTier,
              stableExpansionRenewsAt: restoredState.stableExpansionRenewsAt,
              prenatalBoostedPregnancyIds:
                  restoredState.prenatalBoostedPregnancyIds,
              carrotBoostedHorseIds: restoredState.carrotBoostedHorseIds,
            );
          }
        }

        final snapshot = await _communityRepository.loadSnapshot(
          currentUserId: widget.account.id,
        );
        resolvedCommunityProfiles = snapshot.profiles;
        resolvedCommunityListings = snapshot.listings;
        resolvedLikedHorseIds = Set<String>.from(snapshot.likedHorseIds);
        resolvedFollowedProfileIds = Set<String>.from(
          snapshot.followedProfileIds,
        );
        resolvedInboxItems = await _inboxRepository.loadInboxItems(
          ownerId: widget.account.id,
        );
      } catch (error, stackTrace) {
        _logErrorEvent(
          source: 'restore_game_state',
          message: 'Failed to hydrate owned Supabase state.',
          error: error,
          stackTrace: stackTrace,
        );
        // Keep the app usable even if the live backend is temporarily unavailable.
      }
    }

    setState(() {
      _stableHorses = List<Horse>.from(resolvedStableHorses);
      _marketHorses = _registryService.assignStarterMarketRegistryIds(
        ownerId: widget.account.id,
        horses: restoredState.marketHorses.map(
          _horseRepository.normalizeStarterMarketHorse,
        ),
      );
      _communityListings = resolvedCommunityListings;
      _communityProfiles = resolvedCommunityProfiles;
      _inboxItems = List<InboxItem>.from(resolvedInboxItems);
      _activePregnancies = List<PregnancyRecord>.from(resolvedPregnancies);
      _activeMating = resolvedActiveMating;
      _coinBalance = resolvedCoinBalance;
      _selectedIndex = restoredState.selectedIndex.clamp(0, 4);
      _foalSequence = restoredState.foalSequence;
      _marketPurchaseSequence = restoredState.marketPurchaseSequence;
      _selectedDamId = restoredState.selectedDamId;
      _selectedSireId = restoredState.selectedSireId;
      _likedHorseIds
        ..clear()
        ..addAll(resolvedLikedHorseIds);
      _followedProfileIds
        ..clear()
        ..addAll(resolvedFollowedProfileIds);
      _inventory
        ..clear()
        ..addAll(resolvedInventory);
      _stableExpansionTier = resolvedStableExpansionTier.clamp(0, 2);
      _stableExpansionRenewsAt = _stableExpansionTier > 0
          ? resolvedStableExpansionRenewsAt ??
                restoredState.currentTime.add(const Duration(days: 30))
          : null;
      _prenatalBoostedPregnancyIds
        ..clear()
        ..addAll(resolvedPrenatalBoostedPregnancyIds);
      _carrotBoostedHorseIds
        ..clear()
        ..addAll(resolvedCarrotBoostedHorseIds);
      _readStableAlertIds
        ..clear()
        ..addAll(resolvedReadStableAlertIds);
      _breedingCooldowns = List<BreedingCooldown>.from(
        resolvedBreedingCooldowns,
      );
      _pruneLikedHorseIds();
      _now = restoredState.currentTime;
      _latestBornFoal = restoredState.latestBornFoalId == null
          ? null
          : _stableHorses.cast<Horse?>().firstWhere(
              (horse) => horse?.id == restoredState.latestBornFoalId,
              orElse: () => null,
            );
      _syncBreedingSelections();
    });

    _enforceStableExpansionRenewal(_now, showMessage: false);

    if (!mounted) {
      return;
    }
    setState(() {
      _isHydrating = false;
    });

    if (savedState == null) {
      _advanceTimeline(DateTime.now());
      _persistGameState();
      return;
    }

    _advanceTimeline(DateTime.now());
    _persistGameState();
    unawaited(_syncCommunityStableProjection(showErrors: false));
    _logClientEvent(
      eventType: 'session_restored',
      message: 'App session restored from local and remote state.',
      context: {
        'stable_count': _stableHorses.length,
        'pregnancy_count': _activePregnancies.length,
        'has_active_mating': _activeMating != null,
      },
    );
  }

  Future<void> _refreshOwnedStateFromServer() async {
    if (!_communityRepository.isSupabaseAvailable) {
      return;
    }

    final localIdsByRegistry = {
      for (final horse in _stableHorses) horse.registryId: horse.id,
    };
    final remoteState = await _communityRepository.loadOwnedGameState(
      ownerId: widget.account.id,
      localIdsByRegistry: localIdsByRegistry,
    );
    if (!mounted || remoteState == null) {
      return;
    }

    final previousLatestRegistryId = _latestBornFoal?.registryId;
    setState(() {
      _stableHorses = List<Horse>.from(remoteState.stableHorses);
      _activePregnancies = List<PregnancyRecord>.from(
        remoteState.activePregnancies,
      );
      _breedingCooldowns = List<BreedingCooldown>.from(
        remoteState.breedingCooldowns,
      );
      _activeMating = remoteState.activeMating;
      _coinBalance = remoteState.coinBalance;
      _latestBornFoal = previousLatestRegistryId == null
          ? null
          : _stableHorses.cast<Horse?>().firstWhere(
              (horse) => horse?.registryId == previousLatestRegistryId,
              orElse: () => null,
            );
      _syncBreedingSelections();
    });
    _persistGameState();
    await _refreshCommunitySnapshot();
  }

  PersistedGameState _buildInitialState() {
    return PersistedGameState(
      currentTime: DateTime.now(),
      stableHorses: List<Horse>.from(_horseRepository.loadStable()),
      marketHorses: _registryService.assignStarterMarketRegistryIds(
        ownerId: widget.account.id,
        horses: _horseRepository.loadStarterMarket(),
      ),
      communityListings: _communityRepository.loadInitialListings(),
      coinBalance: 7000,
      selectedIndex: 0,
      foalSequence: 2000,
      marketPurchaseSequence: 5000,
      activePregnancies: const [],
      likedHorseIds: const <String>{},
      followedProfileIds: const <String>{},
      breedingCooldowns: const [],
      inventory: const {},
      stableExpansionTier: 0,
      stableExpansionRenewsAt: null,
      prenatalBoostedPregnancyIds: const <String>{},
      carrotBoostedHorseIds: const <String>{},
      readStableAlertIds: const <String>{},
    );
  }

  CommunityProfile _buildCurrentUserProfile() {
    final seed = widget.account.id.codeUnits.fold<int>(
      0,
      (sum, codeUnit) => sum + codeUnit,
    );
    const accents = <int>[0xFF59F0E4, 0xFFFF5C8A, 0xFFFFC857, 0xFFB36BFF];
    return CommunityProfile(
      id: widget.account.id,
      name: widget.account.displayName,
      handle: widget.account.handle ?? _accountHandle,
      stableName:
          widget.account.stableName ?? '${widget.account.displayName} Stable',
      favoriteBreed:
          widget.account.favoriteBreed ??
          (_stableHorses.isEmpty ? 'Arabian' : _stableHorses.first.breed),
      followerCount: 1 + _followedProfileIds.length,
      weeklyPosts: _stableHorses
          .where((horse) => horse.isFoal)
          .length
          .clamp(1, 12),
      bio:
          'Collector profile for ${widget.account.displayName}, with public horses and formula-priced sale listings.',
      accentValue: widget.account.accentValue ?? accents[seed % accents.length],
      joinedLabel:
          'Joined ${widget.account.createdAt.month}/${widget.account.createdAt.year}',
    );
  }

  String get _accountHandle {
    final cleaned = widget.account.displayName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    return '@${cleaned.isEmpty ? 'stableowner' : cleaned}';
  }

  void _logClientEvent({
    required String eventType,
    String status = 'info',
    String? message,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    unawaited(
      _supportRepository.logClientEvent(
        ownerId: widget.account.id,
        eventType: eventType,
        status: status,
        message: message,
        context: context,
      ),
    );
  }

  void _logErrorEvent({
    required String source,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic> context = const <String, dynamic>{},
  }) {
    unawaited(
      _supportRepository.logErrorEvent(
        ownerId: widget.account.id,
        source: source,
        message: message,
        stackTrace: stackTrace?.toString(),
        context: {...context, if (error != null) 'error': error.toString()},
      ),
    );
  }

  String _generateSupportCode() {
    final cleaned = widget.account.id.replaceAll('-', '');
    final suffix = cleaned.length <= 8 ? cleaned : cleaned.substring(0, 8);
    return 'PH-$suffix-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _selectedTabLabel(int index) {
    switch (index) {
      case 0:
        return 'stable';
      case 1:
        return 'breed';
      case 2:
        return 'social';
      case 3:
        return 'market';
      case 4:
        return 'profile';
    }
    return 'unknown';
  }

  Map<String, dynamic> _buildSupportSnapshotPayload() {
    return {
      'captured_at': DateTime.now().toIso8601String(),
      'game_clock': _now.toIso8601String(),
      'profile': {
        'id': widget.account.id,
        'email': widget.account.email,
        'display_name': widget.account.displayName,
        'handle': widget.account.handle ?? _accountHandle,
        'stable_name':
            widget.account.stableName ?? '${widget.account.displayName} Stable',
      },
      'summary': {
        'coin_balance': _coinBalance,
        'selected_tab': _selectedTabLabel(_selectedIndex),
        'stable_count': _stableHorses.length,
        'market_count': _marketHorses.length,
        'pregnancy_count': _activePregnancies.length,
        'cooldown_count': _breedingCooldowns.length,
        'liked_count': _likedHorseIds.length,
        'followed_count': _followedProfileIds.length,
      },
      'active_mating': _activeMating == null
          ? null
          : {
              'id': _activeMating!.id,
              'dam_id': _activeMating!.damId,
              'dam_name': _activeMating!.damName,
              'sire_id': _activeMating!.sireId,
              'sire_name': _activeMating!.sireName,
              'started_at': _activeMating!.startedAt.toIso8601String(),
              'ends_at': _activeMating!.endsAt.toIso8601String(),
            },
      'stable_horses': _stableHorses
          .map(
            (horse) => {
              'id': horse.id,
              'registry_id': horse.registryId,
              'current_name': horse.currentName,
              'registered_name': horse.registeredName,
              'breed': horse.breed,
              'sex': horse.sex,
              'age_days': horse.ageDays,
              'is_foal': horse.isFoal,
              'is_mutant': horse.isMutant,
              'is_breeding_ready': horse.isBreedingReady,
              'is_retired': horse.isRetired,
            },
          )
          .toList(),
      'pregnancies': _activePregnancies
          .map(
            (pregnancy) => {
              'id': pregnancy.id,
              'registry_id': pregnancy.registryId,
              'dam_id': pregnancy.damId,
              'dam_name': pregnancy.damName,
              'sire_id': pregnancy.sireId,
              'sire_name': pregnancy.sireName,
              'due_at': pregnancy.dueAt.toIso8601String(),
              'conceived_at': pregnancy.conceivedAt.toIso8601String(),
              'is_mutant': pregnancy.isMutant,
            },
          )
          .toList(),
      'breeding_cooldowns': _breedingCooldowns
          .map(
            (cooldown) => {
              'horse_id': cooldown.horseId,
              'horse_name': cooldown.horseName,
              'sex': cooldown.sex,
              'reason': cooldown.reason,
              'ends_at': cooldown.endsAt.toIso8601String(),
            },
          )
          .toList(),
      'community': {
        'listing_count': _communityListings.length,
        'followed_profile_ids': _followedProfileIds.toList()..sort(),
        'liked_horse_ids': _likedHorseIds.toList()..sort(),
      },
      'latest_born_foal_registry_id': _latestBornFoal?.registryId,
    };
  }

  Future<String> _createSupportSnapshot() async {
    final supportCode = _generateSupportCode();
    final summary =
        'Stable ${_stableHorses.length}, pregnancies ${_activePregnancies.length}, cooldowns ${_breedingCooldowns.length}, active mating ${_activeMating != null ? 'yes' : 'no'}.';

    await _supportRepository.createSupportSnapshot(
      ownerId: widget.account.id,
      supportCode: supportCode,
      snapshotSummary: summary,
      snapshotPayload: _buildSupportSnapshotPayload(),
    );
    return supportCode;
  }

  Future<void> _handleSubmitFeedback({
    required String category,
    required String message,
  }) async {
    final trimmedMessage = message.trim();
    String? supportCode;
    try {
      if (category == 'Report a Problem') {
        try {
          supportCode = await _createSupportSnapshot();
        } catch (error, stackTrace) {
          _logErrorEvent(
            source: 'support_snapshot',
            message: 'Problem report snapshot failed.',
            error: error,
            stackTrace: stackTrace,
            context: {
              'category': category,
              'message_length': trimmedMessage.length,
            },
          );
        }
      }
      final sent = await _supportRepository.createFeedbackSubmission(
        ownerId: widget.account.id,
        email: widget.account.email,
        displayName: widget.account.displayName,
        category: category,
        message: trimmedMessage,
        context: {
          'stable_count': _stableHorses.length,
          'market_count': _marketHorses.length,
          'coin_balance': _coinBalance,
          'active_pregnancies': _activePregnancies.length,
          'has_active_mating': _activeMating != null,
          'support_code': ?supportCode,
          'horse_ids': _horseIdSnapshot(),
        },
      );
      _logClientEvent(
        eventType: 'feedback_submitted',
        message: sent
            ? 'Player feedback submitted.'
            : 'Player feedback captured while backend was unavailable.',
        context: {
          'category': category,
          'message_length': trimmedMessage.length,
          'sent_to_backend': sent,
          'support_code': ?supportCode,
        },
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? category == 'Report a Problem'
                      ? 'Problem report sent. Support code: $supportCode'
                      : 'Thanks for the note. Your message was sent.'
                : 'Thanks for the note. Sending needs support to be online.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logErrorEvent(
        source: 'feedback_submission',
        message: 'Failed to submit player feedback.',
        error: error,
        stackTrace: stackTrace,
        context: {
          'category': category,
          'message_length': trimmedMessage.length,
        },
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send feedback right now. Try again soon.'),
        ),
      );
      rethrow;
    }
  }

  Future<void> _handleCopyStableId() async {
    await Clipboard.setData(
      ClipboardData(text: 'Stable ID: ${widget.account.id}'),
    );
    _logClientEvent(
      eventType: 'stable_id_copied',
      message: 'Player copied stable ID.',
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Stable ID copied.')));
  }

  List<Map<String, String>> _horseIdSnapshot() {
    final seenIds = <String>{};
    final entries = <Map<String, String>>[];

    void addHorse(String group, Horse horse) {
      if (!seenIds.add(horse.id)) {
        return;
      }
      entries.add({
        'group': group,
        'name': horse.displayName,
        'horse_id': horse.id,
        'registry_id': horse.registryId,
      });
    }

    for (final horse in _stableHorses) {
      addHorse('Stable', horse);
    }
    for (final horse in _marketHorses) {
      addHorse('Market', horse);
    }
    for (final listing in _communityListings) {
      addHorse('Community Listing', listing.horse);
    }

    return entries;
  }

  int _nextAvailableFoalSequence(String breed) {
    return _registryService.nextAvailableSequence(
      currentSequence: _foalSequence,
      existingRegistryIds: _visibleRegistryIds(),
      buildRegistryId: (sequence) => _registryService.foalRegistryId(
        breed: breed,
        ownerId: widget.account.id,
        sequence: sequence,
      ),
    );
  }

  Future<String?> _reserveHorseRegistryId({required String fallback}) async {
    if (!_communityRepository.isSupabaseAvailable) {
      return fallback;
    }
    try {
      final registryId = await _communityRepository.reserveHorseRegistryId();
      if (registryId == null || registryId.isEmpty) {
        return null;
      }
      _serverReservedRegistryIds.add(registryId);
      return registryId;
    } catch (error, stackTrace) {
      _logErrorEvent(
        source: 'reserve_horse_registry_id',
        message: 'A unique horse registry ID could not be reserved.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> _repairUnsyncedStableRegistryIds() async {
    if (!_communityRepository.isSupabaseAvailable || _stableHorses.isEmpty) {
      return true;
    }

    try {
      final localIdsByRegistry = {
        for (final horse in _stableHorses) horse.registryId: horse.id,
      };
      final remoteStable = await _communityRepository.loadOwnedStable(
        ownerId: widget.account.id,
        localIdsByRegistry: localIdsByRegistry,
      );
      final syncedRegistryIds = {
        for (final horse in remoteStable) horse.registryId,
      };
      var changed = false;
      final repairedStable = <Horse>[];
      for (final horse in _stableHorses) {
        if (syncedRegistryIds.contains(horse.registryId) ||
            _serverReservedRegistryIds.contains(horse.registryId)) {
          repairedStable.add(horse);
          continue;
        }

        final registryId = await _communityRepository.reserveHorseRegistryId();
        if (registryId == null || registryId.isEmpty) {
          return false;
        }
        _serverReservedRegistryIds.add(registryId);
        repairedStable.add(horse.copyWith(registryId: registryId));
        changed = true;
      }

      if (changed && mounted) {
        setState(() {
          _stableHorses = repairedStable;
        });
        await _persistGameState();
      }
      return true;
    } catch (error, stackTrace) {
      _logErrorEvent(
        source: 'repair_unsynced_registry_ids',
        message: 'Unsynced horse registry IDs could not be repaired.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Iterable<String> _visibleRegistryIds() sync* {
    for (final horse in _stableHorses) {
      yield horse.registryId;
    }
    for (final horse in _marketHorses) {
      yield horse.registryId;
    }
    for (final pregnancy in _activePregnancies) {
      yield pregnancy.registryId;
    }
    for (final listing in _communityListings) {
      yield listing.horse.registryId;
    }
  }

  Future<void> _persistGameState() async {
    if (_isHydrating || !mounted) {
      return;
    }

    await _gameStateRepository.saveState(
      widget.account.id,
      PersistedGameState(
        currentTime: _now,
        stableHorses: List<Horse>.from(_stableHorses),
        marketHorses: List<Horse>.from(_marketHorses),
        communityListings: List<CommunityListing>.from(_communityListings),
        activePregnancies: List<PregnancyRecord>.from(_activePregnancies),
        activeMating: _activeMating,
        latestBornFoalId: _latestBornFoal?.id,
        coinBalance: _coinBalance,
        selectedIndex: _selectedIndex,
        foalSequence: _foalSequence,
        marketPurchaseSequence: _marketPurchaseSequence,
        selectedDamId: _selectedDamId,
        selectedSireId: _selectedSireId,
        likedHorseIds: Set<String>.from(_likedHorseIds),
        followedProfileIds: Set<String>.from(_followedProfileIds),
        breedingCooldowns: List<BreedingCooldown>.from(_breedingCooldowns),
        inventory: Map<InventoryItemType, int>.from(_inventory),
        stableExpansionTier: _stableExpansionTier,
        stableExpansionRenewsAt: _stableExpansionRenewsAt,
        prenatalBoostedPregnancyIds: Set<String>.from(
          _prenatalBoostedPregnancyIds,
        ),
        carrotBoostedHorseIds: Set<String>.from(_carrotBoostedHorseIds),
        readStableAlertIds: Set<String>.from(_readStableAlertIds),
      ),
    );
    unawaited(
      _communityRepository.syncCoinBalance(
        profileId: widget.account.id,
        coinBalance: _coinBalance,
      ),
    );
  }

  void _pruneLikedHorseIds() {
    final validIds = {
      ..._stableHorses.map((horse) => horse.id),
      ..._marketHorses.map((horse) => horse.id),
      ..._communityListings.map((listing) => listing.horse.id),
    };
    _likedHorseIds.removeWhere((horseId) => !validIds.contains(horseId));
  }

  Future<bool> _syncCommunityStableProjection({
    bool showErrors = true,
    bool refreshSnapshot = true,
  }) async {
    try {
      final registryIdsReady = await _repairUnsyncedStableRegistryIds();
      if (!registryIdsReady) {
        if (!mounted || !showErrors) {
          return false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Horse IDs could not be reserved on the server yet. Please try again.',
            ),
          ),
        );
        return false;
      }
      await _communityRepository.syncOwnedGameState(
        owner: widget.account,
        stableHorses: _stableHorses,
        activePregnancies: _activePregnancies,
        breedingCooldowns: _breedingCooldowns,
        coinBalance: _coinBalance,
        inventory: Map<InventoryItemType, int>.from(_inventory),
        stableExpansionTier: _stableExpansionTier,
        stableExpansionRenewsAt: _stableExpansionRenewsAt,
        prenatalBoostedPregnancyIds: Set<String>.from(
          _prenatalBoostedPregnancyIds,
        ),
        carrotBoostedHorseIds: Set<String>.from(_carrotBoostedHorseIds),
      );
      if (refreshSnapshot) {
        await _refreshCommunitySnapshot();
      }
      return true;
    } catch (error, stackTrace) {
      _logErrorEvent(
        source: 'sync_owned_game_state',
        message: 'Community sync failed.',
        error: error,
        stackTrace: stackTrace,
        context: {
          'stable_count': _stableHorses.length,
          'pregnancy_count': _activePregnancies.length,
          'cooldown_count': _breedingCooldowns.length,
        },
      );
      if (!mounted || !showErrors) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_communitySyncFailureMessage(error))),
      );
      return false;
    }
  }

  String _communitySyncFailureMessage(Object error) {
    final errorText = error.toString();
    if (errorText.contains('reserve_horse_registry_id')) {
      return 'The horse ID reservation migration has not been applied yet.';
    }
    if (errorText.contains('horses_registry_id_key') ||
        errorText.contains('duplicate key')) {
      return 'One of these horse IDs is already used online. The app needs to reserve a fresh PH number before syncing.';
    }
    if (errorText.contains('Authentication required') ||
        errorText.contains('JWT')) {
      return 'Please sign back in before syncing your stable.';
    }
    return 'Community sync is temporarily unavailable.';
  }

  Future<void> _refreshCommunitySnapshot() async {
    final snapshot = await _communityRepository.loadSnapshot(
      currentUserId: widget.account.id,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _communityProfiles = snapshot.profiles;
      _communityListings = snapshot.listings;
      _likedHorseIds
        ..clear()
        ..addAll(snapshot.likedHorseIds);
      _followedProfileIds
        ..clear()
        ..addAll(snapshot.followedProfileIds);
      _pruneLikedHorseIds();
    });
    _persistGameState();
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.colors});

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

class _BirthRevealSheet extends StatefulWidget {
  const _BirthRevealSheet({
    required this.foal,
    required this.pregnancy,
    required this.onConfirmName,
  });

  final Horse foal;
  final PregnancyRecord pregnancy;
  final ValueChanged<String> onConfirmName;

  @override
  State<_BirthRevealSheet> createState() => _BirthRevealSheetState();
}

class _BirthRevealSheetState extends State<_BirthRevealSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.foal.currentName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: SingleChildScrollView(
            child: SectionCard(
              title: 'Birth Reveal',
              subtitle:
                  '${widget.pregnancy.damName} × ${widget.pregnancy.sireName} finally arrived',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            _RevealPill(
                              label: widget.foal.isMutant
                                  ? 'Mutant foal'
                                  : 'Newborn',
                              color: AppTheme.primary,
                            ),
                            _RevealPill(
                              label: widget.foal.sex,
                              color: AppTheme.secondary,
                            ),
                            _RevealPill(
                              label: 'Gen ${widget.foal.generation}',
                              color: AppTheme.tertiary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        HorsePreview(horse: widget.foal, forceStatic: true),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            RarityBadge(
                              tier: widget.foal.breedingRarity,
                              label:
                                  'Breeding ${widget.foal.breedingRarity.label}',
                              compact: true,
                            ),
                            RarityBadge(
                              tier: widget.foal.visualRarity,
                              label: 'Visual ${widget.foal.visualRarity.label}',
                              compact: true,
                            ),
                            PriceBadge(
                              price: widget.foal.derivedPrice,
                              tier: widget.foal.breedingRarity,
                              compact: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Registered as ${widget.foal.registeredName} with registry ID ${widget.foal.registryId}. Choose the stable name you want to use now.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Stable name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.foal.traits
                        .map(
                          (trait) =>
                              HorseTraitChip(trait: trait, compact: true),
                        )
                        .toList(),
                  ),
                  if (widget.foal.specialTraits.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Special traits: ${widget.foal.specialTraits.join(', ')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        widget.onConfirmName(_controller.text);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Welcome foal to stable'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealPill extends StatelessWidget {
  const _RevealPill({required this.label, required this.color});

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
