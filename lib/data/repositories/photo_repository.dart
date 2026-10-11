import '../../domain/models/trip_photo.dart';

enum PhotoFailure {
  permissionDenied,
  permissionRestricted,
  unavailable,
  busy,
  platform,
}

class PhotoSelectionException implements Exception {
  const PhotoSelectionException(this.failure);

  final PhotoFailure failure;
}

abstract class PhotoRepository {
  /// Returns a temporary photo reference, or null when selection is cancelled.
  Future<TripPhoto?> selectPhoto(PhotoSource source);
}
