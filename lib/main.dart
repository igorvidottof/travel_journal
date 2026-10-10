import 'package:cupertino_ui/cupertino_ui.dart';

void main() {
  runApp(const TravelJournalApp());
}

class TravelJournalApp extends StatelessWidget {
  const TravelJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Travel Journal',
      debugShowCheckedModeBanner: false,
      home: TravelHomePage(),
    );
  }
}

class TravelHomePage extends StatelessWidget {
  const TravelHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('My Trips')),
          SliverFillRemaining(
            child: Center(child: Text('Your journey starts here.')),
          ),
        ],
      ),
    );
  }
}
