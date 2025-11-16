library;

import 'dart:math';
import 'package:dartframe/dartframe.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:geoxml/geoxml.dart';

import '../../utils/utils.dart';
import '../geo_series/geo_series.dart';

part 'functions.dart';
part 'extension.dart';

/// The `GeoDataFrame` class for handling geospatial data in various formats.
///
/// This class extends the functionality of DataFrame by adding support for
/// geometric data. It maintains a geometry column alongside attribute data,
/// similar to GeoPandas in Python.
///
/// Example:
/// ```dart
///   // Future<void> main(List<String> args) async {
///   // Read file
///   final geoDataFrame = await GeoDataFrame.readFile(
///     'example/GH.txt',
///     delimiter: '\t',
///     hasHeader: false,
///     coordinatesColumns: {
///       'latitude': 4,
///       'longitude': 5
///     }, // Specify column names and indices
///   );
///
///   // Get row count
///   print(geoDataFrame.featureCount);
///
///   // Delete a feature
///   geoDataFrame.deleteFeature(0);
///
///   // Access the attribute table as DataFrame
///   print(geoDataFrame.attributes);
///
///   // Use DataFrame operations on attributes
///   print(geoDataFrame.attributes.describe());
///
///   // Add a new column to all features
///   geoDataFrame.attributes['newProperty'] = List.filled(geoDataFrame.featureCount, 'defaultValue');
///
///   // Delete a column from all features
///   geoDataFrame.attributes.drop('newProperty');
///
///   // Update a specific value
///   geoDataFrame.attributes['altitude'][1] = 230.45;
///
///   // Get a specific feature
///   var feature = geoDataFrame.getFeature(1);
///   print(feature);
///
///   // Find features based on a query
///   var foundFeatures = geoDataFrame
///       .findFeatures((feature) =>
///           feature.properties!['latitude'] > 6.5 &&
///           feature.properties!['longitude'] < 0.5);
///   print(foundFeatures.length);
///
///   // Export data to GeoJSON
///   await geoDataFrame.toFile('example/output.geojson');
/// }
///```
class GeoDataFrame extends DataFrame {
  /// The name of the geometry column.
  String geometryColumn;

  /// The coordinate reference system (CRS) of the geometry data.
  final String? crs;

  /// Gets the geometry column as a GeoSeries.
  GeoSeries get geometry =>
      GeoSeries(this[geometryColumn].data, crs: crs, name: geometryColumn);

  /// Sets the geometry column. Accepts a GeoSeries or any Iterable of geometry values.
  /// Replaces/creates the geometry column and updates rows accordingly.
  set geometry(dynamic value) {
    List<dynamic> geomList;
    if (value is GeoSeries) {
      geomList = value.data;
    } else if (value is Iterable) {
      geomList = value.toList();
    } else {
      throw ArgumentError('geometry must be a GeoSeries or Iterable');
    }

    // Ensure geometry column exists
    final bool addedGeometryColumn = !columns.contains(geometryColumn);
    if (addedGeometryColumn) {
      // Use addColumn method to properly add the geometry column
      addColumn(geometryColumn, defaultValue: null);
    }
    final geomIndex = columns.indexOf(geometryColumn);

    // addColumn already handles adding null values to existing rows

    // Ensure rows list can hold all geometries
    final requiredRows = geomList.length;
    final originalRowCount = rows.length;
    while (rows.length < requiredRows) {
      rows.add(List<dynamic>.filled(columns.length, null));
    }

    // Update index if we added new rows
    if (rows.length > originalRowCount) {
      // Extend the index with new numeric indices
      final newIndices = List.generate(
          rows.length - originalRowCount, (i) => originalRowCount + i);
      index.addAll(newIndices);
    }

    // Ensure each row has enough columns (in case there are other column mismatches)
    for (var i = 0; i < rows.length; i++) {
      while (rows[i].length < columns.length) {
        rows[i].add(null);
      }
    }

    // Assign geometries, set null for remaining rows if fewer geometries provided
    for (var i = 0; i < rows.length; i++) {
      rows[i][geomIndex] = i < geomList.length ? geomList[i] : null;
    }

    // Only process geometries if they need conversion (not already GeoJSON geometries)
    bool needsProcessing =
        geomList.any((geom) => geom != null && geom is! GeoJSONGeometry);

    if (needsProcessing) {
      _processGeometryColumn();
    }
  }

  /// Gets the attributes as a DataFrame (without the geometry column).
  DataFrame get attributes {
    final attributeColumns =
        columns.where((col) => col.toString() != geometryColumn).toList();
    final attributeData = rows.map((row) {
      final rowData = <dynamic>[];
      for (int i = 0; i < columns.length; i++) {
        if (columns[i].toString() != geometryColumn) {
          rowData.add(i < row.length ? row[i] : null);
        }
      }
      return rowData;
    }).toList();

    return DataFrame(columns: attributeColumns, attributeData);
  }

