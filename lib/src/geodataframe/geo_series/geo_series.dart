library;

import 'dart:math';
import 'package:dartframe/dartframe.dart';
import 'package:geojson_vi/geojson_vi.dart';

import '../../utils/utils.dart';

part 'functions.dart';
part 'geo_processes/buffer.dart';

/// A `GeoSeries` represents a Series of geometric objects.
///
/// It extends `Series<GeoJSONGeometry?>`, meaning it can hold various types of
/// GeoJSON geometries (like `GeoJSONPoint`, `GeoJSONLineString`, `GeoJSONPolygon`,
/// `GeoJSONMultiPoint`, etc., or `null` values) and associates them with an index.
///
/// `GeoSeries` provides specialized methods for geometric operations, many of which
/// are found in the `GeoSeriesFunctions` and `GeoSeriesProcesses` extensions.
///
/// Attributes:
///  - `crs` (Coordinate Reference System): An optional string representing the
///    coordinate system of the geometries in the series. This is for informational
///    purposes and is not used in calculations by default in this simplified library.
///  - `name`: The name of the Series, defaults to 'geometry'.
///  - `index`: The index for the Series. If not provided, a default integer index is created.
///  - `data`: The list of `GeoJSONGeometry?` objects.
///
/// Examples:
/// ```dart
/// import 'package:dartframe/dartframe.dart';
/// import 'package:geojson_vi/geojson_vi.dart';
///
/// // Creating a GeoSeries from a list of GeoJSON objects
/// final geometries = [
///   GeoJSONPoint([1.0, 1.0]),
///   GeoJSONLineString([[2.0, 2.0], [3.0, 3.0]]),
///   null, // Can include nulls
///   GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]]])
/// ];
/// final geoSeries = GeoSeries(
///   geometries,
///   name: 'my_geometries',
///   index: ['a', 'b', 'c', 'd'],
///   crs: 'EPSG:4326',
/// );
///
/// print(geoSeries);
/// // a    Point(1.0, 1.0)
/// // b    LineString((2.0, 2.0), (3.0, 3.0))
/// // c    null
/// // d    Polygon(((0.0, 0.0), (0.0, 1.0), (1.0, 1.0), (1.0, 0.0), (0.0, 0.0)))
/// // Name: my_geometries, Length: 4, dtype: GeoJSONGeometry, CRS: EPSG:4326
///
/// // Accessing CRS
/// print(geoSeries.crs); // Output: EPSG:4326
/// ```
class GeoSeries extends Series {
  /// The Coordinate Reference System of the geometries in the series.
  ///
  /// This is for informational purposes and is not used in calculations by default
  /// in this simplified library. It can be set during construction.
  final String? crs;

  /// Creates a `GeoSeries` from a list of `GeoJSONGeometry?` objects.
  ///
  /// Parameters:
  ///   - `values`: A list of `GeoJSONGeometry?` objects.
  ///   - `crs`: An optional string representing the Coordinate Reference System
  ///     (e.g., "EPSG:4326").
  ///   - `name`: An optional name for the `GeoSeries`, defaults to 'geometry'.
  ///   - `index`: An optional list of index labels. If not provided, a default
  ///     integer index will be created.
  ///
  /// Example:
  /// ```dart
  /// import 'package:dartframe/dartframe.dart';
  /// import 'package:geojson_vi/geojson_vi.dart';
  ///
  /// final points = [GeoJSONPoint([1,2]), GeoJSONPoint([3,4])];
  /// final series = GeoSeries(points, name: 'sample_points', crs: 'WGS84');
  /// print(series);
  /// // 0    Point(1.0, 2.0)
  /// // 1    Point(3.0, 4.0)
  /// // Name: sample_points, Length: 2, dtype: GeoJSONGeometry, CRS: WGS84
  /// ```
  GeoSeries(super.values, {this.crs, super.name = 'geometry', super.index});

