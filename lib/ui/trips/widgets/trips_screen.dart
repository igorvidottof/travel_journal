import 'package:cupertino_ui/cupertino_ui.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Trips')),
      child: SafeArea(child: Center(child: Text('Your journey starts here.'))),
    );
  }
}