  /// Gets the number of features in the data.
  int get featureCount => rows.length;

  /// The headers for the data columns (property names).
  List get headers => columns.map((col) => col.toString().trim()).toList();

  /// Gets the number of properties in the data.
  int get propertyCount => headers.length;

  /// Copy of the GeoDataFrame
  /// Returns a new GeoDataFrame that is a copy of the current one.
  /// This is useful for creating a duplicate of the data without affecting the original.
  ///
  /// Example:
  /// ```dart
  /// var originalGDF = GeoDataFrame(...);
  /// var copiedGDF = originalGDF.copy();
  /// ```
  GeoDataFrame copy() {
    // Use DataFrame's copy method to ensure all DataFrame properties are properly copied
    final dataFrameCopy = (this as DataFrame).copy();

    // Create and return a new GeoDataFrame with the copied DataFrame
    return GeoDataFrame(
      dataFrameCopy,
      geometryColumn: geometryColumn,
      crs: crs,
    );
  }

  /// Gets the total bounds of all geometries in the GeoDataFrame.
  /// Returns `[minX, minY, maxX, maxY]` for the entire collection.
  List<double> get totalBounds => geometry.totalBounds;

  /// Returns a GeoDataFrame containing the centroids of all geometries.
  GeoSeries get centroid => geometry.centroid;

  // Constructor that takes a DataFrame (primary constructor)
  /// Creates a GeoDataFrame from a DataFrame with a column containing geometry data.
  ///
  /// [dataFrame]: The DataFrame containing attribute data.
  /// [geometryColumn]: The name of the column containing geometry data (WKT strings or coordinates).
  /// [crs]: The coordinate reference system of the geometries.
  ///
  /// Example:
  /// ```dart
  /// var df = DataFrame(
  ///   columns: ['id', 'name', 'geometry'],
  ///   data: [
  ///     [1, 'Point A', 'POINT(0 0)'],
  ///     [2, 'Line B', 'LINESTRING(0 0, 1 1, 2 2)'],
  ///     [3, 'Polygon C', 'POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))']
  ///   ]
  /// );
  /// var gdf = GeoDataFrame(df, geometryColumn: 'geometry', crs: 'EPSG:4326');
  /// ```
  GeoDataFrame(
    DataFrame dataFrame, {
    this.geometryColumn = 'geometry',
    this.crs,
  }) : super(
            columns: dataFrame.columns,
            dataFrame.rows as List<List<dynamic>>,
            index: dataFrame.index) {
    // Process geometry column only if it exists
    if (columns.contains(geometryColumn)) {
      _processGeometryColumn();
    }
  }

  /// Process the geometry column to ensure it contains valid GeoJSON geometries
  void _processGeometryColumn() {
    if (!columns.contains(geometryColumn)) {
      throw ArgumentError(
          'Geometry column $geometryColumn not found in DataFrame');
    }

    // Convert geometry column values to GeoJSON geometries if needed
    List<dynamic> geometryValues = this[geometryColumn].data;
    List<GeoJSONGeometry> processedGeometries = [];

    for (var value in geometryValues) {
      GeoJSONGeometry? geometry;

      if (value is GeoJSONGeometry) {
        // Already a GeoJSON geometry
        geometry = value;
      } else if (value is String) {
        // Try to parse as WKT
        geometry = parseWKT(value);
      } else if (value is List) {
        // Try to parse as coordinate list
        if (value.length >= 2) {
          List<double> coords = [];
          for (var coord in value) {
            coords.add(coord is num ? coord.toDouble() : 0.0);
          }
          geometry = GeoJSONPoint(coords);
        }
      }

      // Use default point geometry if extraction failed
      geometry ??= GeoJSONPoint([0, 0]);
      processedGeometries.add(geometry);
    }

    // Update the geometry column with processed geometries
    this[geometryColumn] = processedGeometries;
  }

  /// Creates a GeoDataFrame from a GeoJSON FeatureCollection.
  ///
  /// [featureCollection]: The GeoJSON FeatureCollection containing the features.
  /// [geometryColumn]: The name of the geometry column.
  /// [crs]: The coordinate reference system of the geometries.
  factory GeoDataFrame.fromFeatureCollection(
    GeoJSONFeatureCollection featureCollection, {
    String geometryColumn = 'geometry',
    String? crs,
  }) {
    // Extract properties and geometries
    List<Map<String, dynamic>> rows = [];
    Set<String> columnNames = {};

    for (var feature in featureCollection.features) {
      if (feature != null) {
        // Create a row for each feature
        Map<String, dynamic> row = {};

        // Add properties
        if (feature.properties != null) {
          row.addAll(feature.properties!);
          columnNames.addAll(feature.properties!.keys);
        }

        // Add geometry
        row[geometryColumn] = feature.geometry;

        rows.add(row);
      }
    }

    // Create column list with geometry column at the end
    List<String> columns = columnNames.toList();
    if (!columns.contains(geometryColumn)) {
      columns.add(geometryColumn);
    }

    // Create data rows
    List<List<dynamic>> data = [];
    for (var row in rows) {
      List<dynamic> rowData = [];
      for (var column in columns) {
        rowData.add(row[column]);
      }
      data.add(rowData);
    }

    // Create DataFrame
    final df = DataFrame(columns: columns, data);

    // Create GeoDataFrame
    return GeoDataFrame(df, geometryColumn: geometryColumn, crs: crs);
  }

