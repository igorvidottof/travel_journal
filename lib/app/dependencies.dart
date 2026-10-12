import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/app_info_repository.dart';
import '../data/repositories/app_info_repository_platform.dart';
import '../data/repositories/maps_repository.dart';
import '../data/repositories/maps_repository_apple.dart';
import '../data/services/location_service.dart';
import '../data/services/app_info_service.dart';
import '../data/services/maps_service.dart';
import '../data/repositories/trip_repository_persistent.dart';
import '../data/repositories/photo_repository.dart';
import '../data/repositories/photo_repository_picker.dart';
import '../data/repositories/trip_repository.dart';
import '../data/services/storage_service_local.dart';
import '../data/services/photo_service_picker.dart';
import '../data/services/photo_storage_service_local.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final appInfoServiceProvider = Provider<AppInfoService>(
  (ref) => AppInfoService(),
);

final appInfoRepositoryProvider = Provider<AppInfoRepository>(
  (ref) => AppInfoRepositoryPlatform(ref.watch(appInfoServiceProvider)),
);

final mapsServiceProvider = Provider<MapsService>((ref) => MapsService());

final mapsRepositoryProvider = Provider<MapsRepository>(
  (ref) => MapsRepositoryApple(ref.watch(mapsServiceProvider)),
);

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
  (ref) => TripRepositoryPersistent(
    ref.watch(storageServiceLocalProvider),
    ref.watch(photoRepositoryProvider),
  ),
);
