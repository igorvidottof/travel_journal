import 'package:cupertino_ui/cupertino_ui.dart';

import '../../../domain/models/trip.dart';
import 'trip_form_screen.dart';

class EditTripScreen extends StatelessWidget {
  const EditTripScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) => TripFormScreen(initialTrip: trip);
}
