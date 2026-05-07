import '../../domain/models/horse.dart';

class HorseRegistryService {
  const HorseRegistryService();

  String foalRegistryId({
    required String breed,
    required String ownerId,
    required int sequence,
  }) {
    return _formatRegistryId(sequence);
  }

  String starterMarketRegistryId({
    required String ownerId,
    required int sequence,
  }) {
    return _formatRegistryId(sequence);
  }

  int nextAvailableSequence({
    required int currentSequence,
    required Iterable<String> existingRegistryIds,
    required String Function(int sequence) buildRegistryId,
  }) {
    final used = existingRegistryIds
        .map((id) => id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet();
    var sequence = currentSequence;
    do {
      sequence += 1;
    } while (used.contains(buildRegistryId(sequence).toLowerCase()));
    return sequence;
  }

  List<Horse> assignStarterMarketRegistryIds({
    required String ownerId,
    required Iterable<Horse> horses,
    int startingSequence = 101,
  }) {
    var sequence = startingSequence;
    return horses.map((horse) {
      final registryId = starterMarketRegistryId(
        ownerId: ownerId,
        sequence: sequence,
      );
      final updated = horse.copyWith(
        id: 'market_${horse.id}_$sequence',
        registryId: registryId,
      );
      sequence += 1;
      return updated;
    }).toList();
  }

  String _formatRegistryId(int sequence) => 'PH$sequence';
}
