import '../../domain/models/trip.dart';
import '../../domain/models/trip_location.dart';
import '../services/storage_service_local.dart';
import 'trip_repository.dart';
import 'photo_repository.dart';

/// Keeps trip IDs reachable after restarts so saved photo associations can load.
class TripRepositoryPersistent implements TripRepository {
  TripRepositoryPersistent(this._storage, this._photos);

  final StorageServiceLocal _storage;
  final PhotoRepository _photos;
  Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<_TripSnapshot> _load() async {
    final raw = await _storage.readJson('trips.json');
    if (raw == null) return const _TripSnapshot([], {});
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
          !_validId(entry['id'] as String) ||
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
    final pending = <String>{};
    final rawPending = raw['pendingPhotoDeletionIds'];
    if (rawPending != null) {
      if (rawPending is! List) {
        throw const FormatException('Invalid pending photo cleanup');
      }
      for (final id in rawPending) {
        if (id is! String ||
            !_validId(id) ||
            ids.contains(id) ||
            !pending.add(id)) {
          throw const FormatException('Invalid pending photo cleanup');
        }
      }
    }
    return _TripSnapshot(List.unmodifiable(trips), pending);
  }

  @override
  Future<List<Trip>> getTrips() => _serialize(() async {
    final snapshot = await _load();
    await _cleanPending(snapshot);
    return snapshot.trips;
  });

  bool _validId(String id) => id.isNotEmpty && id != '.' && id != '..';

  Future<Set<String>> _cleanPending(_TripSnapshot snapshot) async {
    final remaining = {...snapshot.pending};
    for (final id in snapshot.pending) {
      try {
        await _photos.deleteTripPhotos(id);
        remaining.remove(id);
      } on Exception {
        // The durable queue survives a restart and is retried on the next load.
      }
    }
    if (remaining.length != snapshot.pending.length) {
      try {
        await _commit(snapshot.trips, remaining);
      } on Exception {
        // Repeating completed cleanup is harmless if clearing the queue fails.
        return snapshot.pending;
      }
    }
    return remaining;
  }

  @override
  Future<TripDeletionResult> deleteTrip(String tripId) => _serialize(() async {
    final snapshot = await _load();
    if (!snapshot.trips.any((trip) => trip.id == tripId)) {
      throw Exception('Trip not found');
    }
    final remaining = snapshot.trips
        .where((trip) => trip.id != tripId)
        .toList();
    final pending = {...snapshot.pending, tripId};
    // Commit removal and cleanup intent together before touching any photos.
    await _commit(remaining, pending);
    final unfinished = await _cleanPending(_TripSnapshot(remaining, pending));
    return TripDeletionResult(photoCleanupPending: unfinished.contains(tripId));
  });

  @override
  Future<void> addTrip(Trip trip) => _serialize(() async {
    final snapshot = await _load();
    final trips = snapshot.trips;
    if (!_validId(trip.id) ||
        snapshot.pending.contains(trip.id) ||
        trips.any((existing) => existing.id == trip.id)) {
      throw const FormatException('Duplicate trip ID');
    }
    await _commit([...trips, trip], snapshot.pending);
  });

  @override
  Future<void> updateTripDetails(
    String tripId, {
    required String name,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
  }) => _serialize(() async {
    final snapshot = await _load();
    final trips = snapshot.trips;
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
    ], snapshot.pending);
  });

  @override
  Future<void> setLocation(String tripId, TripLocation? location) =>
      _serialize(() async {
        final snapshot = await _load();
        final trips = snapshot.trips;
        if (!trips.any((trip) => trip.id == tripId)) {
          throw Exception('Trip not found');
        }
        await _commit([
          for (final trip in trips)
            trip.id == tripId ? trip.withLocation(location) : trip,
        ], snapshot.pending);
      });

  Future<void> _commit(List<Trip> trips, Set<String> pending) =>
      _storage.writeJson('trips.json', {
        'version': 1,
        if (pending.isNotEmpty) 'pendingPhotoDeletionIds': pending.toList(),
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

class _TripSnapshot {
  const _TripSnapshot(this.trips, this.pending);

  final List<Trip> trips;
  final Set<String> pending;
}
