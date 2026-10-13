import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../domain/use_cases/synchronize_trip_reminders_use_case.dart';
import 'trip_reminder_state.dart';

final tripRemindersViewModelProvider =
    NotifierProvider<TripRemindersViewModel, TripReminderState>(
      TripRemindersViewModel.new,
    );

class TripRemindersViewModel extends Notifier<TripReminderState> {
  int _activeCommands = 0;

  @override
  TripReminderState build() {
    ref.watch(synchronizeTripRemindersUseCaseProvider);
    final lifecycle = AppLifecycleListener(onResume: () => unawaited(retry()));
    ref.onDispose(lifecycle.dispose);
    // Start after Riverpod has installed this view model's initial UI state.
    unawaited(
      Future<void>.microtask(() async {
        if (ref.mounted) await synchronize();
      }),
    );
    return const TripReminderState();
  }

  Future<void> _run(Future<TripReminderResult> Function() command) async {
    _activeCommands++;
    state = TripReminderState(enabled: state.enabled, isBusy: true);
    try {
      final result = await command();
      if (ref.mounted) {
        state = TripReminderState(
          enabled: result.enabled ?? state.enabled,
          isBusy: _activeCommands > 1,
          message: switch (result.outcome) {
            TripReminderOutcome.synchronized => null,
            TripReminderOutcome.permissionDenied =>
              'Notifications are disabled. Allow alerts for Travel Journal in iOS Settings, then enable Trip Reminders again.',
            TripReminderOutcome.permissionRevoked =>
              'Notifications are disabled in iOS Settings. Allow alerts, then retry. Your reminder preference is still saved.',
            TripReminderOutcome.unsupportedPlatform =>
              'Trip reminders are currently available on iOS.',
            TripReminderOutcome.updateFailed =>
              'Unable to update trip reminders. Your trips are saved. Please retry.',
            TripReminderOutcome.cancellationFailed =>
              'Some reminders could not be cancelled. Please retry.',
            TripReminderOutcome.schedulingFailed =>
              'Some reminders could not be updated. Please retry.',
            TripReminderOutcome.capacityLimited =>
              'The nearest ${result.scheduledCount} trips have reminders. iOS allows 64 pending notifications; later trips are synchronized when you reopen the app.',
          },
        );
      }
    } finally {
      _activeCommands--;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.isBusy) return;
    final useCase = ref.read(synchronizeTripRemindersUseCaseProvider);
    await _run(() => useCase.setEnabled(enabled));
  }

  // Trip changes always queue a fresh reconciliation, even when another command
  // is running. Busy state belongs here; serialization belongs to the use case.
  Future<void> synchronize() =>
      _run(ref.read(synchronizeTripRemindersUseCaseProvider).synchronize);

  Future<void> retry() async {
    if (state.isBusy) return;
    await synchronize();
  }

  Future<void> openSettings() async {
    if (state.isBusy) return;
    final notifications = ref.read(notificationRepositoryProvider);
    state = TripReminderState(enabled: state.enabled, isBusy: true);
    try {
      await notifications.openSettings();
      if (ref.mounted) {
        state = TripReminderState(enabled: state.enabled, isBusy: false);
      }
    } catch (_) {
      if (ref.mounted) {
        state = TripReminderState(
          enabled: state.enabled,
          isBusy: false,
          message: 'Unable to open notification settings. Please try again.',
        );
      }
    }
  }
}
