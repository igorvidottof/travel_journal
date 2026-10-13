import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/app_info_repository.dart';
import '../data/repositories/app_info_repository_platform.dart';
import '../data/repositories/maps_repository.dart';
import '../data/repositories/maps_repository_apple.dart';
import '../data/repositories/share_repository.dart';
import '../data/repositories/share_repository_platform.dart';
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
import '../data/services/share_service.dart';
import '../data/services/notification_service.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/notification_repository_platform.dart';
import '../data/repositories/trip_reminder_repository.dart';
import '../data/repositories/trip_reminder_repository_local.dart';
import '../domain/use_cases/synchronize_trip_reminders_use_case.dart';
import '../data/services/timezone_service.dart';
import '../data/repositories/timezone_repository.dart';
import '../data/repositories/timezone_repository_platform.dart';

final timezoneServiceProvider = Provider<TimezoneService>(
  (ref) => TimezoneService(),
);

final timezoneRepositoryProvider = Provider<TimezoneRepository>(
  (ref) => TimezoneRepositoryPlatform(ref.watch(timezoneServiceProvider)),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.watch(timezoneServiceProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) =>
      NotificationRepositoryPlatform(ref.watch(notificationServiceProvider)),
);

final tripReminderRepositoryProvider = Provider<TripReminderRepository>(
  (ref) => TripReminderRepositoryLocal(ref.watch(storageServiceLocalProvider)),
);

final synchronizeTripRemindersUseCaseProvider =
    Provider<SynchronizeTripRemindersUseCase>((ref) {
      return SynchronizeTripRemindersUseCase(
        ref.watch(tripReminderRepositoryProvider),
        ref.watch(notificationRepositoryProvider),
        ref.watch(tripRepositoryProvider),
        ref.watch(timezoneRepositoryProvider),
      );
    });

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

final shareServiceProvider = Provider<ShareService>((ref) => ShareService());

final shareRepositoryProvider = Provider<ShareRepository>(
  (ref) => ShareRepositoryPlatform(
    ref.watch(shareServiceProvider),
    ref.watch(photoStorageServiceLocalProvider),
  ),
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
