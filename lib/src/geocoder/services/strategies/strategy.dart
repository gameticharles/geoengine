import '../../../../geoengine.dart';

export 'google.dart';
export 'open_street_map.dart';
export 'local_data.dart';

/// An abstract class defining the strategy for geocoding services.
///
/// This class provides an interface for implementing different geocoding
/// strategies. Each geocoding service (like Google Maps, OpenStreetMap, etc.)
/// should implement this class to provide specific functionality for
/// geocoding and reverse geocoding operations.
abstract class GeocoderStrategy {
  /// Searches for geographic coordinates based on a given address.
  ///
  /// This method should be implemented to query a geocoding service and
  /// retrieve the geographic coordinates (latitude and longitude) for the
  /// specified address.
  ///
  /// [address]: A string representing the address to be geocoded.
  /// [language]: (Optional) The language code to specify the language in which
  ///             to return results. Defaults to English ('en').
  ///
  /// Use the Use the ISO 639-1 or ISO 639-2 standard for the language code
  /// and the 2 letter ISO 3166-1 standard for the country code. Some examples are:
  /// - en_US: English speakers in the United States of America
  /// - en_UK: English speakers in the United Kingdom
  /// - nl_NL: Dutch speakers in The Netherlands
  ///
  /// Returns a `Future` that resolves to the geocoding result. The actual
  /// structure of this result depends on the specific implementation of the
  /// geocoding service.
  Future<GeocoderRequestResponse> search(String address, String language);

  /// Performs reverse geocoding to find an address based on geographic coordinates.
  ///
  /// This method should be implemented to query a geocoding service and
  /// retrieve the address corresponding to the specified geographic coordinates.
  ///
  /// [location]: A `LatLng` instance representing the geographic coordinates
  ///             (latitude and longitude) for which the address is required.
  /// [language]: (Optional) The language code to specify the language in which
  ///             to return results. Defaults to English ('en').
  ///
  /// Returns a `Future` that resolves to the reverse geocoding result. The
  /// actual structure of this result depends on the specific implementation of
  /// the geocoding service.
  Future<GeocoderRequestResponse> reverse(LatLng location, String language);
}
