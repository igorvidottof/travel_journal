import '../../../domain/models/trip_photo.dart';

class TripPhotosState {
  TripPhotosState({
    List<TripPhoto> photos = const [],
    this.isSelecting = false,
    this.error,
  }) : photos = List.unmodifiable(photos);

  final List<TripPhoto> photos;
  final bool isSelecting;
  final String? error;
}
