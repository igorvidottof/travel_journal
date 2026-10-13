import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/core/ui/app_shell.dart';
import '../ui/trips/view_models/trips_view_model.dart';
import '../ui/settings/view_models/trip_reminders_view_model.dart';

class TravelJournalApp extends ConsumerWidget {
  const TravelJournalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(tripRemindersViewModelProvider);
    // The reminders view model reconciles at startup without requesting permission.
    ref.watch(tripsViewModelProvider);

    return const CupertinoApp(
      title: 'Travel Journal',
      debugShowCheckedModeBanner: false,
      home: AppShell(),
    );
  }
}
