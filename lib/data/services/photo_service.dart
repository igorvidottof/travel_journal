import 'package:image_picker/image_picker.dart';

import '../../domain/models/trip_photo.dart';

/// Wraps the native picker without copying photos to permanent storage.
class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Returns the raw picker result. Null means cancellation; platform errors
  /// propagate to the repository for translation into application failures.
  Future<XFile?> selectPhoto(PhotoSource source) => _picker.pickImage(
    source: source == PhotoSource.camera
        ? ImageSource.camera
        : ImageSource.gallery,
    requestFullMetadata: false,
  );
}
