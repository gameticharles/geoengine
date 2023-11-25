import '../../../../geoengine.dart';
import 'request.dart';
import 'strategy.dart';

/// A concrete implementation of the GeocoderStrategy for the OpenStreetMap Nominatim API.
///
/// This class uses the OpenStreetMap Nominatim API to provide geocoding services,
/// including address-to-coordinate translation (search) and
/// coordinate-to-address translation (reverse).
///
/// It includes a mixin [GeocoderRequestMixin] for shared HTTP request functionality.
class OpenStreetMapGeocoderStrategy
    with GeocoderRequestMixin
    implements GeocoderStrategy {
  final Duration requestTimeout;
  final int retries;

  /// Constructs an instance of OpenStreetMap GeocoderStrategy.
  ///
  /// [requestTimeout]: (Optional) The duration to wait before the request times out.
  ///                   Defaults to a duration of 10 seconds.
  /// [retries]: (Optional) The number of times to retry the request in case
  ///            of a failure. Defaults to 3 retries.
  OpenStreetMapGeocoderStrategy({
    this.requestTimeout = const Duration(seconds: 10),
    this.retries = 3,
  });

  @override
  Future<GeocoderRequestResponse> search(
      String address, String language) async {
    final url =
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}&accept-language=${Uri.encodeComponent(language)}';
    return performRequest(url, requestTimeout,
        retries: retries, service: 'OpenStreetMap');
  }

  @override
  Future<GeocoderRequestResponse> reverse(
      LatLng location, String language) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&accept-language=${Uri.encodeComponent(language)}';
    return performRequest(url, requestTimeout,
        retries: retries, service: 'OpenStreetMap');
  }
}
