import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../data/services/location_service.dart';
import '../../../domain/models/trip_location.dart';
import 'trips_view_model.dart';

class TripLocationState {
  const TripLocationState({
    this.location,
    this.isLocating = false,
    this.isSaving = false,
    this.error,
    this.showSettings = false,
  });

  final TripLocation? location;
  final bool isLocating;
  final bool isSaving;
  final String? error;
  final bool showSettings;
  bool get isBusy => isLocating || isSaving;
}

final tripLocationViewModelProvider = NotifierProvider.autoDispose
    .family<TripLocationViewModel, TripLocationState, String>(
      TripLocationViewModel.new,
    );

class TripLocationViewModel extends Notifier<TripLocationState> {
  TripLocationViewModel(this.tripId);
  final String tripId;

  @override
  TripLocationState build() => TripLocationState(
    location: ref.read(tripDetailsProvider(tripId)).asData?.value?.location,
  );

  void selectLocation(TripLocation location) {
    if (!state.isBusy) state = TripLocationState(location: location);
  }

  Future<void> useCurrentLocation() async {
    if (state.isBusy) return;
    state = TripLocationState(location: state.location, isLocating: true);
    try {
      final location = await ref
          .read(locationServiceProvider)
          .currentLocation();
      if (ref.mounted) state = TripLocationState(location: location);
    } on LocationException catch (error) {
      if (!ref.mounted) return;
      state = TripLocationState(
        location: state.location,
        showSettings: true,
        error: switch (error.failure) {
          LocationFailure.disabled =>
            'Location Services are off. Enable them in iOS Settings or place a pin manually.',
          LocationFailure.denied || LocationFailure.deniedForever =>
            'Location access is denied. Allow access in iOS Settings or place a pin manually.',
        },
      );
    } on TimeoutException {
      if (ref.mounted) {
        state = TripLocationState(
          location: state.location,
          error:
              'Finding your location took too long. Try again or place a pin manually.',
        );
      }
    } on Exception {
      if (ref.mounted) {
        state = TripLocationState(
          location: state.location,
          error:
              'Unable to find your location. Try again or place a pin manually.',
        );
      }
    }
  }

  Future<void> openSettings() async {
    try {
      if (await ref.read(locationServiceProvider).openSettings()) return;
    } on Exception {
      // Keep the picker usable if the platform cannot open Settings.
    }
    if (ref.mounted) {
      state = TripLocationState(
        location: state.location,
        error: 'Unable to open Settings. Open the iOS Settings app manually.',
        showSettings: true,
      );
    }
  }

  Future<bool> save() async {
    final location = state.location;
    if (state.isBusy || location == null) return false;
    final keepAlive = ref.keepAlive();
    state = TripLocationState(location: location, isSaving: true);
    try {
      await ref.read(tripRepositoryProvider).setLocation(tripId, location);
      if (ref.mounted) {
        ref.invalidate(tripsViewModelProvider);
        state = TripLocationState(location: location);
      }
      return true;
    } on Exception {
      if (ref.mounted) {
        state = TripLocationState(
          location: location,
          error: 'Unable to save this location. Please try again.',
        );
      }
      return false;
    } finally {
      keepAlive.close();
    }
  }
}
