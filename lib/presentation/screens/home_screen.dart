import 'package:flutter/material.dart';

import '../../data/repositories/horse_repository.dart';
import '../../domain/models/inbox_item.dart';
import 'stable_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StableScreen(
      stableHorses: const HorseRepository().loadStable(),
      activePregnancies: const [],
      breedingCooldowns: const [],
      currentTime: DateTime.now(),
      inventory: const {},
      stableCap: 10,
      stableCapacityRenewsAt: null,
      prenatalBoostedPregnancyIds: const {},
      carrotBoostedHorseIds: const {},
      inboxItems: const [],
      stableAtCapacity: false,
      onOpenMarketHorses: () {},
      onOpenMarketItems: () {},
      onRenameHorse: (horse, newName) {},
      onPurgeHorse: (_) {},
      onBirthFoal: (_) {},
      onUsePrenatalVitamin: (_) {},
      onUseCarrot: (_) {},
      onMarkInboxItemRead: (_) {},
      onMarkInboxKindRead: (InboxItemKind kind) {},
      onUpdateHorseVisibility:
          (
            horse, {
            bool? isPublicListing,
            bool? isFeaturedProfileHorse,
            bool? isListedForSale,
          }) => null,
    );
  }
}
