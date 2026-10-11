import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/trip.dart';
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

class _TripDetails extends StatelessWidget {
  const _TripDetails({required this.trip});

  final Trip trip;

  Future<void> _addPhoto(BuildContext context) => showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Add Photo'),
      content: const Text('Adding photos to your trip is coming soon.'),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
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
                  Icon(
                    CupertinoIcons.photo,
                    size: 40,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () => _addPhoto(context),
                    child: const Text('Add Photo'),
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
