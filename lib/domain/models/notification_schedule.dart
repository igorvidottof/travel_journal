/// A scheduled instant and its IANA timezone, independent of platform packages.
class NotificationSchedule {
  NotificationSchedule({required DateTime instant, required this.timezone})
    : instant = instant.toUtc();

  final DateTime instant;
  final String timezone;
}
