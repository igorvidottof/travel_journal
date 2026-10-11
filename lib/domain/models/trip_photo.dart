enum PhotoSource { camera, library }

/// A temporary reference to a selected photo, not a permanently stored asset.
class TripPhoto {
  const TripPhoto({required this.path});

  final String path;
}