  /// Creates a `GeoSeries` from a list of Well-Known Text (WKT) strings.
  ///
  /// Each WKT string in the input list is parsed into its corresponding
  /// `GeoJSONGeometry` object. If a WKT string is invalid or cannot be parsed,
  /// the corresponding entry in the `GeoSeries` will be `null`.
  ///
  /// Parameters:
  ///   - `wktStrings`: A list of strings, where each string is a geometry
  ///     represented in WKT format.
  ///   - `crs`: An optional string representing the Coordinate Reference System.
  ///   - `name`: An optional name for the `GeoSeries`, defaults to 'geometry'.
  ///   - `index`: An optional list of index labels.
  ///
  /// Example:
  /// ```dart
  /// import 'package:dartframe/dartframe.dart';
  ///
  /// final wktData = [
  ///   'POINT (30 10)',
  ///   'LINESTRING (30 10, 10 30, 40 40)',
  ///   'POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))',
  ///   'INVALID WKT', // This will result in a null geometry
  ///   null // Explicit null in input list also results in null
  /// ];
  /// final seriesFromWKT = GeoSeries.fromWKT(wktData, name: 'wkt_geoms', crs: 'EPSG:3857');
  ///
  /// print(seriesFromWKT.toWkt(fallback: 'INVALID'));
  /// // 0    POINT (30 10)
  /// // 1    LINESTRING (30 10, 10 30, 40 40)
  /// // 2    POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))
  /// // 3    INVALID
  /// // 4    INVALID
  /// // Name: wkt_geoms_wkt, Length: 5, dtype: String
  /// ```
  factory GeoSeries.fromWKT(List<String> wktStrings,
      {String? crs, String name = 'geometry', List<dynamic>? index}) {
    final geometries = wktStrings.map((wkt) => parseWKT(wkt)).toList();
    return GeoSeries(geometries, crs: crs, name: name, index: index);
  }

  /// Creates a `GeoSeries` from a `GeoJSONFeatureCollection`.
  ///
  /// Each feature in the `GeoJSONFeatureCollection` provides a geometry for the
  /// `GeoSeries`. The properties of the features are not directly stored in the
  /// `GeoSeries` but could be extracted separately into a `DataFrame`.
  /// If a feature in the collection has a `null` geometry, that entry in the
  /// `GeoSeries` will also be `null`.
  ///
  /// Parameters:
  ///   - `featureCollection`: The `GeoJSONFeatureCollection` to extract geometries from.
  ///   - `crs`: An optional string representing the Coordinate Reference System.
  ///     If the `featureCollection` has a `crs` property, that might be used or
  ///     overridden by this parameter depending on specific library logic (in this
  ///     simplified version, this parameter takes precedence).
  ///   - `name`: An optional name for the `GeoSeries`, defaults to 'geometry'.
  ///   - `index`: An optional list of index labels. If not provided, a default
  ///     integer index is used.
  ///
  /// Example:
  /// ```dart
  /// import 'package:dartframe/dartframe.dart';
  /// import 'package:geojson_vi/geojson_vi.dart';
  ///
  /// final featureColl = GeoJSONFeatureCollection([
  ///   GeoJSONFeature(GeoJSONPoint([1,2]), properties: {'id': 1}),
  ///   GeoJSONFeature(GeoJSONLineString([[0,0],[1,1]]), properties: {'id': 2}),
  ///   GeoJSONFeature(null, properties: {'id': 3}), // Feature with null geometry
  /// ]);
  ///
  /// final seriesFromFC = GeoSeries.fromFeatureCollection(featureColl, name: 'fc_geoms');
  /// print(seriesFromFC.toWkt(fallback: 'NULL_GEOM'));
  /// // 0    POINT (1 2)
  /// // 1    LINESTRING (0 0, 1 1)
  /// // 2    NULL_GEOM
  /// // Name: fc_geoms_wkt, Length: 3, dtype: String
  /// ```
  factory GeoSeries.fromFeatureCollection(
    GeoJSONFeatureCollection featureCollection, {
    String? crs,
    String name = 'geometry',
    List<dynamic>? index,
  }) {
    final geometries = featureCollection.features
        .map((feature) => feature?.geometry)
        //.where((geom) => geom != null) // This was filtering out nulls, which might be valid data points
        .toList();

    return GeoSeries(geometries.cast<GeoJSONGeometry?>(),
        crs: crs, name: name, index: index);
  }

