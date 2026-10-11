import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../data/repositories/photo_repository.dart';
import '../../../domain/models/trip_photo.dart';
import 'trip_photos_state.dart';

// Each trip has temporary state that is discarded after its screen is closed.
final tripPhotosViewModelProvider = NotifierProvider.autoDispose
    .family<TripPhotosViewModel, TripPhotosState, String>(
      TripPhotosViewModel.new,
    );

class TripPhotosViewModel extends Notifier<TripPhotosState> {
  TripPhotosViewModel(this.tripId);

  final String tripId;

  @override
  TripPhotosState build() {
    ref.watch(photoRepositoryProvider);
    return TripPhotosState();
  }

  Future<void> selectPhoto(PhotoSource source) async {
    if (state.isSelecting) return;
    final repository = ref.read(photoRepositoryProvider);
    state = TripPhotosState(photos: state.photos, isSelecting: true);

    try {
      final photo = await repository.selectPhoto(source);
      if (!ref.mounted) return;
      state = TripPhotosState(photos: [...state.photos, ?photo]);
    } on PhotoSelectionException catch (error) {
      if (!ref.mounted) return;
      final resource = source == PhotoSource.camera
          ? 'camera'
          : 'photo library';
      final message = switch (error.failure) {
        PhotoFailure.permissionDenied =>
          'Access to the $resource was denied. Allow access in iOS Settings, then try again.',
        PhotoFailure.permissionRestricted =>
          'Access to the $resource is restricted on this device.',
        PhotoFailure.unavailable =>
          'The $resource is unavailable on this device. Try another photo source.',
        PhotoFailure.busy =>
          'Another photo picker is already open. Close it and try again.',
        PhotoFailure.platform =>
          'Unable to select the photo. Please try again.',
      };
      state = TripPhotosState(photos: state.photos, error: message);
    } on Exception {
      if (!ref.mounted) return;
      state = TripPhotosState(
        photos: state.photos,
        error: 'Unable to select the photo. Please try again.',
      );
    }
  }
}
