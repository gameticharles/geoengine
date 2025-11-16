part of 'geodata_frame.dart';

extension GeoDataFrameFunctions on GeoDataFrame {
  /// Adds a new feature to the GeoDataFrame.
  ///
  /// [geometry]: The GeoJSONGeometry for the feature.
  /// [properties]: The properties map for the feature.
  void addFeature(GeoJSONGeometry geometry,
      {Map<String, dynamic>? properties}) {
    // Create a new row for the DataFrame
    final List<dynamic> newRow = List.filled(columns.length, null);

    // Set the geometry in the appropriate column
    final geomIndex = columns.indexOf(geometryColumn);
    if (geomIndex >= 0) {
      newRow[geomIndex] = geometry;
    }

    // Add properties to the row
    if (properties != null) {
      for (var key in properties.keys) {
        final colIndex = columns.indexOf(key);
        if (colIndex >= 0) {
          newRow[colIndex] = properties[key];
        }
      }
    }

    // Add the row to the internal data structure
    rows.add(newRow);

    // Add any new properties as columns if they don't exist
    if (properties != null) {
      for (var key in properties.keys) {
        if (!columns.contains(key) && key != geometryColumn) {
          // Add the new column with default values
          addColumn(key, defaultValue: null);

          // Update the value in the new row for this column
          final colIndex = columns.indexOf(key);
          if (colIndex >= 0 && colIndex < rows.last.length) {
            rows.last[colIndex] = properties[key];
          }
        }
      }
    }
  }

  /// Deletes a feature at the specified index.
  void deleteFeature(int index) {
    if (index >= 0 && index < rows.length) {
      rows.removeAt(index);
    }
  }

  /// Deletes a feature by index.
  void deleteRow(int index) => deleteFeature(index);

  /// Gets a specific feature as a GeoJSONFeature.
  GeoJSONFeature? getFeature(int index) {
    if (index < 0 || index >= rows.length) {
      return null;
    }

    final row = rows[index];
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

    return GeoJSONFeature(geom is GeoJSONGeometry ? geom : GeoJSONPoint([0, 0]),
        properties: properties);
  }

  /// Finds features based on a query function.
  List<GeoJSONFeature> findFeatures(bool Function(GeoJSONFeature) query) {
    final features = <GeoJSONFeature>[];

    for (int i = 0; i < rows.length; i++) {
      final feature = getFeature(i);
      if (feature != null && query(feature)) {
        features.add(feature);
      }
    }

    return features;
  }

  /// Get the rows as List of Maps
  List<Map<String, dynamic>> get rowMaps => toRows();

  /// Converts the GeoDataFrame to a list of maps (rows).
  List<Map<String, dynamic>> toRows() {
    final result = <Map<String, dynamic>>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final Map<String, dynamic> rowMap = {};

      // Add all properties
      for (int j = 0; j < columns.length; j++) {
        if (j < row.length) {
          final colName = columns[j].toString();
          if (colName != geometryColumn) {
            rowMap[colName] = row[j];
          } else {
            // Handle geometry column specially
            final geom = row[j];
            if (geom is GeoJSONPoint) {
              final coords = geom.coordinates;
              if (coords.length >= 2) {
                rowMap['longitude'] = coords[0];
                rowMap['latitude'] = coords[1];
                if (coords.length >= 3) {
                  rowMap['elevation'] = coords[2];
                }
              }
            }
            // Add the geometry object itself
            rowMap[geometryColumn] = geom;
          }
        }
      }

      result.add(rowMap);
    }

