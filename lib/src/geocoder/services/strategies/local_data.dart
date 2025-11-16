// ignore_for_file: unused_element, unused_element_parameter

import 'package:advance_math/advance_math.dart';
import 'package:geoengine/geoengine.dart';
import 'package:kdtree/kdtree.dart';

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
class LocalStrategy implements GeocoderStrategy {
  final List<Map<String, dynamic>> entries;
  final Map<String, dynamic> _cache = {};
  late KDTree _tree;
  int limit;
  ({String x, String y}) coordinatesColumnNames;
  bool isGeodetic;
  int? searchRadius;
  int cacheSize;
  String indexingStrategy;

  /// Private constructor to enforce the use of the factory method.
  LocalStrategy._({
    required this.entries,
    required this.coordinatesColumnNames,
    this.limit = 5,
    this.isGeodetic = true,
    this.searchRadius = 1000, // in meters
    this.cacheSize = 100,
    this.indexingStrategy = 'KDTree',
  }) {
    // Filter out entries that do not have valid latitude and longitude
    var validEntries = entries
        .where((e) =>
            e[coordinatesColumnNames.y]! != null &&
            e[coordinatesColumnNames.x]! != null)
        .toList();

    // // Create points for the k-d tree from the valid entries
    // var points = validEntries
    //     .map((e) => {
    //           coordinatesColumnNames.y: e[coordinatesColumnNames.y]!,
    //           coordinatesColumnNames.x: e[coordinatesColumnNames.x]!
    //         })
    //     .toList();

    if (indexingStrategy == 'RTree') {
      // Initialize RTree
      // _tree = RTree(...);
    } else {
      // Default to KDTree
      _tree = KDTree(
        validEntries,
        isGeodetic ? geodeticDistance : euclideanDistanceMap,
        [coordinatesColumnNames.y, coordinatesColumnNames.x],
      );
    }
  }

  /// Private configuration method.
  void _configure(Map<String, dynamic> config) {
    limit = config['limit'] ?? limit;
    isGeodetic = config['isGeodetic'] ?? isGeodetic;
    searchRadius = config['searchRadius'] ?? searchRadius;
    cacheSize = config['cacheSize'] ?? cacheSize;
    indexingStrategy = config['indexingStrategy'] ?? indexingStrategy;
  }

  /// Public factory method for LocalGeocoderStrategy.
  ///
  /// [entries]: The list of data entries for geocoding, each entry being a map of key-value pairs.
  /// [coordinatesColumnNames]: A tuple specifying the column names for x (longitude/easting) and y (latitude/northing).
  static Map<String, dynamic> create(
      {required List<Map<String, dynamic>> entries,
      required ({String x, String y}) coordinatesColumnNames}) {
    var strategy = LocalStrategy._(
        entries: entries, coordinatesColumnNames: coordinatesColumnNames);
    return {
      'strategy': strategy,
      'configure': (Map<String, dynamic> config) => strategy._configure(config)
    };
  }

  dynamic distance(dynamic a, dynamic b) {
    return pow(a[coordinatesColumnNames.x] - b[coordinatesColumnNames.x], 2) +
        pow(a[coordinatesColumnNames.y] - b[coordinatesColumnNames.y], 2);
  }

  dynamic euclideanDistanceMap(
      Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    return sqrt(pow(a[coordinatesColumnNames.x]! - b[coordinatesColumnNames.x]!,
                2) +
            pow(a[coordinatesColumnNames.y]! - b[coordinatesColumnNames.y]!, 2))
        .toDouble();
  }

  double geodeticDistance(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    return LatLng(a[coordinatesColumnNames.y]!, a[coordinatesColumnNames.x]!)
        .distanceTo(
            LatLng(b[coordinatesColumnNames.y]!, b[coordinatesColumnNames.x]!))!
        .mks
        .toDouble();
  }

  @override
  Future<GeocoderRequestResponse> search(String query, String language) async {
    var cacheKey = 'search-$query-$language';
    if (_cache.containsKey(cacheKey) &&
        _cache[cacheKey] is GeocoderRequestResponse) {
      return _cache[cacheKey];
    }

    var startTime = DateTime.now();
    var matchedEntries = entries.where((entry) {
      // Perform a case-insensitive search on all values
      return entry.values.any((value) {
        // Ensure value is not null and contains the query
        return value != null &&
            value.toString().toLowerCase().contains(query.toLowerCase());
      });
    }).toList();

    // Convert matched entries to the desired format
    var response = GeocoderRequestResponse(
      success: matchedEntries.isNotEmpty,
      duration: DateTime.now().difference(startTime),
      result: matchedEntries.map((e) => e).toList(),
    );

    if (_cache.length >= cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = response;

    return response;
  }

  @override
  Future<GeocoderRequestResponse> reverse(
      LatLng location, String language) async {
    var cacheKey =
        'reverse-${location.latitude.degrees}-${location.longitude.degrees}-$language';
    if (_cache.containsKey(cacheKey) &&
        _cache[cacheKey] is GeocoderRequestResponse) {
      return _cache[cacheKey];
    }

    var startTime = DateTime.now();
    var nearest = _tree.nearest(
      {
        coordinatesColumnNames.y: location.latitude.degrees,
        coordinatesColumnNames.x: location.longitude.degrees
      },
      limit,
      searchRadius,
    );

    // List<Map<String, dynamic>> nearestEntries = nearest.map((nearestPoint) {
    //   var pointCoordinates = {
    //     coordinatesColumnNames.y: nearestPoint[0][coordinatesColumnNames.y],
    //     coordinatesColumnNames.x: nearestPoint[0][coordinatesColumnNames.x]
    //   };
    //   return entries.firstWhere(
    //       (entry) =>
    //           entry[coordinatesColumnNames.y] ==
    //               pointCoordinates[coordinatesColumnNames.y] &&
    //           entry[coordinatesColumnNames.x] ==
    //               pointCoordinates[coordinatesColumnNames.x],
    //       orElse: () => pointCoordinates);
    // }).toList();

    GeocoderRequestResponse response;
    if (nearest.isNotEmpty) {
      response = GeocoderRequestResponse(
        success: true,
        duration: DateTime.now().difference(startTime),
        result: nearest,
      );
    } else {
      response = GeocoderRequestResponse(
        success: false,
        duration: DateTime.now().difference(startTime),
        error: 'No results found',
      );
    }
    if (_cache.length >= cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = response;

    return response;
  }
}
