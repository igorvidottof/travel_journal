import 'dart:ui';

import 'package:share_plus/share_plus.dart' show ShareResultStatus;

import '../../domain/models/trip_photo.dart';
import '../services/photo_storage_service_local.dart';
import '../services/share_service.dart';
import 'share_repository.dart';

class ShareRepositoryPlatform implements ShareRepository {
  ShareRepositoryPlatform(this._service, this._photoStorage);

  final ShareService _service;
  final PhotoStorageServiceLocal _photoStorage;
  bool _isSharing = false;

  @override
  Future<PhotoShareOutcome> sharePhoto(
    TripPhoto photo, {
    required Rect sharePositionOrigin,
  }) async {
    // One native sheet at a time, even across different trip screens.
    if (_isSharing) return PhotoShareOutcome.busy;
    if (!sharePositionOrigin.isFinite || sharePositionOrigin.isEmpty) {
      return PhotoShareOutcome.failed;
    }
    _isSharing = true;
    try {
      final file = await _photoStorage.photoFile(photo.tripId, photo.fileName);
      if (!await file.exists()) return PhotoShareOutcome.missingFile;
      final result = await _service.shareFile(
        file,
        sharePositionOrigin: sharePositionOrigin,
      );
      return switch (result.status) {
        ShareResultStatus.success => PhotoShareOutcome.shared,
        ShareResultStatus.dismissed => PhotoShareOutcome.cancelled,
        ShareResultStatus.unavailable => PhotoShareOutcome.unavailable,
      };
    } on Exception {
      return PhotoShareOutcome.failed;
    } finally {
      _isSharing = false;
    }
  }
}
