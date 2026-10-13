import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../domain/models/notification_schedule.dart';
import 'trip_reminders_view_model.dart';

class NotificationDeliveryCheckState {
  const NotificationDeliveryCheckState({this.isBusy = false, this.message});

  final bool isBusy;
  final String? message;
}

final notificationDeliveryCheckViewModelProvider =
    NotifierProvider.autoDispose<
      NotificationDeliveryCheckViewModel,
      NotificationDeliveryCheckState
    >(NotificationDeliveryCheckViewModel.new);

class NotificationDeliveryCheckViewModel
    extends Notifier<NotificationDeliveryCheckState> {
  @override
  NotificationDeliveryCheckState build() =>
      const NotificationDeliveryCheckState();

  Future<void> send() async {
    final reminders = ref.read(tripRemindersViewModelProvider);
    if (!kDebugMode || state.isBusy || reminders.isBusy || !reminders.enabled) {
      return;
    }
    final keepAlive = ref.keepAlive();
    state = const NotificationDeliveryCheckState(isBusy: true);
    try {
      final notifications = ref.read(notificationRepositoryProvider);
      final timezones = ref.read(timezoneRepositoryProvider);
      final timezone = await timezones.localTimezone();
      final result = await notifications.scheduleDeliveryCheck(
        NotificationSchedule(
          instant: DateTime.now().toUtc().add(const Duration(minutes: 1)),
          timezone: timezone,
        ),
      );
      if (ref.mounted) {
        state = NotificationDeliveryCheckState(
          message: switch (result) {
            NotificationDeliveryCheckResult.scheduled =>
              'Test notification scheduled for one minute from now. Tapping again restarts the timer.',
            NotificationDeliveryCheckResult.permissionDenied =>
              'Allow alerts for Travel Journal in iOS Settings, then try again.',
            NotificationDeliveryCheckResult.capacityReached =>
              'iOS has 64 pending notifications. The test was not scheduled to preserve your trip reminders.',
          },
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = const NotificationDeliveryCheckState(
          message:
              'Unable to schedule the test notification. Please try again.',
        );
      }
    } finally {
      keepAlive.close();
    }
  }
}
