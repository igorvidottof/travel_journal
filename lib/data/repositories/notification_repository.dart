import '../../domain/models/notification_schedule.dart';

enum NotificationDeliveryCheckResult {
  scheduled,
  permissionDenied,
  capacityReached,
}

/// Notification operations available to application repositories.
abstract class NotificationRepository {
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> openSettings();

  Future<Map<int, String?>> pending();
  Future<void> cancel(int id);

  /// Schedules an independent delivery check at the supplied instant without asking
  /// for permission or modifying any trip reminder.
  Future<NotificationDeliveryCheckResult> scheduleDeliveryCheck(
    NotificationSchedule schedule,
  );

  bool isTripReminder(String? payload);

  String payloadFor({
    required String tripId,
    required String name,
    required String destination,
    required DateTime instant,
    required String timezone,
  });

  /// Returns false when the reminder time has already passed.
  Future<bool> schedule({
    required int id,
    required String tripId,
    required String name,
    required String destination,
    required DateTime instant,
    required String timezone,
  });
}
