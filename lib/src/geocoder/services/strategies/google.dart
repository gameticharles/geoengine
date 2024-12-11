// ignore_for_file: unused_element

import '../../../../geoengine.dart';

/// A concrete implementation of the GeocoderStrategy for the Google Geocoding API.
///
/// This class uses the Google Geocoding API to provide geocoding services,
/// including address-to-coordinate translation (search) and
/// coordinate-to-address translation (reverse).
///
/// It includes a mixin [GeocoderRequestMixin] for shared HTTP request functionality.
/// The mixin handles HTTP GET requests with retry logic and timeout handling.
class GoogleStrategy with GeocoderRequestMixin implements GeocoderStrategy {
  String apiKey;
  Duration requestTimeout;
  int retries;
  String regionBias;
  String resultType;
  String locationType;
  String components;
  int rateLimit;

  /// Private constructor to enforce the use of the factory method.
  GoogleStrategy._({
    required this.apiKey,
    this.requestTimeout = const Duration(seconds: 10),
    this.retries = 3,
    this.regionBias = 'US',
    this.resultType = 'address',
    this.locationType = 'ROOFTOP',
    this.components = 'country:US',
    this.rateLimit = 10,
  });

  /// Private configuration method.
  void _configure(Map<String, dynamic> config) {
    requestTimeout = config['requestTimeout'] ?? requestTimeout;
    retries = config['retries'] ?? retries;
    regionBias = config['regionBias'] ?? regionBias;
    resultType = config['resultType'] ?? resultType;
    locationType = config['locationType'] ?? locationType;
    components = config['components'] ?? components;
    rateLimit = config['rateLimit'] ?? rateLimit;
  }

  /// Public factory method.
  static Map<String, dynamic> create(String apiKey) {
    var strategy = GoogleStrategy._(apiKey: apiKey);
    return {
      'strategy': strategy,
      'configure': (Map<String, dynamic> config) => strategy._configure(config)
    };
  }

  @override
  Future<GeocoderRequestResponse> search(
      String address, String language) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&language=${Uri.encodeComponent(language)}&key=$apiKey';
    // Performs the geocoding request using the shared performRequest method
    // from GeocodingRequestMixin with specified parameters.
    return performRequest(url, requestTimeout,
        retries: retries, service: 'Google Maps');
  }

  @override
  Future<GeocoderRequestResponse> reverse(
      LatLng location, String language) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&language=${Uri.encodeComponent(language)}&key=$apiKey';
    // Performs the reverse geocoding request using the shared performRequest method
    // from GeocodingRequestMixin with specified parameters.
    return performRequest(url, requestTimeout,
        retries: retries, service: 'Google Maps');
  }
}
