import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/care_stats.dart';
import '../../domain/models/breeding_cooldown.dart';
import '../../domain/models/community_listing.dart';
import '../../domain/models/genetic_profile.dart';
import '../../domain/models/horse.dart';
import '../../domain/models/horse_trait_defaults.dart';
import '../../domain/models/horse_trait.dart';
import '../../domain/models/inventory_item.dart';
import '../../domain/models/mating_session.dart';
import '../../domain/models/pregnancy_record.dart';
import '../../domain/models/rarity_tier.dart';
import '../../domain/models/starter_tier.dart';

class PersistedGameState {
  const PersistedGameState({
    required this.currentTime,
    required this.stableHorses,
    required this.marketHorses,
    required this.coinBalance,
    required this.selectedIndex,
    required this.foalSequence,
    required this.marketPurchaseSequence,
    required this.likedHorseIds,
    required this.followedProfileIds,
    required this.communityListings,
    required this.breedingCooldowns,
    required this.activePregnancies,
    required this.inventory,
    required this.stableExpansionTier,
    this.stableExpansionRenewsAt,
    required this.prenatalBoostedPregnancyIds,
    required this.carrotBoostedHorseIds,
    required this.readStableAlertIds,
    this.activeMating,
    this.latestBornFoalId,
    this.selectedDamId,
    this.selectedSireId,
  });

  final DateTime currentTime;
  final List<Horse> stableHorses;
  final List<Horse> marketHorses;
  final List<PregnancyRecord> activePregnancies;
  final MatingSession? activeMating;
  final String? latestBornFoalId;
  final int coinBalance;
  final int selectedIndex;
  final int foalSequence;
  final int marketPurchaseSequence;
  final String? selectedDamId;
  final String? selectedSireId;
  final Set<String> likedHorseIds;
  final Set<String> followedProfileIds;
  final List<CommunityListing> communityListings;
  final List<BreedingCooldown> breedingCooldowns;
  final Map<InventoryItemType, int> inventory;
  final int stableExpansionTier;
  final DateTime? stableExpansionRenewsAt;
  final Set<String> prenatalBoostedPregnancyIds;
  final Set<String> carrotBoostedHorseIds;
  final Set<String> readStableAlertIds;
}

class GameStateRepository {
  const GameStateRepository();

  static const int _saveVersion = 6;
  static const int _minimumSupportedSaveVersion = 1;