  /// Creates a GeoDataFrame from a DataFrame and a geometry column.
  ///
  /// [dataFrame]: The DataFrame containing attribute data.
  /// [geometryColumn]: The name of the column containing geometry data. If not provided,
  ///   the method will look for standard coordinate columns based on coordinateType.
  /// [geometryType]: The type of geometry ('point', 'linestring', 'polygon').
  /// [coordinateType]: The type of coordinates ('xy', 'lonlat').
  ///
  /// Returns a new GeoDataFrame.
  static GeoDataFrame fromDataFrame(
    DataFrame dataFrame, {
    String? geometryColumn,
    String geometryType = 'point',
    String coordinateType = 'lonlat',
    String? crs,
  }) {
    // Create a feature collection
    final featureCollection = GeoJSONFeatureCollection([]);

    // Check if we have a specific geometry column or need to use coordinate columns
    int? geometryColumnIndex;
    Map<String, int> coordinateIndices = {};

    if (geometryColumn != null) {
      // Use the specified geometry column
      geometryColumnIndex = dataFrame.columns.indexOf(geometryColumn);
      if (geometryColumnIndex == -1) {
        throw ArgumentError(
            'Geometry column $geometryColumn not found in DataFrame');
      }
    } else {
      // Look for coordinate columns based on coordinateType
      if (coordinateType == 'lonlat') {
        // Find longitude and latitude columns
        for (int i = 0; i < dataFrame.columns.length; i++) {
          String colName = dataFrame.columns[i].toString().toLowerCase();
          if (colName == 'longitude' || colName == 'lon') {
            coordinateIndices['longitude'] = i;
          } else if (colName == 'latitude' || colName == 'lat') {
            coordinateIndices['latitude'] = i;
          } else if (colName == 'altitude' ||
              colName == 'alt' ||
              colName == 'elevation') {
            coordinateIndices['altitude'] = i;
          }
        }

        if (!coordinateIndices.containsKey('longitude') ||
            !coordinateIndices.containsKey('latitude')) {
          throw ArgumentError(
              'Could not find longitude and latitude columns in DataFrame');
        }
      } else if (coordinateType == 'xy') {
        // Find x and y columns
        for (int i = 0; i < dataFrame.columns.length; i++) {
          String colName = dataFrame.columns[i].toString().toLowerCase();
          if (colName == 'x') {
            coordinateIndices['x'] = i;
          } else if (colName == 'y') {
            coordinateIndices['y'] = i;
          } else if (colName == 'z') {
            coordinateIndices['z'] = i;
          }
        }

        if (!coordinateIndices.containsKey('x') ||
            !coordinateIndices.containsKey('y')) {
          throw ArgumentError('Could not find x and y columns in DataFrame');
        }
      }
    }

    // Create a feature for each row in the DataFrame
    for (int i = 0; i < dataFrame.rows.length; i++) {
      final row = dataFrame.rows[i];
      GeoJSONGeometry? geometry;

      if (geometryColumnIndex != null) {
        // Extract geometry from the specified column
        final geometryData = row[geometryColumnIndex];

        // Process geometry based on type
        // ... existing geometry extraction code ...
        if (geometryType == 'point') {
          if (geometryData is List && geometryData.length >= 2) {
            // Direct coordinate list
            List<double> coords = [];
            for (var coord in geometryData) {
              coords.add(coord is num ? coord.toDouble() : 0.0);
            }
            geometry = GeoJSONPoint(coords);
          } else if (geometryData is Map) {
            // Map with x/y or lon/lat keys
            double? x, y;

            if (coordinateType == 'lonlat') {
              x = geometryData['longitude'] is num
                  ? geometryData['longitude'].toDouble()
                  : (geometryData['lon'] is num
                      ? geometryData['lon'].toDouble()
                      : null);

              y = geometryData['latitude'] is num
                  ? geometryData['latitude'].toDouble()
                  : (geometryData['lat'] is num
                      ? geometryData['lat'].toDouble()
                      : null);
            } else {
              // xy
              x = geometryData['x'] is num
                  ? geometryData['x'].toDouble()
                  : null;
              y = geometryData['y'] is num
                  ? geometryData['y'].toDouble()
                  : null;
            }

            if (x != null && y != null) {
              geometry = GeoJSONPoint([x, y]);
            }
          } else if (geometryData is String) {
            // Try to parse WKT or GeoJSON string
            try {
              // Simple WKT point parsing (POINT(x y))
              final match = RegExp(r'POINT\s*\(\s*([0-9.-]+)\s+([0-9.-]+)\s*\)')
                  .firstMatch(geometryData);
              if (match != null) {
                double x = double.parse(match.group(1)!);
                double y = double.parse(match.group(2)!);
                geometry = GeoJSONPoint([x, y]);
              } else {
                // Try as GeoJSON
                final geoJson = GeoJSON.fromJSON(geometryData);
                if (geoJson is GeoJSONGeometry) {
                  geometry = geoJson;
                }
              }
            } catch (e) {
              // Parsing failed, will use default geometry
            }
          }
        } else if (geometryType == 'linestring') {
          // Handle linestring geometry
          if (geometryData is List &&
              geometryData.isNotEmpty &&
              geometryData[0] is List) {
            List<List<double>> coords = [];
            for (var point in geometryData) {
              if (point is List && point.length >= 2) {
                coords.add([
                  point[0] is num ? point[0].toDouble() : 0.0,
                  point[1] is num ? point[1].toDouble() : 0.0
                ]);
              }
            }
            if (coords.isNotEmpty) {
              geometry = GeoJSONLineString(coords);
            }
          }
        } else if (geometryType == 'polygon') {
          // Handle polygon geometry
          if (geometryData is List &&
              geometryData.isNotEmpty &&
              geometryData[0] is List) {
            List<List<List<double>>> coords = [];
            List<List<double>> ring = [];

            for (var point in geometryData) {
              if (point is List && point.length >= 2) {
                ring.add([
                  point[0] is num ? point[0].toDouble() : 0.0,
                  point[1] is num ? point[1].toDouble() : 0.0
                ]);
              }
            }

            if (ring.isNotEmpty) {
              // Ensure the ring is closed
              if (ring.first[0] != ring.last[0] ||
                  ring.first[1] != ring.last[1]) {
                ring.add([ring.first[0], ring.first[1]]);
              }
              coords.add(ring);
              geometry = GeoJSONPolygon(coords);
            }
          }
        }
      } else {
        // Create geometry from coordinate columns
        if (geometryType == 'point') {
          List<double> coords = [];

          if (coordinateType == 'lonlat') {
            // Get longitude and latitude
            var lonIndex = coordinateIndices['longitude']!;
            var latIndex = coordinateIndices['latitude']!;

            var lon = row[lonIndex];
            var lat = row[latIndex];

            double lonValue = lon is num
                ? lon.toDouble()
                : (lon is String ? double.tryParse(lon) ?? 0.0 : 0.0);
            double latValue = lat is num
                ? lat.toDouble()
                : (lat is String ? double.tryParse(lat) ?? 0.0 : 0.0);

            coords.add(lonValue);
            coords.add(latValue);

            // Add altitude if available
            if (coordinateIndices.containsKey('altitude')) {
              var altIndex = coordinateIndices['altitude']!;
              var alt = row[altIndex];
              double altValue = alt is num
                  ? alt.toDouble()
                  : (alt is String ? double.tryParse(alt) ?? 0.0 : 0.0);
              coords.add(altValue);
            }
          } else if (coordinateType == 'xy') {
            // Get x and y
            var xIndex = coordinateIndices['x']!;
            var yIndex = coordinateIndices['y']!;

            var x = row[xIndex];
            var y = row[yIndex];

            double xValue = x is num
                ? x.toDouble()
                : (x is String ? double.tryParse(x) ?? 0.0 : 0.0);
            double yValue = y is num
                ? y.toDouble()
                : (y is String ? double.tryParse(y) ?? 0.0 : 0.0);

            coords.add(xValue);
            coords.add(yValue);

            // Add z if available
            if (coordinateIndices.containsKey('z')) {
              var zIndex = coordinateIndices['z']!;
              var z = row[zIndex];
              double zValue = z is num
                  ? z.toDouble()
                  : (z is String ? double.tryParse(z) ?? 0.0 : 0.0);
              coords.add(zValue);
            }
          }

          if (coords.length >= 2) {
            geometry = GeoJSONPoint(coords);
          }
        }
      }

      // Use default point geometry if extraction failed
      geometry ??= GeoJSONPoint([0, 0]);

      // Create properties from other columns
      final properties = <String, dynamic>{};
      for (int j = 0; j < dataFrame.columns.length; j++) {
        // Skip the geometry column if specified
        if (geometryColumnIndex != null && j == geometryColumnIndex) {
          continue;
        }

        // Skip coordinate columns if using separate coordinates
        if (geometryColumnIndex == null &&
            (coordinateIndices.containsValue(j) && geometryType == 'point')) {
          continue;
        }

        properties[dataFrame.columns[j].toString()] = row[j];
      }

      // Create feature
      final feature = GeoJSONFeature(geometry, properties: properties);
      featureCollection.features.add(feature);
    }

    return GeoDataFrame.fromFeatureCollection(featureCollection, crs: crs);
  }

