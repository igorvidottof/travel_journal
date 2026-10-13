import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/timezone_repository.dart';
import '../../data/repositories/trip_repository.dart';
import '../../data/repositories/trip_reminder_repository.dart';

enum TripReminderOutcome {
  synchronized,
  permissionDenied,
  permissionRevoked,
  unsupportedPlatform,
  updateFailed,
  cancellationFailed,
  schedulingFailed,
  capacityLimited,
}

typedef TripReminderResult = ({
  bool? enabled,
  TripReminderOutcome outcome,
  int scheduledCount,
});

/// Coordinates repositories and returns business outcomes without UI state.
class SynchronizeTripRemindersUseCase {
  SynchronizeTripRemindersUseCase(
    this._preferences,
    this._notifications,
    this._tripRepository,
    this._timezones,
  );

  final TripReminderRepository _preferences;
  final NotificationRepository _notifications;
  final TripRepository _tripRepository;
  final TimezoneRepository _timezones;
  Future<void> _pending = Future.value();

  Future<TripReminderResult> synchronize() => _execute();

  Future<TripReminderResult> setEnabled(bool enabled) =>
      _execute(enable: enabled);

  Future<TripReminderResult> _execute({bool? enable}) {
    final result = _pending.then((_) async {
      bool? enabled;
      try {
        // Each command reads fresh preferences and committed trips. The queue
        // prevents overlapping commands from overwriting newer reminder data.
        final preferences = await _preferences.load();
        enabled = preferences.enabled;
        final ids = Map<String, int>.of(preferences.notificationIds);
        if (enable != null) {
          if (enable && !await _notifications.requestPermission()) {
            return (
              enabled: enabled,
              outcome: TripReminderOutcome.permissionDenied,
              scheduledCount: 0,
            );
          }
          await _preferences.save(enabled: enable, notificationIds: ids);
          enabled = enable;
        }
        return await _reconcile(enabled, ids);
      } on UnsupportedError {
        return (
          enabled: enabled,
          outcome: TripReminderOutcome.unsupportedPlatform,
          scheduledCount: 0,
        );
      } catch (_) {
        // Notification failures never turn a committed trip save into failure.
        return (
          enabled: enabled,
          outcome: TripReminderOutcome.updateFailed,
          scheduledCount: 0,
        );
      }
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  int _idFor(String tripId, Map<String, int> ids, Set<int> reserved) {
    final existing = ids[tripId];
    if (existing != null) {
      if (reserved.contains(existing)) {
        throw StateError('Notification ID is owned by another feature');
      }
      return existing;
    }
    // Deterministic FNV-1a with persisted collision resolution.
    var id = 0x811c9dc5;
    for (final unit in tripId.codeUnits) {
      id = ((id ^ unit) * 0x01000193) & 0x7fffffff;
    }
    if (id == 0) id = 1;
    while (ids.containsValue(id) || reserved.contains(id)) {
      id = id == 0x7fffffff ? 1 : id + 1;
    }
    ids[tripId] = id;
    return id;
  }

  Future<TripReminderResult> _reconcile(
    bool enabled,
    Map<String, int> ids,
  ) async {
    final pending = await _notifications.pending();
    final owned = {
      for (final entry in pending.entries)
        if (_notifications.isTripReminder(entry.value)) entry.key,
    };
    if (!enabled || !await _notifications.hasPermission()) {
      final cancelled = await _cancelReminders(owned);
      return (
        enabled: enabled,
        outcome: !cancelled
            ? TripReminderOutcome.cancellationFailed
            : enabled
            ? TripReminderOutcome.permissionRevoked
            : TripReminderOutcome.synchronized,
        scheduledCount: 0,
      );
    }
    final trips = await _tripRepository.getTrips();
    final liveIds = {for (final trip in trips) ids[trip.id]};
    // Cancel deleted trips even if timezone lookup later fails.
    var failed = !await _cancelReminders(
      owned.where((id) => !liveIds.contains(id)).toSet(),
    );
    final timezone = await _timezones.localTimezone();
    final now = DateTime.now().toUtc();
    final upcoming = trips
        .map(
          (trip) => (
            trip: trip,
            instant: _timezones
                .startOfDayUtc(trip.startDate, timezone: timezone)
                .subtract(const Duration(hours: 24)),
          ),
        )
        .where((item) => item.instant.isAfter(now))
        .toList();
    upcoming.sort((a, b) {
      final order = a.instant.compareTo(b.instant);
      return order == 0 ? a.trip.id.compareTo(b.trip.id) : order;
    });
    final available = (64 - (pending.length - owned.length)).clamp(0, 64);
    final selected = upcoming.take(available).toList();
    final reserved = pending.keys.where((id) => !owned.contains(id)).toSet();
    for (final item in selected) {
      _idFor(item.trip.id, ids, reserved);
    }
    // Persist IDs before creating native requests, retaining the existing format.
    await _preferences.save(enabled: enabled, notificationIds: ids);
    final desired = {
      for (final item in selected)
        ids[item.trip.id]!: _notifications.payloadFor(
          tripId: item.trip.id,
          name: item.trip.name,
          destination: item.trip.destination,
          instant: item.instant,
          timezone: timezone,
        ),
    };
    final cancelled = await _cancelReminders({
      for (final id in owned)
        if (desired[id] != pending[id]) id,
    });
    failed = failed || !cancelled;
    for (final item in selected) {
      final id = ids[item.trip.id]!;
      if (pending[id] == desired[id]) continue;
      try {
        final scheduled = await _notifications.schedule(
          id: id,
          tripId: item.trip.id,
          name: item.trip.name,
          destination: item.trip.destination,
          instant: item.instant,
          timezone: timezone,
        );
        if (!scheduled) desired.remove(id);
      } catch (_) {
        failed = true;
      }
    }
    final actual = await _notifications.pending();
    if (!desired.entries.every((entry) => actual[entry.key] == entry.value) ||
        owned.any((id) => !desired.containsKey(id) && actual.containsKey(id))) {
      failed = true;
    }
    return (
      enabled: enabled,
      outcome: failed
          ? TripReminderOutcome.schedulingFailed
          : upcoming.length > available
          ? TripReminderOutcome.capacityLimited
          : TripReminderOutcome.synchronized,
      scheduledCount: desired.length,
    );
  }

  Future<bool> _cancelReminders(Set<int> ids) async {
    if (ids.isEmpty) return true;
    var succeeded = true;
    for (final id in ids) {
      try {
        await _notifications.cancel(id);
      } catch (_) {
        succeeded = false;
      }
    }
    final remaining = await _notifications.pending();
    return succeeded && !ids.any(remaining.containsKey);
  }
}
