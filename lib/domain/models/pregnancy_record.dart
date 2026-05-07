import 'horse.dart';

class PregnancyRecord {
  PregnancyRecord({
    required this.id,
    required this.damId,
    required this.damName,
    required this.sireId,
    required this.sireName,
    required this.unbornFoalName,
    required this.registryId,
    required this.breed,
    required this.foal,
    required this.conceivedAt,
    required this.dueAt,
    required this.damCooldownEndsAt,
    required this.sireCooldownEndsAt,
    this.isMutant = false,
  });

  final String id;
  final String damId;
  final String damName;
  final String sireId;
  final String sireName;
  final String unbornFoalName;
  final String registryId;
  final String breed;
  final Horse foal;
  final DateTime conceivedAt;
  final DateTime dueAt;
  final DateTime damCooldownEndsAt;
  final DateTime sireCooldownEndsAt;
  final bool isMutant;

  String get cardTitle => '$breed • $unbornFoalName';
  String get cardSubtitle =>
      '$registryId · ${isMutant ? 'Mutant ' : ''}Reserved Foal';

  Duration timeUntilBirthAt(DateTime now) {
    final remaining = dueAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int daysUntilBirthAt(DateTime now) {
    final remaining = timeUntilBirthAt(now);
    if (remaining == Duration.zero) {
      return 0;
    }

    return remaining.inDays + (remaining.inHours % 24 == 0 ? 0 : 1);
  }

  String birthCountdownLabelAt(DateTime now) {
    final remaining = timeUntilBirthAt(now);
    if (remaining == Duration.zero) {
      return 'Ready now';
    }

    if (remaining.inHours < 1) {
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      final minuteText = minutes.toString().padLeft(2, '0');
      final secondText = seconds.toString().padLeft(2, '0');
      return '$minuteText:$secondText';
    }

    if (remaining.inDays < 1) {
      return '${remaining.inHours}h';
    }

    return '${daysUntilBirthAt(now)}d';
  }

  int damCooldownDaysRemainingAt(DateTime now) {
    return _daysRemaining(now, damCooldownEndsAt);
  }

  int sireCooldownDaysRemainingAt(DateTime now) {
    return _daysRemaining(now, sireCooldownEndsAt);
  }

  String damCooldownLabelAt(DateTime now) {
    return _durationLabel(_timeUntil(now, damCooldownEndsAt));
  }

  String sireCooldownLabelAt(DateTime now) {
    return _durationLabel(_timeUntil(now, sireCooldownEndsAt));
  }

  Duration _timeUntil(DateTime now, DateTime endsAt) {
    final remaining = endsAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int _daysRemaining(DateTime now, DateTime endsAt) {
    final remaining = _timeUntil(now, endsAt);
    if (remaining == Duration.zero) {
      return 0;
    }

    return remaining.inDays + (remaining.inHours % 24 == 0 ? 0 : 1);
  }

  String _durationLabel(Duration remaining) {
    if (remaining == Duration.zero) {
      return 'Ready now';
    }

    var totalMinutes = remaining.inMinutes;
    if (remaining.inSeconds % 60 != 0) {
      totalMinutes += 1;
    }

    final days = totalMinutes ~/ Duration.minutesPerDay;
    final hours =
        (totalMinutes % Duration.minutesPerDay) ~/ Duration.minutesPerHour;
    final minutes = totalMinutes % Duration.minutesPerHour;

    final hourText = hours.toString().padLeft(2, '0');
    final minuteText = minutes.toString().padLeft(2, '0');
    if (days > 0) {
      return '$days:$hourText:$minuteText';
    }
    return '$hourText:$minuteText';
  }
}
