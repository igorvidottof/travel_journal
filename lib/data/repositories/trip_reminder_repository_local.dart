import '../../domain/models/trip_reminder_preferences.dart';
import '../services/storage_service_local.dart';
import 'trip_reminder_repository.dart';

/// Source of truth for the persisted preference and stable notification IDs.
class TripReminderRepositoryLocal implements TripReminderRepository {
  TripReminderRepositoryLocal(this._storage);

  final StorageServiceLocal _storage;
  Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<TripReminderPreferences> load() => _serialize(() async {
    final raw = await _storage.readJson('trip_reminders.json');
    if (raw == null) {
      return TripReminderPreferences(enabled: false, notificationIds: {});
    }
    if (raw is! Map<String, dynamic> ||
        raw['version'] != 1 ||
        raw['enabled'] is! bool ||
        raw['ids'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid reminder preferences');
    }
    final ids = <String, int>{};
    for (final entry in (raw['ids'] as Map<String, dynamic>).entries) {
      final id = entry.value;
      if (id is! int || id <= 0 || id > 0x7fffffff || ids.containsValue(id)) {
        throw const FormatException('Invalid notification ID');
      }
      ids[entry.key] = id;
    }
    return TripReminderPreferences(
      enabled: raw['enabled'] as bool,
      notificationIds: ids,
    );
  });

  @override
  Future<void> save({
    required bool enabled,
    required Map<String, int> notificationIds,
  }) {
    final preferences = TripReminderPreferences(
      enabled: enabled,
      notificationIds: notificationIds,
    );
    return _serialize(
      () => _storage.writeJson('trip_reminders.json', {
        'version': 1,
        'enabled': preferences.enabled,
        'ids': preferences.notificationIds,
      }),
    );
  }
}
