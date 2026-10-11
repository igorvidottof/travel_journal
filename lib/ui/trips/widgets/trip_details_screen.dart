import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/trip.dart';
import '../../../domain/models/trip_photo.dart';
import '../view_models/trip_photos_view_model.dart';
import '../view_models/trips_view_model.dart';

class TripDetailsScreen extends ConsumerWidget {
  const TripDetailsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripDetailsProvider(tripId));

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Trip Details'),
        previousPageTitle: 'Trips',
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
              : _TripDetails(trip: trip),
        ),
      ),
    );
  }
}

class _TripDetails extends ConsumerWidget {
  const _TripDetails({required this.trip});

  final Trip trip;

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
    await ref
        .read(tripPhotosViewModelProvider(trip.id).notifier)
        .deletePhoto(photo.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(tripPhotosViewModelProvider(trip.id));
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
          header: const Text('MEMORIES'),
          hasLeading: false,
          children: [
            Padding(
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
                              onPressed: photos.isBusy || photos.loadFailed
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
                          color: CupertinoColors.systemRed.resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                  if (photos.error != null)
                    CupertinoButton(
                      onPressed: photos.isBusy
                          ? null
                          : ref
                                .read(
                                  tripPhotosViewModelProvider(trip.id).notifier,
                                )
                                .loadPhotos,
                      child: const Text('Reload Photos'),
                    ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: photos.isBusy || photos.loadFailed
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
