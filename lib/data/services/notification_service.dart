import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/models/notification_schedule.dart';
import 'timezone_service.dart';

/// Native notification operations; initialization never asks for permission.
class NotificationService {
  NotificationService(this._timezone);

  final TimezoneService _timezone;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!Platform.isIOS) {
      throw UnsupportedError('Trip reminders are currently available on iOS.');
    }
    // On iOS the return value reflects the permission request, not whether
    // initialization succeeded. With requests disabled it returns false.
    // Native initialization failures still propagate as exceptions.
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  IOSFlutterLocalNotificationsPlugin get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()!;

  Future<bool> requestPermission() async {
    await initialize();
    await _ios.requestPermissions(alert: true, sound: true, badge: false);
    return hasPermission();
  }

  Future<bool> hasPermission() async {
    await initialize();
    final permissions = await _ios.checkPermissions();
    return permissions != null &&
        permissions.isEnabled &&
        permissions.isAlertEnabled;
  }

  Future<void> openSettings() async {
    await initialize();
    if (await _ios.openAppNotificationSettings() != true) {
      throw StateError('Unable to open notification settings');
    }
  }

  Future<Map<int, String?>> pending() async {
    await initialize();
    return {
      for (final request in await _plugin.pendingNotificationRequests())
        request.id: request.payload,
    };
  }

  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required String payload,
    required NotificationSchedule schedule,
  }) async {
    await initialize();
    // Recheck near the native call: never turn a past reminder into an alert now.
    if (!schedule.instant.isAfter(DateTime.now().toUtc())) return false;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _timezone.toZonedDateTime(schedule),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          presentBadge: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
    return true;
  }
}
