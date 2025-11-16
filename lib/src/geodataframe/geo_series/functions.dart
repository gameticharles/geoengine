part of 'geo_series.dart';

extension GeoSeriesFunctions on GeoSeries {
  /// Extracts coordinates from each geometry in the GeoSeries into a DataFrame.
  ///
  /// Each row in the resulting DataFrame represents a single coordinate pair (or triplet if `includeZ` is true).
  /// The DataFrame will have columns 'x', 'y', (and 'z' if `includeZ` is true).
  ///
  /// Parameters:
  ///   - `includeZ`: (bool, default: `false`)
  ///     If true, includes the Z-coordinate in the output DataFrame, resulting in columns `['x', 'y', 'z']`.
  ///     If false, only X and Y coordinates are included, resulting in columns `['x', 'y']`.
  ///   - `ignoreIndex`: (bool, default: `false`)
  ///     If true, the resulting DataFrame will have a simple numeric index (0, 1, ..., n-1).
  ///     The original index of the GeoSeries is ignored.
  ///   - `indexParts`: (bool, default: `false`)
  ///     If true, the resulting DataFrame's index will be a multi-level index (or a string representation if `indexPartsAsList` is false)
  ///     composed of the original geometry's index and a part index for each coordinate within that geometry.
  ///     This is useful for relating coordinates back to their specific part in complex geometries.
  ///     If `ignoreIndex` is true, this parameter is effectively ignored.
  ///   - `indexPartsAsList`: (bool, default: `false`)
  ///     If `indexParts` is true, this parameter determines the format of the multi-level index.
  ///     If true, the index will be a `List<List<dynamic>>` where each inner list is `[originalIndex, partIndex]`.
  ///     If false, the index will be a `List<String>` where the string combines the original index and part index.
  ///
  /// Returns:
  ///   (DataFrame): A DataFrame where each row is a coordinate.
  ///   The columns are `['x', 'y']` or `['x', 'y', 'z']`.
  ///   The index depends on the `ignoreIndex` and `indexParts` parameters.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1, 1]),
  ///   GeoJSONLineString([[1, -1], [1, 0]]),
  ///   GeoJSONPolygon([[[3, -1], [4, 0], [3, 1], [3, -1]]]),
  /// ]);
  ///
  /// // Default behavior - preserves original indices
  /// final coords = series.getCoordinates();
  /// // Returns DataFrame:
  /// //      x    y
  /// // 0  1.0  1.0
  /// // 1  1.0 -1.0
  /// // 1  1.0  0.0
  /// // 2  3.0 -1.0
  /// // 2  4.0  0.0
  /// // 2  3.0  1.0
  /// // 2  3.0 -1.0
  ///
  /// // With ignore_index=true - uses sequential indices
  /// final coordsIgnoreIndex = series.getCoordinates(ignoreIndex: true);
  /// // Returns DataFrame:
  /// //      x    y
  /// // 0  1.0  1.0
  /// // 1  1.0 -1.0
  /// // 2  1.0  0.0
  /// // 3  3.0 -1.0
  /// // 4  4.0  0.0
  /// // 5  3.0  1.0
  /// // 6  3.0 -1.0
  ///
  /// // With index_parts=true - uses multi-index with geometry index and part index
  /// final coordsIndexParts = series.getCoordinates(indexParts: true);
  /// // Returns DataFrame:
  /// //        x    y
  /// // 0 0  1.0  1.0
  /// // 1 0  1.0 -1.0
  /// //   1  1.0  0.0
  /// // 2 0  3.0 -1.0
  /// //   1  4.0  0.0
  /// //   2  3.0  1.0
  /// //   3  3.0 -1.0
  ///
  /// // With index_parts=true and index_parts_as_list=true
  /// final coordsIndexPartsList = series.getCoordinates(indexParts: true, indexPartsAsList: true);
  /// print(coordsIndexPartsList.index);
  /// // Output:
  /// // [[0, 0], [1, 0], [1, 1], [2, 0], [2, 1], [2, 2], [2, 3]]
  /// ```
  DataFrame getCoordinates({
    bool includeZ = false,
    bool ignoreIndex = false,
    bool indexParts = false,
    bool indexPartsAsList = false,
  }) {
    List<List<dynamic>> coordData = [];
    List<dynamic> indices = [];
    List<dynamic> partIndices = [];
    List<dynamic> originalIndices = index;

    // Extract coordinates from each geometry
    for (int i = 0; i < data.length; i++) {
      final geom = data[i];
      final originalIndex =
          originalIndices[i]; // Capture original index for this geometry
      if (geom is GeoJSONGeometry) {
        List<List<double>> coords = _extractCoordinates(geom);

        // Add coordinates and indices
        for (int j = 0; j < coords.length; j++) {
          var coord = coords[j];
          if (includeZ) {
            coordData
                .add([coord[0], coord[1], coord.length > 2 ? coord[2] : 0.0]);
          } else {
            coordData.add([coord[0], coord[1]]);
          }

          indices.add(
              originalIndex); // Use original index for this specific geometry
          partIndices.add(j);
        }
      } else {
        // Handle null geometries - add placeholder or skip
        // If we need to maintain a 1:1 correspondence in rows even for null geoms for some reason:
        // coordData.add(includeZ ? [double.nan, double.nan, double.nan] : [double.nan, double.nan]);
        // indices.add(originalIndex);
        // partIndices.add(0);
        // However, get_coordinates usually skips nulls.
      }
    }

    // Create column names
    List<String> columns = includeZ ? ['x', 'y', 'z'] : ['x', 'y'];

    // Create DataFrame
    DataFrame result;
    if (ignoreIndex) {
      // Use simple numeric index for the coordData length
      result = DataFrame(columns: columns, coordData);
    } else if (indexParts) {
      // Create multi-index using both original index and part index
      List<dynamic> multiIndex = List.generate(
          coordData.length, // Length of the actual coordinate data collected
          (k) => indexPartsAsList
              ? [indices[k], partIndices[k]]
              : (partIndices[k] == 0
                  ? "${indices[k]} ${partIndices[k]}"
                  : "  ${partIndices[k]}"
                      .padLeft("${indices[k]} ${partIndices[k]}".length + 1)));
      result = DataFrame(coordData, columns: columns, index: multiIndex);
    } else {
      // Use original geometry indices (flattened, corresponding to each coordinate)
      result = DataFrame(coordData, columns: columns, index: indices);
    }

    return result;
  }

