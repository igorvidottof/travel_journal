import 'dart:convert';

import '../../domain/models/notification_schedule.dart';
import '../services/notification_service.dart';
import 'notification_repository.dart';

/// Translates trip reminders into native notification content and payloads.
class NotificationRepositoryPlatform implements NotificationRepository {
  NotificationRepositoryPlatform(this._service);

  final NotificationService _service;
  static const _payloadPrefix = 'trip-reminder:';

  @override
  Future<bool> requestPermission() => _service.requestPermission();

  @override
  Future<bool> hasPermission() => _service.hasPermission();

  @override
  Future<void> openSettings() => _service.openSettings();

  @override
  Future<Map<int, String?>> pending() => _service.pending();

  @override
  Future<void> cancel(int id) => _service.cancel(id);

  @override
  Future<NotificationDeliveryCheckResult> scheduleDeliveryCheck(
    NotificationSchedule schedule,
  ) async {
    if (!await _service.hasPermission()) {
      return NotificationDeliveryCheckResult.permissionDenied;
    }
    // Trip notification IDs are always positive; zero belongs to this check.
    // Repeated checks replace this request rather than accumulating requests.
    const id = 0;
    const payload = 'debug-reminder:delivery-check';
    final pending = await _service.pending();
    if (pending.length >= 64 && !pending.containsKey(id)) {
      return NotificationDeliveryCheckResult.capacityReached;
    }
    final scheduled = await _service.schedule(
      id: id,
      title: 'Travel Journal test reminder',
      body: 'Local notifications are working.',
      payload: payload,
      schedule: schedule,
    );
    if (!scheduled || (await _service.pending())[id] != payload) {
      throw StateError('The delivery check was not retained by iOS');
    }
    return NotificationDeliveryCheckResult.scheduled;
  }

  @override
  bool isTripReminder(String? payload) =>
      payload?.startsWith(_payloadPrefix) ?? false;

  @override
  String payloadFor({
    required String tripId,
    required String name,
    required String destination,
    required DateTime instant,
    required String timezone,
  }) =>
      '$_payloadPrefix${jsonEncode([tripId, name, destination, instant.toUtc().toIso8601String(), timezone])}';

  @override
  Future<bool> schedule({
    required int id,
    required String tripId,
    required String name,
    required String destination,
    required DateTime instant,
    required String timezone,
  }) async {
    await _service.initialize();
    return _service.schedule(
      id: id,
      title: 'Your trip starts in 24 hours',
      body: '$name — $destination',
      schedule: NotificationSchedule(instant: instant, timezone: timezone),
      payload: payloadFor(
        tripId: tripId,
        name: name,
        destination: destination,
        instant: instant,
        timezone: timezone,
      ),
    );
  }
}
