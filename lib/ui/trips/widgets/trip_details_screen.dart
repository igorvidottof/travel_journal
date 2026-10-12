import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/trip.dart';
import '../../../domain/models/trip_photo.dart';
import '../../core/view_models/app_tab_view_model.dart';
import '../view_models/trip_photos_view_model.dart';
import '../view_models/trip_deletion_view_model.dart';
import '../view_models/trips_view_model.dart';
import 'trip_location_screen.dart';
import 'edit_trip_screen.dart';

class TripDetailsScreen extends ConsumerWidget {
  const TripDetailsScreen({super.key, required this.tripId});

  final String tripId;

  Future<void> _deleteTrip(BuildContext context, WidgetRef ref) async {
    final viewModel = ref.read(tripDeletionViewModelProvider(tripId).notifier);
    if (!viewModel.beginConfirmation()) return;
    final navigator = Navigator.of(context);
    final warningContext = navigator.context;
    final tabs = ref.read(appTabViewModelProvider.notifier);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Delete Trip?'),
        content: const Text(
          'This permanently deletes this trip and its saved photos. Photos in your library are kept.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed != true) {
      viewModel.cancelConfirmation();
      return;
    }
    final result = await viewModel.deleteTrip();
    if (!context.mounted || result == null) return;
    if (!navigator.mounted) return;
    navigator.popUntil((route) => route.isFirst);
    tabs.selectTrips();
    if (result.photoCleanupPending && warningContext.mounted) {
      await showCupertinoDialog<void>(
        context: warningContext,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Trip Deleted'),
          content: const Text(
            'Some saved photo files could not be removed yet. Cleanup will retry the next time trips are loaded, including when you reopen the app.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletion = ref.watch(tripDeletionViewModelProvider(tripId));
    final trip = ref.watch(tripDetailsProvider(tripId));
    final loadedTrip = trip.isLoading || trip.hasError
        ? null
        : trip.asData?.value;

    return PopScope(
      canPop: !deletion.isBusy,
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Trip Details'),
          previousPageTitle: 'Trips',
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: loadedTrip == null || deletion.isBusy
                ? null
                : () => Navigator.of(context, rootNavigator: true).push<void>(
                    CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => EditTripScreen(trip: loadedTrip),
                    ),
                  ),
            child: const Text('Edit'),
          ),
        ),
        child: SafeArea(
          child: trip.when(
            loading: () => Center(
              child: Semantics(
                label: 'Loading trip',
                liveRegion: true,
                child: const CupertinoActivityIndicator(),
              ),
            ),
            error: (error, stackTrace) => _DetailsStatus(
              title: 'Unable to load trip',
              message: 'Please try again.',
              onRetry: ref.read(tripsViewModelProvider.notifier).loadTrips,
            ),
            data: (trip) => trip == null
                ? const _DetailsStatus(
                    title: 'Trip not found',
                    message:
                        'This trip is no longer available. Go back to Trips.',
                  )
                : _TripDetails(
                    trip: trip,
                    onDelete: () => _deleteTrip(context, ref),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TripDetails extends ConsumerWidget {
  const _TripDetails({required this.trip, required this.onDelete});

  final Trip trip;
  final VoidCallback onDelete;

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showCupertinoModalPopup<PhotoSource>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(PhotoSource.camera),
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(PhotoSource.library),
            child: const Text('Choose from Photo Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    if (ref.read(tripDeletionViewModelProvider(trip.id)).isBusy) return;
    await ref
        .read(tripPhotosViewModelProvider(trip.id).notifier)
        .selectPhoto(source);
  }

  Future<void> _deletePhoto(
    BuildContext context,
    WidgetRef ref,
    TripPhoto photo,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text(
          'This permanently removes the saved photo from this trip.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (ref.read(tripDeletionViewModelProvider(trip.id)).isBusy) return;
    await ref
        .read(tripPhotosViewModelProvider(trip.id).notifier)
        .deletePhoto(photo.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(tripPhotosViewModelProvider(trip.id));
    final deletion = ref.watch(tripDeletionViewModelProvider(trip.id));
    final localizations = CupertinoLocalizations.of(context);
    String formatDate(DateTime date) =>
        '${localizations.datePickerMediumDate(date)}, '
        '${localizations.datePickerYear(date.year)}';
    final days = trip.durationInDays;

    return ListView(
      children: [
        CupertinoListSection.insetGrouped(
          header: const Text('TRIP DETAILS'),
          hasLeading: false,
          children: [
            _DetailRow(label: 'Trip name', value: trip.name),
            _DetailRow(label: 'Destination', value: trip.destination),
            _DetailRow(label: 'Start date', value: formatDate(trip.startDate)),
            _DetailRow(label: 'End date', value: formatDate(trip.endDate)),
            _DetailRow(
              label: 'Duration',
              value: '$days ${days == 1 ? 'day' : 'days'}',
            ),
          ],
        ),
        CupertinoListSection.insetGrouped(
          header: const Text('LOCATION'),
          hasLeading: false,
          children: [
            CupertinoListTile(
              title: Text(
                trip.location == null
                    ? 'Add Trip Location'
                    : 'View or Change Location',
              ),
              subtitle: Text(
                trip.location?.label ??
                    'Choose a pin or use your current location',
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: deletion.isBusy
                  ? null
                  : () => Navigator.of(context).push<void>(
                      CupertinoPageRoute(
                        builder: (context) =>
                            TripLocationScreen(tripId: trip.id),
                      ),
                    ),
            ),
          ],
        ),
        CupertinoListSection.insetGrouped(
          header: const Text('MEMORIES'),
          hasLeading: false,
          children: [
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (photos.isLoading) ...[
                      const CupertinoActivityIndicator(),
                      const SizedBox(height: 8),
                      const Text('Loading saved photos…'),
                    ] else if (photos.photos.isEmpty && !photos.loadFailed) ...[
                      Icon(
                        CupertinoIcons.photo,
                        size: 40,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        header: true,
                        child: Text(
                          'No memories yet',
                          style: CupertinoTheme.of(
                            context,
                          ).textTheme.navTitleTextStyle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your trip photos will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ] else if (photos.photos.isNotEmpty) ...[
                      for (final photo in photos.photos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              _PhotoPreview(
                                path: photo.path,
                                isMissing: photo.isMissing,
                              ),
                              CupertinoButton(
                                onPressed:
                                    deletion.isBusy ||
                                        photos.isBusy ||
                                        photos.loadFailed
                                    ? null
                                    : () => _deletePhoto(context, ref, photo),
                                child: photos.deletingPhotoId == photo.id
                                    ? const CupertinoActivityIndicator()
                                    : Text(
                                        'Delete Photo',
                                        style: TextStyle(
                                          color: CupertinoColors.systemRed
                                              .resolveFrom(context),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (photos.error != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          photos.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: CupertinoColors.systemRed.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (photos.error != null)
                      CupertinoButton(
                        onPressed: deletion.isBusy || photos.isBusy
                            ? null
                            : ref
                                  .read(
                                    tripPhotosViewModelProvider(
                                      trip.id,
                                    ).notifier,
                                  )
                                  .loadPhotos,
                        child: const Text('Reload Photos'),
                      ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed:
                          deletion.isBusy || photos.isBusy || photos.loadFailed
                          ? null
                          : () => _addPhoto(context, ref),
                      child: photos.isSelecting
                          ? Semantics(
                              label: 'Selecting and saving photo',
                              liveRegion: true,
                              child: const CupertinoActivityIndicator(),
                            )
                          : const Text('Add Photo'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        CupertinoListSection.insetGrouped(
          hasLeading: false,
          children: [
            CupertinoListTile(
              title: CupertinoButton(
                onPressed: deletion.isBusy || photos.isBusy ? null : onDelete,
                child: deletion.isDeleting
                    ? Semantics(
                        label: 'Deleting trip',
                        liveRegion: true,
                        child: CupertinoActivityIndicator(),
                      )
                    : Text(
                        'Delete Trip',
                        style: TextStyle(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                        ),
                      ),
              ),
            ),
            if (deletion.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    deletion.error!,
                    style: TextStyle(
                      color: CupertinoColors.systemRed.resolveFrom(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path, required this.isMissing});

  final String path;
  final bool isMissing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ColoredBox(
          color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          child: isMissing
              ? const Center(child: Text('This saved photo file is missing.'))
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: 1200,
                  semanticLabel: 'Saved trip photo',
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) =>
                          frame != null || wasSynchronouslyLoaded
                          ? child
                          : const Center(child: CupertinoActivityIndicator()),
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Unable to preview this photo. Try selecting it again.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}

class _DetailsStatus extends StatelessWidget {
  const _DetailsStatus({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.navTitleTextStyle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
