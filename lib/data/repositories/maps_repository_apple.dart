import '../services/maps_service.dart';
import 'maps_repository.dart';

class MapsRepositoryApple implements MapsRepository {
  MapsRepositoryApple(this._service);

  final MapsService _service;

  @override
  Future<bool> openDestination(String destination) async {
    try {
      return await _service.openDestination(destination);
    } on Exception {
      return false;
    }
  }
}
