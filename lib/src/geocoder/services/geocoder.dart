import '../../../geoengine.dart';
import 'strategies/request.dart';
import 'strategies/strategy.dart';

/// A class to perform geocoding operations using different strategies.
///
/// This class acts as a facade to various geocoding strategies, enabling
/// both standard geocoding (address to coordinates) and reverse geocoding
/// (coordinates to address) using the specified strategy.
///
/// Example usage:
/// ```dart
/// var geocoder = Geocoder(strategy: GoogleGeocoderStrategy.create('YOUR_GOOGLE_API_KEY'));
/// var searchResult = await geocoder.search("1600 Amphitheatre Parkway, Mountain View, CA");
/// var reverseResult = await geocoder.reverse(LatLng(37.422, -122.084));
/// ```
class Geocoder {
  final GeocoderStrategy _strategy;
  late final Function(Map<String, dynamic>) _configureStrategy;
  final Map<String, GeocoderRequestResponse> _cache = {};
  DateTime _lastRequestTime;
  final Duration _throttleDuration;

  /// Constructs a Geocoder instance with the specified geocoding strategy.
  ///
  /// [strategy]: An instance of a class that implements the GeocoderStrategy interface.
  /// [config]: (Optional) Configuration options for the strategy.
  /// [throttleDuration]: (Optional) Duration to wait between successive requests.
  Geocoder({
    required Map<String, dynamic> strategyFactory,
    Map<String, dynamic> config = const {},
    Duration throttleDuration = const Duration(seconds: 1),
  })  : _strategy = strategyFactory['strategy'],
        _throttleDuration = throttleDuration,
        _lastRequestTime = DateTime.now(),
        _configureStrategy = strategyFactory['configure'] {
    _configureStrategy(config);
  }

  /// Performs geocoding to find geographic coordinates for the given address.
  Future<GeocoderRequestResponse> search(String address,
      {String language = 'en'}) async {
    var startTime = DateTime.now();
    try {
      await _throttleRequests();
      String cacheKey = '$address-$language';
      if (_cache.containsKey(cacheKey)) {
        _logSearchMetric(address, true, DateTime.now().difference(startTime));
        return _cache[cacheKey]!;
      }

      String normalizedAddress = _normalizeAddress(address);
      var response = await _strategy.search(normalizedAddress, language);
      _cache[cacheKey] = response;
      _logSearchMetric(normalizedAddress, response.success,
          DateTime.now().difference(startTime));
      return response;
    } catch (e) {
      _logSearchMetric(address, false, DateTime.now().difference(startTime));
      return GeocoderRequestResponse(success: false, error: e.toString());
    }
  }

  /// Performs reverse geocoding to find an address for the given geographic coordinates.
  Future<GeocoderRequestResponse> reverse(LatLng location,
      {String language = 'en'}) async {
    var startTime = DateTime.now();
    try {
      await _throttleRequests();
      var response = await _strategy.reverse(location, language);

      _logReverseMetric(
          location, response.success, DateTime.now().difference(startTime));
      return response;
    } catch (e) {
      _logReverseMetric(location, false, DateTime.now().difference(startTime));
      return GeocoderRequestResponse(success: false, error: e.toString());
    }
  }

  /// Normalizes the address string before sending it to the geocoding strategy.
  String _normalizeAddress(String address) {
    // Trim whitespace
    address = address.trim();

    // Replace common abbreviations (e.g., St. -> Street, Rd. -> Road)
    address = address.replaceAll(RegExp(r'\bSt\.\b'), 'Street');
    address = address.replaceAll(RegExp(r'\bRd\.\b'), 'Road');
    // Add more replacements as needed...

    // Remove special characters except for alphanumeric and space
    address = address.replaceAll(RegExp(r'[^\w\s]'), '');

    // Convert to a standard case (e.g., all lowercase)
    address = address.toLowerCase();

    return address;
  }

  /// Throttles the requests to adhere to the specified throttle duration.
  Future<void> _throttleRequests() async {
    var now = DateTime.now();
    if (now.difference(_lastRequestTime) < _throttleDuration) {
      await Future.delayed(
          _throttleDuration - now.difference(_lastRequestTime));
    }
    _lastRequestTime = DateTime.now();
  }

  /// Logs metrics for search queries.
  void _logSearchMetric(String query, bool success, Duration duration) {
    // Example: Log to console - in a real application, replace with a logging framework or analytics service.
    print(
        'Geocoding Search Query: $query, Success: $success, Timestamp: ${DateTime.now()}');

    //Logger.log('Geocoding Search Query: $query, Success: $success, Duration: ${duration.inMilliseconds}ms');

    // If using an analytics service:
    // AnalyticsService.logEvent('geocoding_search', {
    //   'query': query,
    //   'success': success,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });

    // Logging infrastructure :
    // Logger.log({
    //   'type': 'Geocoding Search',
    //   'query': query,
    //   'success': success,
    //   'timestamp': DateTime.now(),
    // });

    // Note: The actual implementation will depend on the logging or analytics solution you choose.
  }

  /// Logs metrics for reverse geocoding queries.
  void _logReverseMetric(LatLng location, bool success, Duration duration) {
    // Example: Log to console - in a real application, replace with a logging framework or analytics service.
    print(
        'Reverse Geocoding Query: Location(${location.latitude.degrees}, ${location.longitude.degrees}), Success: $success, Timestamp: ${DateTime.now()}');

    //Logger.log('Reverse Geocoding Query: Location(${location.latitude}, ${location.longitude}), Success: $success, Duration: ${duration.inMilliseconds}ms');

    // If using an analytics service:
    // AnalyticsService.logEvent('reverse_geocoding_search', {
    //   'latitude': location.latitude,
    //   'longitude': location.longitude,
    //   'success': success,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });

    // logging infrastructure:
    // Logger.log({
    //   'type': 'Reverse Geocoding',
    //   'latitude': location.latitude,
    //   'longitude': location.longitude,
    //   'success': success,
    //   'timestamp': DateTime.now(),
    // });

    // Note: Adapt this to your specific logging or analytics solution.
  }
}
