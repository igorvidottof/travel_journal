import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/trip_repository_persistent.dart';
import '../data/repositories/photo_repository.dart';
import '../data/repositories/photo_repository_picker.dart';
import '../data/repositories/trip_repository.dart';
import '../data/services/storage_service_local.dart';
import '../data/services/photo_service_picker.dart';
import '../data/services/photo_storage_service_local.dart';

final storageServiceLocalProvider = Provider<StorageServiceLocal>(
  (ref) => StorageServiceLocal(),
);

final photoServicePickerProvider = Provider<PhotoServicePicker>(
  (ref) => PhotoServicePicker(),
);

final photoStorageServiceLocalProvider = Provider<PhotoStorageServiceLocal>(
  (ref) => PhotoStorageServiceLocal(ref.watch(storageServiceLocalProvider)),
);

// App-scoped repositories serialize operations across transient view models.
final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => PhotoRepositoryPicker(
    ref.watch(photoServicePickerProvider),
    ref.watch(photoStorageServiceLocalProvider),
  ),
);

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepositoryPersistent(ref.watch(storageServiceLocalProvider)),
);