  /// Creates a GeoDataFrame from a list of coordinates.
  ///
  /// [coordinates]: A list of coordinate pairs (can be `[x,y]`, `[lon,lat]`, etc.)
  /// [attributes]: Optional DataFrame containing attribute data.
  /// [coordinateType]: The type of coordinates ('xy', 'lonlat', etc.)
  /// [crs]: The coordinate reference system.
  ///
  /// Returns a new GeoDataFrame with Point geometries.
  static GeoDataFrame fromCoordinates(
    List<List<double>> coordinates, {
    DataFrame? attributes,
    String coordinateType = 'xy',
    String? crs,
  }) {
    // Create a DataFrame with geometry column
    List<List<dynamic>> data = [];

    for (int i = 0; i < coordinates.length; i++) {
      List<dynamic> row = [];

      // Add attributes if provided
      if (attributes != null && i < attributes.rows.length) {
        row.addAll(attributes.rows[i]);
      }

      // Add geometry
      row.add(coordinates[i]);

      data.add(row);
    }

    // Create columns
    List<String> columns = [];
    if (attributes != null) {
      columns.addAll(attributes.columns.map((c) => c.toString()));
    }
    columns.add('geometry');

    // Create DataFrame
    final df = DataFrame(columns: columns, data);

    // Create GeoDataFrame
    return GeoDataFrame(df, geometryColumn: 'geometry', crs: crs);
  }

