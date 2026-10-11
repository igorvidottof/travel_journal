import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../domain/models/trip.dart';

final tripsViewModelProvider =
    AsyncNotifierProvider<TripsViewModel, List<Trip>>(TripsViewModel.new);

class TripsViewModel extends AsyncNotifier<List<Trip>> {
  @override
  FutureOr<List<Trip>> build() {
    final repository = ref.watch(tripRepositoryProvider);
    return List<Trip>.unmodifiable(repository.getTrips());
  }

  /// Reload through build; AsyncValue exposes loading, data, and errors.
  void loadTrips() => ref.invalidateSelf();
}
