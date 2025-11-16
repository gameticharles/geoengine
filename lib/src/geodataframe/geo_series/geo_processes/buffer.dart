part of '../geo_series.dart';

extension BufferGeoProcess on GeoSeries {
  /// Creates a `GeoSeries` containing the buffer of each geometry in the input GeoSeries.
  ///
  /// A buffer is a zone around a geometry that extends outwards (or inwards for negative distances
  /// on polygons) to a specified `distance`. The resulting geometries represent all points
  /// within that distance from the original geometry.
  ///
  /// Parameters:
  ///   - `distance`: (dynamic, default: `1.0`)
  ///     The distance to buffer the geometries.
  ///     - If a `num` (double or int), all geometries are buffered by this value.
  ///     - If a `List<double>`, each geometry is buffered by the corresponding distance in the list.
  ///       The list must have the same length as the GeoSeries.
  ///     - If a `Series<double>`, each geometry is buffered by the corresponding distance in the Series.
  ///       The Series must have the same length and index as the GeoSeries (though index alignment is not strictly enforced currently).
  ///     A positive distance creates an outward buffer. A negative distance can create an inward buffer
  ///     (primarily for Polygons, current implementation for other types with negative distance might return empty polygons).
  ///   - `resolution`: (int, default: `16`)
  ///     The number of segments used to approximate a quarter circle in round caps and joins, and for buffering points.
  ///     Higher values result in smoother curves but more complex geometries.
  ///   - `capStyle`: (String, default: `'round'`)
  ///     Determines the shape of the buffer at the ends of LineStrings. Options are:
  ///     - `'round'`: Ends are rounded (circular arcs).
  ///     - `'flat'`: Ends are flat and terminate at the original start/end vertices of the line.
  ///     - `'square'`: Ends are flat but extend squarely by the buffer distance beyond the original vertices.
  ///     (Note: Current implementation of cap styles is simplified).
  ///   - `joinStyle`: (String, default: `'round'`)
  ///     Determines the shape of the buffer at the joins (vertices) of LineStrings and Polygons. Options are:
  ///     - `'round'`: Joins are rounded (circular arcs).
  ///     - `'mitre'`: Joins are extended to a sharp point, up to the `mitreLimit`.
  ///     - `'bevel'`: Joins are cut off with a straight line segment.
  ///     (Note: Current implementation of join styles is simplified).
  ///   - `mitreLimit`: (double, default: `5.0`)
  ///     The maximum ratio of the mitre length to the buffer distance when `joinStyle` is `'mitre'`.
  ///     If the limit is exceeded, a bevel join is used instead to prevent excessively long spikes.
  ///     Must be positive.
  ///   - `singleSided`: (bool, default: `false`)
  ///     If true, attempts to create a buffer on only one side of a LineString (e.g., left or right).
  ///     (Note: Current implementation for single-sided buffers is highly simplified and may not produce accurate results).
  ///
  /// Returns:
  ///   (GeoSeries): A new GeoSeries containing the buffered geometries. The CRS of the input
  ///   GeoSeries is preserved. The name of the new series will be `original_name_buffer`.
  ///
  /// Examples:
  /// ```dart
  /// final points = GeoSeries([GeoJSONPoint([0,0]), GeoJSONPoint([10,10])], name: 'points');
  ///
  /// // Buffer all points by a distance of 1.0
  /// final bufferedPoints = points.buffer(distance: 1.0);
  /// print(bufferedPoints.geomType.data); // [Polygon, Polygon]
  ///
  /// // Buffer with a list of distances
  /// final bufferedVary = points.buffer(distance: [0.5, 1.5]);
  ///
  /// final line = GeoSeries([GeoJSONLineString([[0,0],[5,0]])], name: 'line');
  ///
  /// // Buffer line with flat caps
  /// final flatBuffer = line.buffer(distance: 0.5, capStyle: 'flat');
  ///
  /// // Buffer line with square caps
  /// final squareBuffer = line.buffer(distance: 0.5, capStyle: 'square');
  ///
  /// // Buffer line with mitre joins (example, effect more visible with multiple segments)
  /// final mitreBuffer = line.buffer(distance: 0.5, joinStyle: 'mitre', mitreLimit: 2.0);
  /// ```
  GeoSeries buffer({
    dynamic distance = 1.0,
    int resolution = 16,
    String capStyle = 'round',
    String joinStyle = 'round',
    double mitreLimit = 5.0,
    bool singleSided = false,
  }) {
    // Validate parameters
    if (resolution < 1) {
      throw ArgumentError('Resolution must be at least 1');
    }

    if (!['round', 'flat', 'square'].contains(capStyle.toLowerCase())) {
      throw ArgumentError('Cap style must be one of: round, flat, square');
    }

    if (!['round', 'mitre', 'bevel'].contains(joinStyle.toLowerCase())) {
      throw ArgumentError('Join style must be one of: round, mitre, bevel');
    }

    if (mitreLimit <= 0) {
      throw ArgumentError('Mitre limit must be positive');
    }

    // Handle different distance types
    List<double> distances;
    if (distance is num) {
      // Single value for all geometries
      distances = List.filled(data.length, distance.toDouble());
    } else if (distance is List) {
      // List of distances
      if (distance.length != data.length) {
        throw ArgumentError(
            'Distance list must have the same length as the GeoSeries');
      }
      distances = distance.map((d) => d is num ? d.toDouble() : 0.0).toList();
    } else if (distance is Series) {
      // Series of distances
      if (distance.length != data.length) {
        throw ArgumentError(
            'Distance series must have the same length as the GeoSeries');
      }
      distances =
          distance.data.map((d) => d is num ? d.toDouble() : 0.0).toList();
    } else {
      throw ArgumentError('Distance must be a number, list, or Series');
    }

    // Create buffered geometries
    final bufferedGeometries = <GeoJSONGeometry>[];

    for (int i = 0; i < data.length; i++) {
      final geom = data[i];
      final dist = distances[i];

      if (geom is GeoJSONGeometry) {
        bufferedGeometries.add(_bufferGeometry(geom, dist, resolution, capStyle,
            joinStyle, mitreLimit, singleSided));
      } else {
        // Add a default point for non-geometry values
        bufferedGeometries.add(GeoJSONPoint([0, 0]));
      }
    }

    return GeoSeries(bufferedGeometries, crs: crs, name: '${name}_buffer');
  }

