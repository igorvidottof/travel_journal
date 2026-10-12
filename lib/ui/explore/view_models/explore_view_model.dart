import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../domain/models/trip.dart';
import '../../trips/view_models/trips_view_model.dart';

final exploreViewModelProvider =
    AsyncNotifierProvider.autoDispose<ExploreViewModel, List<Trip>>(
      ExploreViewModel.new,
    );

class ExploreViewModel extends AsyncNotifier<List<Trip>> {
  bool _isOpeningMaps = false;

  @override
  Future<List<Trip>> build() => ref.watch(tripsViewModelProvider.future);

  void reloadTrips() => ref.read(tripsViewModelProvider.notifier).loadTrips();

  /// Null means a launch is already in progress; false means launch failed.
  Future<bool?> openDestination(Trip trip) async {
    if (_isOpeningMaps) return null;
    _isOpeningMaps = true;
    try {
      return await ref
          .read(mapsRepositoryProvider)
          .openDestination(trip.destination);
    } finally {
      _isOpeningMaps = false;
    }
  }
}