  /// Creates a `GeoSeries` of `GeoJSONPoint`s from lists of x, y (and optionally z) coordinates.
  ///
  /// In case of geographic coordinates, it is assumed that longitude is captured
  /// by x coordinates and latitude by y.
  ///
  /// Parameters:
  ///   - `x`: A list of `num` representing the x-coordinates of the points.
  ///   - `y`: A list of `num` representing the y-coordinates of the points.
  ///     Must have the same length as `x`.
  ///   - `z`: An optional list of `num` representing the z-coordinates (elevation).
  ///     If provided, must have the same length as `x` and `y`. If omitted, 2D points are created.
  ///   - `crs`: An optional string representing the Coordinate Reference System.
  ///   - `name`: An optional name for the `GeoSeries`, defaults to 'geometry'.
  ///   - `index`: An optional list of index labels.
  ///
  /// Returns:
  ///   A GeoSeries of Point geometries
  ///
  /// Throws:
  ///   - `ArgumentError` if `x` and `y` lists have different lengths, or if `z` is
  ///     provided and has a different length.
  ///
  /// Example:
  /// ```dart
  /// import 'package:dartframe/dartframe.dart';
  ///
  /// final xCoords = [0, 1, 2.5];
  /// final yCoords = [0, 1.5, 3];
  /// final zCoords = [10, 11, 12];
  ///
  /// final series2D = GeoSeries.fromXY(xCoords, yCoords, name: 'points_2d');
  /// print(series2D.toWkt());
  /// // 0    POINT (0 0)
  /// // 1    POINT (1 1.5)
  /// // 2    POINT (2.5 3)
  /// // Name: points_2d_wkt, Length: 3, dtype: String
  ///
  /// final series3D = GeoSeries.fromXY(xCoords, yCoords, z: zCoords, name: 'points_3d', crs: 'EPSG:4979');
  /// print(series3D.toWkt());
  /// // 0    POINT Z (0 0 10)
  /// // 1    POINT Z (1 1.5 11)
  /// // 2    POINT Z (2.5 3 12)
  /// // Name: points_3d_wkt, Length: 3, dtype: String
  /// ```
  factory GeoSeries.fromXY(List<num> x, List<num> y,
      {List<num>? z,
      List<dynamic>? index,
      String? crs,
      String name = 'geometry'}) {
    // Validate input
    if (x.length != y.length) {
      throw ArgumentError('x and y must have the same length');
    }

    if (z != null && z.length != x.length) {
      throw ArgumentError('z must have the same length as x and y');
    }

    // Create point geometries
    final List<GeoJSONGeometry> points = [];

    for (int i = 0; i < x.length; i++) {
      if (z != null) {
        // Create 3D point
        points.add(
            GeoJSONPoint([x[i].toDouble(), y[i].toDouble(), z[i].toDouble()]));
      } else {
        // Create 2D point
        points.add(GeoJSONPoint([x[i].toDouble(), y[i].toDouble()]));
      }
    }

    // Create GeoSeries with optional index
    final geoSeries = GeoSeries(points, crs: crs, name: name);

    // Set index if provided
    if (index != null) {
      if (index.length != x.length) {
        throw ArgumentError(
            'index must have the same length as coordinate lists');
      }
      geoSeries.index = index;
    }

    return geoSeries;
  }

