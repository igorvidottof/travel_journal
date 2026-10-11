import '../../domain/models/trip.dart';
import '../../domain/models/trip_location.dart';
import 'trip_repository.dart';

class TripRepositoryInMemory implements TripRepository {
  final List<Trip> _trips = [];

  @override
  Future<void> setLocation(String tripId, TripLocation? location) async {
    final index = _trips.indexWhere((trip) => trip.id == tripId);
    if (index == -1) throw Exception('Trip not found');
    _trips[index] = _trips[index].withLocation(location);
  }

  @override
  Future<List<Trip>> getTrips() async => List<Trip>.unmodifiable(_trips);

  @override
  Future<void> addTrip(Trip trip) async {
    _trips.add(trip);
  }
}
