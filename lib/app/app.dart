import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/core/ui/app_shell.dart';
import '../ui/trips/view_models/trips_view_model.dart';

class TravelJournalApp extends ConsumerWidget {
  const TravelJournalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load trips at startup while preserving the current placeholder UI.
    ref.watch(tripsViewModelProvider);

    return const CupertinoApp(
      title: 'Travel Journal',
      debugShowCheckedModeBanner: false,
      home: AppShell(),
    );
  }
}
