import '../services/timezone_service.dart';
import 'timezone_repository.dart';

class TimezoneRepositoryPlatform implements TimezoneRepository {
  TimezoneRepositoryPlatform(this._service);

  final TimezoneService _service;

  @override
  Future<String> localTimezone() => _service.localTimezone();

  @override
  DateTime startOfDayUtc(DateTime calendarDate, {required String timezone}) =>
      _service.startOfDayUtc(calendarDate, timezone: timezone);
}
