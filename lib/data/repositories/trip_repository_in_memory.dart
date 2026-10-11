import '../../domain/models/trip.dart';
import 'trip_repository.dart';

class TripRepositoryInMemory implements TripRepository {
  final List<Trip> _trips = [];

  @override
  Future<List<Trip>> getTrips() async => List<Trip>.unmodifiable(_trips);

  @override
  Future<void> addTrip(Trip trip) async {
    _trips.add(trip);
  }
}
