import 'trip_location.dart';

class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.location,
  });

  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final TripLocation? location;

  Trip withLocation(TripLocation? location) => Trip(
    id: id,
    name: name,
    destination: destination,
    startDate: startDate,
    endDate: endDate,
    location: location,
  );

  /// Calendar days including both travel dates, unaffected by daylight saving.
  int get durationInDays {
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final end = DateTime.utc(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }
}