  /// Returns a `List` of the raw `GeoJSONGeometry?` objects contained in the `GeoSeries`.
  ///
  /// If `asGeoJSON` is `true`, it returns a list of the `GeoJSONGeometry` objects
  /// themselves (or `null` values).
  /// If `asGeoJSON` is `false` (default), it attempts to return a list of the
  /// underlying coordinate structures or simpler representations if applicable,
  /// though for `GeoSeries`, it typically returns the `GeoJSONGeometry` objects
  /// directly as there isn't a simpler common "value" type for all geometries.
  ///
  /// Parameters:
  ///   - `asGeoJSON`: If `true`, ensures `GeoJSONGeometry` objects are returned.
  ///     If `false` (default), the behavior might be similar for `GeoSeries` as it
  ///     directly holds `GeoJSONGeometry` instances.
  ///
  /// Returns:
  ///   A `List<GeoJSONGeometry?>`.
  ///
  /// Example:
  /// ```dart
  /// import 'package:dartframe/dartframe.dart';
  /// import 'package:geojson_vi/geojson_vi.dart';
  ///
  /// final p = GeoJSONPoint([1,1]);
  /// final l = GeoJSONLineString([[0,0],[1,1]]);
  /// final series = GeoSeries([p, l, null]);
  ///
  /// final geoms = series.geometries(asGeoJSON: true);
  /// print(geoms.length); // Output: 3
  /// print(geoms[0] is GeoJSONPoint); // Output: true
  /// print(geoms[2] == null); // Output: true
  ///
  /// final geomsDefault = series.geometries(); // Similar to asGeoJSON: true for GeoSeries
  /// print(geomsDefault[0] is GeoJSONPoint); // Output: true
  /// ```
  List<dynamic> geometries({bool asGeoJSON = false}) {
    List<dynamic> result = [];

    for (GeoJSONGeometry? feature in data) {
      if (feature != null) {
        if (asGeoJSON) {
          result.add(feature);
        } else {
          // Extract coordinates based on geometry type
          if (feature is GeoJSONPoint) {
            result.add(feature.coordinates);
          } else if (feature is GeoJSONLineString) {
            result.add(feature.coordinates);
          } else if (feature is GeoJSONPolygon) {
            result.add(feature.coordinates);
          } else if (feature is GeoJSONMultiPoint) {
            result.add(feature.coordinates);
          } else if (feature is GeoJSONMultiLineString) {
            result.add(feature.coordinates);
          } else if (feature is GeoJSONMultiPolygon) {
            result.add(feature.coordinates);
          } else if (feature is GeoJSONGeometryCollection) {
            // For GeometryCollection, maybe return a list of its geometries' coordinates or objects
            result.add(feature.geometries
                .map((g) => g.toMap())
                .toList()); // Example: list of maps
          } else {
            // Default empty coordinates for unsupported geometry types
            result.add([]);
          }
        }
      } else {
        result.add(null); // Preserve nulls
      }
    }

    return result;
  }

  /// Returns a `Series` of Well-Known Text (WKT) representations of the geometries.
  ///
  /// Each geometry in the `GeoSeries` is converted to its WKT string format.
  ///
  /// Parameters:
  ///   - `fallback`: A `String` to use for `null` geometries or in case of an
  ///     error during WKT conversion. Defaults to "EMPTY" which is a common
  ///     representation for empty geometries in WKT, though `null` here means
  ///     missing geometry.
  ///
  /// Returns:
  ///   A `Series<String>` with WKT representations.
  ///
  /// Example:
  /// ```dart
  /// import 'package:dartframe/dartframe.dart';
  /// import 'package:geojson_vi/geojson_vi.dart';
  ///
  /// final series = GeoSeries([
  ///   GeoJSONPoint([30, 10]),
  ///   GeoJSONLineString([[10,10],[20,20]]),
  ///   null
  /// ], name: 'my_geoms');
  ///
  /// print(series.toWkt());
  /// // 0    POINT (30 10)
  /// // 1    LINESTRING (10 10, 20 20)
  /// // 2    EMPTY
  /// // Name: my_geoms_wkt, Length: 3, dtype: String
  ///
  /// print(series.toWkt(fallback: 'NULL_GEOMETRY'));
  /// // 0    POINT (30 10)
  /// // 1    LINESTRING (10 10, 20 20)
  /// // 2    NULL_GEOMETRY
  /// // Name: my_geoms_wkt, Length: 3, dtype: String
  /// ```
  Series<String> toWkt({String fallback = 'EMPTY'}) {
    final List<String> wktList = data.map<String>((geom) {
      try {
        return geom?.toWkt() ?? fallback;
      } catch (e) {
        return fallback;
      }
    }).toList();
    return Series<String>(wktList, name: '${name}_wkt', index: index);
  }

  /// Alias for `toWkt()`.
  ///
  /// Returns a `Series` of Well-Known Text (WKT) representations of the geometries.
  /// See `toWkt()` for more details.
  Series<String> asWkt({String fallback = 'EMPTY'}) =>
      toWkt(fallback: fallback);

