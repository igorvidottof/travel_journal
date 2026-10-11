import 'package:cupertino_ui/cupertino_ui.dart';

import '../ui/core/ui/app_shell.dart';
import 'dependencies.dart';

class TravelJournalApp extends StatefulWidget {
  const TravelJournalApp({super.key});

  @override
  State<TravelJournalApp> createState() => _TravelJournalAppState();
}

class _TravelJournalAppState extends State<TravelJournalApp> {
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _dependencies = AppDependencies();
  }

  @override
  void dispose() {
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Travel Journal',
      debugShowCheckedModeBanner: false,
      home: AppShell(),
    );
  }
}
