import '../../domain/models/trip.dart';
import 'trip_repository.dart';

class InMemoryTripRepository implements TripRepository {
  final List<Trip> _trips = [];

  @override
  List<Trip> getTrips() => List<Trip>.unmodifiable(_trips);

  @override
  Future<void> addTrip(Trip trip) async {
    _trips.add(trip);
  }
}
