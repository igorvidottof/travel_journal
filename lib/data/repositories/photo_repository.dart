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

class PhotoCollection {
  PhotoCollection(List<TripPhoto> photos, {this.warning})
    : photos = List.unmodifiable(photos);

  final List<TripPhoto> photos;
  final String? warning;
}

abstract class PhotoRepository {
  Future<void> deleteTripPhotos(String tripId);

  Future<PhotoCollection> getPhotos(String tripId);

  /// Copies the selected photo before committing its trip association.
  /// Cancellation returns the existing collection without adding a photo.
  Future<PhotoCollection> selectPhoto(String tripId, PhotoSource source);

  Future<PhotoCollection> deletePhoto(String tripId, String photoId);
}