  /// Internal helper to dispatch buffering to the correct geometry-specific function.
  ///
  /// Parameters:
  ///   - `geometry`: The `GeoJSONGeometry` to buffer.
  ///   - `distance`: The buffer distance.
  ///   - `resolution`: Segments for approximating curves.
  ///   - `capStyle`: Style for line endings.
  ///   - `joinStyle`: Style for line joins.
  ///   - `mitreLimit`: Limit for mitre joins.
  ///   - `singleSided`: Whether to buffer one side.
  ///
  /// Returns:
  ///   (GeoJSONGeometry): The buffered geometry. Returns an empty Polygon or original geometry for certain edge cases or unsupported types.
  GeoJSONGeometry _bufferGeometry(
    GeoJSONGeometry geometry,
    double distance,
    int resolution,
    String capStyle,
    String joinStyle,
    double mitreLimit,
    bool singleSided,
  ) {
    // For zero or negative distance with points or lines, return empty polygon
    if (distance <= 0 &&
        (geometry is GeoJSONPoint ||
            geometry is GeoJSONMultiPoint ||
            geometry is GeoJSONLineString ||
            geometry is GeoJSONMultiLineString)) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Implementation for different geometry types
    if (geometry is GeoJSONPoint) {
      return _bufferPoint(geometry, distance, resolution);
    } else if (geometry is GeoJSONLineString) {
      return _bufferLineString(geometry, distance, resolution, capStyle,
          joinStyle, mitreLimit, singleSided);
    } else if (geometry is GeoJSONPolygon) {
      return _bufferPolygon(
          geometry, distance, resolution, joinStyle, mitreLimit);
    } else if (geometry is GeoJSONMultiPoint) {
      return _bufferMultiPoint(geometry, distance, resolution);
    } else if (geometry is GeoJSONMultiLineString) {
      return _bufferMultiLineString(geometry, distance, resolution, capStyle,
          joinStyle, mitreLimit, singleSided);
    } else if (geometry is GeoJSONMultiPolygon) {
      return _bufferMultiPolygon(
          geometry, distance, resolution, joinStyle, mitreLimit);
    }

    // Default case - return the original geometry
    // Default case - return the original geometry if not handled by specific types
    return geometry;
  }