    return result;
  }

  /// Renames the geometry column.
  ///
  /// [newName]: The new name for the geometry column.
  ///
  /// Returns a new GeoDataFrame with the renamed geometry column.
  GeoDataFrame renameGeometry(String newName) {
    if (newName == geometryColumn) {
      return this; // No change needed
    }

    // Create a copy of the DataFrame
    final newDf = copy();

    // Rename the column
    newDf.rename({geometryColumn: newName});

    // Create a new GeoDataFrame with the updated geometry column name
    return GeoDataFrame(newDf, geometryColumn: newName, crs: crs);
  }

  /// Sets a different column as the geometry column.
  ///
  /// [columnName]: The name of the column to set as the geometry column.
  ///
  /// Returns a new GeoDataFrame with the specified column as the geometry.
  GeoDataFrame setGeometry(String columnName) {
    if (columnName == geometryColumn) {
      return this; // No change needed
    }

    if (!columns.contains(columnName)) {
      throw ArgumentError('Column $columnName not found in DataFrame');
    }

    // Create a new GeoDataFrame with the updated geometry column
    return GeoDataFrame(this, geometryColumn: columnName, crs: crs);
  }

  /// Performs a spatial join between this GeoDataFrame and another GeoDataFrame.
  ///
  /// [right]: The GeoDataFrame to join with.
  /// [how]: The type of join ('left', 'right', 'inner', 'outer').
  /// [predicate]: The spatial predicate to use ('intersects', 'within', 'contains', 'touches', 'crosses', 'overlaps').
  ///
  /// Returns a new GeoDataFrame with the joined data.
  GeoDataFrame spatialJoin(GeoDataFrame right,
      {String how = 'inner', String predicate = 'intersects'}) {
    final List<List<dynamic>> resultRows = [];
    final List<String> resultColumns = [];

    // Create column names, avoiding duplicates
    final leftColumns = columns.map((c) => c.toString()).toList();
    final rightColumns = right.columns.map((c) => c.toString()).toList();

    // Add left columns
    resultColumns.addAll(leftColumns);

    // Add right columns with suffix if there are duplicates
    for (final rightCol in rightColumns) {
      if (leftColumns.contains(rightCol)) {
        resultColumns.add('${rightCol}_right');
      } else {
        resultColumns.add(rightCol);
      }
    }

    // Perform spatial join based on the specified predicate
    for (int i = 0; i < rows.length; i++) {
      final leftRow = rows[i];
      final leftGeom =
          _getGeometryFromRow(leftRow, columns.indexOf(geometryColumn));

      bool hasMatch = false;

      for (int j = 0; j < right.rows.length; j++) {
        final rightRow = right.rows[j];
        final rightGeom = _getGeometryFromRow(
            rightRow, right.columns.indexOf(right.geometryColumn));

        if (_spatialPredicate(leftGeom, rightGeom, predicate)) {
          hasMatch = true;

          // Create result row
          final List<dynamic> resultRow = [];
          resultRow.addAll(leftRow);

          // Add right columns, handling duplicates
          for (int k = 0; k < rightColumns.length; k++) {
            resultRow.add(k < rightRow.length ? rightRow[k] : null);
          }

          resultRows.add(resultRow);

          if (how == 'inner' || how == 'left') {
            break; // Only take first match for inner/left joins
          }
        }
      }

      // Handle cases where no match was found
      if (!hasMatch && (how == 'left' || how == 'outer')) {
        final List<dynamic> resultRow = [];
        resultRow.addAll(leftRow);

        // Add null values for right columns
        for (int k = 0; k < rightColumns.length; k++) {
          resultRow.add(null);
        }

        resultRows.add(resultRow);
      }
    }

    // Handle right join and outer join cases
    if (how == 'right' || how == 'outer') {
      for (int j = 0; j < right.rows.length; j++) {
        final rightRow = right.rows[j];
        final rightGeom = _getGeometryFromRow(
            rightRow, right.columns.indexOf(right.geometryColumn));

        bool hasMatch = false;

        for (int i = 0; i < rows.length; i++) {
          final leftRow = rows[i];
          final leftGeom =
              _getGeometryFromRow(leftRow, columns.indexOf(geometryColumn));

          if (_spatialPredicate(leftGeom, rightGeom, predicate)) {
            hasMatch = true;
            break;
          }
        }

        if (!hasMatch && how == 'right') {
          final List<dynamic> resultRow = [];

          // Add null values for left columns
          for (int k = 0; k < leftColumns.length; k++) {
            resultRow.add(null);
          }

          // Add right columns
          resultRow.addAll(rightRow);

          resultRows.add(resultRow);
        }
      }
    }

    // Create result DataFrame
    final resultDf = DataFrame(columns: resultColumns, resultRows);

    // Determine geometry column for result
    String resultGeomColumn = geometryColumn;
    if (resultColumns.contains('${geometryColumn}_right') &&
        !resultColumns.contains(geometryColumn)) {
      resultGeomColumn = '${geometryColumn}_right';
    }

    return GeoDataFrame(resultDf, geometryColumn: resultGeomColumn, crs: crs);
  }

  /// Builds a spatial index for efficient spatial queries.
  void buildSpatialIndex() {
    // In a full implementation, this would build an R-tree or similar spatial index
    // For now, we'll just mark that an index has been built
    _spatialIndexBuilt[this] = true;
  }

  /// Performs a spatial query using a bounding box or geometry.
  ///
  /// [bounds]: Either a `List<double>` representing `[minX, minY, maxX, maxY]` or a GeoJSONGeometry.
  ///
  /// Returns a list of indices of features that intersect with the query bounds.
  List<int> spatialQuery(dynamic bounds) {
    final List<int> results = [];

    if (bounds is List<double> && bounds.length == 4) {
      // Bounding box query
      final minX = bounds[0];
      final minY = bounds[1];
      final maxX = bounds[2];
      final maxY = bounds[3];

      for (int i = 0; i < rows.length; i++) {
        final geom =
            _getGeometryFromRow(rows[i], columns.indexOf(geometryColumn));
        if (geom != null && _intersectsBounds(geom, minX, minY, maxX, maxY)) {
          results.add(i);
        }
      }
    } else if (bounds is GeoJSONGeometry) {
      // Geometry query
      for (int i = 0; i < rows.length; i++) {
        final geom =
            _getGeometryFromRow(rows[i], columns.indexOf(geometryColumn));
        if (geom != null && _spatialPredicate(geom, bounds, 'intersects')) {
          results.add(i);
        }
      }
    }

    return results;
  }

  /// Transforms the GeoDataFrame to a different coordinate reference system.
  ///
  /// [targetCrs]: The target CRS (e.g., 'EPSG:3857', 'EPSG:4326').
  ///
  /// Returns a new GeoDataFrame with transformed coordinates.
  GeoDataFrame toCrs(String targetCrs) {
    if (targetCrs == crs) {
      return copy(); // No transformation needed
    }

    // Create a copy of the GeoDataFrame
    final newGdf = copy();

    // Transform geometries
    final geomIndex = columns.indexOf(geometryColumn);
    if (geomIndex >= 0) {
      for (int i = 0; i < newGdf.rows.length; i++) {
        final geom = _getGeometryFromRow(newGdf.rows[i], geomIndex);
        if (geom != null) {
          newGdf.rows[i][geomIndex] = _transformGeometry(geom, crs, targetCrs);
        }
      }
    }

    // Return new GeoDataFrame with updated CRS
    return GeoDataFrame(
      DataFrame(newGdf.rows as List<List<dynamic>>,
          columns: newGdf.columns, index: newGdf.index),
      geometryColumn: geometryColumn,
      crs: targetCrs,
    );
  }

  /// Performs overlay operations between this GeoDataFrame and another.
  ///
  /// [other]: The other GeoDataFrame to overlay with.
  /// [how]: The type of overlay ('intersection', 'union', 'difference', 'symmetric_difference').
  ///
  /// Returns a new GeoDataFrame with the overlay result.
  GeoDataFrame overlay(GeoDataFrame other, {String how = 'intersection'}) {
    final List<List<dynamic>> resultRows = [];
    final List<String> resultColumns = [];

    // Create column names
    final leftColumns = columns.map((c) => c.toString()).toList();
    final rightColumns = other.columns.map((c) => c.toString()).toList();

    // Add left columns
    resultColumns.addAll(leftColumns);

    // Add right columns with suffix if there are duplicates
    for (final rightCol in rightColumns) {
      if (leftColumns.contains(rightCol)) {
        resultColumns.add('${rightCol}_right');
      } else {
        resultColumns.add(rightCol);
      }
    }

    final leftGeomIndex = columns.indexOf(geometryColumn);
    final rightGeomIndex = other.columns.indexOf(other.geometryColumn);
    final resultGeomIndex = resultColumns.indexOf(geometryColumn);

    switch (how.toLowerCase()) {
      case 'intersection':
        for (int i = 0; i < rows.length; i++) {
          final leftRow = rows[i];
          final leftGeom = _getGeometryFromRow(leftRow, leftGeomIndex);

          for (int j = 0; j < other.rows.length; j++) {
            final rightRow = other.rows[j];
            final rightGeom = _getGeometryFromRow(rightRow, rightGeomIndex);

            if (leftGeom != null &&
                rightGeom != null &&
                _spatialPredicate(leftGeom, rightGeom, 'intersects')) {
              final intersectionGeom =
                  _intersectionGeometry(leftGeom, rightGeom);
              if (intersectionGeom != null) {
                final List<dynamic> resultRow = [];
                resultRow.addAll(leftRow);

                // Add right columns
                for (int k = 0; k < rightColumns.length; k++) {
                  resultRow.add(k < rightRow.length ? rightRow[k] : null);
                }

                // Set intersection geometry
                resultRow[resultGeomIndex] = intersectionGeom;
                resultRows.add(resultRow);
              }
            }
          }
        }
        break;

      case 'union':
        // Add all geometries from left
        for (int i = 0; i < rows.length; i++) {
          final leftRow = rows[i];
          final List<dynamic> resultRow = [];
          resultRow.addAll(leftRow);

          // Add null values for right columns
          for (int k = 0; k < rightColumns.length; k++) {
            resultRow.add(null);
          }

          resultRows.add(resultRow);
        }

        // Add all geometries from right
        for (int j = 0; j < other.rows.length; j++) {
          final rightRow = other.rows[j];
          final List<dynamic> resultRow = [];

          // Add null values for left columns
          for (int k = 0; k < leftColumns.length; k++) {
            resultRow.add(null);
          }

          // Add right columns
          for (int k = 0; k < rightColumns.length; k++) {
            if (rightColumns[k] == other.geometryColumn) {
              resultRow[resultGeomIndex] =
                  k < rightRow.length ? rightRow[k] : null;
            } else {
              resultRow.add(k < rightRow.length ? rightRow[k] : null);
            }
          }

          resultRows.add(resultRow);
        }
        break;

      case 'difference':
        for (int i = 0; i < rows.length; i++) {
          final leftRow = rows[i];
          final leftGeom = _getGeometryFromRow(leftRow, leftGeomIndex);

          bool hasIntersection = false;
          for (int j = 0; j < other.rows.length; j++) {
            final rightGeom =
                _getGeometryFromRow(other.rows[j], rightGeomIndex);

            if (leftGeom != null &&
                rightGeom != null &&
                _spatialPredicate(leftGeom, rightGeom, 'intersects')) {
              hasIntersection = true;
              break;
            }
          }

          if (!hasIntersection) {
            final List<dynamic> resultRow = [];
            resultRow.addAll(leftRow);

            // Add null values for right columns
            for (int k = 0; k < rightColumns.length; k++) {
              resultRow.add(null);
            }

            resultRows.add(resultRow);
          }
        }
        break;

      default:
        throw ArgumentError('Unsupported overlay operation: $how');
    }

    // Create result DataFrame
    final resultDf = DataFrame(columns: resultColumns, resultRows);

    return GeoDataFrame(resultDf, geometryColumn: geometryColumn, crs: crs);
  }

  // Private helper variables and methods
  static final Map<GeoDataFrame, bool> _spatialIndexBuilt = {};

  /// Helper method to get geometry from a row
  GeoJSONGeometry? _getGeometryFromRow(List<dynamic> row, int geomIndex) {
    if (geomIndex >= 0 && geomIndex < row.length) {
      final geomValue = row[geomIndex];
      if (geomValue is GeoJSONGeometry) {
        return geomValue;
      }
    }
    return null;
  }

  /// Helper method to check spatial predicates
  bool _spatialPredicate(
      GeoJSONGeometry? geom1, GeoJSONGeometry? geom2, String predicate) {
    if (geom1 == null || geom2 == null) return false;

    switch (predicate.toLowerCase()) {
      case 'intersects':
        return _intersects(geom1, geom2);
      case 'within':
        return _within(geom1, geom2);
      case 'contains':
        return _contains(geom1, geom2);
      case 'touches':
        return _touches(geom1, geom2);
      case 'crosses':
        return _crosses(geom1, geom2);
      case 'overlaps':
        return _overlaps(geom1, geom2);
      default:
        return _intersects(geom1, geom2);
    }
  }

  /// Simplified intersects check
  bool _intersects(GeoJSONGeometry geom1, GeoJSONGeometry geom2) {
    // Get bounding boxes
    final bbox1 = geom1.bbox;
    final bbox2 = geom2.bbox;

    if (bbox1 == null || bbox2 == null) return false;

    // Check if bounding boxes intersect
    return !(bbox1[2] < bbox2[0] ||
        bbox2[2] < bbox1[0] ||
        bbox1[3] < bbox2[1] ||
        bbox2[3] < bbox1[1]);
  }

  /// Simplified within check
  bool _within(GeoJSONGeometry geom1, GeoJSONGeometry geom2) {
    if (geom1 is GeoJSONPoint && geom2 is GeoJSONPolygon) {
      return _pointInPolygon(geom1.coordinates, geom2.coordinates);
    }
    return false;
  }

  /// Simplified contains check
  bool _contains(GeoJSONGeometry geom1, GeoJSONGeometry geom2) {
    return _within(geom2, geom1);
  }

  /// Simplified touches check
  bool _touches(GeoJSONGeometry geom1, GeoJSONGeometry geom2) {
    // Simplified implementation - just check if they intersect
    return _intersects(geom1, geom2);
  }

  /// Simplified crosses check
  bool _crosses(GeoJSONGeometry geom1, GeoJSONGeometry geom2) {
    // Simplified implementation - just check if they intersect
    return _intersects(geom1, geom2);
  }

  /// Simplified overlaps check
  bool _overlaps(GeoJSONGeometry geom1, GeoJSONGeometry geom2) {
    // Simplified implementation - just check if they intersect
    return _intersects(geom1, geom2);
  }

  /// Check if geometry intersects with bounding box
  bool _intersectsBounds(GeoJSONGeometry geom, double minX, double minY,
      double maxX, double maxY) {
    final bbox = geom.bbox;
    if (bbox == null) return false;

    return !(bbox[2] < minX ||
        maxX < bbox[0] ||
        bbox[3] < minY ||
        maxY < bbox[1]);
  }

  /// Point in polygon test using ray casting algorithm
  bool _pointInPolygon(
      List<double> point, List<List<List<double>>> polygonRings) {
    if (polygonRings.isEmpty) return false;

    final exteriorRing = polygonRings[0];
    bool inside = _pointInRing(point, exteriorRing);

    // Check holes
    for (int i = 1; i < polygonRings.length; i++) {
      if (_pointInRing(point, polygonRings[i])) {
        inside = false; // Point is in a hole
        break;
      }
    }

    return inside;
  }

  /// Point in ring test using ray casting algorithm
  bool _pointInRing(List<double> point, List<List<double>> ring) {
    if (ring.length < 4) return false;

    final x = point[0];
    final y = point[1];
    bool inside = false;

    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];

      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }

    return inside;
  }

  /// Transform geometry between coordinate systems (simplified)
  GeoJSONGeometry _transformGeometry(
      GeoJSONGeometry geom, String? fromCrs, String toCrs) {
    // This is a very simplified transformation that only handles basic cases
    // A full implementation would use a proper coordinate transformation library

    if (fromCrs == toCrs) return geom;

    // Simple transformation from WGS84 to Web Mercator and vice versa
    if ((fromCrs == 'EPSG:4326' && toCrs == 'EPSG:3857') ||
        (fromCrs == null && toCrs == 'EPSG:3857')) {
      return _transformToWebMercator(geom);
    } else if (fromCrs == 'EPSG:3857' && toCrs == 'EPSG:4326') {
      return _transformFromWebMercator(geom);
    }

    // For other transformations, return the original geometry
    return geom;
  }

  /// Transform to Web Mercator (EPSG:3857)
  GeoJSONGeometry _transformToWebMercator(GeoJSONGeometry geom) {
    if (geom is GeoJSONPoint) {
      final coords = geom.coordinates;
      if (coords.length >= 2) {
        final x = coords[0] * 20037508.34 / 180;
        final y = log(tan((90 + coords[1]) * pi / 360)) /
            (pi / 180) *
            20037508.34 /
            180;
        return GeoJSONPoint([x, y]);
      }
    }
    // For other geometry types, return original (simplified)
    return geom;
  }

  /// Transform from Web Mercator (EPSG:3857)
  GeoJSONGeometry _transformFromWebMercator(GeoJSONGeometry geom) {
    if (geom is GeoJSONPoint) {
      final coords = geom.coordinates;
      if (coords.length >= 2) {
        final x = coords[0] * 180 / 20037508.34;
        final y = atan(exp(coords[1] * pi / 20037508.34)) * 360 / pi - 90;
        return GeoJSONPoint([x, y]);
      }
    }
    // For other geometry types, return original (simplified)
    return geom;
  }

  /// Simplified intersection geometry calculation
  GeoJSONGeometry? _intersectionGeometry(
      GeoJSONGeometry geom1, GeoJSONGeometry geom2) {
    // This is a very simplified implementation
    // A full implementation would use a computational geometry library

    if (geom1 is GeoJSONPoint && geom2 is GeoJSONPolygon) {
      if (_pointInPolygon(geom1.coordinates, geom2.coordinates)) {
        return geom1;
      }
    } else if (geom2 is GeoJSONPoint && geom1 is GeoJSONPolygon) {
      if (_pointInPolygon(geom2.coordinates, geom1.coordinates)) {
        return geom2;
      }
    }

    return null;
  }
}
