/// Presentation state owned by the Settings view model.
class TripReminderState {
  const TripReminderState({
    this.enabled = false,
    this.isBusy = true,
    this.message,
  });

  final bool enabled;
  final bool isBusy;
  final String? message;
}
