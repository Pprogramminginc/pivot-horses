class BreedingCooldown {
  const BreedingCooldown({
    required this.horseId,
    required this.horseName,
    required this.sex,
    required this.reason,
    required this.endsAt,
  });

  final String horseId;
  final String horseName;
  final String sex;
  final String reason;
  final DateTime endsAt;

  Duration remainingAt(DateTime now) {
    final remaining = endsAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isActiveAt(DateTime now) => remainingAt(now) > Duration.zero;
}
