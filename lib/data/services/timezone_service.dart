import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/notification_schedule.dart';

/// Wraps device timezone lookup and timezone database conversions.
class TimezoneService {
  bool _initialized = false;

  void _initialize() {
    if (_initialized) return;
    timezone_data.initializeTimeZones();
    _initialized = true;
  }

  Future<String> localTimezone() async {
    _initialize();
    // Refresh on each lookup so changing the device timezone is respected.
    final info = await FlutterTimezone.getLocalTimezone();
    return tz.getLocation(info.identifier).name;
  }

  DateTime startOfDayUtc(DateTime calendarDate, {required String timezone}) {
    _initialize();
    return tz.TZDateTime(
      tz.getLocation(timezone),
      calendarDate.year,
      calendarDate.month,
      calendarDate.day,
    ).toUtc();
  }

  /// Adapter for native plugins that require the timezone package's date type.
  /// This type is kept within the service layer.
  tz.TZDateTime toZonedDateTime(NotificationSchedule schedule) {
    _initialize();
    return tz.TZDateTime.from(
      schedule.instant,
      tz.getLocation(schedule.timezone),
    );
  }
}
