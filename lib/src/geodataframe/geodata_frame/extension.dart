part of 'geodata_frame.dart';

/// Extension to convert GeoJSON geometries to Well-Known Text (WKT) format
extension GeoJSONGeometryToWkt on GeoJSONGeometry {
  /// Converts the geometry to a Well-Known Text (WKT) string representation
  String toWkt() {
    if (this is GeoJSONPoint) {
      final point = this as GeoJSONPoint;
      final coords = point.coordinates;
      if (coords.length >= 2) {
        return 'POINT (${coords[0]} ${coords[1]})';
      }
      return 'POINT EMPTY';
    } else if (this is GeoJSONMultiPoint) {
      final multiPoint = this as GeoJSONMultiPoint;
      final coords = multiPoint.coordinates;
      if (coords.isEmpty) return 'MULTIPOINT EMPTY';

      final pointsStr = coords.map((p) => '(${p[0]} ${p[1]})').join(', ');
      return 'MULTIPOINT ($pointsStr)';
    } else if (this is GeoJSONLineString) {
      final lineString = this as GeoJSONLineString;
      final coords = lineString.coordinates;
      if (coords.isEmpty) return 'LINESTRING EMPTY';

      final pointsStr = coords.map((p) => '${p[0]} ${p[1]}').join(', ');
      return 'LINESTRING ($pointsStr)';
    } else if (this is GeoJSONMultiLineString) {
      final multiLineString = this as GeoJSONMultiLineString;
      final lines = multiLineString.coordinates;
      if (lines.isEmpty) return 'MULTILINESTRING EMPTY';

      final linesStr = lines.map((line) {
        final pointsStr = line.map((p) => '${p[0]} ${p[1]}').join(', ');
        return '($pointsStr)';
      }).join(', ');

      return 'MULTILINESTRING ($linesStr)';
    } else if (this is GeoJSONPolygon) {
      final polygon = this as GeoJSONPolygon;
      final rings = polygon.coordinates;
      if (rings.isEmpty) return 'POLYGON EMPTY';

      final ringsStr = rings.map((ring) {
        final pointsStr = ring.map((p) => '${p[0]} ${p[1]}').join(', ');
        return '($pointsStr)';
      }).join(', ');

      return 'POLYGON ($ringsStr)';
    } else if (this is GeoJSONMultiPolygon) {
      final multiPolygon = this as GeoJSONMultiPolygon;
      final polygons = multiPolygon.coordinates;
      if (polygons.isEmpty) return 'MULTIPOLYGON EMPTY';

      final polygonsStr = polygons.map((polygon) {
        final ringsStr = polygon.map((ring) {
          final pointsStr = ring.map((p) => '${p[0]} ${p[1]}').join(', ');
          return '($pointsStr)';
        }).join(', ');

        return '($ringsStr)';
      }).join(', ');

      return 'MULTIPOLYGON ($polygonsStr)';
    } else {
      return 'GEOMETRY';
    }
  }
}
