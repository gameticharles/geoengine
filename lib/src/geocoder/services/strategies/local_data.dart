import 'package:advance_math/advance_math.dart';
import 'package:geoengine/geoengine.dart';
import 'package:kdtree/kdtree.dart';

import 'request.dart';
import 'strategy.dart';

/// A concrete implementation of the GeocoderStrategy for local geocoding.
///
/// This strategy allows for geocoding and reverse geocoding using a local
/// set of data. It supports both geodetic (latitude/longitude) and projected
/// (e.g., UTM) coordinate systems and can work with various data formats.
///
/// The strategy utilizes a KDTree for efficient nearest-neighbor searches,
/// making it suitable for reverse geocoding operations. For standard geocoding
/// (search by address or other fields), it performs a linear search across all
/// entries.
///
/// Example usage:
/// ```dart
/// var localGeocoding = Geocoder(
///   strategy: LocalGeocodingStrategy(
///     entries: data, // Your local data
///     coordinatesColumnNames: (y: 'latitude', x: 'longitude'), // Specify coordinate columns
///     maxTopResults: 2,
///     isGeodetic: true // Set to false if using projected coordinates
///   )
/// );
/// var result = await localGeocoding.search('Search Query');
/// ```
class LocalGeocodingStrategy implements GeocoderStrategy {
  final List<Map<String, dynamic>> entries;
  late KDTree _tree;
  final int maxTopResults;
  final int? maxDistance;
  ({String x, String y}) coordinatesColumnNames;
  final bool isGeodetic;

  /// Constructs an instance of LocalGeocodingStrategy.
  ///
  /// [entries]: The list of data entries for geocoding, each entry being a map of key-value pairs.
  /// [coordinatesColumnNames]: A tuple specifying the column names for x (longitude/easting) and y (latitude/northing).
  /// [maxTopResults]: (Optional) The maximum number of results to return for reverse geocoding. Defaults to 1.
  /// [maxDistance]: (Optional) The maximum search distance for reverse geocoding.
  /// [isGeodetic]: Indicates whether the coordinates are geodetic (true) or projected (false).
  LocalGeocodingStrategy({
    required this.entries,
    required this.coordinatesColumnNames,
    this.maxTopResults = 1,
    this.maxDistance,
    this.isGeodetic = true,
  }) {
    // Filter out entries that do not have valid latitude and longitude
    var validEntries = entries
        .where((e) =>
            e[coordinatesColumnNames.y]! != null &&
            e[coordinatesColumnNames.x]! != null)
        .toList();

    // Create points for the k-d tree from the valid entries
    var points = validEntries
        .map((e) => {
              coordinatesColumnNames.y: e[coordinatesColumnNames.y]!,
              coordinatesColumnNames.x: e[coordinatesColumnNames.x]!
            })
        .toList();
    _tree = KDTree(points, isGeodetic ? geodeticDistance : euclideanDistanceMap,
        [coordinatesColumnNames.y, coordinatesColumnNames.x]);
  }

  distance(a, b) {
    return pow(a[coordinatesColumnNames.x] - b[coordinatesColumnNames.x], 2) +
        pow(a[coordinatesColumnNames.y] - b[coordinatesColumnNames.y], 2);
  }

  euclideanDistanceMap(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    return sqrt(pow(
            a[coordinatesColumnNames.x]! - b[coordinatesColumnNames.x]!, 2) +
        pow(a[coordinatesColumnNames.y]! - b[coordinatesColumnNames.y]!, 2));
  }

  geodeticDistance(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    return LatLng(a[coordinatesColumnNames.y]!, a[coordinatesColumnNames.x]!)
        .distanceTo(
            LatLng(b[coordinatesColumnNames.y]!, b[coordinatesColumnNames.x]!));
  }

  @override
  Future<GeocoderRequestResponse> search(String query, String language) async {
    var matchedEntries = entries.where((entry) {
      // Perform a case-insensitive search on all values
      return entry.values.any((value) {
        // Ensure value is not null and contains the query
        return value != null &&
            value.toString().toLowerCase().contains(query.toLowerCase());
      });
    }).toList();

    // Convert matched entries to the desired format
    return GeocoderRequestResponse(
      success: matchedEntries.isNotEmpty,
      result: matchedEntries.map((e) => e).toList(),
    );
  }

  @override
  Future<GeocoderRequestResponse> reverse(
      LatLng location, String language) async {
    var nearest = _tree.nearest(
      {
        coordinatesColumnNames.y: location.latitude,
        coordinatesColumnNames.x: location.longitude
      },
      maxTopResults,
      maxDistance,
    );
    if (nearest.isNotEmpty) {
      return GeocoderRequestResponse(
        success: true,
        result: nearest,
      );
    } else {
      return GeocoderRequestResponse(
        success: false,
        error: 'No results found',
      );
    }
  }
}