  /// Returns a `Series` of JSON representations of the geometries.
  ///
  /// Each geometry in the `GeoSeries` is converted to its JSON (Map) format
  /// using its `toMap()` method. `null` geometries will result in `null` entries
  /// in the output Series.
  ///
  /// Returns:
  ///   A `Series<Map<String, dynamic>?>` where each element is the JSON
  ///   representation of the corresponding geometry, or `null`.
  ///
  /// Example:
  /// ```dart
  /// import 'package:dartframe/dartframe.dart';
  /// import 'package:geojson_vi/geojson_vi.dart';
  ///
  /// final series = GeoSeries([
  ///   GeoJSONPoint([30, 10]),
  ///   GeoJSONLineString([[10,10],[20,20]]),
  ///   null
  /// ], name: 'my_geoms');
  ///
  /// final jsonSeries = series.toJson();
  /// print(jsonSeries.data[0]); // Output: {type: Point, coordinates: [30.0, 10.0]}
  /// print(jsonSeries.data[1]); // Output: {type: LineString, coordinates: [[10.0, 10.0], [20.0, 20.0]]}
  /// print(jsonSeries.data[2]); // Output: null
  /// // Name: my_geoms_json, Length: 3, dtype: Map<String, dynamic>?
  /// ```
  Series toJson() {
    final List jsonList = data.map((geom) {
      return geom?.toMap();
    }).toList();
    return Series(jsonList, name: '${name}_json', index: index);
  }

  /// Attempts to make invalid geometries valid.
  ///
  /// **Note: This is a highly simplified version of "make valid".**
  /// Currently, it performs the following:
  /// - If a geometry is already valid (according to the simplified `isValid` check),
  ///   it's cloned and returned.
  /// - If a `GeoJSONPolygon` is invalid (e.g., exterior ring not closed, too few points),
  ///   it is replaced by a default `GeoJSONPoint([0,0])`. This is a placeholder for
  ///   more sophisticated repair logic.
  /// - For other invalid geometry types or `null` values, they are typically returned
  ///   as is, or if they are empty and considered invalid, they might also be replaced
  ///   by the default `GeoJSONPoint([0,0])`.
  ///
  /// This method does **not** implement complex geometric repair algorithms like
  /// those found in GEOS (e.g., `ST_MakeValid`).
  ///
  /// Returns:
  ///   A new `GeoSeries` with geometries processed by the simplified `makeValid` logic.
  ///
  /// Example:
  /// ```dart
  /// import 'package:dartframe/dartframe.dart';
  /// import 'package:geojson_vi/geojson_vi.dart';
  ///
  /// final validPoly = GeoJSONPolygon([[[0,0],[1,0],[1,1],[0,1],[0,0]]]);
  /// final invalidPolyOpen = GeoJSONPolygon([[[0,0],[1,0],[1,1]]]); // Invalid
  /// final emptyLine = GeoJSONLineString([]); // Invalid (empty)
  ///
  /// final series = GeoSeries([validPoly, invalidPolyOpen, emptyLine, null], name: 'shapes');
  /// final madeValidSeries = series.makeValid();
  ///
  /// print(madeValidSeries.toWkt(fallback: 'NULL'));
  /// // 0    POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0)) // Was valid, cloned
  /// // 1    POINT (0 0)                         // Invalid polygon replaced
  /// // 2    POINT (0 0)                         // Empty (invalid) line replaced
  /// // 3    NULL                                // Null remains null
  /// // Name: shapes_made_valid_wkt, Length: 4, dtype: String
  /// ```
  GeoSeries makeValid() {
    List<GeoJSONGeometry?> newGeoms = [];
    for (var geom in data) {
      if (geom == null) {
        newGeoms.add(null);
        continue;
      }
      // Use the existing isValid getter logic
      final currentGeoSeries = GeoSeries([geom], crs: crs, index: [0]);
      if (currentGeoSeries.isValid.data[0]!) {
        // Create a copy by reconstructing the geometry with its coordinates
        if (geom is GeoJSONPoint) {
          newGeoms.add(GeoJSONPoint(List.from(geom.coordinates)));
        } else if (geom is GeoJSONLineString) {
          newGeoms.add(GeoJSONLineString(geom.coordinates
              .map((coord) => List<double>.from(coord))
              .toList()));
        } else if (geom is GeoJSONPolygon) {
          newGeoms.add(GeoJSONPolygon(geom.coordinates
              .map((ring) =>
                  ring.map((coord) => List<double>.from(coord)).toList())
              .toList()));
        } else if (geom is GeoJSONMultiPoint) {
          newGeoms.add(GeoJSONMultiPoint(geom.coordinates
              .map((coord) => List<double>.from(coord))
              .toList()));
        } else if (geom is GeoJSONMultiLineString) {
          newGeoms.add(GeoJSONMultiLineString(geom.coordinates
              .map((line) =>
                  line.map((coord) => List<double>.from(coord)).toList())
              .toList()));
        } else if (geom is GeoJSONMultiPolygon) {
          newGeoms.add(GeoJSONMultiPolygon(geom.coordinates
              .map((polygon) => polygon
                  .map((ring) =>
                      ring.map((coord) => List<double>.from(coord)).toList())
                  .toList())
              .toList()));
        } else if (geom is GeoJSONGeometryCollection) {
          // For geometry collections, recursively copy each geometry
          final copiedGeometries = geom.geometries.map((g) {
            if (g is GeoJSONPoint) {
              return GeoJSONPoint(List.from(g.coordinates));
            }
            if (g is GeoJSONLineString) {
              return GeoJSONLineString(g.coordinates
                  .map((coord) => List<double>.from(coord))
                  .toList());
            }
            if (g is GeoJSONPolygon) {
              return GeoJSONPolygon(g.coordinates
                  .map((ring) =>
                      ring.map((coord) => List<double>.from(coord)).toList())
                  .toList());
            }
            // Add other geometry types as needed
            return g; // fallback
          }).toList();
          newGeoms.add(GeoJSONGeometryCollection(copiedGeometries));
        } else {
          // Fallback for any other geometry types
          newGeoms.add(geom);
        }
      } else {
        // Simplified "repair": replace invalid polygons or empty/invalid geoms with a default point.
        // More sophisticated repair would be needed for real-world scenarios.
        if (geom is GeoJSONPolygon || _isGeometryEmpty(geom)) {
          newGeoms.add(GeoJSONPoint([0, 0]));
        } else {
          // For other types, create a copy as above
          if (geom is GeoJSONPoint) {
            newGeoms.add(GeoJSONPoint(List.from(geom.coordinates)));
          } else if (geom is GeoJSONLineString) {
            newGeoms.add(GeoJSONLineString(geom.coordinates
                .map((coord) => List<double>.from(coord))
                .toList()));
          } else {
            newGeoms.add(geom); // fallback
          }
        }
      }
    }
    return GeoSeries(newGeoms,
        name: '${name}_made_valid', crs: crs, index: index);
  }

