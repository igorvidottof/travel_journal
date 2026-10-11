import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/trips_view_model.dart';
import 'create_trip_screen.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  void _createTrip(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push<void>(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => const CreateTripScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsViewModelProvider);
    final localizations = CupertinoLocalizations.of(context);
    String formatDate(DateTime date) =>
        '${localizations.datePickerMediumDate(date)}, '
        '${localizations.datePickerYear(date.year)}';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Trips'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _createTrip(context),
          child: const Icon(CupertinoIcons.add, semanticLabel: 'Create trip'),
        ),
      ),
      child: SafeArea(
        child: trips.when(
          loading: () => Center(
            child: Semantics(
              label: 'Loading trips',
              liveRegion: true,
              child: const CupertinoActivityIndicator(),
            ),
          ),
          error: (error, stackTrace) => _TripsStatus(
            title: 'Unable to load trips',
            message: 'Please try again.',
            actionLabel: 'Retry',
            onAction: ref.read(tripsViewModelProvider.notifier).loadTrips,
          ),
          data: (trips) => trips.isEmpty
              ? _TripsStatus(
                  title: 'No trips yet',
                  message:
                      'Create your first trip to start your travel journal.',
                  actionLabel: 'Create Trip',
                  onAction: () => _createTrip(context),
                )
              : ListView(
                  children: [
                    CupertinoListSection.insetGrouped(
                      hasLeading: false,
                      children: [
                        for (final trip in trips)
                          CupertinoListTile.notched(
                            key: ValueKey(trip.id),
                            title: Text(
                              trip.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  trip.destination,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatDate(trip.startDate)}'
                                  ' – ${formatDate(trip.endDate)}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TripsStatus extends StatelessWidget {
  const _TripsStatus({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

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
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
