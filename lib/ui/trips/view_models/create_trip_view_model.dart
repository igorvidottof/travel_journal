import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../domain/models/trip.dart';
import 'create_trip_state.dart';
import 'trips_view_model.dart';

final createTripViewModelProvider =
    NotifierProvider.autoDispose<CreateTripViewModel, CreateTripState>(
      CreateTripViewModel.new,
    );

class CreateTripViewModel extends Notifier<CreateTripState> {
  static int _lastId = 0;

  @override
  CreateTripState build() {
    ref.watch(tripRepositoryProvider);
    return const CreateTripState();
  }

  void updateName(String value) {
    if (state.isSaving || value == state.name) return;
    state = state.copyWith(name: value);
  }

  void updateDestination(String value) {
    if (state.isSaving || value == state.destination) return;
    state = state.copyWith(destination: value);
  }

  void updateStartDate(DateTime? value) {
    if (state.isSaving || value == state.startDate) return;
    state = state.copyWith(startDate: value, clearStartDate: value == null);
  }

  void updateEndDate(DateTime? value) {
    if (state.isSaving || value == state.endDate) return;
    state = state.copyWith(endDate: value, clearEndDate: value == null);
  }

  String? _validate() {
    if (state.name.trim().isEmpty) return 'Enter a trip name.';
    if (state.destination.trim().isEmpty) return 'Enter a destination.';
    if (state.startDate == null || state.endDate == null) {
      return 'Select the start and end dates.';
    }
    if (state.endDate!.isBefore(state.startDate!)) {
      return 'The end date must not be earlier than the start date.';
    }
    return null;
  }

  /// Use a monotonic counter to avoid collisions in the in-memory session.
  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    _lastId = timestamp > _lastId ? timestamp : _lastId + 1;
    return _lastId.toString();
  }

  Future<bool> saveTrip() async {
    if (state.isSaving) return false;

    final error = _validate();
    if (error != null) {
      state = state.copyWith(
        status: TripSubmissionStatus.failure,
        error: error,
      );
      return false;
    }

    final repository = ref.read(tripRepositoryProvider);
    final trip = Trip(
      id: _generateId(),
      name: state.name.trim(),
      destination: state.destination.trim(),
      startDate: state.startDate!,
      endDate: state.endDate!,
    );
    // Finish the submission and refresh even if the form loses its listeners.
    final keepAlive = ref.keepAlive();
    state = state.copyWith(status: TripSubmissionStatus.saving);

    try {
      try {
        await repository.addTrip(trip);
      } on Exception {
        if (ref.mounted) {
          state = state.copyWith(
            status: TripSubmissionStatus.failure,
            error: 'Unable to save the trip. Please try again.',
          );
        }
        return false;
      }

      if (ref.mounted) {
        ref.invalidate(tripsViewModelProvider);
        state = const CreateTripState(status: TripSubmissionStatus.success);
      }
      return true;
    } finally {
      keepAlive.close();
    }
  }
}
