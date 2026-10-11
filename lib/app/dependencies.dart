import '../data/repositories/in_memory_trip_repository.dart';
import '../data/repositories/trip_repository.dart';
import '../ui/trips/view_models/create_trip_view_model.dart';
import '../ui/trips/view_models/trips_view_model.dart';

/// Compõe e possui as dependências durante a vida da aplicação.
class AppDependencies {
  AppDependencies() {
    tripsViewModel = TripsViewModel(tripRepository: tripRepository);
    createTripViewModel = CreateTripViewModel(
      tripRepository: tripRepository,
      onTripCreated: tripsViewModel.loadTrips,
    );
    tripsViewModel.loadTrips();
  }

  final TripRepository tripRepository = InMemoryTripRepository();
  late final TripsViewModel tripsViewModel;
  late final CreateTripViewModel createTripViewModel;

  /// Libera os notificadores antes de descartar o escopo da aplicação.
  void dispose() {
    createTripViewModel.dispose();
    tripsViewModel.dispose();
  }
}
