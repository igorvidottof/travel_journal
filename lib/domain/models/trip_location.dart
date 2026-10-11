/// Coordinates independent of map plugins and platform APIs.
class TripLocation {
  TripLocation({required this.latitude, required this.longitude}) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const FormatException('Invalid trip coordinates');
    }
  }

  final double latitude;
  final double longitude;

  String get label =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}
