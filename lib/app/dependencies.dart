import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/in_memory_trip_repository.dart';
import '../data/repositories/trip_repository.dart';

// Keep the repository alive for the app scope so in-memory trips survive
// disposal of feature view models. Both view models use this same provider.
final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => InMemoryTripRepository(),
);
