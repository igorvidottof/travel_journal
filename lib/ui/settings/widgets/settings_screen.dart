import 'package:cupertino_ui/cupertino_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(child: Center(child: Text('Manage your preferences.'))),
    );
  }
}
