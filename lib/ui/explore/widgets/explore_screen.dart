import 'package:cupertino_ui/cupertino_ui.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Explore')),
      child: SafeArea(child: Center(child: Text('Discover maps and places.'))),
    );
  }
}
