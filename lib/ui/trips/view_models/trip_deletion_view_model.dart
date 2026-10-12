import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../data/repositories/trip_repository.dart';
import 'trip_photos_view_model.dart';
import 'trips_view_model.dart';

class TripDeletionState {
  const TripDeletionState({
    this.isConfirming = false,
    this.isDeleting = false,
    this.error,
  });

  final bool isConfirming;
  final bool isDeleting;
  final String? error;

  bool get isBusy => isConfirming || isDeleting;
}

final tripDeletionViewModelProvider = NotifierProvider.autoDispose
    .family<TripDeletionViewModel, TripDeletionState, String>(
      TripDeletionViewModel.new,
    );

class TripDeletionViewModel extends Notifier<TripDeletionState> {
  TripDeletionViewModel(this.tripId);

  final String tripId;

  @override
  TripDeletionState build() => const TripDeletionState();

  bool beginConfirmation() {
    if (state.isBusy || ref.read(tripPhotosViewModelProvider(tripId)).isBusy) {
      return false;
    }
    state = const TripDeletionState(isConfirming: true);
    return true;
  }

  void cancelConfirmation() => state = const TripDeletionState();

  Future<TripDeletionResult?> deleteTrip() async {
    if (state.isDeleting) return null;
    if (ref.read(tripPhotosViewModelProvider(tripId)).isBusy) {
      state = const TripDeletionState(
        error: 'Please wait for the photo operation to finish, then try again.',
      );
      return null;
    }
    final repository = ref.read(tripRepositoryProvider);
    final trips = ref.read(tripsViewModelProvider.notifier);
    final keepAlive = ref.keepAlive();
    state = const TripDeletionState(isDeleting: true);
    TripDeletionResult result;
    try {
      result = await repository.deleteTrip(tripId);
    } on Exception {
      if (ref.mounted) {
        state = const TripDeletionState(
          error:
              'Unable to delete the trip. Your trip and photos are still saved. Please try again.',
        );
      }
      keepAlive.close();
      return null;
    }
    // A committed deletion is success even when later refresh/cleanup is pending.
    if (ref.mounted) {
      trips.removeDeletedTrip(tripId);
      ref.invalidate(tripPhotosViewModelProvider(tripId));
      state = const TripDeletionState();
    }
    keepAlive.close();
    return result;
  }
}
