import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../domain/models/trip.dart';

final tripsViewModelProvider =
    AsyncNotifierProvider<TripsViewModel, List<Trip>>(TripsViewModel.new);

// Derive details from the same repository-backed state as the trip list.
// A missing ID is data (null), rather than a loading error.
final tripDetailsProvider = Provider.autoDispose
    .family<AsyncValue<Trip?>, String>(
      (ref, tripId) => ref.watch(tripsViewModelProvider).whenData((trips) {
        for (final trip in trips) {
          if (trip.id == tripId) return trip;
        }
        return null;
      }),
    );

class TripsViewModel extends AsyncNotifier<List<Trip>> {
  @override
  FutureOr<List<Trip>> build() {
    final repository = ref.watch(tripRepositoryProvider);
    return List<Trip>.unmodifiable(repository.getTrips());
  }

  /// Reload through build; AsyncValue exposes loading, data, and errors.
  void loadTrips() => ref.invalidateSelf();
}
