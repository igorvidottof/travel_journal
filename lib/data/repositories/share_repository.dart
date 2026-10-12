import 'dart:ui';

import '../../domain/models/trip_photo.dart';

enum PhotoShareOutcome {
  shared,
  cancelled,
  unavailable,
  missingFile,
  busy,
  failed,
}

abstract class ShareRepository {
  /// Shares the persisted photo and reports cancellation or recoverable failures.
  Future<PhotoShareOutcome> sharePhoto(
    TripPhoto photo, {
    required Rect sharePositionOrigin,
  });
}