  /// Returns a `Series` containing the count of coordinate pairs in each geometry.
  ///
  /// For Points, this is 1. For LineStrings, it's the number of vertices.
  /// For Polygons, it's the sum of vertices in all rings (exterior and interior).
  /// For Multi-geometries, it's the sum of coordinates in all component geometries.
  /// Null geometries are counted as 0.
  ///
  /// Returns:
  ///   (`Series<int>`): A Series where each value is the number of coordinate pairs
  ///   for the corresponding geometry in the GeoSeries. The Series will have the
  ///   same index as the original GeoSeries.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1, 1]),
  ///   GeoJSONLineString([[1, -1], [1, 0]]),
  ///   GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]], [[0.2,0.2],[0.8,0.2],[0.8,0.8],[0.2,0.8],[0.2,0.2]]]), // Polygon with 1 hole
  ///   null,
  /// ], name: 'geometries');
  /// final counts = series.countCoordinates;
  /// print(counts);
  /// // Output:
  /// // Series(name: geometries_coordinate_count, index: [0, 1, 2, 3], data: [1, 2, 10, 0])
  /// // Point: 1 coord
  /// // LineString: 2 coords
  /// // Polygon: 5 (exterior) + 5 (interior) = 10 coords
  /// // null: 0 coords
  /// ```
  Series<int> get countCoordinates {
    final counts = data.map((geom) {
      if (geom == null) return 0;
      if (geom is GeoJSONPoint) return 1;
      if (geom is GeoJSONMultiPoint) return geom.coordinates.length;
      if (geom is GeoJSONLineString) return geom.coordinates.length;
      if (geom is GeoJSONMultiLineString) {
        return geom.coordinates.fold<int>(0, (sum, line) => sum + line.length);
      }
      if (geom is GeoJSONPolygon) {
        return geom.coordinates.fold<int>(0, (sum, ring) => sum + ring.length);
      }
      if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.fold<int>(
            0,
            (sum, poly) =>
                sum +
                poly.fold<int>(0, (sumRing, ring) => sumRing + ring.length));
      }
      return 0;
    }).toList();
    return Series<int>(counts, name: '${name}_coordinate_count', index: index);
  }

  /// Returns a `Series` containing the number of geometries within each geometry.
  ///
  /// For simple geometries (Point, LineString, Polygon), this count is 1 (if the geometry is not null or empty in some contexts).
  /// For multi-part geometries (MultiPoint, MultiLineString, MultiPolygon), it's the number of individual
  /// geometries they contain. For GeometryCollection, it's the number of geometries in the collection.
  /// Null geometries are counted as 0.
  ///
  /// Returns:
  ///   (`Series<int>`): A Series where each value is the count of sub-geometries
  ///   for the corresponding geometry in the GeoSeries. The Series will have the
  ///   same index as the original GeoSeries.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1, 1]),
  ///   GeoJSONMultiPoint([[1,1], [2,2]]),
  ///   GeoJSONLineString([[1,-1],[1,0]]),
  ///   GeoJSONMultiPolygon([
  ///     [[[0,0],[0,1],[1,1],[1,0],[0,0]]], // One polygon
  ///     [[[2,2],[2,3],[3,3],[3,2],[2,2]]]  // Second polygon
  ///   ]),
  ///   null
  /// ], name: 'geometries');
  /// final counts = series.countGeometries;
  /// print(counts);
  /// // Output:
  /// // Series(name: geometries_geometry_count, index: [0, 1, 2, 3, 4], data: [1, 2, 1, 2, 0])
  /// // Point: 1
  /// // MultiPoint: 2
  /// // LineString: 1
  /// // MultiPolygon: 2
  /// // null: 0
  /// ```
  Series<int> get countGeometries {
    final counts = data.map((geom) {
      if (geom is GeoJSONMultiPoint) return geom.coordinates.length;
      if (geom is GeoJSONMultiLineString) return geom.coordinates.length;
      if (geom is GeoJSONMultiPolygon) return geom.coordinates.length;
      if (geom is GeoJSONGeometry) return 1;
      return 0; // Treat null as 0 geometries
    }).toList();
    return Series<int>(counts, name: '${name}_geometry_count', index: index);
  }

  /// Returns a `Series` containing the number of interior rings in each polygonal geometry.
  ///
  /// For Polygons, this is the number of rings minus one (the exterior ring).
  /// For MultiPolygons, this is the sum of interior rings across all component Polygons.
  /// For non-polygonal geometries or null geometries, the count is 0.
  ///
  /// Returns:
  ///   (`Series<int>`): A Series where each value is the count of interior rings
  ///   for the corresponding geometry. The Series shares the same index as the original GeoSeries.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]]]), // No interior rings
  ///   GeoJSONPolygon([
  ///     [[0,0],[0,5],[5,5],[5,0],[0,0]], // Exterior
  ///     [[1,1],[1,2],[2,2],[2,1],[1,1]], // Interior 1
  ///     [[3,3],[3,4],[4,4],[4,3],[3,3]]  // Interior 2
  ///   ]),
  ///   GeoJSONMultiPolygon([
  ///     [[[10,10],[10,11],[11,11],[11,10],[10,10]]], // Polygon 1, 0 interior rings
  ///     [
  ///       [[20,20],[20,25],[25,25],[25,20],[20,20]], // Polygon 2, exterior
  ///       [[21,21],[21,22],[22,22],[22,21],[21,21]]  // Polygon 2, 1 interior ring
  ///     ]
  ///   ]),
  ///   GeoJSONPoint([0,0]), // Not a polygon
  ///   null
  /// ], name: 'polygons');
  /// final interiorRingCounts = series.countInteriorRings;
  /// print(interiorRingCounts);
  /// // Output:
  /// // Series(name: polygons_interior_rings_count, index: [0, 1, 2, 3, 4], data: [0, 2, 1, 0, 0])
  /// ```
  Series<int> get countInteriorRings {
    final counts = data.map((geom) {
      if (geom == null) return 0;
      if (geom is GeoJSONPolygon) {
        return geom.coordinates.length > 1 ? geom.coordinates.length - 1 : 0;
      }
      if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.fold<int>(
            0, (sum, poly) => sum + (poly.length > 1 ? poly.length - 1 : 0));
      }
      return 0; // Non-polygonal or null geometries have 0 interior rings
    }).toList();
    return Series<int>(counts,
        name: '${name}_interior_rings_count', index: index);
  }

  /// Returns a `Series` of boolean values indicating if each geometry is closed.
  ///
  /// For LineStrings, this checks if the start and end points are coincident.
  /// For Polygons, the exterior and interior rings are inherently closed by definition if valid.
  /// This method primarily applies to LineStrings. For other geometry types, it typically returns false
  /// or depends on specific interpretations (e.g., a Polygon's rings are closed).
  /// Null geometries are considered not closed (false).
  ///
  /// Returns:
  ///   (`Series<bool>`): A Series of booleans, true if a geometry is closed, otherwise false.
  ///   The Series shares the same index as the original GeoSeries.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0,0], [1,1], [0,1], [0,0]]), // Closed
  ///   GeoJSONLineString([[0,0], [1,1]]),             // Not closed
  ///   GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]]]), // Considered closed by nature
  ///   null
  /// ], name: 'lines');
  /// final closedStatus = series.isClosed;
  /// print(closedStatus);
  /// // Output:
  /// // Series(name: lines_is_closed, index: [0, 1, 2, 3], data: [true, false, false, false])
  /// // Note: For Polygons, this specific `isClosed` often refers to the LineString property.
  /// // A valid Polygon's rings are inherently closed. The result here might be false
  /// // as it's checking the LineString-specific definition.
  /// ```
  Series<bool> get isClosed {
    final closedFlags = data.map((geom) {
      if (geom == null) return false;
      if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        if (coords.length < 2) return false;
        return _arePointsEqual(coords.first, coords.last);
      }
      return false;
    }).toList();
    return Series(closedFlags, name: '${name}_is_closed', index: index);
  }

  /// Returns a `Series` of boolean values indicating if each geometry is empty.
  ///
  /// A geometry is considered empty if it has no points or does not meet the minimum requirements
  /// for its type (e.g., a LineString with < 2 points, a Polygon's exterior ring with < 4 points).
  /// Following GeoPandas convention, a `null` geometry entry in the GeoSeries is *not* considered empty;
  /// it's treated as a non-existent geometry rather than an empty one, so it returns `false`.
  ///
  /// Returns:
  ///   (`Series<bool>`): A Series of booleans, true if a geometry is empty, otherwise false.
  ///   The Series shares the same index as the original GeoSeries.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([]),                             // Empty Point
  ///   GeoJSONLineString([[0,0]]),                   // Empty LineString (needs >= 2 points)
  ///   GeoJSONPolygon([[[0,0],[1,1],[0,1]]]),        // Empty Polygon (ring needs >= 4 points)
  ///   GeoJSONMultiPoint([]),                        // Empty MultiPoint
  ///   GeoJSONPoint([1,1]),                          // Non-empty Point
  ///   null                                          // Null geometry
  /// ], name: 'geometries');
  /// final emptyStatus = series.isEmpty;
  /// print(emptyStatus);
  /// // Output:
  /// // Series(name: geometries_is_empty, index: [0, 1, 2, 3, 4, 5], data: [true, true, true, true, false, false])
  /// ```
  Series<bool> get isEmpty {
    final emptyFlags = data.map((geom) {
      if (geom == null) {
        return false; // Consistent with GeoPandas: None is not empty.
      }
      return _isGeometryEmpty(geom); // Uses the internal helper
    }).toList();
    return Series<bool>(emptyFlags, name: '${name}_is_empty', index: index);
  }

  /// Returns a `Series` of boolean values indicating if each geometry is a ring.
  ///
  /// A geometry is considered a ring if it is a LineString that is:
  /// 1. Closed (its start and end points are coincident).
  /// 2. Simple (it does not intersect itself, though this implementation primarily checks for closure and point count).
  /// 3. Has at least 4 points (e.g., A-B-C-A).
  ///
  /// For other geometry types or null geometries, this returns false.
  /// Note: The simplicity check here is basic (closure and point count). For a more rigorous check,
  /// one might combine `isRing && isSimple`.
  ///
  /// Returns:
  ///   (`Series<bool>`): A Series of booleans, true if a geometry is a ring, otherwise false.
  ///   The Series shares the same index as the original GeoSeries.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0,0], [1,1], [0,1], [0,0]]), // Valid ring
  ///   GeoJSONLineString([[0,0], [1,1], [0,1]]),       // Not closed, not a ring
  ///   GeoJSONLineString([[0,0], [1,1], [0,0]]),         // Not enough distinct points (needs >= 4 total, 3 distinct for A-B-A)
  ///   GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]]]), // Not a LineString
  ///   null
  /// ], name: 'features');
  /// final ringStatus = series.isRing;
  /// print(ringStatus);
  /// // Output:
  /// // Series(name: features_is_ring, index: [0, 1, 2, 3, 4], data: [true, false, false, false, false])
  /// ```
  Series<bool> get isRing {
    final ringFlags = data.map((geom) {
      if (geom == null) return false;
      if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        if (coords.length < 4) {
          return false; // Ring needs at least 4 points (A-B-C-A)
        }
        return _arePointsEqual(coords.first, coords.last); // Check closure
      }
      return false; // Only LineStrings can be rings
    }).toList();
    return Series<bool>(ringFlags, name: '${name}_is_ring', index: index);
  }

  /// Returns a `Series` of boolean values indicating if each geometry is valid.
  ///
  /// A geometry is valid if it conforms to the geometric rules for its type (e.g., Polygons should not
  /// have self-intersecting rings, rings should be properly oriented, holes should be within the exterior).
  ///
  /// - Null geometries are considered invalid.
  /// - Empty geometries are considered invalid.
  /// - Polygon validation in this implementation is simplified:
  ///   - Checks if rings have at least 4 points and are closed.
  ///   - Basic check for duplicate points in rings.
  ///   - Does not currently perform full OGC validation (e.g., ring orientation, intersection checks between rings).
  /// - Other geometry types (Points, LineStrings, Multi-types) are generally considered valid if not null or empty,
  ///   though more sophisticated checks (like self-intersection for LineStrings) would be part of a full `isSimple` check.
  ///
  /// Returns:
  ///   (`Series<bool>`): A Series of booleans, true if a geometry is considered valid, otherwise false.
  ///   The Series shares the same index as the original GeoSeries.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1,1]),                                  // Valid
  ///   GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]]]),      // Valid (simple polygon)
  ///   GeoJSONPolygon([[[0,0],[1,1],[0,1]]]),                // Invalid (ring has < 4 points)
  ///   GeoJSONLineString([[0,0],[1,1],[0,0],[0,1]]),         // Potentially invalid if self-intersecting (valid by current simple check)
  ///   null,                                                 // Invalid (null)
  ///   GeoJSONPoint([])                                      // Invalid (empty)
  /// ], name: 'geometries');
  /// final validStatus = series.isValid;
  /// print(validStatus);
  /// // Output:
  /// // Series(name: geometries_is_valid, index: [0, 1, 2, 3, 4, 5], data: [true, true, false, true, false, false])
  /// ```
  Series<bool> get isValid {
    final validFlags = data.map((geom) {
      if (geom == null) return false;
      if (_isGeometryEmpty(geom)) {
        return false; // Empty geometries are not valid
      }

      if (geom is GeoJSONPolygon) {
        return isValidPolygon(geom.coordinates); // Simplified check
      } else if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty) return false;
        return geom.coordinates
            .every((polygonRings) => isValidPolygon(polygonRings));
      }
      // For types other than Polygon/MultiPolygon, if they are not empty and not null,
      // this basic `isValid` check considers them valid. More complex validity (e.g., LineString self-intersection)
      // would be part of `isSimple`.
      return true;
    }).toList();
    return Series<bool>(validFlags, name: '${name}_is_valid', index: index);
  }

  /// Returns a `Series` of boolean values indicating if each geometry has a Z-coordinate.
  ///
  /// This checks if the coordinates within the geometries include a third value (Z).
  /// For multi-part geometries, it typically checks the first coordinate of the first part.
  /// Null geometries are considered not to have a Z-coordinate (false).
  ///
  /// Returns:
  ///   (`Series<bool>`): A Series of booleans, true if a geometry has Z-coordinates, otherwise false.
  ///   The Series shares the same index as the original GeoSeries.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1, 2, 3]),       // Has Z
  ///   GeoJSONPoint([1, 2]),          // No Z
  ///   GeoJSONLineString([[1,2,3], [4,5,6]]), // Has Z
  ///   GeoJSONPolygon([[[1,2],[3,4],[5,6],[1,2]]]), // No Z
  ///   null
  /// ], name: 'geometries');
  /// final zStatus = series.hasZ;
  /// print(zStatus);
  /// // Output:
  /// // Series(name: geometries_has_z, index: [0, 1, 2, 3, 4], data: [true, false, true, false, false])
  /// ```
  Series<bool> get hasZ {
    final hasZFlags = data.map((geom) {
      if (geom == null) return false;
      if (geom is GeoJSONPoint) return geom.coordinates.length > 2;
      if (geom is GeoJSONMultiPoint) {
        return geom.coordinates.isNotEmpty && geom.coordinates[0].length > 2;
      }
      if (geom is GeoJSONLineString) {
        return geom.coordinates.isNotEmpty && geom.coordinates[0].length > 2;
      }
      if (geom is GeoJSONMultiLineString) {
        return geom.coordinates.isNotEmpty &&
            geom.coordinates[0].isNotEmpty &&
            geom.coordinates[0][0].length > 2;
      }
      if (geom is GeoJSONPolygon) {
        return geom.coordinates.isNotEmpty &&
            geom.coordinates[0].isNotEmpty &&
            geom.coordinates[0][0].length > 2;
      }
      if (geom is GeoJSONMultiPolygon) {
        return geom.coordinates.isNotEmpty &&
            geom.coordinates[0].isNotEmpty &&
            geom.coordinates[0][0].isNotEmpty &&
            geom.coordinates[0][0][0].length > 2;
      }
      return false; // Default if type doesn't match or structure is unexpected
    }).toList();
    return Series<bool>(hasZFlags, name: '${name}_has_z', index: index);
  }

  /// Returns a `DataFrame` containing the bounding box of each geometry.
  ///
  /// The DataFrame has columns `['minx', 'miny', 'maxx', 'maxy']`.
  /// Each row corresponds to a geometry in the GeoSeries and contains the minimum X,
  /// minimum Y, maximum X, and maximum Y coordinates that define the bounding box
  /// for that geometry.
  ///
  /// For empty or invalid geometries, or geometries where bounds cannot be determined
  /// (e.g., a Point with no coordinates, a LineString with < 2 points, an empty Polygon),
  /// a default bounding box of `[0.0, 0.0, 0.0, 0.0]` is returned.
  /// Null geometries also result in `[0.0, 0.0, 0.0, 0.0]`.
  ///
  /// The returned DataFrame retains the index of the original GeoSeries.
  ///
  /// Returns:
  ///   (DataFrame): A DataFrame with columns `['minx', 'miny', 'maxx', 'maxy']`
  ///   representing the bounding box of each geometry.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1, 2]),
  ///   GeoJSONLineString([[0, 0], [2, 3]]),
  ///   GeoJSONPolygon([[[0,0],[0,4],[4,4],[4,0],[0,0]]]),
  ///   null
  /// ], name: 'geometries', index: ['a', 'b', 'c', 'd']);
  /// final boundsDf = series.bounds;
  /// print(boundsDf);
  /// // Output:
  /// // DataFrame(columns: [minx, miny, maxx, maxy], index: [a, b, c, d], data:
  /// // [[1.0, 2.0, 1.0, 2.0],
  /// //  [0.0, 0.0, 2.0, 3.0],
  /// //  [0.0, 0.0, 4.0, 4.0],
  /// //  [0.0, 0.0, 0.0, 0.0]])
  /// ```
  DataFrame get bounds {
    final List<List<double>> boundsData = [];
    final List<dynamic> newIndex = [];

    for (int i = 0; i < data.length; i++) {
      final geom = data[i];
      final originalIdx = index[i];

      if (geom is GeoJSONPolygon &&
          (geom.coordinates.isEmpty ||
              geom.coordinates[0].isEmpty ||
              geom.coordinates[0].length < 4)) {
        boundsData.add([0.0, 0.0, 0.0, 0.0]);
      } else if (geom is GeoJSONLineString && geom.coordinates.length < 2) {
        boundsData.add([0.0, 0.0, 0.0, 0.0]);
      } else if (geom is GeoJSONPoint && geom.coordinates.isEmpty) {
        boundsData.add([0.0, 0.0, 0.0, 0.0]);
      } else if (geom is GeoJSONGeometry) {
        try {
          final bbox = geom.bbox ?? [0.0, 0.0, 0.0, 0.0];
          boundsData.add(bbox);
        } catch (e) {
          boundsData.add([0.0, 0.0, 0.0, 0.0]);
        }
      } else {
        boundsData.add([0.0, 0.0, 0.0, 0.0]);
      }
      newIndex.add(originalIdx);
    }
    return DataFrame(boundsData,
        columns: ['minx', 'miny', 'maxx', 'maxy'], index: newIndex);
  }

  /// Returns a `List<double>` representing the total bounding box of all geometries in the GeoSeries.
  ///
  /// The list contains four values: `[minx, miny, maxx, maxy]`, which are the
  /// overall minimum X, minimum Y, maximum X, and maximum Y coordinates that
  /// encompass all geometries in the series.
  ///
  /// Empty or invalid geometries, or those resulting in a `[0.0, 0.0, 0.0, 0.0]` individual bound,
  /// are generally ignored in the calculation unless they are the only geometries present.
  /// If the series is empty or all geometries result in `[0.0,0.0,0.0,0.0]` bounds,
  /// it returns `[0.0, 0.0, 0.0, 0.0]`.
  ///
  /// Returns:
  ///   (`List<double>`): A list of four doubles: `[minx, miny, maxx, maxy]`.
  ///
  /// Examples:
  /// ```dart
  /// final series1 = GeoSeries([
  ///   GeoJSONPoint([1, 2]),
  ///   GeoJSONLineString([[0, 0], [2, 3]]),
  /// ]);
  /// print(series1.totalBounds); // Output: [0.0, 0.0, 2.0, 3.0]
  ///
  /// final series2 = GeoSeries([
  ///   GeoJSONPolygon([[[0,0],[0,4],[4,4],[4,0],[0,0]]]),
  ///   GeoJSONPoint([-1, 5]),
  /// ]);
  /// print(series2.totalBounds); // Output: [-1.0, 0.0, 4.0, 5.0]
  ///
  /// final series3 = GeoSeries([null, GeoJSONPoint([])]); // Empty or null geoms
  /// print(series3.totalBounds); // Output: [0.0, 0.0, 0.0, 0.0]
  /// ```
  List<double> get totalBounds {
    List<double>? currentOverallBounds;
    for (var geom in data) {
      List<double> geomBounds;
      if (geom is GeoJSONPolygon &&
          (geom.coordinates.isEmpty ||
              geom.coordinates[0].isEmpty ||
              geom.coordinates[0].length < 4)) {
        geomBounds = [0.0, 0.0, 0.0, 0.0];
      } else if (geom is GeoJSONLineString && geom.coordinates.length < 2) {
        geomBounds = [0.0, 0.0, 0.0, 0.0];
      } else if (geom is GeoJSONPoint && geom.coordinates.isEmpty) {
        geomBounds = [0.0, 0.0, 0.0, 0.0];
      } else if (geom is GeoJSONGeometry) {
        try {
          geomBounds = geom.bbox ?? [0.0, 0.0, 0.0, 0.0];
        } catch (e) {
          geomBounds = [0.0, 0.0, 0.0, 0.0];
        }
      } else {
        geomBounds = [0.0, 0.0, 0.0, 0.0];
      }

      bool isEffectivelyEmpty = geomBounds[0] == 0 &&
          geomBounds[1] == 0 &&
          geomBounds[2] == 0 &&
          geomBounds[3] == 0;

      if (currentOverallBounds == null) {
        currentOverallBounds = List.from(geomBounds);
      } else {
        if (!isEffectivelyEmpty) {
          currentOverallBounds[0] = min(currentOverallBounds[0], geomBounds[0]);
          currentOverallBounds[1] = min(currentOverallBounds[1], geomBounds[1]);
          currentOverallBounds[2] = max(currentOverallBounds[2], geomBounds[2]);
          currentOverallBounds[3] = max(currentOverallBounds[3], geomBounds[3]);
        }
      }
    }
    return currentOverallBounds ?? [0.0, 0.0, 0.0, 0.0];
  }

  /// Computes the geometric centroid of each geometry in the GeoSeries.
  ///
  /// The centroid is a `GeoJSONPoint` representing the center of mass of the geometry.
  /// - For Points, the centroid is the point itself.
  /// - For LineStrings, it's the midpoint of the line (weighted by segment lengths if segments are unequal, though this implementation is a simple average of coordinates).
  /// - For Polygons, it's the center of mass of the polygon area.
  /// - For Multi-geometries, it's typically the centroid of the union of their components, or a weighted average of the centroids of their components.
  ///
  /// If a geometry is empty or its centroid cannot be computed (e.g., an empty LineString),
  /// a default `GeoJSONPoint([0, 0])` is returned for that geometry.
  /// Null geometries also result in `GeoJSONPoint([0,0])`.
  ///
  /// Returns:
  ///   (GeoSeries): A new GeoSeries containing `GeoJSONPoint` geometries representing the
  ///   centroids. The new series shares the same index and CRS as the original GeoSeries.
  ///   The name of the new series will be `original_name_centroid`.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1, 1]),
  ///   GeoJSONLineString([[0, 0], [2, 2]]),
  ///   GeoJSONPolygon([[[0,0],[0,4],[4,4],[4,0],[0,0]]]), // Centroid should be [2,2]
  ///   null
  /// ], name: 'features', index: ['a','b','c','d']);
  /// final centroids = series.centroid;
  /// print(centroids);
  /// // Output:
  /// // GeoSeries(name: features_centroid, crs: null, index: [a, b, c, d], data:
  /// // [GeoJSONPoint([1.0, 1.0]), GeoJSONPoint([1.0, 1.0]), GeoJSONPoint([2.0, 2.0]), GeoJSONPoint([0.0, 0.0])])
  /// // Note: LineString centroid here is a simple average of coordinates.
  /// ```
  GeoSeries get centroid {
    final centroids = data.map((geom) {
      if (geom == null) return GeoJSONPoint([0, 0]);
      if (geom is GeoJSONPoint) {
        return geom;
      } else if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isEmpty ||
            geom.coordinates[0].isEmpty ||
            geom.coordinates[0].length < 3) {
          return GeoJSONPoint([0, 0]);
        }
        final coords = geom.coordinates[0];
        double sumX = 0, sumY = 0;
        int numPoints = 0;
        for (int k = 0; k < coords.length - 1; k++) {
          sumX += coords[k][0];
          sumY += coords[k][1];
          numPoints++;
        }
        if (!_arePointsEqual(coords.first, coords.last) ||
            coords.length - 1 == 0) {
          if (coords.isNotEmpty && numPoints < coords.length) {
            sumX += coords.last[0];
            sumY += coords.last[1];
            numPoints++;
          }
        }
        if (numPoints == 0) return GeoJSONPoint([0, 0]);
        return GeoJSONPoint([sumX / numPoints, sumY / numPoints]);
      } else if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        if (coords.isEmpty) return GeoJSONPoint([0, 0]);
        double sumX = 0, sumY = 0;
        for (var point in coords) {
          sumX += point[0];
          sumY += point[1];
        }
        return GeoJSONPoint([sumX / coords.length, sumY / coords.length]);
      } else if (geom is GeoJSONMultiPoint) {
        final coords = geom.coordinates;
        if (coords.isEmpty) return GeoJSONPoint([0, 0]);
        double sumX = 0, sumY = 0;
        for (var point in coords) {
          sumX += point[0];
          sumY += point[1];
        }
        return GeoJSONPoint([sumX / coords.length, sumY / coords.length]);
      } else if (geom is GeoJSONMultiLineString) {
        final lineStrings = geom.coordinates;
        if (lineStrings.isEmpty) return GeoJSONPoint([0, 0]);
        double sumX = 0, sumY = 0;
        int totalPoints = 0;
        for (var lineString in lineStrings) {
          if (lineString.isEmpty) continue;
          for (var point in lineString) {
            sumX += point[0];
            sumY += point[1];
            totalPoints++;
          }
        }
        if (totalPoints > 0) {
          return GeoJSONPoint([sumX / totalPoints, sumY / totalPoints]);
        }
        return GeoJSONPoint([0, 0]);
      } else if (geom is GeoJSONMultiPolygon) {
        final polygons = geom.coordinates;
        if (polygons.isEmpty) return GeoJSONPoint([0, 0]);
        double totalArea = 0;
        double weightedSumX = 0;
        double weightedSumY = 0;
        for (var polygonRings in polygons) {
          if (polygonRings.isNotEmpty && polygonRings[0].length >= 3) {
            final coords = polygonRings[0];
            double sumX = 0, sumY = 0;
            int numPoints = 0;
            for (int k = 0; k < coords.length - 1; k++) {
              sumX += coords[k][0];
              sumY += coords[k][1];
              numPoints++;
            }
            if (!_arePointsEqual(coords.first, coords.last) ||
                coords.length - 1 == 0) {
              if (coords.isNotEmpty && numPoints < coords.length) {
                sumX += coords.last[0];
                sumY += coords.last[1];
                numPoints++;
              }
            }
            if (numPoints == 0) continue;
            final centroidX = sumX / numPoints;
            final centroidY = sumY / numPoints;
            final currentPolygonArea =
                _calculatePolygonAreaForCentroid(polygonRings);
            totalArea += currentPolygonArea;
            weightedSumX += centroidX * currentPolygonArea;
            weightedSumY += centroidY * currentPolygonArea;
          }
        }
        if (totalArea > 0) {
          return GeoJSONPoint(
              [weightedSumX / totalArea, weightedSumY / totalArea]);
        }
        return GeoJSONPoint([0, 0]);
      }
      return GeoJSONPoint([0, 0]);
    }).toList();
    return GeoSeries(centroids,
        name: '${name}_centroid', crs: crs, index: index);
  }

  /// Returns a `Series` containing the geometry type of each geometry in the GeoSeries.
  ///
  /// The geometry types are returned as strings, such as 'Point', 'LineString', 'Polygon',
  /// 'MultiPoint', 'MultiLineString', 'MultiPolygon', 'GeometryCollection'.
  /// If a geometry is null or its type cannot be determined, 'Unknown' is returned.
  ///
  /// Returns:
  ///   (`Series<String>`): A Series of strings representing the type of each geometry.
  ///   The Series shares the same index as the original GeoSeries.
  ///   The name of the new series will be `original_name_geom_type`.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1, 1]),
  ///   GeoJSONLineString([[0, 0], [2, 2]]),
  ///   GeoJSONPolygon([[[0,0],[0,4],[4,4],[4,0],[0,0]]]),
  ///   GeoJSONMultiPoint([]),
  ///   null
  /// ], name: 'features');
  /// final types = series.geomType;
  /// print(types);
  /// // Output:
  /// // Series(name: features_geom_type, index: [0, 1, 2, 3, 4], data: [Point, LineString, Polygon, MultiPoint, Unknown])
  /// ```
  Series<String> get geomType {
    final types = data.map((geom) {
      if (geom == null) return 'Unknown';
      if (geom is GeoJSONPoint) return 'Point';
      if (geom is GeoJSONMultiPoint) return 'MultiPoint';
      if (geom is GeoJSONLineString) return 'LineString';
      if (geom is GeoJSONMultiLineString) return 'MultiLineString';
      if (geom is GeoJSONPolygon) return 'Polygon';
      if (geom is GeoJSONMultiPolygon) return 'MultiPolygon';
      if (geom is GeoJSONGeometryCollection) return 'GeometryCollection';
      return 'Unknown'; // Should not happen with GeoJSONGeometry base type
    }).toList();
    return Series<String>(types, name: '${name}_geom_type', index: index);
  }

  /// Calculates the area of each polygonal geometry in the GeoSeries.
  ///
  /// The area is calculated in the units of the coordinate system.
  /// - For Polygons, it's the area of the exterior ring minus the area of any interior rings.
  /// - For MultiPolygons, it's the sum of the areas of all component Polygons.
  /// - For non-polygonal geometries (Points, LineStrings) and null geometries, the area is 0.0.
  ///
  /// Note: The calculation assumes planar geometry and uses the shoelace formula.
  ///
  /// Returns:
  ///   (`Series<double>`): A Series of doubles representing the area of each geometry.
  ///   The Series shares the same index as the original GeoSeries.
  ///   The name of the new series will be `original_name_area`.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPolygon([[[0,0],[0,2],[2,2],[2,0],[0,0]]]), // Area = 4.0
  ///   GeoJSONPolygon([ // Area = 4.0 (outer) - 1.0 (inner) = 3.0
  ///     [[0,0],[0,2],[2,2],[2,0],[0,0]],
  ///     [[0.5,0.5],[0.5,1.5],[1.5,1.5],[1.5,0.5],[0.5,0.5]]
  ///   ]),
  ///   GeoJSONPoint([1,1]), // Area = 0.0
  ///   null               // Area = 0.0
  /// ], name: 'shapes');
  /// final areas = series.area;
  /// print(areas);
  /// // Output:
  /// // Series(name: shapes_area, index: [0, 1, 2, 3], data: [4.0, 3.0, 0.0, 0.0])
  /// ```
  Series<double> get area {
    final areas = data.map((geom) {
      if (geom == null) return 0.0;
      if (geom is GeoJSONPolygon) {
        return _calculatePolygonArea(geom.coordinates);
      }
      if (geom is GeoJSONMultiPolygon) {
        double totalArea = 0;
        for (var polygon in geom.coordinates) {
          totalArea += _calculatePolygonArea(polygon);
        }
        return totalArea;
      }
      return 0.0; // Non-polygonal geometries have zero area
    }).toList();
    return Series<double>(areas, name: '${name}_area', index: index);
  }

  /// Returns a new `GeoSeries` containing the geometric boundaries of each geometry.
  ///
  /// The boundary of a geometry is defined as follows:
  /// - For Polygons: A MultiLineString representing the exterior and interior rings (or LineString if only one ring).
  ///   If the polygon is empty or invalid (e.g. < 4 points in a ring), an empty GeometryCollection is returned.
  /// - For LineStrings: A MultiPoint representing the start and end points. If the LineString is closed or has < 2 points,
  ///   an empty GeometryCollection is returned.
  /// - For Points and MultiPoints: An empty GeometryCollection (as they have no boundary).
  /// - For MultiLineStrings: A MultiPoint collection of the start and end points of all non-closed component LineStrings.
  /// - For MultiPolygons: A MultiLineString collection of all rings from all component Polygons.
  /// - For null geometries: An empty GeometryCollection.
  ///
  /// Returns:
  ///   (GeoSeries): A new GeoSeries where each geometry is the boundary of the corresponding
  ///   input geometry. The new series shares the same index and CRS.
  ///   The name of the new series will be `original_name_boundary`.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]]]),
  ///   GeoJSONLineString([[0,0],[1,1]]),
  ///   GeoJSONPoint([0,0]),
  ///   null
  /// ], name: 'items');
  /// final boundaries = series.boundary;
  /// print(boundaries.geomType); // To see the types of boundary geometries
  /// // Example output for types might be:
  /// // Series(name: items_boundary_geom_type, index: [0, 1, 2, 3], data: [LineString, MultiPoint, GeometryCollection, GeometryCollection])
  ///
  /// // Example of what a polygon boundary might look like:
  /// // For a simple polygon GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]]])
  /// // its boundary is GeoJSONLineString([[0,0],[0,1],[1,1],[1,0],[0,0]])
  ///
  /// // For a line GeoJSONLineString([[0,0],[1,1]])
  /// // its boundary is GeoJSONMultiPoint([[0,0],[1,1]])
  /// ```
  GeoSeries get boundary {
    final boundaries = data.map((geom) {
      if (geom == null) return GeoJSONGeometryCollection([]);
      if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isEmpty || geom.coordinates[0].length < 4) {
          return GeoJSONGeometryCollection([]);
        }
        if (geom.coordinates.length > 1) {
          final validRings =
              geom.coordinates.where((ring) => ring.length >= 4).toList();
          if (validRings.isEmpty) return GeoJSONGeometryCollection([]);
          // If only the exterior was valid and it was the only ring initially, return as LineString
          if (validRings.length == 1 &&
              geom.coordinates.length == 1 &&
              validRings[0] == geom.coordinates[0]) {
            return GeoJSONLineString(validRings[0]);
          }
          return GeoJSONMultiLineString(validRings);
        }
        return GeoJSONLineString(geom.coordinates[0]);
      } else if (geom is GeoJSONLineString) {
        final coords = geom.coordinates;
        if (coords.length < 2) return GeoJSONGeometryCollection([]);
        if (_arePointsEqual(coords.first, coords.last)) {
          return GeoJSONGeometryCollection([]);
        }
        return GeoJSONMultiPoint([coords.first, coords.last]);
      } else if (geom is GeoJSONPoint) {
        return GeoJSONGeometryCollection([]);
      } else if (geom is GeoJSONMultiPoint) {
        return GeoJSONGeometryCollection([]);
      } else if (geom is GeoJSONMultiLineString) {
        if (geom.coordinates.isEmpty) return GeoJSONGeometryCollection([]);
        List<List<double>> boundaryPoints = [];
        for (var lineStringCoords in geom.coordinates) {
          if (lineStringCoords.length < 2) continue;
          if (!_arePointsEqual(lineStringCoords.first, lineStringCoords.last)) {
            boundaryPoints.add(lineStringCoords.first);
            boundaryPoints.add(lineStringCoords.last);
          }
        }
        if (boundaryPoints.isEmpty) return GeoJSONGeometryCollection([]);
        return GeoJSONMultiPoint(boundaryPoints);
      } else if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty) return GeoJSONGeometryCollection([]);
        List<List<List<double>>> allRings = [];
        for (var polygonCoordList in geom.coordinates) {
          for (var ring in polygonCoordList) {
            if (ring.length >= 4) allRings.add(ring);
          }
        }
        if (allRings.isEmpty) return GeoJSONGeometryCollection([]);
        return GeoJSONMultiLineString(allRings);
      }
      return GeoJSONGeometryCollection([]);
    }).toList();
    return GeoSeries(boundaries,
        name: '${name}_boundary', crs: crs, index: index);
  }

  /// Returns a `Series` containing the length of each linear or polygonal geometry.
  ///
  /// The length is calculated in the units of the coordinate reference system (CRS).
  /// - For LineStrings: The sum of the lengths of its segments.
  /// - For MultiLineStrings: The sum of the lengths of all component LineStrings.
  /// - For Polygons: The length of its exterior ring. (Note: GeoPandas includes lengths of interior rings too, this version simplifies to exterior only for `geomLength` but full perimeter for `boundary` of polygon can be calculated).
  /// - For MultiPolygons: The sum of the lengths of the exterior rings of all component Polygons.
  /// - For Points and MultiPoints: The length is 0.0.
  /// - For GeometryCollections: The sum of lengths of its linear/polygonal components.
  /// - For null geometries: The length is 0.0.
  ///
  /// Returns:
  ///   (`Series<double>`): A Series of doubles representing the length of each geometry.
  ///   The Series shares the same index as the original GeoSeries.
  ///   The name of the new series will be `original_name_geom_length`.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0,0],[0,3]]), // Length = 3.0
  ///   GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]]]), // Perimeter of exterior = 4.0
  ///   GeoJSONMultiLineString([[[0,0],[1,0]], [[1,0],[1,1]]]), // Length = 1.0 + 1.0 = 2.0
  ///   GeoJSONPoint([1,1]), // Length = 0.0
  ///   null
  /// ], name: 'features');
  /// final lengths = series.geomLength;
  /// print(lengths);
  /// // Output:
  /// // Series(name: features_geom_length, index: [0, 1, 2, 3, 4], data: [3.0, 4.0, 2.0, 0.0, 0.0])
  /// ```
  Series<double> get geomLength {
    final lengths = data.map((geom) {
      if (geom == null) return 0.0;
      if (geom is GeoJSONLineString) {
        return _calculateLineStringLength(geom.coordinates);
      }
      if (geom is GeoJSONMultiLineString) {
        double totalLength = 0.0;
        for (var line in geom.coordinates) {
          totalLength += _calculateLineStringLength(line);
        }
        return totalLength;
      } else if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isNotEmpty && geom.coordinates[0].isNotEmpty) {
          return _calculateLineStringLength(geom.coordinates[0]);
        }
        return 0.0;
      } else if (geom is GeoJSONMultiPolygon) {
        double totalLength = 0.0;
        for (var polygon in geom.coordinates) {
          if (polygon.isNotEmpty && polygon[0].isNotEmpty) {
            totalLength += _calculateLineStringLength(polygon[0]);
          }
        }
        return totalLength;
      } else if (geom is GeoJSONGeometryCollection) {
        double totalLength = 0.0;
        for (var subGeom in geom.geometries) {
          final tempSeries = GeoSeries([subGeom], crs: crs);
          totalLength += tempSeries.geomLength.data[0] as double;
        }
        return totalLength;
      } else if (geom is GeoJSONPoint || geom is GeoJSONMultiPoint) {
        return 0.0;
      }
      return 0.0; // Default for non-linear/non-polygonal or unhandled types
    }).toList();
    return Series<double>(lengths, name: '${name}_geom_length', index: index);
  }

  /// Calculates the length of a LineString defined by a list of coordinates.
  ///
  /// Parameters:
  ///   - `coordinates`: (`List<List<double>>`) A list of coordinate pairs (e.g., `[[x1,y1],[x2,y2],...]`).
  ///
  /// Returns:
  ///   (double): The total length of the line segments. Returns 0.0 if there are fewer than 2 coordinates.
  double _calculateLineStringLength(List<List<double>> coordinates) {
    if (coordinates.length < 2) return 0.0;
    double length = 0.0;
    for (int i = 0; i < coordinates.length - 1; i++) {
      length += _distance(coordinates[i], coordinates[i + 1]);
    }
    return length;
  }

  /// Returns a `Series` of boolean values indicating if a LineString, LinearRing,
  /// or the exterior ring of a Polygon is oriented counter-clockwise (CCW).
  ///
  /// The orientation is determined by calculating the signed area of the ring.
  /// A positive area typically indicates CCW orientation.
  /// - For LineStrings and LinearRings: Checks if the ring is closed and has at least 4 points.
  /// - For Polygons: Checks the orientation of its exterior ring.
  /// - For other geometry types or invalid rings (not closed, < 4 points), it returns false.
  /// - Null geometries return false.
  ///
  /// Returns:
  ///   (`Series<bool>`): A Series of booleans, true if the geometry (or its exterior ring)
  ///   is counter-clockwise, otherwise false. Shares the original GeoSeries index.
  ///   Name will be `original_name_is_ccw`.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0,0],[1,1],[0,1],[0,0]]), // CCW (signed area > 0)
  ///   GeoJSONLineString([[0,0],[0,1],[1,1],[0,0]]), // CW (signed area < 0)
  ///   GeoJSONPolygon([[[0,0],[10,0],[10,10],[0,10],[0,0]]]), // Exterior CCW
  ///   GeoJSONLineString([[0,0],[1,1]]), // Not a ring
  ///   null
  /// ], name: 'shapes');
  /// final ccwStatus = series.isCCW;
  /// print(ccwStatus);
  /// // Output:
  /// // Series(name: shapes_is_ccw, index: [0, 1, 2, 3, 4], data: [true, false, true, false, false])
  /// ```
  Series<bool> get isCCW {
    final ccwFlags = data.map((geom) {
      if (geom == null) return false;
      List<List<double>>? coordsToCheck;
      if (geom is GeoJSONLineString) {
        coordsToCheck = geom.coordinates;
      } else if (geom is GeoJSONPolygon && geom.coordinates.isNotEmpty) {
        coordsToCheck = geom.coordinates[0]; // Check exterior ring of polygon
      }

      if (coordsToCheck != null) {
        if (coordsToCheck.length < 4 ||
            !_arePointsEqual(coordsToCheck.first, coordsToCheck.last)) {
          return false;
        }
        return _calculateSignedArea(coordsToCheck) > 0;
      }
      return false; // Default for non-applicable types or invalid rings
    }).toList();
    return Series<bool>(ccwFlags, name: '${name}_is_ccw', index: index);
  }

  /// Returns a `Series` of boolean values indicating whether each geometry in this GeoSeries
  /// contains the `other` geometry.
  ///
  /// The `contains` predicate is true if the `other` geometry is entirely within the
  /// boundaries of the geometry in this GeoSeries, and their boundaries do not touch.
  ///
  /// Parameters:
  ///   - `other`: (GeoJSONGeometry | GeoSeries)
  ///     The geometry or series of geometries to test for containment.
  ///     If `other` is a `GeoJSONGeometry`, each geometry in this GeoSeries is tested against it.
  ///     If `other` is a `GeoSeries`, an element-wise containment test is performed.
  ///     The `align` parameter controls how these series are matched.
  ///   - `align`: (bool, default: `true`)
  ///     If true and `other` is a `GeoSeries`, the operation aligns both GeoSeries based on their
  ///     index before performing the element-wise test. If false, or if indices are not aligned,
  ///     the operation is performed based on the order of geometries.
  ///     Currently, if `align` is true and lengths differ, it matches up to the shortest length.
  ///     Full index-based alignment is not yet implemented.
  ///
  /// Returns:
  ///   (`Series<bool>`): A Series of booleans indicating the result of the containment test
  ///   for each geometry. True if contained, false otherwise.
  ///   The Series shares the same index as this GeoSeries.
  ///   Name will be `original_name_contains`.
  ///
  /// Note:
  ///   The current implementation of `_containsGeometry` is simplified and may not cover all
  ///   complex geometric cases or OGC standards perfectly (e.g., complex interactions with holes,
  ///   multi-component geometries). It primarily handles:
  ///   - Polygon containing Point (checks exterior and holes).
  ///   - Point containing Point (equality).
  ///   - LineString containing Point (point on line).
  ///   - Basic LineString containing LineString (all points of other on this).
  ///   - Basic Polygon containing LineString (all points of other in this).
  ///   - Basic Polygon containing Polygon (all points of other's exterior in this).
  ///   - Simplified fallback for MultiGeometries (checks first component).
  ///   Empty or null geometries generally result in false.
  ///
  /// Examples:
  /// ```dart
  /// final polygon = GeoJSONPolygon([[[0,0],[0,5],[5,5],[5,0],[0,0]]]);
  /// final pointIn = GeoJSONPoint([1,1]);
  /// final pointOut = GeoJSONPoint([6,6]);
  /// final lineIn = GeoJSONLineString([[1,1],[2,2]]);
  ///
  /// final series = GeoSeries([polygon, GeoJSONPoint([10,10])], name: 'areas');
  ///
  /// // Test against a single geometry
  /// print(series.contains(pointIn));
  /// // Output: Series(name: areas_contains, index: [0, 1], data: [true, false])
  ///
  /// final otherSeries = GeoSeries([pointIn, pointOut], name: 'points');
  /// print(series.contains(otherSeries)); // Element-wise
  /// // Output: Series(name: areas_contains, index: [0, 1], data: [true, false])
  /// ```
  Series<bool> contains(dynamic other, {bool align = true}) {
    if (other is GeoJSONGeometry) {
      final result = data.map((g) => _containsGeometry(g, other)).toList();
      return Series<bool>(result, name: '${name}_contains', index: index);
    } else if (other is GeoSeries) {
      // Simplified positional for now if align is true but indices differ or not handled
      if (align && length != other.length) {
        // This warning should be refined when proper alignment is added
        print(
            "Warning: GeoSeries.contains with align=true and different lengths is using positional matching up to shortest length. Full index-based alignment is not yet implemented.");
      }
      List<bool> resultData = [];
      int len =
          min(length, other.length); // Process up to the shorter length for now
      for (int i = 0; i < len; ++i) {
        // TO BE DONE: Implement proper index alignment if align is true
        resultData.add(_containsGeometry(data[i], other.data[i]));
      }
      // For remaining elements in `this` series if it's longer
      for (int i = len; i < length; ++i) {
        resultData.add(false);
      }
      // If `other` was longer, its extra elements are ignored in this simplified model
      return Series<bool>(resultData, name: '${name}_contains', index: index);
    }
    throw ArgumentError(
        "Other must be GeoJSONGeometry or GeoSeries, but was ${other.runtimeType}");
  }

  /// Helper method to check if geometry `geom1` contains geometry `geom2`.
  ///
  /// Parameters:
  ///   - `geom1`: The potential container geometry.
  ///   - `geom2`: The potential contained geometry.
  ///
  /// Returns:
  ///   (bool): True if `geom1` contains `geom2`, false otherwise.
  ///
  /// Note: This is a simplified implementation. See `contains()` docstring for details.
  bool _containsGeometry(GeoJSONGeometry? geom1, GeoJSONGeometry? geom2) {
    if (geom1 == null || geom2 == null) return false;
    if (_isGeometryEmpty(geom1) || _isGeometryEmpty(geom2)) return false;

    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPoint) {
      if (geom1.coordinates.isEmpty || geom1.coordinates[0].length < 4) {
        return false;
      }
      // Point in polygon (exterior)
      if (!_pointInPolygon(geom2.coordinates, geom1.coordinates[0])) {
        return false;
      }
      // Point not in any hole
      for (int i = 1; i < geom1.coordinates.length; i++) {
        if (_pointInPolygon(geom2.coordinates, geom1.coordinates[i])) {
          return false;
        }
      }
      return true;
    }
    if (geom1 is GeoJSONPoint && geom2 is GeoJSONPoint) {
      return _arePointsEqual(geom1.coordinates, geom2.coordinates);
    }
    if (geom1 is GeoJSONLineString && geom2 is GeoJSONPoint) {
      if (geom1.coordinates.length < 2) return false;
      return _pointOnLine(geom2.coordinates, geom1.coordinates);
    }
    // Basic LineString contains LineString (all points of geom2 on geom1)
    if (geom1 is GeoJSONLineString && geom2 is GeoJSONLineString) {
      if (geom1.coordinates.length < 2 || geom2.coordinates.length < 2) {
        return false;
      }
      return geom2.coordinates.every((p) => _pointOnLine(p, geom1.coordinates));
    }
    // Polygon contains LineString: all points of LineString must be in Polygon
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONLineString) {
      if (geom1.coordinates.isEmpty ||
          geom1.coordinates[0].length < 4 ||
          geom2.coordinates.length < 2) {
        return false;
      }
      return geom2.coordinates
          .every((p) => _containsGeometry(geom1, GeoJSONPoint(p)));
    }
    // Polygon contains Polygon: all points of geom2's exterior ring must be in geom1.
    // This is a simplification and doesn't handle all edge cases (e.g. shared boundaries, holes).
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPolygon) {
      if (geom1.coordinates.isEmpty ||
          geom1.coordinates[0].length < 4 ||
          geom2.coordinates.isEmpty ||
          geom2.coordinates[0].length < 4) {
        return false;
      }
      return geom2.coordinates[0]
          .every((p) => _containsGeometry(geom1, GeoJSONPoint(p)));
    }

    // Fallback for MultiGeometries (simplified: check first component)
    if (geom1 is GeoJSONMultiPoint && geom1.coordinates.isNotEmpty) {
      return _containsGeometry(GeoJSONPoint(geom1.coordinates[0]), geom2);
    }
    if (geom1 is GeoJSONMultiLineString &&
        geom1.coordinates.isNotEmpty &&
        geom1.coordinates[0].isNotEmpty) {
      return _containsGeometry(GeoJSONLineString(geom1.coordinates[0]), geom2);
    }
    if (geom1 is GeoJSONMultiPolygon &&
        geom1.coordinates.isNotEmpty &&
        geom1.coordinates[0].isNotEmpty) {
      return _containsGeometry(GeoJSONPolygon(geom1.coordinates[0]), geom2);
    }

    return false;
  }

  /// Helper method to check if a geometry is considered empty.
  ///
  /// Parameters:
  ///   - `geom`: The geometry to check.
  ///
  /// Returns:
  ///   (bool): True if the geometry is empty, false otherwise.
  ///   A `null` input is considered empty by this helper.
  ///
  /// Emptiness rules:
  /// - Point: `coordinates` list is empty.
  /// - MultiPoint: `coordinates` list is empty.
  /// - LineString: `coordinates` list has fewer than 2 points.
  /// - MultiLineString: `coordinates` list is empty, or all component LineStrings are empty.
  /// - Polygon: `coordinates` list is empty, or its exterior ring (`coordinates[0]`) has fewer than 4 points.
  /// - MultiPolygon: `coordinates` list is empty, or all component Polygons are empty.
  /// - GeometryCollection: `geometries` list is empty, or all component geometries are empty.
  bool _isGeometryEmpty(GeoJSONGeometry? geom) {
    if (geom == null) {
      return true; // Internal helper treats null as leading to emptiness
    }
    if (geom is GeoJSONPoint) return geom.coordinates.isEmpty;
    if (geom is GeoJSONMultiPoint) return geom.coordinates.isEmpty;
    if (geom is GeoJSONLineString) return geom.coordinates.length < 2;
    if (geom is GeoJSONMultiLineString) {
      return geom.coordinates.isEmpty ||
          geom.coordinates.every((l) => l.length < 2);
    }
    if (geom is GeoJSONPolygon) {
      return geom.coordinates.isEmpty || geom.coordinates[0].length < 4;
    }
    if (geom is GeoJSONMultiPolygon) {
      return geom.coordinates.isEmpty ||
          geom.coordinates.every((p) => p.isEmpty || p[0].length < 4);
    }
    if (geom is GeoJSONGeometryCollection) {
      return geom.geometries.isEmpty ||
          geom.geometries.every((g) => _isGeometryEmpty(g));
    }
    return true;
  }

  /// Check if a point is inside a polygon ring using the ray casting algorithm
  bool _pointInPolygon(List<double> point, List<List<double>> polygonRing) {
    bool inside = false;
    double x = point[0];
    double y = point[1];
    if (polygonRing.length < 4) return false; // Not a valid ring

    for (int i = 0, j = polygonRing.length - 1;
        i < polygonRing.length;
        j = i++) {
      double xi = polygonRing[i][0];
      double yi = polygonRing[i][1];
      double xj = polygonRing[j][0];
      double yj = polygonRing[j][1];
      bool intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// Check if a point is on a line segment list
  bool _pointOnLine(List<double> pointCoords, List<List<double>> lineCoords) {
    if (lineCoords.length < 2) return false;
    for (int i = 0; i < lineCoords.length - 1; i++) {
      if (_pointToLineSegmentDistance(
              pointCoords, lineCoords[i], lineCoords[i + 1]) <
          1e-9) {
        return true;
      }
    }
    return false;
  }

  /// Calculate Euclidean distance between two points
  double _distance(List<double> p1, List<double> p2) {
    if (p1.isEmpty || p2.isEmpty || p1.length < 2 || p2.length < 2) {
      return double.nan;
    }
    double dx = p1[0] - p2[0];
    double dy = p1[1] - p2[1];
    return sqrt(dx * dx + dy * dy);
  }

  /// Helper function to check if two points are equal (within a small tolerance)
  bool _arePointsEqual(List<double> p1, List<double> p2,
      {double epsilon = 1e-9}) {
    if (p1.length != p2.length || p1.length < 2) return false;
    for (int i = 0; i < p1.length; i++) {
      if ((p1[i] - p2[i]).abs() > epsilon) return false;
    }
    return true;
  }

  /// Calculates the signed area of a closed ring (polygon or linestring).
  /// The sign indicates orientation (e.g., positive for CCW, negative for CW).
  /// Uses the shoelace formula.
  ///
  /// Parameters:
  ///   - `coords`: (`List<List<double>>`) A list of coordinate pairs forming a closed ring.
  ///     The first and last points should ideally be the same.
  ///
  /// Returns:
  ///   (double): The signed area. Returns 0.0 if the ring has fewer than 3 coordinates.
  double _calculateSignedArea(List<List<double>> coords) {
    if (coords.isEmpty || coords.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < coords.length - 1; i++) {
      area +=
          (coords[i][0] * coords[i + 1][1]) - (coords[i + 1][0] * coords[i][1]);
    }
    area += (coords[coords.length - 1][0] * coords[0][1]) -
        (coords[0][0] * coords[coords.length - 1][1]);
    return area / 2.0;
  }

  /// Calculates the absolute area of a single polygon ring using the Shoelace formula.
  ///
  /// Parameters:
  ///   - `ringCoordinates`: (`List<List<double>>`) A list of coordinate pairs forming a ring.
  ///     It's assumed to be closed and have at least 4 points for a valid area.
  ///
  /// Returns:
  ///   (double): The absolute area of the ring. Returns 0.0 if the ring has fewer than 4 coordinates.
  double _calculateRingArea(List<List<double>> ringCoordinates) {
    if (ringCoordinates.length < 4) {
      return 0.0; // A ring needs at least 4 points (A-B-C-A)
    }
    return _calculateSignedArea(ringCoordinates).abs();
  }

  /// Returns a new `GeoSeries` containing the exterior ring of each polygonal geometry.
  ///
  /// - For Polygons: Returns a `GeoJSONLineString` representing the exterior ring.
  ///   If the polygon is empty or its exterior ring is invalid (< 4 points), an empty `GeoJSONGeometryCollection` is returned.
  /// - For MultiPolygons: Returns a `GeoJSONMultiLineString` containing the exterior rings of all
  ///   component polygons. If a component polygon is empty/invalid, its exterior is skipped.
  ///   If only one valid exterior ring is found, it's returned as a `GeoJSONLineString`.
  ///   If no valid exterior rings are found, or the MultiPolygon is empty, an empty `GeoJSONGeometryCollection` is returned.
  /// - For non-polygonal geometries (Points, LineStrings) and null geometries: Returns an empty `GeoJSONGeometryCollection`.
  ///
  /// Returns:
  ///   (GeoSeries): A new GeoSeries where each geometry is the exterior ring (or collection of rings)
  ///   of the corresponding input polygonal geometry. Shares the original index and CRS.
  ///   Name will be `original_name_exterior`.
  ///
  /// Examples:
  /// ```dart
  /// final poly = GeoJSONPolygon([
  ///   [[0,0],[0,2],[2,2],[2,0],[0,0]], // Exterior
  ///   [[0.5,0.5],[0.5,1.5],[1.5,1.5],[1.5,0.5],[0.5,0.5]] // Interior
  /// ]);
  /// final multiPoly = GeoJSONMultiPolygon([
  ///   [[[10,10],[10,12],[12,12],[12,10],[10,10]]],
  ///   [[[20,20],[20,22],[22,22],[22,20],[20,20]]]
  /// ]);
  /// final series = GeoSeries([poly, multiPoly, GeoJSONPoint([0,0])], name: 'polys');
  /// final exteriors = series.exterior;
  /// print(exteriors.geomType);
  /// // Output:
  /// // Series(name: polys_exterior_geom_type, index: [0, 1, 2], data: [LineString, MultiLineString, GeometryCollection])
  ///
  /// print(exteriors.data[0]); // GeoJSONLineString for poly's exterior
  /// ```
  GeoSeries get exterior {
    final exteriors = data.map((geom) {
      if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isNotEmpty && geom.coordinates[0].length >= 4) {
          return GeoJSONLineString(geom.coordinates[0]);
        }
        return GeoJSONGeometryCollection([]); // Invalid or empty polygon
      } else if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty) return GeoJSONGeometryCollection([]);
        List<List<List<double>>> exteriorRings = [];
        for (var polygonCoords in geom.coordinates) {
          if (polygonCoords.isNotEmpty && polygonCoords[0].length >= 4) {
            exteriorRings.add(polygonCoords[0]);
          }
        }
        if (exteriorRings.isEmpty) return GeoJSONGeometryCollection([]);
        if (exteriorRings.length == 1) {
          return GeoJSONLineString(exteriorRings[0]); // Single valid exterior
        }
        return GeoJSONMultiLineString(exteriorRings);
      }
      return GeoJSONGeometryCollection([]); // Not a Polygon or MultiPolygon
    }).toList();
    return GeoSeries(exteriors,
        name: '${name}_exterior', crs: crs, index: index);
  }

  /// Returns a `Series` where each element is a list of `GeoJSONLineString` geometries
  /// representing the interior rings (holes) of each polygonal geometry.
  ///
  /// - For Polygons: Returns a list containing `GeoJSONLineString`s for each interior ring.
  ///   If there are no interior rings, an empty list is returned.
  /// - For MultiPolygons: Returns a list containing `GeoJSONLineString`s for all interior rings
  ///   from all component polygons.
  /// - For non-polygonal geometries and null geometries: An empty list is returned.
  ///
  /// Each `GeoJSONLineString` in the list represents one interior ring.
  ///
  /// Returns:
  ///   (`Series<List<GeoJSONLineString>>`): A Series where each item is a list of `GeoJSONLineString`s.
  ///   Shares the original index. Name will be `original_name_interiors`.
  ///
  /// Examples:
  /// ```dart
  /// final polyWithHole = GeoJSONPolygon([
  ///   [[0,0],[0,5],[5,5],[5,0],[0,0]], // Exterior
  ///   [[1,1],[1,2],[2,2],[2,1],[1,1]]  // Interior 1
  /// ]);
  /// final simplePoly = GeoJSONPolygon([[[10,10],[10,11],[11,11],[11,10],[10,10]]]);
  /// final series = GeoSeries([polyWithHole, simplePoly, GeoJSONPoint([0,0])], name: 'features');
  /// final interiorsSeries = series.interiors;
  ///
  /// print(interiorsSeries.data[0].length); // Output: 1 (one interior ring for polyWithHole)
  /// print(interiorsSeries.data[0][0] is GeoJSONLineString); // Output: true
  /// print(interiorsSeries.data[1].length); // Output: 0 (no interior rings for simplePoly)
  /// print(interiorsSeries.data[2].length); // Output: 0 (Point has no interiors)
  /// ```
  Series<List<GeoJSONLineString>> get interiors {
    final allInteriors = data.map((geom) {
      List<GeoJSONLineString> interiorLineStrings = [];
      if (geom is GeoJSONPolygon) {
        if (geom.coordinates.length > 1) {
          // Has interior rings
          for (int i = 1; i < geom.coordinates.length; i++) {
            if (geom.coordinates[i].length >= 4) {
              // Valid ring
              interiorLineStrings.add(GeoJSONLineString(geom.coordinates[i]));
            }
          }
        }
      } else if (geom is GeoJSONMultiPolygon) {
        for (var polygonCoords in geom.coordinates) {
          if (polygonCoords.length > 1) {
            // This polygon has interior rings
            for (int i = 1; i < polygonCoords.length; i++) {
              if (polygonCoords[i].length >= 4) {
                // Valid ring
                interiorLineStrings.add(GeoJSONLineString(polygonCoords[i]));
              }
            }
          }
        }
      }
      return interiorLineStrings;
    }).toList();
    return Series<List<GeoJSONLineString>>(allInteriors,
        name: '${name}_interiors', index: index);
  }

  /// Returns a `Series` containing the x-coordinate of each Point geometry.
  ///
  /// For non-Point geometries or Points with no coordinates, `double.nan` is returned.
  ///
  /// Returns:
  ///   (`Series<double>`): A Series of x-coordinates. Shares the original index.
  ///   Name will be `original_name_x`.
  ///
  /// Example:
  /// ```dart
  /// final series = GeoSeries([GeoJSONPoint([10, 20]), GeoJSONLineString([[0,0],[1,1]]), null]);
  /// print(series.x);
  /// // Output: Series(name: _x, index: [0, 1, 2], data: [10.0, NaN, NaN])
  /// ```
  Series<double> get x {
    final values = data.map((geom) {
      if (geom is GeoJSONPoint && geom.coordinates.isNotEmpty) {
        return geom.coordinates[0];
      }
      return double.nan;
    }).toList();
    return Series<double>(values, name: '${name}_x', index: index);
  }

  /// Returns a `Series` containing the y-coordinate of each Point geometry.
  ///
  /// For non-Point geometries or Points with fewer than 2 coordinates, `double.nan` is returned.
  ///
  /// Returns:
  ///   (`Series<double>`): A Series of y-coordinates. Shares the original index.
  ///   Name will be `original_name_y`.
  ///
  /// Example:
  /// ```dart
  /// final series = GeoSeries([GeoJSONPoint([10, 20]), GeoJSONPoint([5]), null]);
  /// print(series.y);
  /// // Output: Series(name: _y, index: [0, 1, 2], data: [20.0, NaN, NaN])
  /// ```
  Series<double> get y {
    final values = data.map((geom) {
      if (geom is GeoJSONPoint && geom.coordinates.length > 1) {
        return geom.coordinates[1];
      }
      return double.nan;
    }).toList();
    return Series<double>(values, name: '${name}_y', index: index);
  }

  /// Returns a `Series` containing the z-coordinate of each Point geometry.
  ///
  /// For non-Point geometries or Points with fewer than 3 coordinates (i.e., no z-value),
  /// `double.nan` is returned.
  ///
  /// Returns:
  ///   (`Series<double>`): A Series of z-coordinates. Shares the original index.
  ///   Name will be `original_name_z`.
  ///
  /// Example:
  /// ```dart
  /// final series = GeoSeries([GeoJSONPoint([10, 20, 30]), GeoJSONPoint([5, 15]), null]);
  /// print(series.z);
  /// // Output: Series(name: _z, index: [0, 1, 2], data: [30.0, NaN, NaN])
  /// ```
  Series<double> get z {
    final values = data.map((geom) {
      if (geom is GeoJSONPoint && geom.coordinates.length > 2) {
        return geom.coordinates[2];
      }
      return double.nan;
    }).toList();
    return Series<double>(values, name: '${name}_z', index: index);
  }

  /// Returns a `GeoSeries` of points that are guaranteed to be within each geometry.
  /// These points may not be the geometric centroid.
  ///
  /// - For Points, it's the point itself.
  /// - For LineStrings, it's typically the first coordinate.
  /// - For Polygons, it's a point calculated from its exterior ring's coordinates (often an average, not necessarily the true centroid or a point on surface).
  /// - For Multi-geometries, it's typically a representative point from their first component geometry.
  /// - For empty or null geometries, an empty `GeoJSONGeometryCollection` is returned.
  ///
  /// Note: The "representative point" from GEOS (which GeoPandas uses) is more sophisticated, often ensuring
  /// the point is on the surface. This implementation is a simpler version.
  ///
  /// Returns:
  ///   (GeoSeries): A GeoSeries of `GeoJSONPoint` (or `GeoJSONGeometryCollection` for empty/null inputs)
  ///   representing a point within each geometry. Shares original index and CRS.
  ///   Name will be `original_name_representative_point`.
  ///
  /// Example:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONLineString([[0,0],[2,2],[2,0]]),
  ///   GeoJSONPolygon([[[0,0],[0,4],[4,4],[4,0],[0,0]]]),
  ///   null
  /// ], name: 'geoms');
  /// final repPoints = series.representativePoint;
  /// print(repPoints);
  /// // Example Output (points might vary based on exact implementation):
  /// // GeoSeries(name: geoms_representative_point, crs: null, index: [0, 1, 2], data:
  /// // [GeoJSONPoint([0.0, 0.0]), GeoJSONPoint([2.0, 2.0]), GeoJSONGeometryCollection([])])
  /// ```
  GeoSeries get representativePoint {
    final points = data.map((geom) {
      if (geom == null || _isGeometryEmpty(geom)) {
        return GeoJSONGeometryCollection(
            []); // Return empty collection for null or empty
      }
      if (geom is GeoJSONPoint) return geom;
      if (geom is GeoJSONLineString) return GeoJSONPoint(geom.coordinates[0]);
      if (geom is GeoJSONPolygon) {
        final coords = geom.coordinates[0];
        double sumX = 0, sumY = 0;
        int numPoints = 0;
        for (int k = 0; k < coords.length - 1; k++) {
          sumX += coords[k][0];
          sumY += coords[k][1];
          numPoints++;
        }
        if (!_arePointsEqual(coords.first, coords.last) ||
            coords.length - 1 == 0) {
          if (coords.isNotEmpty && numPoints < coords.length) {
            sumX += coords.last[0];
            sumY += coords.last[1];
            numPoints++;
          }
        }
        if (numPoints == 0) return GeoJSONGeometryCollection([]);
        return GeoJSONPoint([sumX / numPoints, sumY / numPoints]);
      }
      if (geom is GeoJSONMultiPoint && geom.coordinates.isNotEmpty) {
        return GeoJSONPoint(geom.coordinates[0]);
      }
      if (geom is GeoJSONMultiLineString &&
          geom.coordinates.isNotEmpty &&
          geom.coordinates[0].isNotEmpty) {
        return GeoJSONPoint(geom.coordinates[0][0]);
      }
      if (geom is GeoJSONMultiPolygon &&
          geom.coordinates.isNotEmpty &&
          geom.coordinates[0].isNotEmpty &&
          geom.coordinates[0][0].isNotEmpty) {
        final coords = geom.coordinates[0][0];
        double sumX = 0, sumY = 0;
        int numPoints = 0;
        for (int k = 0; k < coords.length - 1; k++) {
          sumX += coords[k][0];
          sumY += coords[k][1];
          numPoints++;
        }
        if (!_arePointsEqual(coords.first, coords.last) ||
            coords.length - 1 == 0) {
          if (coords.isNotEmpty && numPoints < coords.length) {
            sumX += coords.last[0];
            sumY += coords.last[1];
            numPoints++;
          }
        }
        if (numPoints == 0) return GeoJSONGeometryCollection([]);
        return GeoJSONPoint([sumX / numPoints, sumY / numPoints]);
      }
      return GeoJSONGeometryCollection([]);
    }).toList();
    return GeoSeries(points,
        name: '${name}_representative_point', crs: crs, index: index);
  }

  /// Internal helper to round a double value to a specified grid size or number of decimal places.
  ///
  /// Parameters:
  ///   - `value`: The double value to round.
  ///   - `gridSize`: The grid size. If `gridSize` is, for example, 0.1, the value will be rounded to one decimal place.
  ///     If `gridSize` is 10, the value will be rounded to the nearest multiple of 10.
  ///     If `gridSize` is 0.0, no rounding is performed.
  ///     Special handling for `gridSize` like 0.01, 0.001 for decimal places.
  ///
  /// Returns:
  ///   (double): The rounded value.
  double _roundToPrecision(double value, double gridSize) {
    if (gridSize <= 0) {
      return value; // No rounding for zero or negative grid size
    }
    if (gridSize == 1.0) {
      return value.roundToDouble(); // Simple rounding to nearest integer
    }

    // Determine decimal places if gridSize is like 0.1, 0.01, etc.
    int decimalPlaces = 0;
    if (gridSize > 0 && gridSize < 1) {
      String s =
          gridSize.toStringAsFixed(10); // Avoid scientific notation issues
      int dotIndex = s.indexOf('.');
      if (dotIndex != -1) {
        String fraction = s.substring(dotIndex + 1);
        bool isPowerOfTen = true;
        for (int i = 0; i < fraction.length; ++i) {
          if (i < fraction.length - 1 && fraction[i] != '0') {
            isPowerOfTen = false;
            break;
          }
          if (i == fraction.length - 1 && fraction[i] != '1') {
            isPowerOfTen = false;
            break;
          }
          if (fraction[i] == '0') {
            decimalPlaces++;
          } else if (fraction[i] == '1') {
            decimalPlaces++; // Count the '1' as a decimal place
            break; // Stop after the '1'
          }
        }
        if (!isPowerOfTen) {
          // If not a clean power of ten (e.g., 0.25), use general rounding
          return (value / gridSize).round() * gridSize;
        }
      } else {
        // Should not happen for gridSize > 0 and < 1 if it's a valid number
        return (value / gridSize).round() * gridSize;
      }
    } else if (gridSize > 1) {
      // For grid sizes like 10, 100, etc.
      return (value / gridSize).round() * gridSize;
    }
    // This part handles decimalPlaces determined above
    double multiplier = pow(10, decimalPlaces).toDouble();
    return (value * multiplier).round() / multiplier;
  }

  /// Internal helper to round a single coordinate (list of doubles) to a specified grid size.
  ///
  /// Parameters:
  ///   - `coord`: The coordinate (e.g., `[x, y]` or `[x, y, z]`).
  ///   - `gridSize`: The grid size for rounding each ordinate.
  ///
  /// Returns:
  ///   (`List<double>`): The rounded coordinate.
  List<double> _roundCoordinate(List<double> coord, double gridSize) {
    return coord.map((val) => _roundToPrecision(val, gridSize)).toList();
  }

  /// Internal helper to round a list of coordinates.
  List<List<double>> _roundCoordinatesList(
      List<List<double>> coordsList, double gridSize) {
    return coordsList
        .map((coord) => _roundCoordinate(coord, gridSize))
        .toList();
  }

  /// Internal helper to round a list of lists of coordinates (e.g., for Polygons, MultiLineStrings).
  List<List<List<double>>> _roundCoordinatesListList(
      List<List<List<double>>> coordsListList, double gridSize) {
    return coordsListList
        .map((coordsList) => _roundCoordinatesList(coordsList, gridSize))
        .toList();
  }

  /// Internal helper to round a list of lists of lists of coordinates (e.g., for MultiPolygons).
  List<List<List<List<double>>>> _roundCoordinatesListListList(
      List<List<List<List<double>>>> coordsListListList, double gridSize) {
    return coordsListListList
        .map((coordsListList) =>
            _roundCoordinatesListList(coordsListList, gridSize))
        .toList();
  }

  /// Returns a new `GeoSeries` with all coordinate values rounded to a specified `gridSize`.
  ///
  /// The `gridSize` determines the precision of the output coordinates.
  /// - If `gridSize` is 0, no rounding occurs.
  /// - If `gridSize` is, for example, 0.1, coordinates will be rounded to one decimal place.
  /// - If `gridSize` is 10, coordinates will be rounded to the nearest multiple of 10.
  ///
  /// This can be useful for snapping geometries to a grid or reducing precision.
  ///
  /// Parameters:
  ///   - `gridSize`: (double) The grid size to round coordinates to. Must be non-negative.
  ///     A value of 0 means no rounding. For decimal place rounding, use values like
  ///     0.1 (1 decimal place), 0.01 (2 decimal places), etc.
  ///
  /// Returns:
  ///   (GeoSeries): A new GeoSeries with rounded coordinates. Shares the original index and CRS.
  ///   Name will be `original_name_prec`.
  ///
  /// Throws:
  ///   (ArgumentError): If `gridSize` is negative.
  ///
  /// Examples:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1.234, 5.678]),
  ///   GeoJSONLineString([[0.12, 0.34], [0.56, 0.78]])
  /// ], name: 'geoms');
  ///
  /// // Round to 1 decimal place
  /// final precise1 = series.setPrecision(0.1);
  /// print(precise1.data[0]); // GeoJSONPoint([1.2, 5.7])
  ///
  /// // Round to nearest integer
  /// final preciseInt = series.setPrecision(1.0);
  /// print(preciseInt.data[0]); // GeoJSONPoint([1.0, 6.0])
  ///
  /// // Round to nearest 10
  /// final precise10 = GeoSeries([GeoJSONPoint([12, 27])]).setPrecision(10.0);
  /// print(precise10.data[0]); // GeoJSONPoint([10.0, 30.0])
  ///
  /// // No rounding
  /// final precise0 = series.setPrecision(0.0);
  /// print(precise0.data[0]); // GeoJSONPoint([1.234, 5.678])
  /// ```
  GeoSeries setPrecision(double gridSize) {
    if (gridSize == 0) {
      // Return a new GeoSeries with a copy of the data, but not modifying original
      return GeoSeries(List.from(data), name: name, crs: crs, index: index);
    }
    if (gridSize < 0) throw ArgumentError("gridSize must be non-negative.");

    final newGeometries = data.map((geom) {
      if (geom == null) return null;
      if (geom is GeoJSONPoint) {
        return GeoJSONPoint(_roundCoordinate(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONLineString) {
        return GeoJSONLineString(
            _roundCoordinatesList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONPolygon) {
        return GeoJSONPolygon(
            _roundCoordinatesListList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONMultiPoint) {
        return GeoJSONMultiPoint(
            _roundCoordinatesList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONMultiLineString) {
        return GeoJSONMultiLineString(
            _roundCoordinatesListList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONMultiPolygon) {
        return GeoJSONMultiPolygon(
            _roundCoordinatesListListList(geom.coordinates, gridSize));
      }
      if (geom is GeoJSONGeometryCollection) {
        List<GeoJSONGeometry> roundedGeoms = [];
        for (var subGeom in geom.geometries) {
          // Create a temporary GeoSeries for the sub-geometry to recursively call setPrecision
          var tempSeries = GeoSeries([subGeom], crs: crs); // Retain CRS
          var roundedSubGeom = tempSeries.setPrecision(gridSize).data[0];
          if (roundedSubGeom != null) roundedGeoms.add(roundedSubGeom);
        }
        return GeoJSONGeometryCollection(roundedGeoms);
      }
      return geom; // Should not be reached if all types are handled
    }).toList();
    return GeoSeries(newGeometries,
        name: '${name}_prec', crs: crs, index: index);
  }

  /// Returns a `Series` containing the precision of each geometry.
  ///
  /// Note: This method currently returns `double.nan` for all geometries,
  /// as the concept of "getting" a precision is not well-defined for GeoJSON
  /// objects themselves (they store coordinates as doubles). The `setPrecision`
  /// method returns a new GeoSeries with modified coordinates, but the original
  /// geometries do not inherently store a precision value. This getter might be
  /// intended for future use or a different interpretation of precision.
  ///
  /// Returns:
  ///   (`Series<double>`): A Series of `double.nan` values. Shares the original index.
  ///   Name will be `original_name_precision`.
  ///
  /// Example:
  /// ```dart
  /// final series = GeoSeries([GeoJSONPoint([1.23, 4.56])]);
  /// print(series.getPrecision);
  /// // Output: Series(name: _precision, index: [0], data: [NaN])
  /// ```
  Series<double> get getPrecision {
    final values = data.map((_) => double.nan).toList();
    return Series<double>(values, name: '${name}_precision', index: index);
  }

  /// Computes the Cartesian distance between the geometries in this `GeoSeries` and an `other` geometry or `GeoSeries`.
  ///
  /// Distances are returned in the units of the current CRS.
  ///
  /// Parameters:
  ///   - `other`: (GeoJSONGeometry | GeoSeries)
  ///     The geometry or series of geometries to compute the distance to.
  ///     If `other` is a `GeoJSONGeometry`, the distance from each geometry in this GeoSeries
  ///     to that single geometry is computed.
  ///     If `other` is a `GeoSeries`, an element-wise distance computation is performed.
  ///     The `align` parameter controls how these series are matched.
  ///   - `align`: (bool, default: `true`)
  ///     If true and `other` is a `GeoSeries`, the operation attempts to align both GeoSeries
  ///     based on their index before performing the element-wise test. If indices are not aligned
  ///     or lengths differ, it currently matches based on order up to the length of the shorter series.
  ///     Full index-based alignment is not yet implemented.
  ///
  /// Returns:
  ///   (`Series<double>`): A Series of floating-point values representing the calculated distances.
  ///   `double.nan` may be returned for empty geometries or unhandled complex cases.
  ///   The Series shares the same index as this GeoSeries.
  ///   Name will be `original_name_distance`.
  ///
  /// Note:
  ///   The distance calculation handles common cases like Point-Point, Point-LineString, Point-Polygon.
  ///   Distances involving LineStrings and Polygons are generally based on the shortest distance
  ///   between any two parts of the geometries. For complex MultiGeometries, the calculation
  ///   might be simplified (e.g., distance to the first component).
  ///   Empty or null geometries will typically result in `double.nan`.
  ///
  /// Examples:
  /// ```dart
  /// final point1 = GeoJSONPoint([0,0]);
  /// final point2 = GeoJSONPoint([3,4]); // Distance to point1 is 5.0
  /// final line1 = GeoJSONLineString([[0,10],[0,0]]); // Distance to point1 is 0.0
  ///
  /// final series = GeoSeries([point1, GeoJSONPoint([1,1])], name: 'origins');
  ///
  /// // Distance to a single geometry
  /// print(series.distance(point2));
  /// // Output: Series(name: origins_distance, index: [0, 1], data: [5.0, 3.60555...]) (sqrt((3-1)^2 + (4-1)^2))
  ///
  /// final otherSeries = GeoSeries([point2, line1], name: 'targets');
  /// print(series.distance(otherSeries)); // Element-wise
  /// // Output: Series(name: origins_distance, index: [0, 1], data: [5.0, 1.0]) // dist( (1,1) to line((0,10)-(0,0)) is 1.0)
  /// ```
  Series<double> distance(dynamic other, {bool align = true}) {
    List<double> distances = [];
    // Create a new index list based on the current GeoSeries's index.
    // This ensures the returned Series has the correct index, especially if `other` is shorter.
    List<dynamic> newIndex = List.from(index);

    if (other is GeoJSONGeometry) {
      for (int i = 0; i < length; i++) {
        distances.add(_calculateDistanceBetweenGeometries(data[i], other));
      }
    } else if (other is GeoSeries) {
      int commonLength = min(length, other.length);
      if (align && length != other.length) {
        // This warning should be refined when proper alignment is added
        print(
            "Warning: GeoSeries.distance with align=true and different lengths is using positional matching up to shortest length. Full index-based alignment is not yet implemented.");
      }

      for (int i = 0; i < commonLength; i++) {
        // TO BE DONE: Implement proper index alignment if align is true
        distances
            .add(_calculateDistanceBetweenGeometries(data[i], other.data[i]));
      }
      // If this GeoSeries is longer than `other`, fill remaining distances with NaN.
      for (int i = commonLength; i < length; i++) {
        distances.add(double.nan);
      }
      // If `other` was longer, its extra elements are ignored, and `newIndex` (from this series) determines the output length.
    } else {
      throw ArgumentError(
          "The 'other' parameter must be a GeoJSONGeometry or a GeoSeries, but was ${other.runtimeType}.");
    }
    return Series<double>(distances, name: '${name}_distance', index: newIndex);
  }

  /// Internal helper to calculate the distance between two GeoJSON geometries.
  ///
  /// Parameters:
  ///   - `geom1`: The first geometry.
  ///   - `geom2`: The second geometry.
  ///
  /// Returns:
  ///   (double): The calculated distance. Returns `double.nan` if geometries are null, empty,
  ///   or the combination is not handled.
  ///
  /// Note: This is a simplified implementation. See `distance()` docstring for more details.
  double _calculateDistanceBetweenGeometries(
      GeoJSONGeometry? geom1, GeoJSONGeometry? geom2) {
    if (geom1 == null || geom2 == null) return double.nan;
    if (_isGeometryEmpty(geom1) || _isGeometryEmpty(geom2)) return double.nan;

    // Point to Point
    if (geom1 is GeoJSONPoint && geom2 is GeoJSONPoint) {
      return _distance(geom1.coordinates, geom2.coordinates);
    }
    // Point to LineString (and vice-versa)
    if (geom1 is GeoJSONPoint && geom2 is GeoJSONLineString) {
      return _pointToLineStringDistance(geom1, geom2);
    }
    if (geom1 is GeoJSONLineString && geom2 is GeoJSONPoint) {
      return _pointToLineStringDistance(geom2, geom1);
    }
    // Point to Polygon (and vice-versa)
    if (geom1 is GeoJSONPoint && geom2 is GeoJSONPolygon) {
      return _pointToPolygonDistance(geom1, geom2);
    }
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPoint) {
      return _pointToPolygonDistance(geom2, geom1);
    }

    // LineString to LineString
    if (geom1 is GeoJSONLineString && geom2 is GeoJSONLineString) {
      // Check for intersection first (distance is 0)
      for (var p1c in geom1.coordinates) {
        if (_pointToLineStringDistance(GeoJSONPoint(p1c), geom2) < 1e-9) {
          return 0.0;
        }
      }
      for (var p2c in geom2.coordinates) {
        if (_pointToLineStringDistance(GeoJSONPoint(p2c), geom1) < 1e-9) {
          return 0.0;
        }
      }
      // If no intersection, calculate min distance between segments/points
      double minD = double.infinity;
      for (var p1c in geom1.coordinates) {
        minD = min(minD, _pointToLineStringDistance(GeoJSONPoint(p1c), geom2));
      }
      for (var p2c in geom2.coordinates) {
        minD = min(minD, _pointToLineStringDistance(GeoJSONPoint(p2c), geom1));
      }
      return minD == double.infinity ? double.nan : minD;
    }
    // LineString to Polygon (and vice-versa)
    if ((geom1 is GeoJSONLineString && geom2 is GeoJSONPolygon) ||
        (geom1 is GeoJSONPolygon && geom2 is GeoJSONLineString)) {
      GeoJSONLineString line =
          (geom1 is GeoJSONLineString ? geom1 : geom2 as GeoJSONLineString);
      GeoJSONPolygon poly =
          (geom1 is GeoJSONPolygon ? geom1 : geom2 as GeoJSONPolygon);
      // Check for intersection (distance 0)
      for (var v in line.coordinates) {
        if (_pointToPolygonDistance(GeoJSONPoint(v), poly) < 1e-9) return 0.0;
      }
      for (var ring in poly.coordinates) {
        for (var pv in ring) {
          if (_pointToLineStringDistance(GeoJSONPoint(pv), line) < 1e-9) {
            return 0.0;
          }
        }
      }
      // If no intersection, calculate min distance
      double minD = double.infinity;
      for (var v in line.coordinates) {
        minD = min(
            minD,
            _pointToPolygonDistance(GeoJSONPoint(v), poly,
                skipInsideCheck: true)); // skip check if point is inside
      }
      for (var ring in poly.coordinates) {
        for (var pv in ring) {
          minD = min(minD, _pointToLineStringDistance(GeoJSONPoint(pv), line));
        }
      }
      return minD == double.infinity ? double.nan : minD;
    }
    // Polygon to Polygon
    if (geom1 is GeoJSONPolygon && geom2 is GeoJSONPolygon) {
      // Check for intersection (distance 0)
      for (var r1 in geom1.coordinates) {
        for (var v1 in r1) {
          if (_pointToPolygonDistance(GeoJSONPoint(v1), geom2) < 1e-9) {
            return 0.0;
          }
        }
      }
      for (var r2 in geom2.coordinates) {
        for (var v2 in r2) {
          if (_pointToPolygonDistance(GeoJSONPoint(v2), geom1) < 1e-9) {
            return 0.0;
          }
        }
      }
      // If no intersection, calculate min distance between their boundaries
      double minD = double.infinity;
      for (var r1 in geom1.coordinates) {
        for (var v1 in r1) {
          minD = min(
              minD,
              _pointToPolygonDistance(GeoJSONPoint(v1), geom2,
                  skipInsideCheck: true));
        }
      }
      for (var r2 in geom2.coordinates) {
        for (var v2 in r2) {
          minD = min(
              minD,
              _pointToPolygonDistance(GeoJSONPoint(v2), geom1,
                  skipInsideCheck: true));
        }
      }
      return minD == double.infinity ? double.nan : minD;
    }

    // --- Handle MultiGeometries by iterating over components ---
    // geom1 is Multi*, geom2 is single or Multi*
    if (geom1 is GeoJSONMultiPoint) {
      if (geom1.coordinates.isEmpty) return double.nan;
      double minD = double.infinity;
      for (var pCoords in geom1.coordinates) {
        minD = min(minD,
            _calculateDistanceBetweenGeometries(GeoJSONPoint(pCoords), geom2));
      }
      return minD == double.infinity ? double.nan : minD;
    } else if (geom2 is GeoJSONMultiPoint) {
      // Symmetry: geom2 is MultiPoint, geom1 is single (already handled) or Multi* (next cases)
      return _calculateDistanceBetweenGeometries(geom2, geom1);
    }

    if (geom1 is GeoJSONMultiLineString) {
      if (geom1.coordinates.isEmpty) return double.nan;
      double minD = double.infinity;
      for (var lCoords in geom1.coordinates) {
        if (lCoords.isNotEmpty) {
          minD = min(
              minD,
              _calculateDistanceBetweenGeometries(
                  GeoJSONLineString(lCoords), geom2));
        }
      }
      return minD == double.infinity ? double.nan : minD;
    } else if (geom2 is GeoJSONMultiLineString) {
      return _calculateDistanceBetweenGeometries(geom2, geom1);
    }

    if (geom1 is GeoJSONMultiPolygon) {
      if (geom1.coordinates.isEmpty) return double.nan;
      double minD = double.infinity;
      for (var pRings in geom1.coordinates) {
        if (pRings.isNotEmpty) {
          minD = min(
              minD,
              _calculateDistanceBetweenGeometries(
                  GeoJSONPolygon(pRings), geom2));
        }
      }
      return minD == double.infinity ? double.nan : minD;
    } else if (geom2 is GeoJSONMultiPolygon) {
      return _calculateDistanceBetweenGeometries(geom2, geom1);
    }

    if (geom1 is GeoJSONGeometryCollection) {
      if (geom1.geometries.isEmpty) return double.nan;
      double minD = double.infinity;
      for (var g in geom1.geometries) {
        minD = min(minD, _calculateDistanceBetweenGeometries(g, geom2));
      }
      return minD == double.infinity ? double.nan : minD;
    } else if (geom2 is GeoJSONGeometryCollection) {
      return _calculateDistanceBetweenGeometries(geom2, geom1);
    }
    return double.nan; // Fallback for unhandled combinations
  }

  /// Internal helper: Calculates the shortest distance from a point to a line segment.
  ///
  /// Parameters:
  ///   - `pCoords`: Coordinates of the point `[x, y]`.
  ///   - `segA`: Coordinates of the start point of the segment `[x, y]`.
  ///   - `segB`: Coordinates of the end point of the segment `[x, y]`.
  ///
  /// Returns:
  ///   (double): The shortest distance from the point to the line segment.
  double _pointToLineSegmentDistance(
      List<double> pCoords, List<double> segA, List<double> segB) {
    final double ax = segA[0];
    final double ay = segA[1];
    final double bx = segB[0];
    final double by = segB[1];
    final double px = pCoords[0];
    final double py = pCoords[1];

    final double l2 = (bx - ax) * (bx - ax) +
        (by - ay) * (by - ay); // Squared length of the segment
    if (l2 == 0.0) return _distance(pCoords, segA); // Segment is a point

    // Parameter t for the projection of P onto the line AB
    // t = dot((P-A), (B-A)) / |B-A|^2
    final double t = ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / l2;

    if (t < 0.0) {
      return _distance(
          pCoords, segA); // Projection is outside segment, closest to A
    } else if (t > 1.0) {
      return _distance(
          pCoords, segB); // Projection is outside segment, closest to B
    }
    // Projection falls within the segment
    final List<double> projection = [ax + t * (bx - ax), ay + t * (by - ay)];
    return _distance(pCoords, projection);
  }

  /// Internal helper: Calculates the shortest distance from a point to a LineString.
  ///
  /// Parameters:
  ///   - `point`: The `GeoJSONPoint`.
  ///   - `lineString`: The `GeoJSONLineString`.
  ///
  /// Returns:
  ///   (double): The shortest distance. `double.nan` if LineString is empty or has 1 point.
  double _pointToLineStringDistance(
      GeoJSONPoint point, GeoJSONLineString lineString) {
    if (lineString.coordinates.isEmpty) return double.nan;
    if (lineString.coordinates.length == 1) {
      // LineString is effectively a point
      return _distance(point.coordinates, lineString.coordinates[0]);
    }

    double minDistance = double.infinity;
    for (int i = 0; i < lineString.coordinates.length - 1; i++) {
      final double segmentDistance = _pointToLineSegmentDistance(
          point.coordinates,
          lineString.coordinates[i],
          lineString.coordinates[i + 1]);
      minDistance = min(minDistance, segmentDistance);
    }
    return minDistance == double.infinity ? double.nan : minDistance;
  }

  /// Internal helper: Calculates the shortest distance from a point to a Polygon.
  ///
  /// Parameters:
  ///   - `point`: The `GeoJSONPoint`.
  ///   - `polygon`: The `GeoJSONPolygon`.
  ///   - `skipInsideCheck`: (bool, default: false) If true, skips checking if the point is inside the polygon.
  ///     Used when calculating polygon-to-polygon distance where intersection means 0 distance.
  ///
  /// Returns:
  ///   (double): The shortest distance. 0.0 if the point is inside the polygon (and not in a hole).
  ///   `double.nan` if polygon is invalid or empty.
  double _pointToPolygonDistance(GeoJSONPoint point, GeoJSONPolygon polygon,
      {bool skipInsideCheck = false}) {
    if (polygon.coordinates.isEmpty ||
        polygon.coordinates[0].isEmpty ||
        polygon.coordinates[0].length < 4) {
      // Invalid polygon
      return double.nan;
    }

    if (!skipInsideCheck) {
      // Check if point is inside the polygon (exterior ring)
      if (_pointInPolygon(point.coordinates, polygon.coordinates[0])) {
        bool inHole = false;
        // Check if point is inside any of the interior rings (holes)
        for (int i = 1; i < polygon.coordinates.length; i++) {
          if (polygon.coordinates[i].length >= 4 && // Valid hole
              _pointInPolygon(point.coordinates, polygon.coordinates[i])) {
            inHole = true;
            break;
          }
        }
        if (!inHole) return 0.0; // Point is inside exterior and not in any hole
        // If in a hole, distance is to the boundary of that hole (handled below)
      }
    }

    // If point is outside or in a hole, calculate distance to all rings (exterior and interior)
    double minDistance = double.infinity;
    for (var ringCoords in polygon.coordinates) {
      if (ringCoords.length < 2) continue; // Should be at least a segment
      // Treat each ring as a LineString for distance calculation
      GeoJSONLineString ringLineString = GeoJSONLineString(ringCoords);
      minDistance =
          min(minDistance, _pointToLineStringDistance(point, ringLineString));
    }
    return minDistance == double.infinity ? double.nan : minDistance;
  }

  /// Calculates the area of a polygon, considering holes.
  /// Assumes first ring is exterior, subsequent are interior.
  /// Uses `_calculateRingArea` which takes absolute area.
  ///
  /// Parameters:
  ///   - `polygonCoordinates`: (`List<List<List<double>>>`) The coordinate structure of the polygon.
  ///
  /// Returns:
  ///   (double): The calculated area.
  double _calculatePolygonArea(List<List<List<double>>> polygonCoordinates) {
    if (polygonCoordinates.isEmpty) return 0.0;
    double totalArea = _calculateRingArea(polygonCoordinates[0]);
    for (int i = 1; i < polygonCoordinates.length; i++) {
      totalArea -= _calculateRingArea(polygonCoordinates[i]);
    }
    return totalArea;
  }

  // --- Simplicity Helpers ---

  /// Helper to determine if two line segments intersect.
  ///
  /// Parameters:
  ///   - `p1`, `q1`: Endpoints of the first line segment.
  ///   - `p2`, `q2`: Endpoints of the second line segment.
  ///   - `includeEndpoints`: (bool, default: `false`)
  ///     If true, segments are considered intersecting if they only share an endpoint.
  ///     If false, sharing an endpoint does not count as an intersection.
  ///
  /// Returns:
  ///   (bool): True if the segments intersect, false otherwise.
  ///
  /// This method uses an orientation test to check for intersections.
  /// Orientation of an ordered triplet (p, q, r) can be:
  /// - 0: Collinear
  /// - 1: Clockwise
  /// - 2: Counterclockwise
  bool _segmentsIntersect(
      List<double> p1, List<double> q1, List<double> p2, List<double> q2,
      {bool includeEndpoints = false}) {
    // Helper to find orientation of ordered triplet (p, q, r).
    int orientation(List<double> p, List<double> q, List<double> r) {
      double val =
          (q[1] - p[1]) * (r[0] - q[0]) - (q[0] - p[0]) * (r[1] - q[1]);
      if (val.abs() < 1e-9) return 0; // Collinear (within a small tolerance)
      return (val > 0) ? 1 : 2; // Clockwise or Counterclockwise
    }

    // Helper to check if point q lies on segment pr (assuming p,q,r are collinear)
    bool onSegment(List<double> p, List<double> q, List<double> r) {
      return (q[0] <= max(p[0], r[0]) + 1e-9 && // Check with tolerance
          q[0] >= min(p[0], r[0]) - 1e-9 &&
          q[1] <= max(p[1], r[1]) + 1e-9 &&
          q[1] >= min(p[1], r[1]) - 1e-9);
    }

    int o1 = orientation(p1, q1, p2);
    int o2 = orientation(p1, q1, q2);
    int o3 = orientation(p2, q2, p1);
    int o4 = orientation(p2, q2, q1);

    // General case: Segments cross each other (different orientations)
    if (o1 != 0 && o2 != 0 && o3 != 0 && o4 != 0) {
      if (o1 != o2 && o3 != o4) return true;
    }

    // Special Cases for collinear points:
    // An intersection occurs if a point of one segment lies on the other segment.
    // If includeEndpoints is false, we must ensure the intersection point is not an endpoint.
    if (o1 == 0 && onSegment(p1, p2, q1)) {
      // p1, q1, p2 are collinear and p2 lies on segment p1q1
      return includeEndpoints ||
          (!_arePointsEqual(p2, p1) && !_arePointsEqual(p2, q1));
    }
    if (o2 == 0 && onSegment(p1, q2, q1)) {
      // p1, q1, q2 are collinear and q2 lies on segment p1q1
      return includeEndpoints ||
          (!_arePointsEqual(q2, p1) && !_arePointsEqual(q2, q1));
    }
    if (o3 == 0 && onSegment(p2, p1, q2)) {
      // p2, q2, p1 are collinear and p1 lies on segment p2q2
      return includeEndpoints ||
          (!_arePointsEqual(p1, p2) && !_arePointsEqual(p1, q2));
    }
    if (o4 == 0 && onSegment(p2, q1, q2)) {
      // p2, q2, q1 are collinear and q1 lies on segment p2q2
      return includeEndpoints ||
          (!_arePointsEqual(q1, p2) && !_arePointsEqual(q1, q2));
    }

    return false; // Segments do not intersect
  }

  /// Internal helper to check if a LineString geometry is simple (does not self-intersect).
  ///
  /// Parameters:
  ///   - `line`: The `GeoJSONLineString` to check.
  ///
  /// Returns:
  ///   (bool): True if the LineString is simple, false otherwise.
  ///
  /// Simplicity rules:
  /// - Lines with 0, 1, or 2 points are simple.
  /// - No duplicate consecutive points (e.g., A-A-B or A-B-B-C), unless it's a 3-point line
  ///   that closes on itself (A-B-A), which is simple if A and B are distinct.
  ///   A line like A-A-A is not simple.
  /// - Non-adjacent segments must not intersect. Intersections are checked excluding shared endpoints.
  ///   For closed lines, the first and last segments can meet at the shared endpoint without being
  ///   considered a self-intersection, provided they don't cross otherwise.
  bool _isLineStringSimple(GeoJSONLineString line) {
    final coords = line.coordinates;
    if (coords.length <= 2) {
      return true; // A line with 0, 1, or 2 points is inherently simple. Emptiness is handled by `_isGeometryEmpty`.
    }

    // Check for duplicate consecutive points
    for (int i = 0; i < coords.length - 1; i++) {
      if (_arePointsEqual(coords[i], coords[i + 1])) {
        // A-B-A case: coords.length is 3. coords[0]=A, coords[1]=B, coords[2]=A.
        // If coords[0] == coords[1] (A=B), then it's A-A-A, which is not simple.
        if (coords.length == 3 && _arePointsEqual(coords[0], coords[2])) {
          // A-B-A form
          if (_arePointsEqual(coords[0], coords[1])) {
            return false;
          } // A-A-A is not simple
        } else {
          return false; // Any other consecutive duplicate makes it non-simple (e.g., A-A-B or A-B-B-C)
        }
      }
    }

    // Check for self-intersections among non-adjacent segments
    // A segment is (coords[i], coords[i+1])
    // Another segment is (coords[j], coords[j+1])
    for (int i = 0; i < coords.length - 1; i++) {
      // j starts from i+2 to avoid checking adjacent segments (which share a point but shouldn't "intersect" in a self-intersection sense)
      // and to avoid checking a segment against itself.
      for (int j = i + 2; j < coords.length - 1; j++) {
        // Special handling for the case where the line is closed:
        // The last segment (coords[coords.length-2], coords[coords.length-1]) should not intersect the first segment (coords[0], coords[1])
        // except at their shared endpoint if the line is closed.
        // The `_segmentsIntersect` with `includeEndpoints: false` handles this: it won't report true if they only touch at endpoints.
        bool isClosedLine = _arePointsEqual(coords.first, coords.last);
        if (isClosedLine && i == 0 && j == coords.length - 2) {
          // This condition means we are comparing the first segment (coords[0]-coords[1])
          // with the "virtual" segment before the closing point if we imagine the line extended.
          // More directly, we are checking if the first segment (coords[0] to coords[1])
          // intersects with the last actual segment (coords[coords.length-2] to coords[coords.length-1]).
          // If they intersect other than at the shared start/end point, it's not simple.
          // `includeEndpoints: false` is crucial here.
          if (_segmentsIntersect(
              coords[i], coords[i + 1], coords[j], coords[j + 1],
              includeEndpoints: false)) {
            return false;
          }
          // This specific pair (first and last segment of a closed loop) is now checked.
          // No need to `continue` as the loop structure handles other pairs.
        } else {
          // General check for non-adjacent segments.
          if (_segmentsIntersect(
              coords[i], coords[i + 1], coords[j], coords[j + 1],
              includeEndpoints: false)) {
            // `includeEndpoints: false` is typically used for self-intersection
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Returns a `Series` of boolean values indicating if each geometry is "simple".
  ///
  /// A geometry is simple if it does not intersect itself. The exact definition of simplicity
  /// varies by geometry type according to OGC standards.
  /// - **Point**: Always simple.
  /// - **MultiPoint**: Simple if no two points are identical. (Empty MultiPoint is considered not simple here).
  /// - **LineString**: Simple if it does not cross or touch itself, except at the start and end points if it's a closed ring.
  /// - **Polygon**: Simple if its rings (exterior and interior) are simple and do not intersect each other inappropriately
  ///   (e.g., interior rings must be within the exterior, rings should not self-intersect).
  ///   (Note: Current Polygon simplicity check is basic, mainly ring simplicity).
  /// - **MultiLineString**: Simple if its elements are simple and only intersect at endpoints. (Current check is element simplicity).
  /// - **MultiPolygon**: Simple if its elements are simple and only touch at boundaries. (Current check is element simplicity).
  /// - **GeometryCollection**: Simple if all its elements are simple and follow rules for their combination. (Current check is element simplicity).
  ///
  /// Null or empty geometries are generally considered not simple by this implementation.
  ///
  /// Returns:
  ///   `(Series<bool>)`: A Series of booleans, true if a geometry is simple, otherwise false.
  ///   Shares the original index. Name will be `original_name_is_simple`.
  ///
  /// Example:
  /// ```dart
  /// final simpleLine = GeoJSONLineString([[0,0],[1,1],[1,0]]);
  /// final selfIntersectLine = GeoJSONLineString([[0,0],[2,2],[0,2],[2,0]]); // Crosses itself
  /// final simplePoly = GeoJSONPolygon([[[0,0],[0,1],[1,1],[1,0],[0,0]]]);
  ///
  /// final series = GeoSeries([simpleLine, selfIntersectLine, simplePoly, GeoJSONPoint([0,0])], name: 'geoms');
  /// print(series.isSimple);
  /// // Output:
  /// // Series(name: geoms_is_simple, index: [0, 1, 2, 3], data: [true, false, true, true])
  /// ```
  Series<bool> get isSimple {
    final simpleFlags = data.map((geom) {
      if (geom == null || _isGeometryEmpty(geom)) {
        return false; // Not simple if null or empty
      }

      if (geom is GeoJSONPoint) return true;

      if (geom is GeoJSONMultiPoint) {
        // Simple if no two points are identical
        if (geom.coordinates.isEmpty) {
          return false; // Empty is not simple by convention here
        }
        Set<String> pointStrings = {};
        for (var p in geom.coordinates) {
          String pStr =
              "${p[0]},${p[1]}"; // Simple string representation for uniqueness
          if (pointStrings.contains(pStr)) return false;
          pointStrings.add(pStr);
        }
        return true;
      }

      if (geom is GeoJSONLineString) return _isLineStringSimple(geom);

      if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isEmpty || geom.coordinates[0].length < 4) {
          return false; // Invalid/empty polygon is not simple
        }
        // Exterior ring must be simple
        if (!_isLineStringSimple(GeoJSONLineString(geom.coordinates[0]))) {
          return false;
        }
        // Interior rings must be simple and not intersect each other or the exterior (simplified check)
        for (int i = 1; i < geom.coordinates.length; i++) {
          if (!_isLineStringSimple(GeoJSONLineString(geom.coordinates[i]))) {
            return false;
          }
          // TO BE DONE: Add checks for interior ring containment and non-intersection with other rings.
        }
        return true;
      }

      if (geom is GeoJSONMultiLineString) {
        if (geom.coordinates.isEmpty) return false;
        // TO BE DONE: Also check that lines only intersect at endpoints for full OGC simplicity.
        return geom.coordinates.every(
            (lineCoords) => _isLineStringSimple(GeoJSONLineString(lineCoords)));
      }

      if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty) return false;
        // TO BE DONE: Also check that polygons only touch at boundaries for full OGC simplicity.
        return geom.coordinates.every((polyCoords) =>
            GeoSeries([GeoJSONPolygon(polyCoords)], crs: crs, index: [0])
                .isSimple
                .data[0]!);
      }

      if (geom is GeoJSONGeometryCollection) {
        if (geom.geometries.isEmpty) return false;
        // TO BE DONE: Check interactions between components for full OGC simplicity.

        return geom.geometries.every(
            (g) => GeoSeries([g], crs: crs, index: [0]).isSimple.data[0]!);
      }

      return false;
    }).toList();
    return Series(simpleFlags, name: '${name}_is_simple', index: index);
  }

  /// Returns a `Series` of strings explaining why each geometry is invalid, or "Valid Geometry" if valid.
  ///
  /// This method provides a human-readable reason for invalidity based on the checks performed
  /// by the `isValid` getter.
  /// - For null geometries: "Null geometry".
  /// - For empty geometries: "Empty geometry".
  /// - For Polygons/MultiPolygons that fail `_isValidPolygon`: "Invalid Polygon" or "Invalid MultiPolygon".
  ///   (More detailed reasons from `_isValidPolygon` are not yet piped through).
  /// - For other geometries considered valid by `isValid`: "Valid Geometry".
  ///
  /// Returns:
  ///   (`Series<String>`): A Series of strings. Shares the original index.
  ///   Name will be `original_name_is_valid_reason`.
  ///
  /// Example:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([1,1]),
  ///   GeoJSONPolygon([[[0,0],[1,1],[0,1]]]), // Invalid: ring < 4 points
  ///   null
  /// ], name: 'geoms');
  /// print(series.isValidReason());
  /// // Output:
  /// // Series(name: geoms_is_valid_reason, index: [0, 1, 2], data: [Valid Geometry, Invalid Polygon, Null geometry])
  /// ```
  Series<String> isValidReason() {
    final reasons = data.map((geom) {
      if (geom == null) return "Null geometry";
      if (_isGeometryEmpty(geom)) return "Empty geometry";

      if (geom is GeoJSONPolygon) {
        if (!_isValidPolygon(geom.coordinates)) {
          // TO BE DONE: _isValidPolygon could return a reason string directly for more detail
          return "Invalid Polygon";
        }
      } else if (geom is GeoJSONMultiPolygon) {
        if (geom.coordinates.isEmpty ||
            !geom.coordinates
                .every((polygonRings) => _isValidPolygon(polygonRings))) {
          return "Invalid MultiPolygon";
        }
      }
      // For other types, if they are not empty, our current isValid considers them valid.
      return "Valid Geometry";
    }).toList();
    return Series(reasons, name: '${name}_is_valid_reason', index: index);
  }

  /// Checks if a single polygon's coordinate structure is valid according to simplified rules.
  ///
  /// Parameters:
  ///   - `polygonCoords`: (`List<List<List<double>>>`) The coordinate structure of the polygon,
  ///     where the first list is the exterior ring and subsequent lists are interior rings.
  ///
  /// Returns:
  ///   (bool): True if the polygon structure is considered valid by these simplified checks,
  ///   false otherwise.
  ///
  /// Validation checks:
  /// 1. Must have at least one ring (the exterior ring).
  /// 2. Each ring must have at least 4 coordinate pairs.
  /// 3. Each ring must be closed (first and last points are identical).
  /// 4. Each ring (excluding the closing point) must not contain duplicate points (basic self-tangency/intersection check).
  ///
  /// Note: This does not check for ring orientation (e.g., exterior CCW, interior CW) or
  /// intersections between different rings, or if interior rings are properly contained within the exterior.
  bool _isValidPolygon(List<List<List<double>>> polygonCoords) {
    if (polygonCoords.isEmpty) {
      return false;
    }

    // For each ring
    for (var ring in polygonCoords) {
      // A ring must have at least 4 points (to be closed)
      if (ring.length < 4) {
        return false;
      }

      // First and last points must be the same (closed ring)
      if (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1]) {
        return false;
      }

      // Check for self-intersection by looking for duplicate points within the ring (excluding the closing point).
      // This is a simplified check and doesn't catch all self-intersections.
      Set<String> pointSet = {};
      for (int i = 0; i < ring.length - 1; i++) {
        // Iterate up to the point before the closing duplicate
        String pointKey =
            '${ring[i][0]},${ring[i][1]}'; // Create a string key for the point
        if (pointSet.contains(pointKey)) {
          return false; // Duplicate point found, indicating a self-tangency or intersection at a vertex
        }
        pointSet.add(pointKey);
      }
    }

    // TO BE DONE: Add checks for ring orientation and containment of holes if enhancing validity.
    return true;
  }

  // Private helper to extract all coordinates from any geometry type into a flat list of [x,y] or [x,y,z] lists.
  // Used by getCoordinates.
  List<List<double>> _extractCoordinates(GeoJSONGeometry geometry) {
    if (geometry is GeoJSONPoint) {
      return geometry.coordinates.isNotEmpty ? [geometry.coordinates] : [];
    }
    if (geometry is GeoJSONMultiPoint) return geometry.coordinates;
    if (geometry is GeoJSONLineString) return geometry.coordinates;
    if (geometry is GeoJSONMultiLineString) {
      List<List<double>> coords = [];
      for (var line in geometry.coordinates) {
        coords.addAll(line);
      }
      return coords;
    }
    if (geometry is GeoJSONPolygon) {
      List<List<double>> coords = [];
      for (var ring in geometry.coordinates) {
        coords.addAll(ring);
      }
      return coords;
    }
    if (geometry is GeoJSONMultiPolygon) {
      List<List<double>> coords = [];
      for (var polygon in geometry.coordinates) {
        for (var ring in polygon) {
          coords.addAll(ring);
        }
      }
      return coords;
    }
    if (geometry is GeoJSONGeometryCollection) {
      List<List<double>> coords = [];
      for (var subGeom in geometry.geometries) {
        coords.addAll(_extractCoordinates(subGeom)); // Recursive call
      }
      return coords;
    }
    return []; // Should not be reached if all types are handled
  }

  // Private helper for centroid calculation of polygons, may need refinement.
  // Currently calculates area of the exterior ring only, for weighting in MultiPolygon centroids.
  double _calculatePolygonAreaForCentroid(
      List<List<List<double>>> polygonCoordinates) {
    if (polygonCoordinates.isEmpty) return 0.0;
    return _calculateRingArea(
        polygonCoordinates[0]); // Area of the exterior ring
  }

  /// Computes the convex hull of all geometries in the GeoSeries.
  ///
  /// The convex hull is the smallest convex polygon that contains all the points
  /// from all geometries in the series.
  ///
  /// Returns:
  ///   (GeoJSONGeometry): A GeoJSONPolygon representing the convex hull of all geometries,
  ///   or a GeoJSONPoint if there's only one unique point, or an empty GeometryCollection
  ///   if there are no valid geometries.
  ///
  /// Example:
  /// ```dart
  /// final series = GeoSeries([
  ///   GeoJSONPoint([0, 0]),
  ///   GeoJSONPoint([1, 0]),
  ///   GeoJSONPoint([0.5, 1]),
  /// ]);
  /// final hull = series.convexHull();
  /// print(hull.toWkt()); // Should be a triangle containing all three points
  /// ```
  GeoJSONGeometry convexHull() {
    // Collect all points from all geometries
    List<List<double>> allPoints = [];

    for (var geom in data) {
      if (geom != null) {
        allPoints.addAll(_extractCoordinates(geom));
      }
    }

    if (allPoints.isEmpty) {
      return GeoJSONGeometryCollection([]);
    }

    if (allPoints.length == 1) {
      return GeoJSONPoint(allPoints[0]);
    }

    if (allPoints.length == 2) {
      return GeoJSONLineString(allPoints);
    }

    // Remove duplicate points
    final uniquePoints = <List<double>>[];
    for (var point in allPoints) {
      bool isDuplicate = false;
      for (var existing in uniquePoints) {
        if (existing.length >= 2 &&
            point.length >= 2 &&
            (existing[0] - point[0]).abs() < 1e-10 &&
            (existing[1] - point[1]).abs() < 1e-10) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        uniquePoints.add(point);
      }
    }

    if (uniquePoints.length < 3) {
      if (uniquePoints.length == 1) {
        return GeoJSONPoint(uniquePoints[0]);
      } else if (uniquePoints.length == 2) {
        return GeoJSONLineString(uniquePoints);
      } else {
        return GeoJSONGeometryCollection([]);
      }
    }

    // Compute convex hull using Graham scan algorithm
    final hullPoints = _grahamScan(uniquePoints);

    if (hullPoints.length < 3) {
      if (hullPoints.length == 1) {
        return GeoJSONPoint(hullPoints[0]);
      } else if (hullPoints.length == 2) {
        return GeoJSONLineString(hullPoints);
      } else {
        return GeoJSONGeometryCollection([]);
      }
    }

    // Close the polygon
    final closedHull = List<List<double>>.from(hullPoints);
    if (closedHull.isNotEmpty &&
        (closedHull.first[0] != closedHull.last[0] ||
            closedHull.first[1] != closedHull.last[1])) {
      closedHull.add([closedHull.first[0], closedHull.first[1]]);
    }

    return GeoJSONPolygon([closedHull]);
  }

  /// Graham scan algorithm for computing convex hull
  List<List<double>> _grahamScan(List<List<double>> points) {
    if (points.length < 3) return points;

    // Find the bottom-most point (and leftmost in case of tie)
    List<double> start = points[0];
    int startIndex = 0;

    for (int i = 1; i < points.length; i++) {
      final point = points[i];
      if (point[1] < start[1] ||
          (point[1] == start[1] && point[0] < start[0])) {
        start = point;
        startIndex = i;
      }
    }

    // Remove start point from the list and add it to the beginning
    points.removeAt(startIndex);
    points.insert(0, start);

    // Sort points by polar angle with respect to start point
    points.sublist(1).sort((a, b) {
      final angleA = atan2(a[1] - start[1], a[0] - start[0]);
      final angleB = atan2(b[1] - start[1], b[0] - start[0]);

      if (angleA < angleB) return -1;
      if (angleA > angleB) return 1;

      // If angles are equal, sort by distance
      final distA = (a[0] - start[0]) * (a[0] - start[0]) +
          (a[1] - start[1]) * (a[1] - start[1]);
      final distB = (b[0] - start[0]) * (b[0] - start[0]) +
          (b[1] - start[1]) * (b[1] - start[1]);

      return distA.compareTo(distB);
    });

    // Build convex hull
    final hull = <List<double>>[];

    for (var point in points) {
      // Remove points that make a right turn
      while (hull.length >= 2 &&
          _crossProduct(hull[hull.length - 2], hull[hull.length - 1], point) <=
              0) {
        hull.removeLast();
      }
      hull.add(point);
    }

    return hull;
  }

  /// Calculate cross product for three points to determine turn direction
  double _crossProduct(List<double> o, List<double> a, List<double> b) {
    return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
  }
}
