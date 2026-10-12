abstract class MapsRepository {
  /// Returns false when the destination cannot be opened in Apple Maps.
  Future<bool> openDestination(String destination);
}
