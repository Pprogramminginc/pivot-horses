class BreedingPreview {
  const BreedingPreview({
    required this.breed,
    required this.likelyTraits,
    required this.mutationChance,
    required this.projectedRarityLabel,
    required this.inheritanceNotes,
    required this.mutationSummary,
    required this.raritySummary,
    this.possibleSpecialTraits = const [],
  });

  final String breed;
  final Map<String, List<String>> likelyTraits;
  final double mutationChance;
  final String projectedRarityLabel;
  final List<String> inheritanceNotes;
  final String mutationSummary;
  final String raritySummary;
  final List<String> possibleSpecialTraits;
}
