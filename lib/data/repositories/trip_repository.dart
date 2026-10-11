import '../../domain/models/trip.dart';
import '../../domain/models/trip_location.dart';

abstract class TripRepository {
  /// Retorna uma lista não modificável das viagens cadastradas.
  Future<List<Trip>> getTrips();

  Future<void> addTrip(Trip trip);

  Future<void> setLocation(String tripId, TripLocation? location);
}
