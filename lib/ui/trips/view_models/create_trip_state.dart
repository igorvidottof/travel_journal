enum TripSubmissionStatus { idle, saving, success, failure }

class CreateTripState {
  const CreateTripState({
    this.name = '',
    this.destination = '',
    this.startDate,
    this.endDate,
    this.status = TripSubmissionStatus.idle,
    this.error,
  });

  final String name;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final TripSubmissionStatus status;
  final String? error;

  bool get isSaving => status == TripSubmissionStatus.saving;

  CreateTripState copyWith({
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
    TripSubmissionStatus status = TripSubmissionStatus.idle,
    String? error,
  }) {
    return CreateTripState(
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      status: status,
      error: error,
    );
  }
}