  /// Buffers a single `GeoJSONPoint` geometry.
  ///
  /// Creates a circular polygon around the point with the given `distance` as radius.
  /// The circle is approximated by `resolution` * 4 segments.
  ///
  /// Parameters:
  ///   - `point`: The `GeoJSONPoint` to buffer.
  ///   - `distance`: The buffer radius. If non-positive, an empty polygon is returned.
  ///   - `resolution`: The number of segments per quarter circle for approximation.
  ///
  /// Returns:
  ///   (GeoJSONPolygon): A polygon representing the buffer.
  GeoJSONPolygon _bufferPoint(
      GeoJSONPoint point, double distance, int resolution) {
    if (distance <= 0) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    final center = point.coordinates;
    final ring = <List<double>>[];

    // Create a circle approximation
    for (int i = 0; i <= resolution * 4; i++) {
      final angle = 2 * pi * i / (resolution * 4);
      final x = center[0] + distance * cos(angle);
      final y = center[1] + distance * sin(angle);
      ring.add([x, y]);
    }

    // Ensure the ring is closed
    if (ring.isNotEmpty &&
        (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
      ring.add([ring.first[0], ring.first[1]]);
    }

    return GeoJSONPolygon([ring]);
  }

  /// Buffers a single `GeoJSONLineString` geometry.
  ///
  /// Creates a polygon around the line. This implementation is simplified and primarily offsets
  /// segments and applies basic cap styles. Join styles are not fully implemented.
  ///
  /// Parameters:
  ///   - `line`: The `GeoJSONLineString` to buffer.
  ///   - `distance`: The buffer distance. If non-positive, an empty polygon is returned.
  ///   - `resolution`: Segments for approximating curves in round caps.
  ///   - `capStyle`: Style for line endings ('round', 'flat', 'square').
  ///   - `joinStyle`: Style for line joins (simplified handling).
  ///   - `mitreLimit`: Limit for mitre joins (simplified handling).
  ///   - `singleSided`: Whether to buffer one side (simplified handling).
  ///
  /// Returns:
  ///   (GeoJSONGeometry): A polygon representing the buffer, or an empty polygon if input is invalid or distance is non-positive.
  GeoJSONGeometry _bufferLineString(
      GeoJSONLineString line,
      double distance,
      int resolution,
      String capStyle,
      String joinStyle,
      double mitreLimit,
      bool singleSided) {
    if (distance <= 0) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // This is a simplified implementation that creates a basic buffer
    // A full implementation would handle cap styles, join styles, etc.

    final coords = line.coordinates;
    if (coords.length < 2) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Create a simple buffer by offsetting each segment
    List<List<double>> leftSide = [];
    List<List<double>> rightSide = [];

    for (int i = 0; i < coords.length - 1; i++) {
      final p1 = coords[i];
      final p2 = coords[i + 1];

      // Calculate perpendicular vector
      final dx = p2[0] - p1[0];
      final dy = p2[1] - p1[1];
      final length = sqrt(dx * dx + dy * dy);

      if (length > 0) {
        final offsetX = -dy * distance / length;
        final offsetY = dx * distance / length;

        // Add points to left and right sides
        leftSide.add([p1[0] + offsetX, p1[1] + offsetY]);
        rightSide.add([p1[0] - offsetX, p1[1] - offsetY]);

        if (i == coords.length - 2) {
          // Add the last point
          leftSide.add([p2[0] + offsetX, p2[1] + offsetY]);
          rightSide.add([p2[0] - offsetX, p2[1] - offsetY]);
        }
      }
    }

    // Handle cap style for start and end
    if (capStyle == 'round') {
      // Add semicircles at the ends
      _addRoundCap(coords.first, coords[1], distance, resolution, true,
          leftSide, rightSide);
      _addRoundCap(coords.last, coords[coords.length - 2], distance, resolution,
          false, leftSide, rightSide);
    } else if (capStyle == 'square') {
      // Add square caps
      _addSquareCap(coords.first, coords[1], distance, leftSide, rightSide);
      _addSquareCap(coords.last, coords[coords.length - 2], distance, leftSide,
          rightSide);
    }
    // 'flat' cap style doesn't need additional points

    // Combine left and right sides to form a polygon
    List<List<double>> ring = [];
    ring.addAll(leftSide);

    // Add right side in reverse order
    for (int i = rightSide.length - 1; i >= 0; i--) {
      ring.add(rightSide[i]);
    }

    // Close the ring
    if (ring.isNotEmpty) {
      ring.add([ring.first[0], ring.first[1]]);
    }

    return GeoJSONPolygon([ring]);
  }

  /// Internal helper to add a round cap to one end of a line segment during buffering.
  ///
  /// Modifies `leftSide` and `rightSide` lists by adding points forming a semicircle.
  /// Note: This is a simplified implementation for cap handling.
  ///
  /// Parameters:
  ///   - `endPoint`: The endpoint of the line where the cap is added.
  ///   - `adjacentPoint`: The point on the line adjacent to `endPoint`, used for direction.
  ///   - `distance`: The buffer radius.
  ///   - `resolution`: Segments per quarter circle for the round cap.
  ///   - `isStart`: True if capping the start of the line, false for the end.
  ///   - `leftSide`: List of coordinates for the left side of the buffer, modified in place.
  ///   - `rightSide`: List of coordinates for the right side of the buffer, modified in place.
  void _addRoundCap(
      List<double> endPoint,
      List<double> adjacentPoint,
      double distance,
      int resolution,
      bool isStart,
      List<List<double>> leftSide,
      List<List<double>> rightSide) {
    // Calculate direction vector
    final dx = adjacentPoint[0] - endPoint[0];
    final dy = adjacentPoint[1] - endPoint[1];
    final length = sqrt(dx * dx + dy * dy);

    if (length > 0) {
      final normalizedDx = dx / length;
      final normalizedDy = dy / length;

      // Calculate perpendicular vector
      final perpX = -normalizedDy;
      final perpY = normalizedDx;

      // Starting angle depends on whether this is the start or end cap
      double startAngle;
      double endAngle;

      if (isStart) {
        startAngle = atan2(-perpY, -perpX);
        endAngle = atan2(perpY, perpX);
      } else {
        startAngle = atan2(perpY, perpX);
        endAngle = atan2(-perpY, -perpX) + 2 * pi;
      }

      // Ensure the angle range is correct
      if (endAngle < startAngle) {
        endAngle += 2 * pi;
      }

      // Number of segments in the semicircle
      final segments = resolution * 2;
      final angleStep = (endAngle - startAngle) / segments;

      // Generate points along the semicircle
      List<List<double>> capPoints = [];
      for (int i = 0; i <= segments; i++) {
        final angle = startAngle + i * angleStep;
        final x = endPoint[0] + distance * cos(angle);
        final y = endPoint[1] + distance * sin(angle);
        capPoints.add([x, y]);
      }

      // Add cap points to the appropriate side
      if (isStart) {
        // For start cap, add points in reverse order to the beginning of leftSide
        for (int i = capPoints.length - 1; i >= 0; i--) {
          if (i == capPoints.length - 1) {
            rightSide.insert(0, capPoints[i]);
          } else if (i == 0) {
            leftSide.insert(0, capPoints[i]);
          } else {
            // These points go between left and right sides
            // In a full implementation, we'd need to handle this differently
          }
        }
      } else {
        // For end cap, add points to the end of rightSide
        for (int i = 0; i < capPoints.length; i++) {
          if (i == 0) {
            leftSide.add(capPoints[i]);
          } else if (i == capPoints.length - 1) {
            rightSide.add(capPoints[i]);
          } else {
            // These points go between left and right sides
            // In a full implementation, we'd need to handle this differently
          }
        }
      }
    }
  }

  /// Internal helper to add a square cap to one end of a line segment during buffering.
  ///
  /// Modifies `leftSide` and `rightSide` lists by adding points forming a square end.
  /// Note: This is a simplified implementation for cap handling.
  ///
  /// Parameters:
  ///   - `endPoint`: The endpoint of the line where the cap is added.
  ///   - `adjacentPoint`: The point on the line adjacent to `endPoint`, used for direction.
  ///   - `distance`: The buffer radius (determines the extension of the square).
  ///   - `leftSide`: List of coordinates for the left side of the buffer, modified in place.
  ///   - `rightSide`: List of coordinates for the right side of the buffer, modified in place.
  void _addSquareCap(
      List<double> endPoint,
      List<double> adjacentPoint,
      double distance,
      List<List<double>> leftSide,
      List<List<double>> rightSide) {
    // Calculate direction vector
    final dx = adjacentPoint[0] - endPoint[0];
    final dy = adjacentPoint[1] - endPoint[1];
    final length = sqrt(dx * dx + dy * dy);

    if (length > 0) {
      final normalizedDx = dx / length;
      final normalizedDy = dy / length;

      // Calculate perpendicular vector
      final perpX = -normalizedDy * distance;
      final perpY = normalizedDx * distance;

      // Calculate the extension vector
      final extX = -normalizedDx * distance;
      final extY = -normalizedDy * distance;

      // Calculate the corner points
      final leftCorner = [
        endPoint[0] + perpX + extX,
        endPoint[1] + perpY + extY
      ];
      final rightCorner = [
        endPoint[0] - perpX + extX,
        endPoint[1] - perpY + extY
      ];

      // Add the corner points to the appropriate side
      if (leftSide.isEmpty || rightSide.isEmpty) {
        // If sides are empty, add the corners as the first points
        leftSide.add(leftCorner);
        rightSide.add(rightCorner);
      } else {
        // Check if this is the start or end cap
        if (leftSide.first[0] == endPoint[0] + perpX &&
            leftSide.first[1] == endPoint[1] + perpY) {
          // This is the start cap
          leftSide.insert(0, leftCorner);
          rightSide.insert(0, rightCorner);
        } else {
          // This is the end cap
          leftSide.add(leftCorner);
          rightSide.add(rightCorner);
        }
      }
    }
  }

  /// Buffers a single `GeoJSONPolygon` geometry.
  ///
  /// For positive distance, it expands the polygon. For negative distance, it attempts to shrink it
  /// (current implementation is simplified and might just return the original polygon for negative distances).
  /// Join styles are considered for the exterior ring. Holes are not fully handled in this simplified version.
  ///
  /// Parameters:
  ///   - `polygon`: The `GeoJSONPolygon` to buffer.
  ///   - `distance`: The buffer distance.
  ///   - `resolution`: Segments for approximating curves in round joins.
  ///   - `joinStyle`: Style for ring joins.
  ///   - `mitreLimit`: Limit for mitre joins.
  ///
  /// Returns:
  ///   (GeoJSONGeometry): A polygon representing the buffer.
  GeoJSONGeometry _bufferPolygon(GeoJSONPolygon polygon, double distance,
      int resolution, String joinStyle, double mitreLimit) {
    if (distance == 0) {
      return polygon; // Return the original polygon for zero distance
    }

    // For negative distance, we need to shrink the polygon
    // This is a simplified implementation that only handles positive distances
    if (distance < 0) {
      // For a proper implementation, we would need to handle polygon shrinking
      // which is more complex than expansion
      return polygon;
    }

    // For positive distance, we expand the polygon
    // This is a simplified implementation that creates a buffer around each ring
    final coordinates = polygon.coordinates;
    if (coordinates.isEmpty || coordinates[0].isEmpty) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Buffer the outer ring
    final outerRing = coordinates[0];
    final bufferedOuterRing = _bufferRing(
        outerRing, distance, resolution, joinStyle, mitreLimit, false);

    // For a proper implementation, we would also handle inner rings (holes)
    // by buffering them with negative distance

    return GeoJSONPolygon([bufferedOuterRing]);
  }

  /// Internal helper to buffer a single ring (list of coordinates forming a closed line).
  ///
  /// This is used for buffering the rings of a polygon. It treats the ring as a LineString
  /// and applies buffering. `isHole` determines the direction of the buffer distance.
  /// Cap style is implicitly 'round' as rings are closed.
  /// Note: This is a simplified approach.
  ///
  /// Parameters:
  ///   - `ring`: The list of coordinates forming the ring.
  ///   - `distance`: The buffer distance.
  ///   - `resolution`: Segments for approximating curves.
  ///   - `joinStyle`: Style for joins.
  ///   - `mitreLimit`: Limit for mitre joins.
  ///   - `isHole`: True if the ring is an interior hole (buffers inwards), false otherwise.
  ///
  /// Returns:
  ///   `(List<List<double>>)`: The coordinates of the buffered ring. Returns original if buffering fails.
  List<List<double>> _bufferRing(List<List<double>> ring, double distance,
      int resolution, String joinStyle, double mitreLimit, bool isHole) {
    // Create a LineString from the ring and buffer it.
    // A more robust implementation would directly handle ring buffering topology.
    final lineString = GeoJSONLineString(ring);
    final bufferedLine = _bufferLineString(
        lineString,
        isHole
            ? -distance
            : distance, // Negative distance for holes (shrinking)
        resolution,
        'round', // Cap style is effectively irrelevant for closed rings
        joinStyle,
        mitreLimit,
        false); // SingleSided is false for rings

    // Extract the coordinates from the resulting polygon buffer
    if (bufferedLine is GeoJSONPolygon && bufferedLine.coordinates.isNotEmpty) {
      return bufferedLine
          .coordinates[0]; // Return the exterior ring of the buffer
    }

    // Fallback to original ring if buffering failed or returned unexpected type
    return ring;
  }

  /// Buffers a `GeoJSONMultiPoint` geometry.
  ///
  /// Each point in the MultiPoint is buffered individually.
  /// Note: This simplified version returns the buffer of the first point only,
  /// a full implementation would union the buffers of all points.
  ///
  /// Parameters:
  ///   - `multiPoint`: The `GeoJSONMultiPoint` to buffer.
  ///   - `distance`: Buffer radius. If non-positive, an empty polygon is returned.
  ///   - `resolution`: Segments per quarter circle for point buffers.
  ///
  /// Returns:
  ///   (GeoJSONGeometry): A polygon representing the buffer (currently of the first point).
  GeoJSONGeometry _bufferMultiPoint(
      GeoJSONMultiPoint multiPoint, double distance, int resolution) {
    if (distance <= 0) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    final coordinates = multiPoint.coordinates;
    if (coordinates.isEmpty) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Buffer each point and combine the results
    List<GeoJSONPolygon> bufferedPoints = [];
    for (final point in coordinates) {
      final bufferedPoint =
          _bufferPoint(GeoJSONPoint(point), distance, resolution);
      bufferedPoints.add(bufferedPoint);
    }

    // For a proper implementation, we would need to union all the buffered points
    // This is a simplified implementation that just returns the first buffered point
    if (bufferedPoints.isNotEmpty) {
      return bufferedPoints.first;
    }

    return GeoJSONPolygon([
      [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0]
      ]
    ]); // Empty polygon if no points or non-positive distance
  }

