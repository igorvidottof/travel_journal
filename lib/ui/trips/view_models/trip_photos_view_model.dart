import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/dependencies.dart';
import '../../../data/repositories/photo_repository.dart';
import '../../../data/repositories/share_repository.dart';
import '../../../domain/models/trip_photo.dart';
import 'trip_photos_state.dart';

final tripPhotosViewModelProvider = NotifierProvider.autoDispose
    .family<TripPhotosViewModel, TripPhotosState, String>(
      TripPhotosViewModel.new,
    );

class TripPhotosViewModel extends Notifier<TripPhotosState> {
  TripPhotosViewModel(this.tripId);

  final String tripId;

  @override
  TripPhotosState build() {
    final repository = ref.watch(photoRepositoryProvider);
    // Start after build has returned its initial loading state.
    unawaited(Future.microtask(() => _load(repository)));
    return TripPhotosState(isLoading: true);
  }

  void _showCollection(PhotoCollection collection) {
    if (!ref.mounted) return;
    state = TripPhotosState(
      photos: collection.photos,
      error: collection.warning,
    );
  }

  Future<void> _load(PhotoRepository repository) async {
    if (!ref.mounted) return;
    try {
      _showCollection(await repository.getPhotos(tripId));
    } on Exception {
      if (!ref.mounted) return;
      state = TripPhotosState(
        photos: state.photos,
        loadFailed: true,
        error: 'Unable to load saved photos. Please retry.',
      );
    }
  }

  Future<void> loadPhotos() async {
    if (state.isBusy) return;
    state = TripPhotosState(photos: state.photos, isLoading: true);
    await _load(ref.read(photoRepositoryProvider));
  }

  Future<void> selectPhoto(PhotoSource source) async {
    if (state.isBusy || state.loadFailed) return;
    final repository = ref.read(photoRepositoryProvider);
    final keepAlive = ref.keepAlive();
    state = TripPhotosState(photos: state.photos, isSelecting: true);

    try {
      _showCollection(await repository.selectPhoto(tripId, source));
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
        error:
            'Unable to save the photo. Check available storage and try again.',
      );
    } finally {
      keepAlive.close();
    }
  }

  Future<void> deletePhoto(String photoId) async {
    if (state.isBusy || state.loadFailed) return;
    final repository = ref.read(photoRepositoryProvider);
    final keepAlive = ref.keepAlive();
    state = TripPhotosState(photos: state.photos, deletingPhotoId: photoId);
    try {
      _showCollection(await repository.deletePhoto(tripId, photoId));
    } on Exception {
      if (!ref.mounted) return;
      state = TripPhotosState(
        photos: state.photos,
        error: 'Unable to delete the photo. Please retry.',
      );
    } finally {
      keepAlive.close();
    }
  }

  Future<void> sharePhoto(TripPhoto photo, Rect origin) async {
    if (state.isBusy || state.loadFailed) return;
    final repository = ref.read(shareRepositoryProvider);
    final keepAlive = ref.keepAlive();
    final previous = state;
    state = TripPhotosState(photos: previous.photos, sharingPhotoId: photo.id);
    try {
      final outcome = await repository.sharePhoto(
        photo,
        sharePositionOrigin: origin,
      );
      if (!ref.mounted) return;
      final error = switch (outcome) {
        PhotoShareOutcome.missingFile =>
          'This saved photo file is missing and cannot be shared.',
        PhotoShareOutcome.busy =>
          'Another Share Sheet is open. Close it and try again.',
        PhotoShareOutcome.failed =>
          'Unable to share the photo. Please try again.',
        // An unavailable result does not mean sharing failed: the platform
        // may have opened the sheet without reporting the selected action.
        PhotoShareOutcome.shared ||
        PhotoShareOutcome.cancelled ||
        PhotoShareOutcome.unavailable => previous.error,
      };
      state = TripPhotosState(photos: previous.photos, error: error);
    } finally {
      if (ref.mounted && state.sharingPhotoId != null) state = previous;
      keepAlive.close();
    }
  }
}
