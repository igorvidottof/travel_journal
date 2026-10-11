import '../../domain/models/trip.dart';
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
      trips.add(
        Trip(
          id: entry['id'] as String,
          name: entry['name'] as String,
          destination: entry['destination'] as String,
          startDate: DateTime.parse(entry['startDate'] as String),
          endDate: DateTime.parse(entry['endDate'] as String),
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
    await _storage.writeJson('trips.json', {
      'version': 1,
      'trips': [
        for (final item in [...trips, trip])
          {
            'id': item.id,
            'name': item.name,
            'destination': item.destination,
            'startDate': item.startDate.toIso8601String(),
            'endDate': item.endDate.toIso8601String(),
          },
      ],
    });
  });
}