  Future<PersistedGameState?> loadState(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawState = prefs.getString(_stateKey(accountId));
    if (rawState == null || rawState.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawState);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final version = (decoded['version'] as num?)?.toInt();
      if (version == null ||
          version < _minimumSupportedSaveVersion ||
          version > _saveVersion) {
        return null;
      }

      return PersistedGameState(
        currentTime: DateTime.parse(decoded['currentTime'] as String),
        stableHorses: _horseListFromJson(decoded['stableHorses']),
        marketHorses: _horseListFromJson(decoded['marketHorses']),
        activePregnancies: _pregnancyListFromJson(
          decoded['activePregnancies'],
          fallback: _pregnancyFromJson(decoded['activePregnancy']),
        ),
        activeMating: _matingFromJson(decoded['activeMating']),
        latestBornFoalId: decoded['latestBornFoalId'] as String?,
        coinBalance: (decoded['coinBalance'] as num?)?.toInt() ?? 7000,
        selectedIndex: (decoded['selectedIndex'] as num?)?.toInt() ?? 0,
        foalSequence: (decoded['foalSequence'] as num?)?.toInt() ?? 2000,
        marketPurchaseSequence:
            (decoded['marketPurchaseSequence'] as num?)?.toInt() ?? 5000,
        selectedDamId: decoded['selectedDamId'] as String?,
        selectedSireId: decoded['selectedSireId'] as String?,
        likedHorseIds: {
          ...((decoded['likedHorseIds'] as List<dynamic>? ?? const [])
              .whereType<String>()),
        },
        followedProfileIds: {
          ...((decoded['followedProfileIds'] as List<dynamic>? ?? const [])
              .whereType<String>()),
        },
        communityListings: _communityListingsFromJson(
          decoded['communityListings'],
        ),
        breedingCooldowns: _cooldownListFromJson(decoded['breedingCooldowns']),
        inventory: _inventoryFromJson(decoded['inventory']),
        stableExpansionTier:
            (decoded['stableExpansionTier'] as num?)?.toInt() ?? 0,
        stableExpansionRenewsAt: _dateTimeFromJson(
          decoded['stableExpansionRenewsAt'],
        ),
        prenatalBoostedPregnancyIds: {
          ...((decoded['prenatalBoostedPregnancyIds'] as List<dynamic>? ??
                  const [])
              .whereType<String>()),
        },
        carrotBoostedHorseIds: {
          ...((decoded['carrotBoostedHorseIds'] as List<dynamic>? ?? const [])
              .whereType<String>()),
        },
        readStableAlertIds: {
          ...((decoded['readStableAlertIds'] as List<dynamic>? ?? const [])
              .whereType<String>()),
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveState(String accountId, PersistedGameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      'version': _saveVersion,
      'currentTime': state.currentTime.toIso8601String(),
      'stableHorses': state.stableHorses.map(_horseToJson).toList(),
      'marketHorses': state.marketHorses.map(_horseToJson).toList(),
      'activePregnancies': state.activePregnancies
          .map(_pregnancyToJson)
          .toList(),
      'activeMating': _matingToJson(state.activeMating),
      'latestBornFoalId': state.latestBornFoalId,
      'coinBalance': state.coinBalance,
      'selectedIndex': state.selectedIndex,
      'foalSequence': state.foalSequence,
      'marketPurchaseSequence': state.marketPurchaseSequence,
      'selectedDamId': state.selectedDamId,
      'selectedSireId': state.selectedSireId,
      'likedHorseIds': state.likedHorseIds.toList(),
      'followedProfileIds': state.followedProfileIds.toList(),
      'communityListings': state.communityListings
          .map(_communityListingToJson)
          .toList(),
      'breedingCooldowns': state.breedingCooldowns
          .map(_cooldownToJson)
          .toList(),
      'inventory': state.inventory.map(
        (type, quantity) => MapEntry(inventoryItemTypeKey(type), quantity),
      ),
      'stableExpansionTier': state.stableExpansionTier,
      'stableExpansionRenewsAt': state.stableExpansionRenewsAt
          ?.toIso8601String(),
      'prenatalBoostedPregnancyIds': state.prenatalBoostedPregnancyIds.toList(),
      'carrotBoostedHorseIds': state.carrotBoostedHorseIds.toList(),
      'readStableAlertIds': state.readStableAlertIds.toList(),
    });
    await prefs.setString(_stateKey(accountId), encoded);
  }

  Future<void> clearState(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey(accountId));
  }

  String _stateKey(String accountId) => 'pivot_horses.game_state.v1.$accountId';

