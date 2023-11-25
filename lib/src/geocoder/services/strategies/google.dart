import '../../../../geoengine.dart';
import 'request.dart';
import 'strategy.dart';

/// A concrete implementation of the GeocoderStrategy for the Google Geocoding API.
///
/// This class uses the Google Geocoding API to provide geocoding services,
/// including address-to-coordinate translation (search) and
/// coordinate-to-address translation (reverse).
///
/// It includes a mixin [GeocoderRequestMixin] for shared HTTP request functionality.
/// The mixin handles HTTP GET requests with retry logic and timeout handling.
class GoogleGeocoderStrategy
    with GeocoderRequestMixin
    implements GeocoderStrategy {
  final String apiKey;
  final Duration requestTimeout;
  final int retries;

  /// Constructs an instance of Google GeocoderStrategy with the provided Google API key.
  ///
  /// [apiKey]: The API key for accessing the Google Geocoding API. This key is used
  ///           to authenticate requests to the Google API.
  ///
  /// [requestTimeout]: (Optional) The duration to wait before the request times out.
  ///                   Defaults to a duration of 10 seconds. This timeout is applied
  ///                   to each attempt of the HTTP request.
  ///
  /// [retries]: (Optional) The number of times to retry the request in case
  ///            of a failure. Defaults to 3 retries. This parameter controls the
  ///            number of retry attempts if the initial request fails.
  GoogleGeocoderStrategy(
    this.apiKey, {
    this.requestTimeout = const Duration(seconds: 10),
    this.retries = 3,
  });

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
