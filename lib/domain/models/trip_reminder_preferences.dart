class TripReminderPreferences {
  TripReminderPreferences({
    required this.enabled,
    required Map<String, int> notificationIds,
  }) : notificationIds = Map.unmodifiable(notificationIds);

  final bool enabled;
  final Map<String, int> notificationIds;
}
