import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/trips_view_model.dart';
import 'create_trip_screen.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

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
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).push<void>(
                CupertinoPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (context) => const CreateTripScreen(),
                ),
              ),
          child: const Icon(CupertinoIcons.add, semanticLabel: 'Create trip'),
        ),
      ),
      child: SafeArea(
        child: trips.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to load trips. Please try again.'),
                CupertinoButton(
                  onPressed: ref
                      .read(tripsViewModelProvider.notifier)
                      .loadTrips,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (trips) => trips.isEmpty
              ? const Center(child: Text('Tap + to create your first trip.'))
              : ListView(
                  children: [
                    CupertinoListSection.insetGrouped(
                      hasLeading: false,
                      children: [
                        for (final trip in trips)
                          CupertinoListTile(
                            key: ValueKey(trip.id),
                            title: Text(trip.name),
                            subtitle: Text(
                              '${trip.destination}\n'
                              '${formatDate(trip.startDate)}'
                              ' – ${formatDate(trip.endDate)}',
                              maxLines: 3,
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
