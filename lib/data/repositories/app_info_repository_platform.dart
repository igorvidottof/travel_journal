import '../services/app_info_service.dart';
import 'app_info_repository.dart';

class AppInfoRepositoryPlatform implements AppInfoRepository {
  AppInfoRepositoryPlatform(this._service);

  final AppInfoService _service;

  @override
  Future<String> loadVersion() => _service.loadVersion();
}
