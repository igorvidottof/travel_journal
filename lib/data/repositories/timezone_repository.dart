/// Device timezone information and calendar conversions using plain Dart types.
abstract class TimezoneRepository {
  /// Returns the device's current IANA timezone identifier.
  Future<String> localTimezone();

  /// Interprets the date's calendar components in the given timezone and returns
  /// local midnight as a UTC instant, respecting daylight-saving transitions.
  DateTime startOfDayUtc(DateTime calendarDate, {required String timezone});
}
