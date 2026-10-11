import 'package:flutter/foundation.dart';

import '../../../data/repositories/trip_repository.dart';
import '../../../domain/models/trip.dart';

class CreateTripViewModel extends ChangeNotifier {
  CreateTripViewModel({
    required this._tripRepository,
    required this._onTripCreated,
  });

  final TripRepository _tripRepository;
  final VoidCallback _onTripCreated;
  static int _lastId = 0;

  String _name = '';
  String _destination = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  bool _isDisposed = false;
  String? _error;

  String get name => _name;
  String get destination => _destination;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isSaving => _isSaving;
  String? get error => _error;

  void updateName(String value) {
    if (_isDisposed || _isSaving || value == _name) return;
    _name = value;
    _error = null;
    notifyListeners();
  }

  void updateDestination(String value) {
    if (_isDisposed || _isSaving || value == _destination) return;
    _destination = value;
    _error = null;
    notifyListeners();
  }

  void updateStartDate(DateTime? value) {
    if (_isDisposed || _isSaving || value == _startDate) return;
    _startDate = value;
    _error = null;
    notifyListeners();
  }

  void updateEndDate(DateTime? value) {
    if (_isDisposed || _isSaving || value == _endDate) return;
    _endDate = value;
    _error = null;
    notifyListeners();
  }

  String? _validate() {
    if (_name.trim().isEmpty) return 'Enter a trip name.';
    if (_destination.trim().isEmpty) return 'Enter a destination.';
    if (_startDate == null || _endDate == null) {
      return 'Select the start and end dates.';
    }
    if (_endDate!.isBefore(_startDate!)) {
      return 'The end date must not be earlier than the start date.';
    }
    return null;
  }

  /// Usa um contador monotônico para evitar colisões na sessão em memória.
  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    _lastId = timestamp > _lastId ? timestamp : _lastId + 1;
    return _lastId.toString();
  }

  /// Salva a viagem e solicita a atualização da lista após o sucesso.
  Future<bool> saveTrip() async {
    if (_isDisposed || _isSaving) return false;

    _error = _validate();
    if (_error != null) {
      notifyListeners();
      return false;
    }

    final trip = Trip(
      id: _generateId(),
      name: _name.trim(),
      destination: _destination.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
    );
    _isSaving = true;
    notifyListeners();

    try {
      try {
        await _tripRepository.addTrip(trip);
      } on Exception {
        if (!_isDisposed) {
          _error = 'Unable to save the trip. Please try again.';
        }
        return false;
      }

      if (!_isDisposed) {
        _name = '';
        _destination = '';
        _startDate = null;
        _endDate = null;
        _onTripCreated();
      }
      return true;
    } finally {
      _isSaving = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
