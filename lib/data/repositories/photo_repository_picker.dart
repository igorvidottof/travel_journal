import 'dart:math';

import 'package:flutter/services.dart';

import '../../domain/models/trip_photo.dart';
import '../services/photo_service_picker.dart';
import '../services/photo_storage_service_local.dart';
import 'photo_repository.dart';

/// Serializes read-modify-write operations so concurrent screens cannot lose
/// associations or clean up another operation's newly copied file.
class PhotoRepositoryPicker implements PhotoRepository {
  PhotoRepositoryPicker(this._service, this._storage);

  final PhotoServicePicker _service;
  final PhotoStorageServiceLocal _storage;
  final Random _random = Random.secure();
  Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<PhotoCollection> _load(String tripId) async {
    await _requireTrip(tripId);
    final raw = await _storage.readMetadata(tripId);
    if (raw == null) {
      return _collection(tripId, []);
    }
    if (raw is! Map<String, dynamic> ||
        raw['version'] != 1 ||
        raw['photos'] is! List) {
      throw const FormatException('Unsupported photo metadata');
    }
    final photos = <TripPhoto>[];
    final ids = <String>{};
    for (final entry in raw['photos'] as List<dynamic>) {
      if (entry is! Map<String, dynamic> ||
          entry['id'] is! String ||
          entry['fileName'] is! String ||
          entry['createdAt'] is! String) {
        throw const FormatException('Invalid photo metadata');
      }
      final data = entry;
      final id = data['id'] as String;
      final fileName = data['fileName'] as String;
      if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(id) ||
          !ids.add(id) ||
          !fileName.startsWith('$id.')) {
        throw const FormatException('Invalid photo metadata');
      }
      final file = await _storage.photoFile(tripId, fileName);
      photos.add(
        TripPhoto(
          id: id,
          tripId: tripId,
          fileName: fileName,
          path: file.path,
          createdAt: DateTime.parse(data['createdAt'] as String),
          isMissing: !await file.exists(),
        ),
      );
    }
    return _collection(tripId, photos);
  }

  Future<void> _requireTrip(String tripId) async {
    if (!await _storage.tripExists(tripId)) throw Exception('Trip not found');
  }

  @override
  Future<void> deleteTripPhotos(String tripId) =>
      _serialize(() => _storage.deleteTripPhotos(tripId));

  Future<void> _commit(String tripId, List<TripPhoto> photos) async {
    await _requireTrip(tripId);
    await _storage.writeMetadata(tripId, {
      'version': 1,
      'photos': [
        for (final photo in photos)
          {
            'id': photo.id,
            'fileName': photo.fileName,
            'createdAt': photo.createdAt.toUtc().toIso8601String(),
          },
      ],
    });
  }

  Future<PhotoCollection> _collection(
    String tripId,
    List<TripPhoto> photos,
  ) async {
    final cleaned = await _storage.cleanUnusedFiles(
      tripId,
      photos.map((photo) => photo.fileName).toSet(),
    );
    return PhotoCollection(
      photos,
      warning: !cleaned
          ? 'Some unused photo files could not be removed. Retry loading photos to finish cleanup.'
          : photos.any((photo) => photo.isMissing)
          ? 'Some saved photo files are missing. You can remove their entries or add the photos again.'
          : null,
    );
  }

  @override
  Future<PhotoCollection> getPhotos(String tripId) =>
      _serialize(() => _load(tripId));

  Future<String?> _selectPath(PhotoSource source) async {
    try {
      return (await _service.selectPhoto(source))?.path;
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

  @override
  Future<PhotoCollection> selectPhoto(
    String tripId,
    PhotoSource source,
  ) => _serialize(() async {
    final current = await _load(tripId);
    final selectedPath = await _selectPath(source);
    if (selectedPath == null) return current;
    await _requireTrip(tripId);
    final id = List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final extension = selectedPath.split('.').last.toLowerCase();
    final fileName =
        '$id.${RegExp(r'^[a-z0-9]{1,10}$').hasMatch(extension) ? extension : 'jpg'}';
    final photos = [...current.photos];
    try {
      final path = await _storage.savePhoto(tripId, fileName, selectedPath);
      photos.add(
        TripPhoto(
          id: id,
          tripId: tripId,
          fileName: fileName,
          path: path,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      await _commit(tripId, photos);
    } catch (_) {
      // The old snapshot remains authoritative if copying or commit fails.
      // Cleanup is best-effort and is retried on the next load.
      await _storage.cleanUnusedFiles(
        tripId,
        current.photos.map((photo) => photo.fileName).toSet(),
      );
      rethrow;
    }
    return _collection(tripId, photos);
  });

  @override
  Future<PhotoCollection> deletePhoto(
    String tripId,
    String photoId,
  ) => _serialize(() async {
    final current = await _load(tripId);
    final remaining = current.photos
        .where((photo) => photo.id != photoId)
        .toList();
    // Commit first: a failed metadata write leaves the original file intact.
    // A failed deletion leaves an orphan that cleanup can safely retry.
    await _commit(tripId, remaining);
    return _collection(tripId, remaining);
  });
}
