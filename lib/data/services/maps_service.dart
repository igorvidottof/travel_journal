import 'package:url_launcher/url_launcher.dart';

class MapsService {
  /// Opens a destination search in Apple Maps, without accessing location.
  Future<bool> openDestination(String destination) async {
    final query = destination.trim();
    if (query.isEmpty) return false;
    final url = Uri.https('maps.apple.com', '/', {'q': query});
    return launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
  }
}