  List<Horse> _horseListFromJson(dynamic raw) {
    if (raw is! List<dynamic>) {
      return const [];
    }
    return raw.whereType<Map<String, dynamic>>().map(_horseFromJson).toList();
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

  DateTime? _dateTimeFromJson(dynamic raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Horse _horseFromJson(Map<String, dynamic> json) {
    final rawLineageMemory =
        json['lineageMemory'] as Map<String, dynamic>? ?? const {};
    final lineageMemory = <String, Map<String, int>>{};
    for (final entry in rawLineageMemory.entries) {
      final rawDepths = entry.value;
      if (rawDepths is! Map<String, dynamic>) {
        continue;
      }
      lineageMemory[entry.key] = {
        for (final depthEntry in rawDepths.entries)
          depthEntry.key: (depthEntry.value as num).toInt(),
      };
    }

    return normalizeHorseVisibleTraits(
      Horse(
        id: json['id'] as String,
        registryId: json['registryId'] as String,
        registeredName: json['registeredName'] as String,
        currentName: json['currentName'] as String,
        breed: json['breed'] as String,
        sex: json['sex'] as String,
        generation: (json['generation'] as num).toInt(),
        ageDays: (json['ageDays'] as num).toInt(),
        breedingRetirementDays: (json['breedingRetirementDays'] as num).toInt(),
        traits: ((json['traits'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(_traitFromJson)
            .toList()),
        starterTier: StarterTier.values.byName(json['starterTier'] as String),
        price: (json['price'] as num).toInt(),
        geneticProfile: _geneticProfileFromJson(
          json['geneticProfile'] as Map<String, dynamic>,
        ),
        careStats: _careStatsFromJson(
          json['careStats'] as Map<String, dynamic>,
        ),
        transferCount: (json['transferCount'] as num?)?.toInt() ?? 0,
        specialTraits: ((json['specialTraits'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList()),
        lineageMemory: lineageMemory,
        isMutant: json['isMutant'] as bool? ?? false,
        isPublicListing: json['isPublicListing'] as bool? ?? false,
        isFeaturedProfileHorse:
            json['isFeaturedProfileHorse'] as bool? ?? false,
        isListedForSale: json['isListedForSale'] as bool? ?? false,
        damSnapshot: json['damSnapshot'] is Map<String, dynamic>
            ? _horseFromJson(json['damSnapshot'] as Map<String, dynamic>)
            : null,
        sireSnapshot: json['sireSnapshot'] is Map<String, dynamic>
            ? _horseFromJson(json['sireSnapshot'] as Map<String, dynamic>)
            : null,
      ),
    );
  }

  Map<String, dynamic> _horseToJson(Horse horse) {
    return {
      'id': horse.id,
      'registryId': horse.registryId,
      'registeredName': horse.registeredName,
      'currentName': horse.currentName,
      'breed': horse.breed,
      'sex': horse.sex,
      'generation': horse.generation,
      'ageDays': horse.ageDays,
      'breedingRetirementDays': horse.breedingRetirementDays,
      'traits': horse.traits.map(_traitToJson).toList(),
      'starterTier': horse.starterTier.name,
      'price': horse.price,
      'geneticProfile': _geneticProfileToJson(horse.geneticProfile),
      'careStats': _careStatsToJson(horse.careStats),
      'transferCount': horse.transferCount,
      'specialTraits': horse.specialTraits,
      'lineageMemory': horse.lineageMemory,
      'isMutant': horse.isMutant,
      'isPublicListing': horse.isPublicListing,
      'isFeaturedProfileHorse': horse.isFeaturedProfileHorse,
      'isListedForSale': horse.isListedForSale,
      'damSnapshot': horse.damSnapshot == null
          ? null
          : _horseToJson(horse.damSnapshot!),
      'sireSnapshot': horse.sireSnapshot == null
          ? null
          : _horseToJson(horse.sireSnapshot!),
    };
  }

  HorseTrait _traitFromJson(Map<String, dynamic> json) {
    return HorseTrait(
      type: json['type'] as String,
      option: json['option'] as String,
      rarity: RarityTier.values.byName(json['rarity'] as String),
    );
  }

  Map<String, dynamic> _traitToJson(HorseTrait trait) {
    return {
      'type': trait.type,
      'option': trait.option,
      'rarity': trait.rarity.name,
    };
  }

  GeneticProfile _geneticProfileFromJson(Map<String, dynamic> json) {
    final rawRareTraitChances =
        json['rareTraitChances'] as Map<String, dynamic>? ?? const {};
    return GeneticProfile(
      breedingPotential: json['breedingPotential'] as String,
      bloodlineScore: (json['bloodlineScore'] as num).toInt(),
      mutationAffinity: (json['mutationAffinity'] as num).toDouble(),
      rareTraitChances: {
        for (final entry in rawRareTraitChances.entries)
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

  CareStats _careStatsFromJson(Map<String, dynamic> json) {
    return CareStats(
      hungerLevel: (json['hungerLevel'] as num).toInt(),
      happinessLevel: (json['happinessLevel'] as num).toInt(),
      energyLevel: (json['energyLevel'] as num).toInt(),
      saltLickEnjoyment: (json['saltLickEnjoyment'] as num).toInt(),
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

  PregnancyRecord? _pregnancyFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return PregnancyRecord(
      id: raw['id'] as String,
      damId: raw['damId'] as String,
      damName: raw['damName'] as String,
      sireId: raw['sireId'] as String,
      sireName: raw['sireName'] as String,
      unbornFoalName: raw['unbornFoalName'] as String,
      registryId: raw['registryId'] as String,
      breed: raw['breed'] as String,
      foal: _horseFromJson(raw['foal'] as Map<String, dynamic>),
      conceivedAt: DateTime.parse(raw['conceivedAt'] as String),
      dueAt: DateTime.parse(raw['dueAt'] as String),
      damCooldownEndsAt: DateTime.parse(raw['damCooldownEndsAt'] as String),
      sireCooldownEndsAt: DateTime.parse(raw['sireCooldownEndsAt'] as String),
      isMutant: raw['isMutant'] as bool? ?? false,
    );
  }

  List<PregnancyRecord> _pregnancyListFromJson(
    dynamic raw, {
    PregnancyRecord? fallback,
  }) {
    if (raw is List<dynamic>) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(_pregnancyFromJson)
          .whereType<PregnancyRecord>()
          .toList();
    }
    if (fallback != null) {
      return [fallback];
    }
    return const [];
  }

  Map<String, dynamic> _pregnancyToJson(PregnancyRecord record) {
    return {
      'id': record.id,
      'damId': record.damId,
      'damName': record.damName,
      'sireId': record.sireId,
      'sireName': record.sireName,
      'unbornFoalName': record.unbornFoalName,
      'registryId': record.registryId,
      'breed': record.breed,
      'foal': _horseToJson(record.foal),
      'conceivedAt': record.conceivedAt.toIso8601String(),
      'dueAt': record.dueAt.toIso8601String(),
      'damCooldownEndsAt': record.damCooldownEndsAt.toIso8601String(),
      'sireCooldownEndsAt': record.sireCooldownEndsAt.toIso8601String(),
      'isMutant': record.isMutant,
    };
  }

  MatingSession? _matingFromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return MatingSession(
      id: raw['id'] as String,
      damId: raw['damId'] as String,
      damName: raw['damName'] as String,
      sireId: raw['sireId'] as String,
      sireName: raw['sireName'] as String,
      startedAt: DateTime.parse(raw['startedAt'] as String),
      endsAt: DateTime.parse(raw['endsAt'] as String),
    );
  }

  Map<String, dynamic>? _matingToJson(MatingSession? session) {
    if (session == null) {
      return null;
    }
    return {
      'id': session.id,
      'damId': session.damId,
      'damName': session.damName,
      'sireId': session.sireId,
      'sireName': session.sireName,
      'startedAt': session.startedAt.toIso8601String(),
      'endsAt': session.endsAt.toIso8601String(),
    };
  }

  List<BreedingCooldown> _cooldownListFromJson(dynamic raw) {
    if (raw is! List<dynamic>) {
      return const [];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(_cooldownFromJson)
        .toList();
  }

  BreedingCooldown _cooldownFromJson(Map<String, dynamic> json) {
    return BreedingCooldown(
      horseId: json['horseId'] as String,
      horseName: json['horseName'] as String,
      sex: json['sex'] as String,
      reason: json['reason'] as String,
      endsAt: DateTime.parse(json['endsAt'] as String),
    );
  }

  Map<String, dynamic> _cooldownToJson(BreedingCooldown cooldown) {
    return {
      'horseId': cooldown.horseId,
      'horseName': cooldown.horseName,
      'sex': cooldown.sex,
      'reason': cooldown.reason,
      'endsAt': cooldown.endsAt.toIso8601String(),
    };
  }

  List<CommunityListing> _communityListingsFromJson(dynamic raw) {
    if (raw is! List<dynamic>) {
      return const [];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(_communityListingFromJson)
        .toList();
  }

  CommunityListing _communityListingFromJson(Map<String, dynamic> json) {
    return CommunityListing(
      id: json['id'] as String,
      sellerProfileId: json['sellerProfileId'] as String,
      sellerName: json['sellerName'] as String,
      sellerHandle: json['sellerHandle'] as String,
      sellerStableName: json['sellerStableName'] as String,
      sellerPayout: (json['sellerPayout'] as num).toInt(),
      horse: _horseFromJson(json['horse'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> _communityListingToJson(CommunityListing listing) {
    return {
      'id': listing.id,
      'sellerProfileId': listing.sellerProfileId,
      'sellerName': listing.sellerName,
      'sellerHandle': listing.sellerHandle,
      'sellerStableName': listing.sellerStableName,
      'sellerPayout': listing.sellerPayout,
      'horse': _horseToJson(listing.horse),
    };
  }
}
