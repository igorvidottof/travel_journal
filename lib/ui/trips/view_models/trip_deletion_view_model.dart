import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;

import '../../../app/dependencies.dart';
import '../../../data/repositories/trip_repository.dart';
import 'trip_photos_view_model.dart';
import 'trips_view_model.dart';
import '../../settings/view_models/trip_reminders_view_model.dart';

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
  KeepAliveLink? _confirmationLifetime;

  @override
  TripDeletionState build() => const TripDeletionState();

  bool get _hasPhotoMutation {
    final provider = tripPhotosViewModelProvider(tripId);
    if (!ref.exists(provider)) return false;
    final photos = ref.read(provider);
    return photos.isSelecting ||
        photos.deletingPhotoId != null ||
        photos.sharingPhotoId != null;
  }

  bool beginConfirmation() {
    if (state.isBusy || _hasPhotoMutation) {
      return false;
    }
    _confirmationLifetime = ref.keepAlive();
    state = const TripDeletionState(isConfirming: true);
    return true;
  }

  void _releaseConfirmation() {
    _confirmationLifetime?.close();
    _confirmationLifetime = null;
  }

  void cancelConfirmation() {
    if (ref.mounted && !state.isDeleting) {
      state = const TripDeletionState();
    }
    _releaseConfirmation();
  }

  Future<TripDeletionResult?> deleteTrip() async {
    if (state.isDeleting) return null;
    if (_hasPhotoMutation) {
      state = const TripDeletionState(
        error: 'Please wait for the photo operation to finish, then try again.',
      );
      _releaseConfirmation();
      return null;
    }
    final repository = ref.read(tripRepositoryProvider);
    final reminders = ref.read(tripRemindersViewModelProvider.notifier);
    final trips = ref.read(tripsViewModelProvider.notifier);
    final keepAlive = ref.keepAlive();
    _releaseConfirmation();
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
    await reminders.synchronize();
    if (ref.mounted) {
      trips.removeDeletedTrip(tripId);
      ref.invalidate(tripPhotosViewModelProvider(tripId));
      state = const TripDeletionState();
    }
    keepAlive.close();
    return result;
  }
}
