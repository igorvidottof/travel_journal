import '../../domain/models/trip.dart';

abstract class TripRepository {
  /// Retorna uma lista não modificável das viagens cadastradas.
  Future<List<Trip>> getTrips();

  Future<void> addTrip(Trip trip);
}
