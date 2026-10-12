import '../../domain/models/trip.dart';
import '../../domain/models/trip_location.dart';
import '../services/storage_service_local.dart';
import 'trip_repository.dart';

/// Keeps trip IDs reachable after restarts so saved photo associations can load.
class TripRepositoryPersistent implements TripRepository {
  TripRepositoryPersistent(this._storage);

  final StorageServiceLocal _storage;
  Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<Trip>> _load() async {
    final raw = await _storage.readJson('trips.json');
    if (raw == null) return const [];
    if (raw is! Map<String, dynamic> ||
        raw['version'] != 1 ||
        raw['trips'] is! List) {
      throw const FormatException('Invalid trip metadata');
    }
    final trips = <Trip>[];
    final ids = <String>{};
    for (final entry in raw['trips'] as List<dynamic>) {
      if (entry is! Map<String, dynamic> ||
          entry['id'] is! String ||
          entry['name'] is! String ||
          entry['destination'] is! String ||
          entry['startDate'] is! String ||
          entry['endDate'] is! String ||
          !ids.add(entry['id'] as String)) {
        throw const FormatException('Invalid trip metadata');
      }
      final coordinates = entry['location'];
      TripLocation? location;
      if (coordinates != null) {
        if (coordinates is! Map<String, dynamic> ||
            coordinates['latitude'] is! num ||
            coordinates['longitude'] is! num) {
          throw const FormatException('Invalid trip location');
        }
        location = TripLocation(
          latitude: (coordinates['latitude'] as num).toDouble(),
          longitude: (coordinates['longitude'] as num).toDouble(),
        );
      }
      trips.add(
        Trip(
          id: entry['id'] as String,
          name: entry['name'] as String,
          destination: entry['destination'] as String,
          startDate: DateTime.parse(entry['startDate'] as String),
          endDate: DateTime.parse(entry['endDate'] as String),
          location: location,
        ),
      );
    }
    return List.unmodifiable(trips);
  }

  @override
  Future<List<Trip>> getTrips() => _serialize(_load);

  @override
  Future<void> addTrip(Trip trip) => _serialize(() async {
    final trips = await _load();
    if (trips.any((existing) => existing.id == trip.id)) {
      throw const FormatException('Duplicate trip ID');
    }
    await _commit([...trips, trip]);
  });

  @override
  Future<void> updateTripDetails(
    String tripId, {
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
  }) => _serialize(() async {
    final trips = await _load();
    if (!trips.any((trip) => trip.id == tripId)) {
      throw Exception('Trip not found');
    }
    await _commit([
      for (final trip in trips)
        trip.id == tripId
            ? trip.withDetails(
                name: name,
                destination: destination,
                startDate: startDate,
                endDate: endDate,
              )
            : trip,
    ]);
  });

  @override
  Future<void> setLocation(String tripId, TripLocation? location) =>
      _serialize(() async {
        final trips = await _load();
        if (!trips.any((trip) => trip.id == tripId)) {
          throw Exception('Trip not found');
        }
        await _commit([
          for (final trip in trips)
            trip.id == tripId ? trip.withLocation(location) : trip,
        ]);
      });

  Future<void> _commit(List<Trip> trips) => _storage.writeJson('trips.json', {
    'version': 1,
    'trips': [
      for (final item in trips)
        {
          'id': item.id,
          'name': item.name,
          'destination': item.destination,
          'startDate': item.startDate.toIso8601String(),
          'endDate': item.endDate.toIso8601String(),
          if (item.location != null)
            'location': {
              'latitude': item.location!.latitude,
              'longitude': item.location!.longitude,
            },
        },
    ],
  });
}
