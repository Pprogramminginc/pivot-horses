import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/breeding_cooldown.dart';
import '../../domain/models/care_stats.dart';
import '../../domain/models/community_listing.dart';
import '../../domain/models/community_profile.dart';
import '../../domain/models/genetic_profile.dart';
import '../../domain/models/horse.dart';
import '../../domain/models/horse_trait_defaults.dart';
import '../../domain/models/horse_trait.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/models/local_account.dart';
import '../../domain/models/mating_session.dart';
import '../../domain/models/pregnancy_record.dart';
import '../../domain/models/rarity_tier.dart';
import '../../domain/models/starter_tier.dart';
import '../sample/sample_horses.dart';

class CommunitySnapshot {
  const CommunitySnapshot({
    required this.profiles,
    required this.listings,
    required this.followedProfileIds,
    required this.likedHorseIds,
  });

  final List<CommunityProfile> profiles;
  final List<CommunityListing> listings;
  final Set<String> followedProfileIds;
  final Set<String> likedHorseIds;
}

class CommunityPurchaseResult {
  const CommunityPurchaseResult({required this.buyerCoinBalance});

  final int buyerCoinBalance;
}

class _ProfileGameState {
  const _ProfileGameState({
    this.inventory = const <InventoryItemType, int>{},
    this.stableExpansionTier = 0,
    this.stableExpansionRenewsAt,
    this.prenatalBoostedPregnancyIds = const <String>{},
    this.carrotBoostedHorseIds = const <String>{},
  });

  final Map<InventoryItemType, int> inventory;
  final int stableExpansionTier;
  final DateTime? stableExpansionRenewsAt;
  final Set<String> prenatalBoostedPregnancyIds;
  final Set<String> carrotBoostedHorseIds;
}

class OwnedGameStateSnapshot {
  const OwnedGameStateSnapshot({
    required this.coinBalance,
    required this.stableHorses,
    required this.activePregnancies,
    required this.breedingCooldowns,
    required this.activeMating,
    required this.inventory,
    required this.stableExpansionTier,
    required this.stableExpansionRenewsAt,
    required this.prenatalBoostedPregnancyIds,
    required this.carrotBoostedHorseIds,
  });

  final int coinBalance;
  final List<Horse> stableHorses;
  final List<PregnancyRecord> activePregnancies;
  final List<BreedingCooldown> breedingCooldowns;
  final MatingSession? activeMating;
  final Map<InventoryItemType, int> inventory;
  final int stableExpansionTier;
  final DateTime? stableExpansionRenewsAt;
  final Set<String> prenatalBoostedPregnancyIds;
  final Set<String> carrotBoostedHorseIds;

  bool get hasOwnedProgress =>
      stableHorses.isNotEmpty ||
      activePregnancies.isNotEmpty ||
      breedingCooldowns.isNotEmpty ||
      activeMating != null;
}

class CommunityRepository {
  const CommunityRepository();

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isSupabaseAvailable => _supabaseClient != null;

  List<CommunityListing> loadInitialListings() => _sampleListings();

