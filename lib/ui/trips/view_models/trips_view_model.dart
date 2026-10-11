import 'package:flutter/foundation.dart';

import '../../../data/repositories/trip_repository.dart';
import '../../../domain/models/trip.dart';

class TripsViewModel extends ChangeNotifier {
  TripsViewModel({required this._tripRepository});

  final TripRepository _tripRepository;
  List<Trip> _trips = const [];
  bool _isLoading = false;
  String? _error;

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Recarrega uma cópia imutável dos dados do repositório síncrono.
  void loadTrips() {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trips = List<Trip>.unmodifiable(_tripRepository.getTrips());
    } on Exception {
      _error = 'Unable to load trips. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
