enum StarterTier {
  basic(label: 'Basic Starter'),
  promising(label: 'Promising Starter'),
  premium(label: 'Premium Starter');

  const StarterTier({required this.label});

  final String label;
}
