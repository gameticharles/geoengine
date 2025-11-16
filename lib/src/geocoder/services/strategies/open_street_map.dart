// ignore_for_file: unused_element, unused_element_parameter

import '../../../coordinate_systems/points/points.dart';
import 'request.dart';
import 'strategy.dart';

/// A concrete implementation of the GeocoderStrategy for the OpenStreetMap Nominatim API.
///
/// This class uses the OpenStreetMap Nominatim API to provide geocoding services,
/// including address-to-coordinate translation (search) and
/// coordinate-to-address translation (reverse).
///
/// It includes a mixin [GeocoderRequestMixin] for shared HTTP request functionality.
class OpenStreetMapStrategy
    with GeocoderRequestMixin
    implements GeocoderStrategy {
  Duration requestTimeout;
  int retries;
  String email;
  String countryCodes;
  String viewBox;
  String boundedViewBox;
  int limit;
  int addressDetails;

  /// Private constructor to enforce the use of the factory method.
  OpenStreetMapStrategy._({
    this.requestTimeout = const Duration(seconds: 10),
    this.retries = 3,
    this.email = '',
    this.countryCodes = '',
    this.viewBox = '',
    this.boundedViewBox = '',
    this.limit = 5,
    this.addressDetails = 1,
  });

  /// Private configuration method.
  void _configure(Map<String, dynamic> config) {
    requestTimeout = config['requestTimeout'] ?? const Duration(seconds: 10);
    retries = config['retries'] ?? 3;
    email = config['email'] ?? '';
    countryCodes = config['countryCodes'] ?? '';
    viewBox = config['viewBox'] ?? '';
    viewBox = config['boundedViewBox'] ?? '';
    limit = config['limit'] ?? 5;
    addressDetails = config['addressDetails'] ?? 1;
  }

  /// Public factory method.
  static Map<String, dynamic> create() {
    var strategy = OpenStreetMapStrategy._();
    return {
      'strategy': strategy,
      'configure': (Map<String, dynamic> config) => strategy._configure(config)
    };
  }

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