  /// Buffers a `GeoJSONMultiLineString` geometry.
  ///
  /// Each LineString in the MultiLineString is buffered individually.
  /// Note: This simplified version returns the buffer of the first LineString only,
  /// a full implementation would union the buffers of all LineStrings.
  ///
  /// Parameters:
  ///   - `multiLineString`: The `GeoJSONMultiLineString` to buffer.
  ///   - `distance`: Buffer distance. If non-positive, an empty polygon is returned.
  ///   - `resolution`: Segments for approximating curves.
  ///   - `capStyle`: Style for line endings.
  ///   - `joinStyle`: Style for line joins.
  ///   - `mitreLimit`: Limit for mitre joins.
  ///   - `singleSided`: Whether to buffer one side.
  ///
  /// Returns:
  ///   (GeoJSONGeometry): A polygon representing the buffer (currently of the first line).
  GeoJSONGeometry _bufferMultiLineString(
      GeoJSONMultiLineString multiLineString,
      double distance,
      int resolution,
      String capStyle,
      String joinStyle,
      double mitreLimit,
      bool singleSided) {
    if (distance <= 0) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    final coordinates = multiLineString.coordinates;
    if (coordinates.isEmpty) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Buffer each linestring and combine the results
    List<GeoJSONGeometry> bufferedLines = [];
    for (final line in coordinates) {
      final bufferedLine = _bufferLineString(GeoJSONLineString(line), distance,
          resolution, capStyle, joinStyle, mitreLimit, singleSided);
      bufferedLines.add(bufferedLine);
    }

    // For a proper implementation, we would need to union all the buffered lines
    // This is a simplified implementation that just returns the first buffered line
    if (bufferedLines.isNotEmpty) {
      return bufferedLines.first;
    }

    return GeoJSONPolygon([
      [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0]
      ]
    ]); // Empty polygon if no lines or non-positive distance
  }

  /// Buffers a `GeoJSONMultiPolygon` geometry.
  ///
  /// Each Polygon in the MultiPolygon is buffered individually.
  /// Note: This simplified version returns the buffer of the first Polygon only,
  /// a full implementation would union the buffers of all Polygons.
  ///
  /// Parameters:
  ///   - `multiPolygon`: The `GeoJSONMultiPolygon` to buffer.
  ///   - `distance`: Buffer distance. If zero, returns original.
  ///   - `resolution`: Segments for approximating curves.
  ///   - `joinStyle`: Style for polygon joins.
  ///   - `mitreLimit`: Limit for mitre joins.
  ///
  /// Returns:
  ///   (GeoJSONGeometry): A polygon representing the buffer (currently of the first polygon).
  GeoJSONGeometry _bufferMultiPolygon(GeoJSONMultiPolygon multiPolygon,
      double distance, int resolution, String joinStyle, double mitreLimit) {
    if (distance == 0) {
      return multiPolygon; // Return the original multipolygon for zero distance
    }

    final coordinates = multiPolygon.coordinates;
    if (coordinates.isEmpty) {
      return GeoJSONPolygon([
        [
          [0, 0],
          [0, 0],
          [0, 0],
          [0, 0]
        ]
      ]); // Empty polygon
    }

    // Buffer each polygon and combine the results
    List<GeoJSONGeometry> bufferedPolygons = [];
    for (final polygon in coordinates) {
      final bufferedPolygon = _bufferPolygon(
          GeoJSONPolygon(polygon), distance, resolution, joinStyle, mitreLimit);
      bufferedPolygons.add(bufferedPolygon);
    }

    // For a proper implementation, we would need to union all the buffered polygons
    // This is a simplified implementation that just returns the first buffered polygon
    if (bufferedPolygons.isNotEmpty) {
      return bufferedPolygons.first;
    }

    return GeoJSONPolygon([
      [
        [0, 0],
        [0, 0],
        [0, 0],
        [0, 0]
      ]
    ]); // Empty polygon
  }
}
