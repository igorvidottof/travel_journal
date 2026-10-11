import 'package:flutter/services.dart';

import '../../domain/models/trip_photo.dart';
import '../services/photo_service.dart';
import 'photo_repository.dart';

/// Converts native picker results and failures into application types.
/// Selected-photo UI state stays in the view model; no photos are persisted.
class PickerPhotoRepository implements PhotoRepository {
  PickerPhotoRepository(this._service);

  final PhotoService _service;

  @override
  Future<TripPhoto?> selectPhoto(PhotoSource source) async {
    try {
      final photo = await _service.selectPhoto(source);
      return photo == null ? null : TripPhoto(path: photo.path);
    } on PlatformException catch (error) {
      final failure = switch (error.code) {
        'camera_access_denied' ||
        'photo_access_denied' => PhotoFailure.permissionDenied,
        'camera_access_restricted' ||
        'photo_access_restricted' => PhotoFailure.permissionRestricted,
        'camera_unavailable' || 'invalid_source' => PhotoFailure.unavailable,
        'already_active' || 'multiple_request' => PhotoFailure.busy,
        _ => PhotoFailure.platform,
      };
      throw PhotoSelectionException(failure);
    } on MissingPluginException {
      throw const PhotoSelectionException(PhotoFailure.unavailable);
    }
  }
}
