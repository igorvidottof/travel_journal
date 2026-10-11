enum PhotoSource { camera, library }

/// Persistent metadata plus a path resolved within the current app container.
class TripPhoto {
  const TripPhoto({
    required this.id,
    required this.tripId,
    required this.fileName,
    required this.path,
    required this.createdAt,
    this.isMissing = false,
  });

  final String id;
  final String tripId;
  final String fileName;
  final String path;
  final DateTime createdAt;
  final bool isMissing;
}