  /// Retrieves the geometry at a specific index label.
  ///
  /// Parameters:
  ///   - `indexLabel`: The label or index for which to retrieve the geometry.
  ///
  /// Returns:
  ///   The `GeoJSONGeometry?` at the specified index. Returns `null` if the
  ///   index label does not exist or if the value at that index is `null`.
  ///
  /// Throws:
  ///   - `StateError` if the index label is not found in the `GeoSeries`.
  ///
  /// Example:
  /// ```dart
  /// import 'package:dartframe/dartframe.dart';
  ///
  /// final series = GeoSeries(
  ///   [GeoJSONPoint([1,1]), GeoJSONLineString([[0,0],[1,0]])],
  ///   index: ['a', 'b']
  /// );
  ///
  /// final geomA = series.getGeometry('a');
  /// print(geomA?.toWkt()); // Output: POINT (1 1)
  ///
  /// final geomA = series.getGeometry(0);
  /// print(geomA?.toWkt()); // Output: POINT (1 1)
  ///
  /// try {
  ///   series.getGeometry('c');
  /// } catch (e) {
  ///   print(e); // Output: StateError: No element
  /// }
  /// ```
  GeoJSONGeometry? getGeometry(dynamic indexLabel) {
    if (indexLabel is int) {
      if (indexLabel < 0 || indexLabel >= data.length) {
        throw RangeError.index(indexLabel, data, 'index', 'Index out of range');
      }
      return data[indexLabel];
    }
    int loc = index.indexOf(indexLabel);
    if (loc == -1) {
      throw StateError('Index label "$indexLabel" not found in GeoSeries.');
    }
    return data[loc];
  }
}
