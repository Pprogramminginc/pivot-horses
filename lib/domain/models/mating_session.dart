class MatingSession {
  MatingSession({
    required this.id,
    required this.damId,
    required this.damName,
    required this.sireId,
    required this.sireName,
    required this.startedAt,
    required this.endsAt,
  });

  final String id;
  final String damId;
  final String damName;
  final String sireId;
  final String sireName;
  final DateTime startedAt;
  final DateTime endsAt;

  Duration remainingAt(DateTime now) {
    final remaining = endsAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
