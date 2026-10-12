import 'package:package_info_plus/package_info_plus.dart';

/// Reads metadata from the installed app rather than a hardcoded version.
class AppInfoService {
  Future<String> loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}
