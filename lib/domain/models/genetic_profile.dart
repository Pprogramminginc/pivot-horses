class GeneticProfile {
  const GeneticProfile({
    required this.breedingPotential,
    required this.bloodlineScore,
    required this.mutationAffinity,
    this.rareTraitChances = const {},
  });

  final String breedingPotential;
  final int bloodlineScore;
  final double mutationAffinity;
  final Map<String, double> rareTraitChances;
}
