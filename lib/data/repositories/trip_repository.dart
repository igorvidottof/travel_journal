import '../../domain/models/trip.dart';
import '../../domain/models/trip_location.dart';

class TripDeletionResult {
  const TripDeletionResult({this.photoCleanupPending = false});

  final bool photoCleanupPending;
}

abstract class TripRepository {
  /// Retorna uma lista não modificável das viagens cadastradas.
  Future<List<Trip>> getTrips();

  Future<void> addTrip(Trip trip);

  Future<TripDeletionResult> deleteTrip(String tripId);

  Future<void> updateTripDetails(
    String tripId, {
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> setLocation(String tripId, TripLocation? location);
}
