import 'package:geolocator/geolocator.dart';

import '../../domain/models/trip_location.dart';

enum LocationFailure { disabled, denied, deniedForever }

class LocationException implements Exception {
  const LocationException(this.failure);
  final LocationFailure failure;
}

/// Requests a single foreground fix only after an explicit user action.
class LocationService {
  Future<TripLocation> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.disabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.deniedForever);
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const LocationException(LocationFailure.denied);
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return TripLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();
}
