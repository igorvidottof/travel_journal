import '../../../domain/models/trip_photo.dart';

class TripPhotosState {
  TripPhotosState({
    List<TripPhoto> photos = const [],
    this.isLoading = false,
    this.isSelecting = false,
    this.deletingPhotoId,
    this.sharingPhotoId,
    this.loadFailed = false,
    this.error,
  }) : photos = List.unmodifiable(photos);

  final List<TripPhoto> photos;
  final bool isLoading;
  final bool isSelecting;
  final String? deletingPhotoId;
  final String? sharingPhotoId;
  final bool loadFailed;
  final String? error;

  bool get isBusy =>
      isLoading ||
      isSelecting ||
      deletingPhotoId != null ||
      sharingPhotoId != null;
}
