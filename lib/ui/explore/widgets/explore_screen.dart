import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/trip.dart';
import '../view_models/explore_view_model.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  Future<void> _openDestination(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
  ) async {
    final opened = await ref
        .read(exploreViewModelProvider.notifier)
        .openDestination(trip);
    if (opened != false || !context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Unable to Open Apple Maps'),
        content: Text(
          'We couldn’t open ${trip.destination} in Apple Maps. Make sure Apple Maps is installed, then try again.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(exploreViewModelProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(middle: Text('Explore')),
      child: SafeArea(
        child: trips.when(
          loading: () => Center(
            child: Semantics(
              label: 'Loading destinations',
              liveRegion: true,
              child: const CupertinoActivityIndicator(),
            ),
          ),
          error: (error, stackTrace) => _ExploreStatus(
            title: 'Unable to load destinations',
            message: 'Please try again.',
            onRetry: ref.read(exploreViewModelProvider.notifier).reloadTrips,
          ),
          data: (trips) => trips.isEmpty
              ? const _ExploreStatus(
                  title: 'No destinations yet',
                  message:
                      'Add a trip in the Trips tab to explore its destination in Apple Maps.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Explore your destinations',
                          style: CupertinoTheme.of(
                            context,
                          ).textTheme.navTitleTextStyle,
                        ),
                      );
                    }
                    final trip = trips[index - 1];
                    return _DestinationCard(
                      key: ValueKey(trip.id),
                      trip: trip,
                      onPressed: () => _openDestination(context, ref, trip),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    super.key,
    required this.trip,
    required this.onPressed,
  });

  final Trip trip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final blue = CupertinoColors.systemBlue.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.all(20),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(CupertinoIcons.map, size: 32, color: blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.destination,
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Open in Apple Maps',
                    style: TextStyle(color: blue, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(CupertinoIcons.arrow_up_right, color: secondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ExploreStatus extends StatelessWidget {
  const _ExploreStatus({
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
                Icon(
                  CupertinoIcons.map,
                  size: 48,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                const SizedBox(height: 16),
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
