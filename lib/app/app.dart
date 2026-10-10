import 'package:cupertino_ui/cupertino_ui.dart';

import '../ui/core/ui/app_shell.dart';

class TravelJournalApp extends StatelessWidget {
  const TravelJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Travel Journal',
      debugShowCheckedModeBanner: false,
      home: AppShell(),
    );
  }
}
