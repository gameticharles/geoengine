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
/// var geocoder = Geocoder(strategy: GoogleGeocoderStrategy('YOUR_GOOGLE_API_KEY'));
/// var searchResult = await geocoder.search("1600 Amphitheatre Parkway, Mountain View, CA");
/// var reverseResult = await geocoder.reverse(LatLng(37.422, -122.084));
/// ```
class Geocoder {
  final GeocoderStrategy _strategy;

  /// Constructs a Geocoder instance with the specified geocoding strategy.
  ///
  /// [strategy]: An instance of a class that implements the GeocoderStrategy interface.
  Geocoder({required GeocoderStrategy strategy}) : _strategy = strategy;

  /// Performs geocoding to find geographic coordinates for the given address.
  ///
  /// [address]: The address to geocode.
  /// [language]: (Optional) The language in which to return results.
  ///
  /// Returns a `Future` that resolves to geocoding results.
  Future<GeocoderRequestResponse> search(String address,
      {String language = 'en'}) {
    return _strategy.search(address, language);
  }

  /// Performs reverse geocoding to find an address for the given geographic coordinates.
  ///
  /// [location]: The geographic coordinates (latitude and longitude) for reverse geocoding.
  /// [language]: (Optional) The language in which to return results.
  ///
  /// Returns a `Future` that resolves to reverse geocoding results.
  Future<GeocoderRequestResponse> reverse(LatLng location,
      {String language = 'en'}) {
    return _strategy.reverse(location, language);
  }
}
