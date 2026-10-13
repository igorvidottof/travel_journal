import '../../domain/models/trip_reminder_preferences.dart';

abstract class TripReminderRepository {
  Future<TripReminderPreferences> load();
  Future<void> save({
    required bool enabled,
    required Map<String, int> notificationIds,
  });
}
