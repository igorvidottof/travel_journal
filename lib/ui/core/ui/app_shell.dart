import 'package:cupertino_ui/cupertino_ui.dart';

import '../../explore/widgets/explore_screen.dart';
import '../../settings/widgets/settings_screen.dart';
import '../../trips/widgets/trips_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.briefcase),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => switch (index) {
            0 => const TripsScreen(),
            1 => const ExploreScreen(),
            2 => const SettingsScreen(),
            _ => throw StateError('Unknown tab index: $index'),
          },
        );
      },
    );
  }
}