  Future<String?> reserveHorseRegistryId() async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return null;
    }
    final result = await supabase.rpc('reserve_horse_registry_id');
    return result as String?;
  }

  Future<CommunitySnapshot> loadSnapshot({
    required String currentUserId,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return CommunitySnapshot(
        profiles: _sampleProfiles(),
        listings: _sampleListings(),
        followedProfileIds: const <String>{},
        likedHorseIds: const <String>{},
      );
    }

    final profilesResponse = await supabase
        .from('profiles')
        .select()
        .neq('id', currentUserId)
        .order('created_at');
    final profileRows = List<Map<String, dynamic>>.from(profilesResponse);
    final profileIds = profileRows
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();

    final followerRows = profileIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supabase
                .from('follows')
                .select('followee_id')
                .inFilter('followee_id', profileIds),
          );
    final followerCounts = <String, int>{};
    for (final row in followerRows) {
      final followeeId = row['followee_id'] as String?;
      if (followeeId == null) {
        continue;
      }
      followerCounts.update(
        followeeId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final publicHorseRows = profileIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supabase
                .from('horses')
                .select('owner_id')
                .or(
                  'is_public_listing.eq.true,is_featured_profile_horse.eq.true,is_listed_for_sale.eq.true',
                )
                .inFilter('owner_id', profileIds),
          );
    final postCounts = <String, int>{};
    for (final row in publicHorseRows) {
      final ownerId = row['owner_id'] as String?;
      if (ownerId == null) {
        continue;
      }
      postCounts.update(ownerId, (count) => count + 1, ifAbsent: () => 1);
    }

    final profiles = profileRows.map((row) {
      final id = row['id'] as String;
      final createdAt =
          DateTime.tryParse((row['created_at'] as String?) ?? '') ??
          DateTime.now();
      return CommunityProfile(
        id: id,
        name: (row['display_name'] as String?) ?? 'Stable Owner',
        handle: (row['handle'] as String?) ?? '@stableowner',
        stableName: (row['stable_name'] as String?) ?? 'Untitled Stable',
        favoriteBreed: (row['favorite_breed'] as String?) ?? 'Arabian',
        followerCount: followerCounts[id] ?? 0,
        weeklyPosts: (postCounts[id] ?? 0).clamp(1, 20),
        bio: (row['bio'] as String?)?.trim().isNotEmpty == true
            ? (row['bio'] as String)
            : 'Public collector profile with visible horses and live listings.',
        accentValue: (row['accent_value'] as num?)?.toInt() ?? 0xFF59F0E4,
        joinedLabel: 'Joined ${createdAt.month}/${createdAt.year}',
      );
    }).toList();

    final followedRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('follows')
          .select('followee_id')
          .eq('follower_id', currentUserId),
    );
    final followedProfileIds = {
      for (final row in followedRows)
        if (row['followee_id'] is String) row['followee_id'] as String,
    };

    final listings = await _loadSupabaseListings(supabase);
    final likedHorseIds = await _loadLikedHorseRegistryIds(
      supabase,
      currentUserId: currentUserId,
    );

    return CommunitySnapshot(
      profiles: profiles,
      listings: listings,
      followedProfileIds: followedProfileIds,
      likedHorseIds: likedHorseIds,
    );
  }

  Future<void> syncCurrentUserProfile(LocalAccount account) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    final displayName = account.displayName.trim().isEmpty
        ? 'Player'
        : account.displayName.trim();
    final handle = account.handle ?? _defaultHandle(displayName);
    await supabase.from('profiles').upsert({
      'id': account.id,
      'email': account.email,
      'display_name': displayName,
      'handle': handle,
      'stable_name': account.stableName ?? '$displayName Stable',
      'favorite_breed': account.favoriteBreed ?? 'Arabian',
      'accent_value': account.accentValue ?? 0xFF59F0E4,
    });
  }

  Future<void> syncCoinBalance({
    required String profileId,
    required int coinBalance,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }
    await supabase
        .from('profiles')
        .update({'coin_balance': coinBalance})
        .eq('id', profileId);
  }

  Future<void> syncProfileGameState({
    required String profileId,
    required int coinBalance,
    required Map<InventoryItemType, int> inventory,
    required int stableExpansionTier,
    required DateTime? stableExpansionRenewsAt,
    required Set<String> prenatalBoostedPregnancyIds,
    required Set<String> carrotBoostedHorseIds,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }
    await supabase
        .from('profiles')
        .update({
          'coin_balance': coinBalance,
          'inventory': _inventoryToJson(inventory),
          'stable_expansion_tier': stableExpansionTier,
          'stable_expansion_renews_at': stableExpansionRenewsAt
              ?.toIso8601String(),
          'prenatal_boosted_pregnancy_ids': prenatalBoostedPregnancyIds
              .toList(),
          'carrot_boosted_horse_ids': carrotBoostedHorseIds.toList(),
        })
        .eq('id', profileId);
  }

  Future<int?> loadCoinBalance({required String profileId}) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return null;
    }
    final row = await supabase
        .from('profiles')
        .select('coin_balance')
        .eq('id', profileId)
        .maybeSingle();
    return (row?['coin_balance'] as num?)?.toInt();
  }

  Future<_ProfileGameState> _loadProfileGameState({
    required String ownerId,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return const _ProfileGameState();
    }

    final row = await supabase
        .from('profiles')
        .select(
          'inventory, stable_expansion_tier, stable_expansion_renews_at, prenatal_boosted_pregnancy_ids, carrot_boosted_horse_ids',
        )
        .eq('id', ownerId)
        .maybeSingle();
    if (row == null) {
      return const _ProfileGameState();
    }

    return _ProfileGameState(
      inventory: _inventoryFromJson(row['inventory']),
      stableExpansionTier: (row['stable_expansion_tier'] as num?)?.toInt() ?? 0,
      stableExpansionRenewsAt: _dateTimeFromJson(
        row['stable_expansion_renews_at'],
      ),
      prenatalBoostedPregnancyIds: _stringSetFromJson(
        row['prenatal_boosted_pregnancy_ids'],
      ),
      carrotBoostedHorseIds: _stringSetFromJson(
        row['carrot_boosted_horse_ids'],
      ),
    );
  }

  Future<OwnedGameStateSnapshot?> loadOwnedGameState({
    required String ownerId,
    Map<String, String> localIdsByRegistry = const <String, String>{},
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return null;
    }

    final coinBalance = await loadCoinBalance(profileId: ownerId) ?? 7000;
    final profileState = await _loadProfileGameState(ownerId: ownerId);
    final stableHorses = await loadOwnedStable(
      ownerId: ownerId,
      localIdsByRegistry: localIdsByRegistry,
    );
    final activePregnancies = await loadOwnedPregnancies(
      ownerId: ownerId,
      localIdsByRegistry: localIdsByRegistry,
    );
    final breedingCooldowns = await loadOwnedBreedingCooldowns(
      ownerId: ownerId,
      localIdsByRegistry: localIdsByRegistry,
    );
    final activeMating = await loadActiveMatingSession(
      ownerId: ownerId,
      localIdsByRegistry: localIdsByRegistry,
    );

    return OwnedGameStateSnapshot(
      coinBalance: coinBalance,
      stableHorses: stableHorses,
      activePregnancies: activePregnancies,
      breedingCooldowns: breedingCooldowns,
      activeMating: activeMating,
      inventory: profileState.inventory,
      stableExpansionTier: profileState.stableExpansionTier,
      stableExpansionRenewsAt: profileState.stableExpansionRenewsAt,
      prenatalBoostedPregnancyIds: profileState.prenatalBoostedPregnancyIds,
      carrotBoostedHorseIds: profileState.carrotBoostedHorseIds,
    );
  }

  Future<List<Horse>> loadOwnedStable({
    required String ownerId,
    Map<String, String> localIdsByRegistry = const <String, String>{},
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return const [];
    }

    final horseRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('horses')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at'),
    );
    if (horseRows.isEmpty) {
      return const [];
    }

    final horseIds = [
      for (final row in horseRows)
        if (row['id'] is String) row['id'] as String,
    ];
    final traitRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('horse_traits')
          .select()
          .inFilter('horse_id', horseIds)
          .order('sort_order'),
    );
    final traitsByHorseId = <String, List<Map<String, dynamic>>>{};
    for (final row in traitRows) {
      final horseId = row['horse_id'] as String?;
      if (horseId == null) {
        continue;
      }
      traitsByHorseId.putIfAbsent(horseId, () => []).add(row);
    }

    return [
      for (final row in horseRows)
        _horseFromDbRow(
          row,
          localId: localIdsByRegistry[row['registry_id'] as String? ?? ''],
          traitRows: traitsByHorseId[row['id'] as String? ?? ''] ?? const [],
        ),
    ];
  }

  Future<void> syncOwnedStable({
    required LocalAccount owner,
    required List<Horse> stableHorses,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    final existingRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('horses')
          .select('id, registry_id')
          .eq('owner_id', owner.id),
    );
    final existingHorseIdsByRegistry = {
      for (final row in existingRows)
        if (row['registry_id'] is String && row['id'] is String)
          row['registry_id'] as String: row['id'] as String,
    };

    final desiredRegistryIds = stableHorses
        .map((horse) => horse.registryId)
        .toSet();
    final staleHorseIds = [
      for (final entry in existingHorseIdsByRegistry.entries)
        if (!desiredRegistryIds.contains(entry.key)) entry.value,
    ];
    if (staleHorseIds.isNotEmpty) {
      await supabase
          .from('horse_listings')
          .delete()
          .inFilter('horse_id', staleHorseIds);
      await supabase.from('horses').delete().inFilter('id', staleHorseIds);
    }

    for (final horse in stableHorses) {
      await supabase
          .from('horses')
          .upsert(
            _horseToDbRow(ownerId: owner.id, horse: horse),
            onConflict: 'registry_id',
          );
    }

    final refreshedRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('horses')
          .select('id, registry_id')
          .eq('owner_id', owner.id),
    );
    final horseIdsByRegistry = {
      for (final row in refreshedRows)
        if (row['registry_id'] is String && row['id'] is String)
          row['registry_id'] as String: row['id'] as String,
    };

    for (final horse in stableHorses) {
      final horseId = horseIdsByRegistry[horse.registryId];
      if (horseId == null) {
        continue;
      }
      await supabase.from('horse_traits').delete().eq('horse_id', horseId);
      await supabase.from('horse_traits').insert([
        for (var index = 0; index < horse.traits.length; index++)
          {
            'horse_id': horseId,
            'trait_type': horse.traits[index].type,
            'trait_option': horse.traits[index].option,
            'rarity': horse.traits[index].rarity.name,
            'sort_order': index,
          },
      ]);

      if (horse.isListedForSale) {
        await supabase.from('horse_listings').upsert({
          'horse_id': horseId,
          'seller_id': owner.id,
          'buyer_price': horse.playerSalePrice,
          'seller_payout': horse.sellerListingPayout,
          'status': 'open',
          'sold_at': null,
        }, onConflict: 'horse_id');
      } else {
        await supabase.from('horse_listings').delete().eq('horse_id', horseId);
      }
    }
  }

  Future<List<PregnancyRecord>> loadOwnedPregnancies({
    required String ownerId,
    Map<String, String> localIdsByRegistry = const <String, String>{},
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return const [];
    }

    final rows = List<Map<String, dynamic>>.from(
      await supabase
          .from('pregnancies')
          .select()
          .eq('owner_id', ownerId)
          .isFilter('delivered_at', null)
          .order('due_at'),
    );
    if (rows.isEmpty) {
      return const [];
    }

    final horseIds = <String>{
      for (final row in rows) ...[
        if (row['dam_id'] is String) row['dam_id'] as String,
        if (row['sire_id'] is String) row['sire_id'] as String,
      ],
    }.toList();
    final horseRows = horseIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supabase
                .from('horses')
                .select('id, registry_id')
                .inFilter('id', horseIds),
          );
    final registryByDbHorseId = {
      for (final row in horseRows)
        if (row['id'] is String && row['registry_id'] is String)
          row['id'] as String: row['registry_id'] as String,
    };

    return rows.map((row) {
      final damRegistryId = registryByDbHorseId[row['dam_id'] as String? ?? ''];
      final sireRegistryId =
          registryByDbHorseId[row['sire_id'] as String? ?? ''];
      return PregnancyRecord(
        id: row['id'] as String,
        damId: localIdsByRegistry[damRegistryId ?? ''] ?? damRegistryId ?? '',
        damName: row['dam_name'] as String? ?? 'Dam',
        sireId:
            localIdsByRegistry[sireRegistryId ?? ''] ?? sireRegistryId ?? '',
        sireName: row['sire_name'] as String? ?? 'Sire',
        unbornFoalName: row['unborn_foal_name'] as String? ?? 'Reserved Foal',
        registryId: row['registry_id'] as String? ?? 'PENDING',
        breed: row['breed'] as String? ?? 'Horse',
        foal:
            _horseSnapshotFromJson(row['foal_payload']) ??
            Horse(
              id: row['registry_id'] as String? ?? 'PENDING',
              registryId: row['registry_id'] as String? ?? 'PENDING',
              registeredName:
                  row['unborn_foal_name'] as String? ?? 'Reserved Foal',
              currentName:
                  row['unborn_foal_name'] as String? ?? 'Reserved Foal',
              breed: row['breed'] as String? ?? 'Horse',
              sex: 'Mare',
              generation: 1,
              ageDays: Horse.newbornAgeDays,
              breedingRetirementDays: Horse.breedingRetirementAgeDays,
              traits: const [],
              starterTier: StarterTier.basic,
              price: 0,
              geneticProfile: const GeneticProfile(
                breedingPotential: 'Steady starter depth',
                bloodlineScore: 40,
                mutationAffinity: 0,
                rareTraitChances: {},
              ),
              careStats: const CareStats(
                hungerLevel: 75,
                happinessLevel: 75,
                energyLevel: 75,
                saltLickEnjoyment: 75,
              ),
            ),
        conceivedAt:
            DateTime.tryParse(row['conceived_at'] as String? ?? '') ??
            DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
        dueAt:
            DateTime.tryParse(row['due_at'] as String? ?? '') ?? DateTime.now(),
        damCooldownEndsAt:
            DateTime.tryParse(row['dam_cooldown_ends_at'] as String? ?? '') ??
            DateTime.tryParse(row['due_at'] as String? ?? '') ??
            DateTime.now(),
        sireCooldownEndsAt:
            DateTime.tryParse(row['sire_cooldown_ends_at'] as String? ?? '') ??
            DateTime.tryParse(row['due_at'] as String? ?? '') ??
            DateTime.now(),
        isMutant: row['is_mutant'] as bool? ?? false,
      );
    }).toList();
  }

  Future<List<BreedingCooldown>> loadOwnedBreedingCooldowns({
    required String ownerId,
    Map<String, String> localIdsByRegistry = const <String, String>{},
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return const [];
    }

    final rows = List<Map<String, dynamic>>.from(
      await supabase
          .from('breeding_cooldowns')
          .select()
          .eq('owner_id', ownerId)
          .order('ends_at'),
    );
    if (rows.isEmpty) {
      return const [];
    }

    final horseIds = [
      for (final row in rows)
        if (row['horse_id'] is String) row['horse_id'] as String,
    ];
    final horseRows = horseIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supabase
                .from('horses')
                .select('id, registry_id')
                .inFilter('id', horseIds),
          );
    final registryByDbHorseId = {
      for (final row in horseRows)
        if (row['id'] is String && row['registry_id'] is String)
          row['id'] as String: row['registry_id'] as String,
    };

    return rows.map((row) {
      final registryId = registryByDbHorseId[row['horse_id'] as String? ?? ''];
      return BreedingCooldown(
        horseId: localIdsByRegistry[registryId ?? ''] ?? registryId ?? '',
        horseName: row['horse_name'] as String? ?? 'Horse',
        sex: row['sex'] as String? ?? 'Mare',
        reason: row['reason'] as String? ?? 'Recovery',
        endsAt:
            DateTime.tryParse(row['ends_at'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<MatingSession?> loadActiveMatingSession({
    required String ownerId,
    Map<String, String> localIdsByRegistry = const <String, String>{},
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return null;
    }

    final row = await supabase
        .from('mating_sessions')
        .select()
        .eq('owner_id', ownerId)
        .isFilter('resolved_at', null)
        .order('started_at')
        .limit(1)
        .maybeSingle();
    if (row == null) {
      return null;
    }

    final horseIds = [
      if (row['dam_id'] is String) row['dam_id'] as String,
      if (row['sire_id'] is String) row['sire_id'] as String,
    ];
    final horseRows = horseIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
            await supabase
                .from('horses')
                .select('id, registry_id')
                .inFilter('id', horseIds),
          );
    final registryByDbHorseId = {
      for (final horseRow in horseRows)
        if (horseRow['id'] is String && horseRow['registry_id'] is String)
          horseRow['id'] as String: horseRow['registry_id'] as String,
    };

    final damRegistryId = registryByDbHorseId[row['dam_id'] as String? ?? ''];
    final sireRegistryId = registryByDbHorseId[row['sire_id'] as String? ?? ''];

    return MatingSession(
      id: row['id'] as String,
      damId: localIdsByRegistry[damRegistryId ?? ''] ?? damRegistryId ?? '',
      damName: row['dam_name'] as String? ?? 'Dam',
      sireId: localIdsByRegistry[sireRegistryId ?? ''] ?? sireRegistryId ?? '',
      sireName: row['sire_name'] as String? ?? 'Sire',
      startedAt:
          DateTime.tryParse(row['started_at'] as String? ?? '') ??
          DateTime.now(),
      endsAt:
          DateTime.tryParse(row['ends_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Future<void> syncOwnedBreedingState({
    required String ownerId,
    required List<Horse> stableHorses,
    required List<PregnancyRecord> activePregnancies,
    required List<BreedingCooldown> breedingCooldowns,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    final horseRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('horses')
          .select('id, registry_id')
          .eq('owner_id', ownerId),
    );
    final dbHorseIdByRegistry = {
      for (final row in horseRows)
        if (row['id'] is String && row['registry_id'] is String)
          row['registry_id'] as String: row['id'] as String,
    };
    final stableHorseById = {for (final horse in stableHorses) horse.id: horse};

    await supabase.from('pregnancies').delete().eq('owner_id', ownerId);
    final pregnancyRows = <Map<String, dynamic>>[];
    for (final pregnancy in activePregnancies) {
      final damRegistryId =
          stableHorseById[pregnancy.damId]?.registryId ?? pregnancy.damId;
      final sireRegistryId =
          stableHorseById[pregnancy.sireId]?.registryId ?? pregnancy.sireId;
      final damDbId = dbHorseIdByRegistry[damRegistryId];
      final sireDbId = dbHorseIdByRegistry[sireRegistryId];
      if (damDbId == null || sireDbId == null) {
        continue;
      }
      pregnancyRows.add({
        'id': pregnancy.id,
        'owner_id': ownerId,
        'dam_id': damDbId,
        'dam_name': pregnancy.damName,
        'sire_id': sireDbId,
        'sire_name': pregnancy.sireName,
        'unborn_foal_name': pregnancy.unbornFoalName,
        'registry_id': pregnancy.registryId,
        'breed': pregnancy.breed,
        'foal_payload': _horseSnapshotToJson(pregnancy.foal),
        'conceived_at': pregnancy.conceivedAt.toIso8601String(),
        'due_at': pregnancy.dueAt.toIso8601String(),
        'dam_cooldown_ends_at': pregnancy.damCooldownEndsAt.toIso8601String(),
        'sire_cooldown_ends_at': pregnancy.sireCooldownEndsAt.toIso8601String(),
        'is_mutant': pregnancy.isMutant,
        'delivered_at': null,
      });
    }
    if (pregnancyRows.isNotEmpty) {
      await supabase.from('pregnancies').insert(pregnancyRows);
    }

    await supabase.from('breeding_cooldowns').delete().eq('owner_id', ownerId);
    final cooldownRows = <Map<String, dynamic>>[];
    for (final cooldown in breedingCooldowns) {
      final registryId =
          stableHorseById[cooldown.horseId]?.registryId ?? cooldown.horseId;
      final horseDbId = dbHorseIdByRegistry[registryId];
      if (horseDbId == null) {
        continue;
      }
      cooldownRows.add({
        'owner_id': ownerId,
        'horse_id': horseDbId,
        'horse_name': cooldown.horseName,
        'sex': cooldown.sex,
        'reason': cooldown.reason,
        'ends_at': cooldown.endsAt.toIso8601String(),
      });
    }
    if (cooldownRows.isNotEmpty) {
      await supabase.from('breeding_cooldowns').insert(cooldownRows);
    }
  }

  Future<void> syncOwnedGameState({
    required LocalAccount owner,
    required List<Horse> stableHorses,
    required List<PregnancyRecord> activePregnancies,
    required List<BreedingCooldown> breedingCooldowns,
    required int coinBalance,
    required Map<InventoryItemType, int> inventory,
    required int stableExpansionTier,
    required DateTime? stableExpansionRenewsAt,
    required Set<String> prenatalBoostedPregnancyIds,
    required Set<String> carrotBoostedHorseIds,
  }) async {
    await syncProfileGameState(
      profileId: owner.id,
      coinBalance: coinBalance,
      inventory: inventory,
      stableExpansionTier: stableExpansionTier,
      stableExpansionRenewsAt: stableExpansionRenewsAt,
      prenatalBoostedPregnancyIds: prenatalBoostedPregnancyIds,
      carrotBoostedHorseIds: carrotBoostedHorseIds,
    );
    await syncOwnedStable(owner: owner, stableHorses: stableHorses);
    await syncOwnedBreedingState(
      ownerId: owner.id,
      stableHorses: stableHorses,
      activePregnancies: activePregnancies,
      breedingCooldowns: breedingCooldowns,
    );
  }

  Map<String, int> _inventoryToJson(Map<InventoryItemType, int> inventory) {
    return {
      for (final entry in inventory.entries)
        if (entry.value > 0) inventoryItemTypeKey(entry.key): entry.value,
    };
  }

  Map<InventoryItemType, int> _inventoryFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return const {};
    }

    final inventory = <InventoryItemType, int>{};
    for (final entry in raw.entries) {
      final type = inventoryItemTypeFromKey(entry.key);
      final quantity = entry.value is num ? (entry.value as num).toInt() : 0;
      if (type != null && quantity > 0) {
        inventory[type] = quantity;
      }
    }
    return inventory;
  }

  Set<String> _stringSetFromJson(dynamic raw) {
    if (raw is! List<dynamic>) {
      return const <String>{};
    }
    return {...raw.whereType<String>()};
  }

  DateTime? _dateTimeFromJson(dynamic raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<MatingSession?> startMatingSession({
    required Horse dam,
    required Horse sire,
    required PregnancyRecord standardPregnancy,
    required PregnancyRecord mutantPregnancy,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return null;
    }

    final result = await supabase.rpc(
      'start_mating_session',
      params: {
        'dam_registry_id': dam.registryId,
        'sire_registry_id': sire.registryId,
        'standard_pregnancy_payload': _pregnancyCandidateToJson(
          standardPregnancy,
        ),
        'mutant_pregnancy_payload': _pregnancyCandidateToJson(mutantPregnancy),
      },
    );
    if (result is! Map<String, dynamic>) {
      return null;
    }

    return MatingSession(
      id: result['id'] as String,
      damId: dam.id,
      damName: result['dam_name'] as String? ?? dam.displayName,
      sireId: sire.id,
      sireName: result['sire_name'] as String? ?? sire.displayName,
      startedAt:
          DateTime.tryParse(result['started_at'] as String? ?? '') ??
          DateTime.now(),
      endsAt:
          DateTime.tryParse(result['ends_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Future<void> resolveMatingSession({required String sessionId}) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }
    await supabase.rpc(
      'resolve_mating_session',
      params: {'target_session_id': sessionId},
    );
  }

  Future<void> deliverPregnancy({required String pregnancyId}) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }
    await supabase.rpc(
      'deliver_pregnancy',
      params: {'target_pregnancy_id': pregnancyId},
    );
  }

  Future<void> toggleFollow({
    required String followerId,
    required String followeeId,
    required bool shouldFollow,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }
    if (shouldFollow) {
      await supabase.from('follows').upsert({
        'follower_id': followerId,
        'followee_id': followeeId,
      });
      return;
    }
    await supabase
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('followee_id', followeeId);
  }

  Future<void> toggleHorseLike({
    required String profileId,
    required Horse horse,
    required bool shouldLike,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    final horseId = await _horseIdForRegistryId(
      supabase,
      registryId: horse.registryId,
    );
    if (horseId == null) {
      return;
    }

    if (shouldLike) {
      await supabase.from('horse_likes').upsert({
        'profile_id': profileId,
        'horse_id': horseId,
      });
      return;
    }

    await supabase
        .from('horse_likes')
        .delete()
        .eq('profile_id', profileId)
        .eq('horse_id', horseId);
  }

  Future<CommunityPurchaseResult?> purchaseListing({
    required String listingId,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return null;
    }

    final result = await supabase.rpc(
      'purchase_horse_listing',
      params: {'target_listing_id': listingId},
    );
    if (result is! Map<String, dynamic>) {
      return null;
    }
    return CommunityPurchaseResult(
      buyerCoinBalance: (result['buyer_coin_balance'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<CommunityListing>> _loadSupabaseListings(
    SupabaseClient supabase,
  ) async {
    final listingRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('horse_listings')
          .select('id, horse_id, seller_id, buyer_price, seller_payout')
          .eq('status', 'open')
          .order('created_at'),
    );
    if (listingRows.isEmpty) {
      return const [];
    }

    final horseIds = [
      for (final row in listingRows)
        if (row['horse_id'] is String) row['horse_id'] as String,
    ];
    final sellerIds = [
      for (final row in listingRows)
        if (row['seller_id'] is String) row['seller_id'] as String,
    ];

    final horseRows = List<Map<String, dynamic>>.from(
      await supabase.from('horses').select().inFilter('id', horseIds),
    );
    final traitRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('horse_traits')
          .select()
          .inFilter('horse_id', horseIds)
          .order('sort_order'),
    );
    final sellerRows = List<Map<String, dynamic>>.from(
      await supabase.from('profiles').select().inFilter('id', sellerIds),
    );

    final traitsByHorseId = <String, List<Map<String, dynamic>>>{};
    for (final row in traitRows) {
      final horseId = row['horse_id'] as String?;
      if (horseId == null) {
        continue;
      }
      traitsByHorseId.putIfAbsent(horseId, () => []).add(row);
    }

    final horsesById = {
      for (final row in horseRows)
        if (row['id'] is String)
          row['id'] as String: _horseFromDbRow(
            row,
            traitRows: traitsByHorseId[row['id'] as String] ?? const [],
          ),
    };
    final sellersById = {
      for (final row in sellerRows)
        if (row['id'] is String) row['id'] as String: row,
    };

    final listings = <CommunityListing>[];
    for (final row in listingRows) {
      final horseId = row['horse_id'] as String?;
      final sellerId = row['seller_id'] as String?;
      final horse = horseId == null ? null : horsesById[horseId];
      final seller = sellerId == null ? null : sellersById[sellerId];
      if (horse == null || seller == null) {
        continue;
      }
      listings.add(
        CommunityListing(
          id: row['id'] as String,
          sellerProfileId: sellerId!,
          sellerName: (seller['display_name'] as String?) ?? 'Stable Owner',
          sellerHandle: (seller['handle'] as String?) ?? '@stableowner',
          sellerStableName:
              (seller['stable_name'] as String?) ?? 'Untitled Stable',
          horse: horse,
          sellerPayout: (row['seller_payout'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    return listings;
  }

  Future<Set<String>> _loadLikedHorseRegistryIds(
    SupabaseClient supabase, {
    required String currentUserId,
  }) async {
    final likeRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('horse_likes')
          .select('horse_id')
          .eq('profile_id', currentUserId),
    );
    if (likeRows.isEmpty) {
      return const <String>{};
    }
    final horseIds = [
      for (final row in likeRows)
        if (row['horse_id'] is String) row['horse_id'] as String,
    ];
    final horseRows = List<Map<String, dynamic>>.from(
      await supabase
          .from('horses')
          .select('id, registry_id')
          .inFilter('id', horseIds),
    );
    return {
      for (final row in horseRows)
        if (row['registry_id'] is String) row['registry_id'] as String,
    };
  }

  Future<String?> _horseIdForRegistryId(
    SupabaseClient supabase, {
    required String registryId,
  }) async {
    final row = await supabase
        .from('horses')
        .select('id')
        .eq('registry_id', registryId)
        .maybeSingle();
    return row?['id'] as String?;
  }

  Map<String, dynamic> _pregnancyCandidateToJson(PregnancyRecord record) {
    return {
      'unbornFoalName': record.unbornFoalName,
      'registryId': record.registryId,
      'breed': record.breed,
      'foal': _horseSnapshotToJson(record.foal),
      'isMutant': record.isMutant,
    };
  }

  Map<String, dynamic> _horseToDbRow({
    required String ownerId,
    required Horse horse,
  }) {
    return {
      'owner_id': ownerId,
      'registry_id': horse.registryId,
      'registered_name': horse.registeredName,
      'current_name': horse.currentName,
      'breed': horse.breed,
      'sex': horse.sex,
      'generation': horse.generation,
      'age_days': horse.ageDays,
      'breeding_retirement_days': horse.breedingRetirementDays,
      'starter_tier': horse.starterTier.name,
      'price': horse.price,
      'transfer_count': horse.transferCount,
      'is_mutant': horse.isMutant,
      'is_public_listing': horse.isPublicListing,
      'is_featured_profile_horse': horse.isFeaturedProfileHorse,
      'is_listed_for_sale': horse.isListedForSale,
      'genetic_profile': _geneticProfileToJson(horse.geneticProfile),
      'care_stats': _careStatsToJson(horse.careStats),
      'lineage_memory': horse.lineageMemory,
      'special_traits': horse.specialTraits,
      'dam_snapshot': horse.damSnapshot == null
          ? null
          : _horseSnapshotToJson(horse.damSnapshot!),
      'sire_snapshot': horse.sireSnapshot == null
          ? null
          : _horseSnapshotToJson(horse.sireSnapshot!),
    };
  }

  Horse _horseFromDbRow(
    Map<String, dynamic> row, {
    String? localId,
    required List<Map<String, dynamic>> traitRows,
  }) {
    final registryId = row['registry_id'] as String;
    return normalizeHorseVisibleTraits(
      Horse(
        id: localId ?? registryId,
        registryId: registryId,
        registeredName: row['registered_name'] as String,
        currentName: row['current_name'] as String,
        breed: row['breed'] as String,
        sex: row['sex'] as String,
        generation: (row['generation'] as num?)?.toInt() ?? 1,
        ageDays: (row['age_days'] as num?)?.toInt() ?? 1,
        breedingRetirementDays:
            (row['breeding_retirement_days'] as num?)?.toInt() ??
            Horse.breedingRetirementAgeDays,
        traits: [
          for (final traitRow in traitRows)
            HorseTrait(
              type: traitRow['trait_type'] as String,
              option: traitRow['trait_option'] as String,
              rarity: _rarityFromName(traitRow['rarity'] as String?),
            ),
        ],
        starterTier: _starterTierFromName(row['starter_tier'] as String?),
        price: (row['price'] as num?)?.toInt() ?? 0,
        geneticProfile: _geneticProfileFromJson(row['genetic_profile']),
        careStats: _careStatsFromJson(row['care_stats']),
        transferCount: (row['transfer_count'] as num?)?.toInt() ?? 0,
        specialTraits: (row['special_traits'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        lineageMemory: _lineageMemoryFromJson(row['lineage_memory']),
        isMutant: row['is_mutant'] as bool? ?? false,
        isPublicListing: row['is_public_listing'] as bool? ?? false,
        isFeaturedProfileHorse:
            row['is_featured_profile_horse'] as bool? ?? false,
        isListedForSale: row['is_listed_for_sale'] as bool? ?? false,
        damSnapshot: _horseSnapshotFromJson(row['dam_snapshot']),
        sireSnapshot: _horseSnapshotFromJson(row['sire_snapshot']),
      ),
    );
  }

  Map<String, dynamic> _horseSnapshotToJson(Horse horse) {
    return {
      'id': horse.id,
      'registry_id': horse.registryId,
      'registered_name': horse.registeredName,
      'current_name': horse.currentName,
      'breed': horse.breed,
      'sex': horse.sex,
      'generation': horse.generation,
      'age_days': horse.ageDays,
      'breeding_retirement_days': horse.breedingRetirementDays,
      'traits': [
        for (final trait in horse.traits)
          {
            'type': trait.type,
            'option': trait.option,
            'rarity': trait.rarity.name,
          },
      ],
      'starter_tier': horse.starterTier.name,
      'price': horse.price,
      'transfer_count': horse.transferCount,
      'special_traits': horse.specialTraits,
      'lineage_memory': horse.lineageMemory,
      'is_mutant': horse.isMutant,
      'is_public_listing': horse.isPublicListing,
      'is_featured_profile_horse': horse.isFeaturedProfileHorse,
      'is_listed_for_sale': horse.isListedForSale,
      'genetic_profile': _geneticProfileToJson(horse.geneticProfile),
      'care_stats': _careStatsToJson(horse.careStats),
      'dam_snapshot': horse.damSnapshot == null
          ? null
          : _horseSnapshotToJson(horse.damSnapshot!),
      'sire_snapshot': horse.sireSnapshot == null
          ? null
          : _horseSnapshotToJson(horse.sireSnapshot!),
    };
  }

  Horse? _horseSnapshotFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return normalizeHorseVisibleTraits(
      Horse(
        id: raw['id'] as String? ?? raw['registry_id'] as String? ?? 'snapshot',
        registryId: raw['registry_id'] as String? ?? 'snapshot',
        registeredName: raw['registered_name'] as String? ?? 'Snapshot',
        currentName: raw['current_name'] as String? ?? 'Snapshot',
        breed: raw['breed'] as String? ?? 'Horse',
        sex: raw['sex'] as String? ?? 'Mare',
        generation: (raw['generation'] as num?)?.toInt() ?? 1,
        ageDays: (raw['age_days'] as num?)?.toInt() ?? 1,
        breedingRetirementDays:
            (raw['breeding_retirement_days'] as num?)?.toInt() ??
            Horse.breedingRetirementAgeDays,
        traits: [
          for (final trait in (raw['traits'] as List<dynamic>? ?? const []))
            if (trait is Map<String, dynamic>)
              HorseTrait(
                type: trait['type'] as String? ?? 'body_type',
                option: trait['option'] as String? ?? 'Unknown',
                rarity: _rarityFromName(trait['rarity'] as String?),
              ),
        ],
        starterTier: _starterTierFromName(raw['starter_tier'] as String?),
        price: (raw['price'] as num?)?.toInt() ?? 0,
        geneticProfile: _geneticProfileFromJson(raw['genetic_profile']),
        careStats: _careStatsFromJson(raw['care_stats']),
        transferCount: (raw['transfer_count'] as num?)?.toInt() ?? 0,
        specialTraits: (raw['special_traits'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        lineageMemory: _lineageMemoryFromJson(raw['lineage_memory']),
        isMutant: raw['is_mutant'] as bool? ?? false,
        isPublicListing: raw['is_public_listing'] as bool? ?? false,
        isFeaturedProfileHorse:
            raw['is_featured_profile_horse'] as bool? ?? false,
        isListedForSale: raw['is_listed_for_sale'] as bool? ?? false,
        damSnapshot: _horseSnapshotFromJson(raw['dam_snapshot']),
        sireSnapshot: _horseSnapshotFromJson(raw['sire_snapshot']),
      ),
    );
  }

  GeneticProfile _geneticProfileFromJson(dynamic raw) {
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final rareTraitChances =
        json['rareTraitChances'] as Map<String, dynamic>? ??
        json['rare_trait_chances'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return GeneticProfile(
      breedingPotential:
          json['breedingPotential'] as String? ??
          json['breeding_potential'] as String? ??
          'Steady starter depth',
      bloodlineScore:
          (json['bloodlineScore'] as num?)?.toInt() ??
          (json['bloodline_score'] as num?)?.toInt() ??
          40,
      mutationAffinity:
          (json['mutationAffinity'] as num?)?.toDouble() ??
          (json['mutation_affinity'] as num?)?.toDouble() ??
          0.0,
      rareTraitChances: {
        for (final entry in rareTraitChances.entries)
          entry.key: (entry.value as num).toDouble(),
      },
    );
  }

  Map<String, dynamic> _geneticProfileToJson(GeneticProfile profile) {
    return {
      'breedingPotential': profile.breedingPotential,
      'bloodlineScore': profile.bloodlineScore,
      'mutationAffinity': profile.mutationAffinity,
      'rareTraitChances': profile.rareTraitChances,
    };
  }

  CareStats _careStatsFromJson(dynamic raw) {
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    return CareStats(
      hungerLevel:
          (json['hungerLevel'] as num?)?.toInt() ??
          (json['hunger_level'] as num?)?.toInt() ??
          75,
      happinessLevel:
          (json['happinessLevel'] as num?)?.toInt() ??
          (json['happiness_level'] as num?)?.toInt() ??
          75,
      energyLevel:
          (json['energyLevel'] as num?)?.toInt() ??
          (json['energy_level'] as num?)?.toInt() ??
          75,
      saltLickEnjoyment:
          (json['saltLickEnjoyment'] as num?)?.toInt() ??
          (json['salt_lick_enjoyment'] as num?)?.toInt() ??
          75,
    );
  }

  Map<String, dynamic> _careStatsToJson(CareStats stats) {
    return {
      'hungerLevel': stats.hungerLevel,
      'happinessLevel': stats.happinessLevel,
      'energyLevel': stats.energyLevel,
      'saltLickEnjoyment': stats.saltLickEnjoyment,
    };
  }

  Map<String, Map<String, int>> _lineageMemoryFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return const <String, Map<String, int>>{};
    }
    return {
      for (final entry in raw.entries)
        if (entry.value is Map<String, dynamic>)
          entry.key: {
            for (final depthEntry
                in (entry.value as Map<String, dynamic>).entries)
              depthEntry.key: (depthEntry.value as num).toInt(),
          },
    };
  }

  RarityTier _rarityFromName(String? name) {
    if (name == null) {
      return RarityTier.common;
    }
    return RarityTier.values.firstWhere(
      (tier) => tier.name == name,
      orElse: () => RarityTier.common,
    );
  }

  StarterTier _starterTierFromName(String? name) {
    if (name == null) {
      return StarterTier.basic;
    }
    return StarterTier.values.firstWhere(
      (tier) => tier.name == name,
      orElse: () => StarterTier.basic,
    );
  }

  String _defaultHandle(String displayName) {
    final cleaned = displayName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    return '@${cleaned.isEmpty ? 'stableowner' : cleaned}';
  }

  List<CommunityProfile> _sampleProfiles() {
    return const [
      CommunityProfile(
        id: 'mina',
        name: 'Mina Rios',
        handle: '@goldmane',
        stableName: 'Sunrail Stables',
        favoriteBreed: 'Arabian',
        followerCount: 248,
        weeklyPosts: 12,
        bio:
            'Mina tracks elegant desert lines and curates bright collector horses with clean pedigrees.',
        accentValue: 0xFF59F0E4,
        joinedLabel: 'Joined Season 1',
      ),
      CommunityProfile(
        id: 'theo',
        name: 'Theo Marsh',
        handle: '@marshline',
        stableName: 'Blue Creek Farm',
        favoriteBreed: 'Appaloosa',
        followerCount: 311,
        weeklyPosts: 8,
        bio:
            'Theo favors rugged sale picks, sturdy sires, and durable working bloodlines.',
        accentValue: 0xFFFF5C8A,
        joinedLabel: 'Joined Season 1',
      ),
      CommunityProfile(
        id: 'jules',
        name: 'Jules Hart',
        handle: '@foalwatch',
        stableName: 'Silver Lantern',
        favoriteBreed: 'Percheron',
        followerCount: 189,
        weeklyPosts: 15,
        bio:
            'Jules spotlights newborns, pedigree notes, and young lines that age into serious value.',
        accentValue: 0xFFFFC857,
        joinedLabel: 'Joined Season 2',
      ),
      CommunityProfile(
        id: 'asha',
        name: 'Asha Bell',
        handle: '@lineageatlas',
        stableName: 'Cinder Gate',
        favoriteBreed: 'Paint Horse',
        followerCount: 427,
        weeklyPosts: 10,
        bio:
            'Asha curates premium sale watchlists with a bias toward collector-grade public horses.',
        accentValue: 0xFFB36BFF,
        joinedLabel: 'Joined Season 2',
      ),
    ];
  }

  List<CommunityListing> _sampleListings() {
    return [
      _sampleListing(
        sellerProfileId: 'mina',
        sellerName: 'Mina Rios',
        sellerHandle: '@goldmane',
        sellerStableName: 'Sunrail Stables',
        horse: starterMarketHorses[3].copyWith(
          id: 'community_mina_silver_lark',
          currentName: 'Velvet Halo',
          registeredName: 'Velvet Halo',
          starterTier: StarterTier.premium,
          transferCount: 1,
          isPublicListing: true,
          isFeaturedProfileHorse: true,
          isListedForSale: true,
        ),
      ),
      _sampleListing(
        sellerProfileId: 'theo',
        sellerName: 'Theo Marsh',
        sellerHandle: '@marshline',
        sellerStableName: 'Blue Creek Farm',
        horse: starterMarketHorses[4].copyWith(
          id: 'community_theo_spotted_fern',
          currentName: 'Copper Anthem',
          registeredName: 'Copper Anthem',
          transferCount: 2,
          isPublicListing: true,
          isFeaturedProfileHorse: false,
          isListedForSale: true,
        ),
      ),
      _sampleListing(
        sellerProfileId: 'jules',
        sellerName: 'Jules Hart',
        sellerHandle: '@foalwatch',
        sellerStableName: 'Silver Lantern',
        horse: starterMarketHorses[2].copyWith(
          id: 'community_jules_marble_fawn',
          currentName: 'Ash Verse',
          registeredName: 'Ash Verse',
          transferCount: 1,
          isPublicListing: true,
          isFeaturedProfileHorse: true,
          isListedForSale: true,
        ),
      ),
      _sampleListing(
        sellerProfileId: 'asha',
        sellerName: 'Asha Bell',
        sellerHandle: '@lineageatlas',
        sellerStableName: 'Cinder Gate',
        horse: starterMarketHorses[5].copyWith(
          id: 'community_asha_bramble_row',
          currentName: 'Rose Circuit',
          registeredName: 'Rose Circuit',
          transferCount: 3,
          isPublicListing: true,
          isFeaturedProfileHorse: true,
          isListedForSale: true,
        ),
      ),
    ];
  }

  CommunityListing _sampleListing({
    required String sellerProfileId,
    required String sellerName,
    required String sellerHandle,
    required String sellerStableName,
    required Horse horse,
  }) {
    return CommunityListing(
      id: 'listing_${horse.id}',
      sellerProfileId: sellerProfileId,
      sellerName: sellerName,
      sellerHandle: sellerHandle,
      sellerStableName: sellerStableName,
      sellerPayout: horse.sellerListingPayout,
      horse: horse,
    );
  }
}