  /// Extracts the geometries as a list.
  ///
  /// [asGeoJSON]: If true, returns geometries as GeoJSON objects.
  /// If false, returns geometries as coordinate lists.
  List<dynamic> geometries({bool asGeoJSON = false}) =>
      geometry.geometries(asGeoJSON: asGeoJSON);

  /// Get the GeoJSON FeatureCollection
  GeoJSONFeatureCollection get featureCollection => toFeatureCollection();

  /// Converts the GeoDataFrame to a GeoJSON FeatureCollection.
  GeoJSONFeatureCollection toFeatureCollection() {
    final features = <GeoJSONFeature>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];

      // Get geometry
      final geomIndex = columns.indexOf(geometryColumn);
      final geom = geomIndex >= 0 && geomIndex < row.length
          ? row[geomIndex]
          : GeoJSONPoint([0, 0]);

      // Create properties
      final properties = <String, dynamic>{};
      for (int j = 0; j < columns.length; j++) {
        if (j != geomIndex && j < row.length) {
          properties[columns[j].toString()] = row[j];
        }
      }

      // Create feature
      final feature = GeoJSONFeature(
          geom is GeoJSONGeometry ? geom : GeoJSONPoint([0, 0]),
          properties: properties);

      features.add(feature);
    }

    return GeoJSONFeatureCollection(features);
  }

  /// Reads spatial data from a file, automatically determining the driver.
  ///
  /// [filePath]: The path of the file to read.
  /// [driver]: The type of driver to use. Defaults to 'Auto', which automatically determines the driver.
  /// Other parameters as per your existing implementation.
  ///
  /// Returns a `Future<GeoDataFrame>` representing the read data.
  static Future<GeoDataFrame> readFile(
    String filePath, {
    String driver = 'Auto',
    String delimiter = ',',
    bool hasHeader = true,
    String eol = '\r\n',
    String textDelimiter = '"',
    bool delimitAllFields = false,
    Map<String, int>? coordinatesColumns,
    String? geometryColumn,
    String coordinateType = 'lonlat',
    String? crs,
  }) async {
    if (driver == 'Auto') {
      driver = getDriverForExtension(filePath);
    }

    FileIO fileIO = FileIO();
    Stream<String> lines;

    if (filePath.isNotEmpty) {
      // Read file
      lines = fileIO.readFileAsStream(filePath);
    } else {
      throw ArgumentError('Either inputFilePath must be provided.');
    }

    // Create a new FeatureCollection to store the data
    final featureCollection = GeoJSONFeatureCollection([]);

    switch (driver) {
      case 'TXT':
      case 'CSV':
        // First, collect all lines to build a DataFrame
        List<String> allLines = [];
        await for (String line in lines) {
          allLines.add(line);
        }

        // Create a DataFrame from the CSV data
        DataFrame df = await DataFrame.fromCSV(
          csv: allLines.join('\n'),
          delimiter: delimiter,
          hasHeader: hasHeader,
        );

        // If a geometry column is specified, try to parse WKT geometries
        if (geometryColumn != null) {
          int geometryColumnIndex = df.columns.indexOf(geometryColumn);
          if (geometryColumnIndex != -1) {
            // Create a GeoDataFrame directly from the DataFrame with WKT geometries
            return GeoDataFrame(df, geometryColumn: geometryColumn, crs: crs);
          }
        }

        // If no geometry column is specified or found, fall back to coordinate columns
        if (coordinatesColumns != null) {
          // Create a feature collection
          final featureCollection = GeoJSONFeatureCollection([]);

          // Process rows to extract coordinates
          for (int i = 0; i < df.rows.length; i++) {
            final row = df.rows[i];

            // Create properties map from all columns
            final properties = <String, dynamic>{};
            for (int j = 0; j < df.columns.length; j++) {
              properties[df.columns[j].toString()] = row[j];
            }

            // Extract coordinates
            List<double>? coordinates;

            // Support for different coordinate types
            if (coordinateType == 'lonlat' || coordinateType == 'xy') {
              // For lon/lat or x/y coordinates
              double? x, y;

              if (coordinateType == 'lonlat') {
                if (coordinatesColumns.containsKey('longitude') &&
                    coordinatesColumns['longitude']! < df.columns.length) {
                  var lonValue = row[coordinatesColumns['longitude']!];
                  x = lonValue is num
                      ? lonValue.toDouble()
                      : (lonValue is String ? double.tryParse(lonValue) : null);
                }

                if (coordinatesColumns.containsKey('latitude') &&
                    coordinatesColumns['latitude']! < df.columns.length) {
                  var latValue = row[coordinatesColumns['latitude']!];
                  y = latValue is num
                      ? latValue.toDouble()
                      : (latValue is String ? double.tryParse(latValue) : null);
                }
              } else {
                // xy
                if (coordinatesColumns.containsKey('x') &&
                    coordinatesColumns['x']! < df.columns.length) {
                  var xValue = row[coordinatesColumns['x']!];
                  x = xValue is num
                      ? xValue.toDouble()
                      : (xValue is String ? double.tryParse(xValue) : null);
                }

                if (coordinatesColumns.containsKey('y') &&
                    coordinatesColumns['y']! < df.columns.length) {
                  var yValue = row[coordinatesColumns['y']!];
                  y = yValue is num
                      ? yValue.toDouble()
                      : (yValue is String ? double.tryParse(yValue) : null);
                }
              }

              if (x != null && y != null) {
                coordinates = [x, y];
              }
            } else if (coordinateType == 'xyz' || coordinateType == 'lonlatz') {
              // For 3D coordinates
              double? x, y, z;

              if (coordinateType == 'lonlatz') {
                if (coordinatesColumns.containsKey('longitude') &&
                    coordinatesColumns['longitude']! < df.columns.length) {
                  var lonValue = row[coordinatesColumns['longitude']!];
                  x = lonValue is num
                      ? lonValue.toDouble()
                      : (lonValue is String ? double.tryParse(lonValue) : null);
                }

                if (coordinatesColumns.containsKey('latitude') &&
                    coordinatesColumns['latitude']! < df.columns.length) {
                  var latValue = row[coordinatesColumns['latitude']!];
                  y = latValue is num
                      ? latValue.toDouble()
                      : (latValue is String ? double.tryParse(latValue) : null);
                }

                if (coordinatesColumns.containsKey('altitude') &&
                    coordinatesColumns['altitude']! < df.columns.length) {
                  var altValue = row[coordinatesColumns['altitude']!];
                  z = altValue is num
                      ? altValue.toDouble()
                      : (altValue is String ? double.tryParse(altValue) : null);
                }
              } else {
                // xyz
                if (coordinatesColumns.containsKey('x') &&
                    coordinatesColumns['x']! < df.columns.length) {
                  var xValue = row[coordinatesColumns['x']!];
                  x = xValue is num
                      ? xValue.toDouble()
                      : (xValue is String ? double.tryParse(xValue) : null);
                }

                if (coordinatesColumns.containsKey('y') &&
                    coordinatesColumns['y']! < df.columns.length) {
                  var yValue = row[coordinatesColumns['y']!];
                  y = yValue is num
                      ? yValue.toDouble()
                      : (yValue is String ? double.tryParse(yValue) : null);
                }

                if (coordinatesColumns.containsKey('z') &&
                    coordinatesColumns['z']! < df.columns.length) {
                  var zValue = row[coordinatesColumns['z']!];
                  z = zValue is num
                      ? zValue.toDouble()
                      : (zValue is String ? double.tryParse(zValue) : null);
                }
              }

              if (x != null && y != null) {
                coordinates = [x, y];
                if (z != null) {
                  coordinates.add(z);
                }
              }
            }

            // Create a Point geometry if coordinates are available
            if (coordinates != null && coordinates.length >= 2) {
              final point = GeoJSONPoint(coordinates);
              final feature = GeoJSONFeature(point, properties: properties);
              featureCollection.features.add(feature);
            } else {
              // Create a feature without geometry if coordinates are not available
              final feature =
                  GeoJSONFeature(GeoJSONPoint([0, 0]), // Default point
                      properties: properties);
              featureCollection.features.add(feature);
            }
          }

          return GeoDataFrame.fromFeatureCollection(featureCollection,
              crs: crs);
        }

        // If neither geometry column nor coordinate columns are specified,
        // return a DataFrame with no geometries
        return GeoDataFrame.fromFeatureCollection(GeoJSONFeatureCollection([]),
            crs: crs);

      case 'ESRI Shapefile':
        // Read Shapefile - to be implemented
        // For now, return empty GeoDataFrame
        return GeoDataFrame.fromFeatureCollection(featureCollection);

      case 'GeoJSON':
        // Read GeoJSON file
        final buffer = StringBuffer();
        await for (String line in lines) {
          buffer.write(line);
        }

        final jsonString = buffer.toString();
        final geoJson = GeoJSON.fromJSON(jsonString);

        if (geoJson is GeoJSONFeatureCollection) {
          return GeoDataFrame.fromFeatureCollection(geoJson);
        } else if (geoJson is GeoJSONFeature) {
          // Create a feature collection with a single feature
          final collection = GeoJSONFeatureCollection([]);
          collection.features.add(geoJson);

          return GeoDataFrame.fromFeatureCollection(collection);
        } else if (geoJson is GeoJSONGeometry) {
          // Create a feature with the geometry
          final feature = GeoJSONFeature(geoJson);
          final collection = GeoJSONFeatureCollection([]);
          collection.features.add(feature);
          return GeoDataFrame.fromFeatureCollection(collection);
        }
        break;

      case 'GPX':
        var geoXml = await GeoXml.fromGpxStream(lines);
        // Convert GPX to GeoJSON FeatureCollection
        final collection = GeoJSONFeatureCollection([]);

        // Process waypoints
        for (var wpt in geoXml.wpts) {
          final point = GeoJSONPoint([wpt.lon ?? 0, wpt.lat ?? 0]);
          final properties = <String, dynamic>{
            'name': wpt.name,
            'description': wpt.desc,
            'elevation': wpt.ele,
            'time': wpt.time?.toIso8601String(),
          };

          // Remove null values
          properties.removeWhere((key, value) => value == null);

          final feature = GeoJSONFeature(point, properties: properties);
          collection.features.add(feature);
        }

        // Process tracks
        for (var trk in geoXml.trks) {
          for (var seg in trk.trksegs) {
            final coordinates = <List<double>>[];
            for (var pt in seg.trkpts) {
              coordinates.add([pt.lon ?? 0, pt.lat ?? 0]);
            }

            if (coordinates.isNotEmpty) {
              final lineString = GeoJSONLineString(coordinates);
              final properties = <String, dynamic>{
                'name': trk.name,
                'description': trk.desc,
              };

              // Remove null values
              properties.removeWhere((key, value) => value == null);

              final feature =
                  GeoJSONFeature(lineString, properties: properties);
              collection.features.add(feature);
            }
          }
        }

        // Process routes
        for (var rte in geoXml.rtes) {
          final coordinates = <List<double>>[];
          for (var pt in rte.rtepts) {
            coordinates.add([pt.lon ?? 0, pt.lat ?? 0]);
          }

          if (coordinates.isNotEmpty) {
            final lineString = GeoJSONLineString(coordinates);
            final properties = <String, dynamic>{
              'name': rte.name,
              'description': rte.desc,
            };

            // Remove null values
            properties.removeWhere((key, value) => value == null);

            final feature = GeoJSONFeature(lineString, properties: properties);
            collection.features.add(feature);
          }
        }

        return GeoDataFrame.fromFeatureCollection(collection);

      case 'GML':
      case 'KML':
        var geoXml = await GeoXml.fromKmlStream(lines);
        // Convert KML to GeoJSON FeatureCollection - similar to GPX conversion
        // This is a simplified implementation
        final collection = GeoJSONFeatureCollection([]);

        // Process placemarks (similar to waypoints in GPX)
        for (var placemark in geoXml.wpts) {
          final point = GeoJSONPoint([placemark.lon ?? 0, placemark.lat ?? 0]);
          final properties = <String, dynamic>{
            'name': placemark.name,
            'description': placemark.desc,
            'elevation': placemark.ele,
          };

          // Remove null values
          properties.removeWhere((key, value) => value == null);

          final feature = GeoJSONFeature(point, properties: properties);
          collection.features.add(feature);
        }

        return GeoDataFrame.fromFeatureCollection(collection);

      default:
        return GeoDataFrame.fromFeatureCollection(
            featureCollection); // Return empty GeoDataFrame
    }

    return GeoDataFrame.fromFeatureCollection(
        featureCollection); // Default return
  }

  /// Exports the data to different file formats, automatically determining the driver.
  ///
  /// [filePath]: The path of the file to write to.
  /// Other parameters as per your existing implementation.
  ///
  /// Returns a `Future<void>` indicating the completion of the file writing process.
  Future<void> toFile(
    String filePath, {
    String driver = 'Auto',
    String delimiter = ',',
    bool includeHeader = true,
    String defaultEol = '\r\n',
    String defaultTextDelimiter = '"',
    bool defaultDelimitAllFields = false,
  }) async {
    if (driver == 'Auto') {
      driver = getDriverForExtension(filePath);
    }

    FileIO fileIO = FileIO();

    switch (driver) {
      case 'TXT':
      case 'CSV':
        final buffer = StringBuffer();

        // Write header
        if (includeHeader && headers.isNotEmpty) {
          buffer.writeln(headers.join(delimiter));
        }

        // Write data rows
        for (var feature in featureCollection.features) {
          if (feature?.properties != null) {
            final rowValues = headers
                .map((h) => feature!.properties![h]?.toString() ?? '')
                .toList();
            buffer.writeln(rowValues.join(delimiter));
          }
        }

        fileIO.saveToFile(filePath, buffer.toString());
        break;

      case 'GeoJSON':
        // Export to GeoJSON
        final jsonString = featureCollection.toJSON(indent: 2);
        fileIO.saveToFile(filePath, jsonString);
        break;

      case 'ESRI Shapefile':
        // Export to Shapefile - to be implemented
        throw UnimplementedError('Shapefile export is not yet implemented');

      case 'GPX':
        // Convert GeoJSON to GPX
        var gpx = GeoXml();
        gpx.creator = "GeoEngine library";

        // Process Point features as waypoints
        for (var feature in featureCollection.features) {
          if (feature != null && feature.geometry is GeoJSONPoint) {
            final point = feature.geometry as GeoJSONPoint;
            final coords = point.coordinates;

            if (coords.length >= 2) {
              final wpt = Wpt(
                lat: coords[1],
                lon: coords[0],
                ele: feature.properties?['elevation'] ?? 0.0,
                name: feature.properties?['name'] ?? '',
                desc: feature.properties?['description'] ?? '',
              );
              gpx.wpts.add(wpt);
            }
          }
        }

        // Process LineString features as tracks
        for (var feature in featureCollection.features) {
          if (feature != null && feature.geometry is GeoJSONLineString) {
            final lineString = feature.geometry as GeoJSONLineString;
            final coords = lineString.coordinates;

            final trk = Trk();
            trk.name = feature.properties?['name'] ?? '';
            trk.desc = feature.properties?['description'] ?? '';

            final trkSeg = Trkseg();
            for (var coord in coords) {
              if (coord.length >= 2) {
                final trkpt = Wpt(
                  lat: coord[1],
                  lon: coord[0],
                  ele: feature.properties?['elevation'] ?? 0.0,
                );
                trkSeg.trkpts.add(trkpt);
              }
            }

            trk.trksegs.add(trkSeg);
            gpx.trks.add(trk);
          }
        }

        // Generate GPX string and save to file
        final gpxString = gpx.toGpxString(pretty: true);
        fileIO.saveToFile(filePath, gpxString);
        break;

      case 'KML':
        // Convert GeoJSON to KML
        var geoXml = GeoXml();
        geoXml.creator = "GeoEngine library";

        // Process Point features as placemarks
        for (var feature in featureCollection.features) {
          if (feature != null && feature.geometry is GeoJSONPoint) {
            final point = feature.geometry as GeoJSONPoint;
            final coords = point.coordinates;

            if (coords.length >= 2) {
              final wpt = Wpt(
                lat: coords[1],
                lon: coords[0],
                ele: feature.properties?['elevation'] ?? 0.0,
                name: feature.properties?['name'] ?? '',
                desc: feature.properties?['description'] ?? '',
              );
              geoXml.wpts.add(wpt);
            }
          }
        }

        // Generate KML string and save to file
        final kmlString = geoXml.toKmlString(
            pretty: true, altitudeMode: AltitudeMode.clampToGround);
        fileIO.saveToFile(filePath, kmlString);
        break;

      default:
        throw UnsupportedError('Unsupported file format: $driver');
    }
  }

  /// Creates a GeoDataFrame instance from a list of maps (rows).
  static GeoDataFrame fromRows(List<Map<String, dynamic>> rows) {
    final featureCollection = GeoJSONFeatureCollection([]);

    for (var row in rows) {
      // Extract coordinates if available
      double? lat, lon;
      if (row.containsKey('latitude')) {
        lat = row['latitude'] is double
            ? row['latitude']
            : double.tryParse(row['latitude'].toString());
      }

      if (row.containsKey('longitude')) {
        lon = row['longitude'] is double
            ? row['longitude']
            : double.tryParse(row['longitude'].toString());
      }

      // Create geometry
      GeoJSONGeometry geometry;
      if (lat != null && lon != null) {
        geometry = GeoJSONPoint([lon, lat]);
      } else {
        // Default point at 0,0 if no coordinates
        geometry = GeoJSONPoint([0, 0]);
      }

      // Create properties (excluding lat/lon)
      final properties = <String, dynamic>{};
      for (var key in row.keys) {
        if (key != 'latitude' && key != 'longitude') {
          properties[key] = row[key];
        }
      }

      // Create feature
      final feature = GeoJSONFeature(geometry, properties: properties);
      featureCollection.features.add(feature);
    }

    return GeoDataFrame.fromFeatureCollection(featureCollection);
  }
}
