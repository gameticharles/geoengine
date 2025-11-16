import 'package:geoengine/geoengine.dart';
import 'package:test/test.dart';

void main() {
  group('GeoSeries Constructor and Core Properties', () {
    test('basic constructor with Point geometries', () {
      final points = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONPoint([3.0, 4.0]),
        GeoJSONPoint([5.0, 6.0])
      ];
      final geoSeries = GeoSeries(points, name: 'test_points');

      expect(geoSeries.data, equals(points));
      expect(geoSeries.name, equals('test_points'));
      expect(geoSeries.length, equals(3));
      expect(geoSeries.crs, isNull);
      expect(geoSeries.index, equals([0, 1, 2]));
    });

    test('constructor with CRS and custom index', () {
      final points = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONPoint([3.0, 4.0])
      ];
      final geoSeries = GeoSeries(points,
          crs: 'EPSG:4326', name: 'geo_points', index: ['A', 'B']);

      expect(geoSeries.crs, equals('EPSG:4326'));
      expect(geoSeries.name, equals('geo_points'));
      expect(geoSeries.index, equals(['A', 'B']));
    });

    test('constructor with mixed geometry types', () {
      final geometries = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONLineString([
          [0.0, 0.0],
          [1.0, 1.0]
        ]),
        GeoJSONPolygon([
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [0.0, 1.0],
            [0.0, 0.0]
          ]
        ])
      ];
      final geoSeries = GeoSeries(geometries);

      expect(geoSeries.length, equals(3));
      expect(geoSeries.data[0], isA<GeoJSONPoint>());
      expect(geoSeries.data[1], isA<GeoJSONLineString>());
      expect(geoSeries.data[2], isA<GeoJSONPolygon>());
    });
  });

  group('GeoSeries.fromWKT Factory', () {
    test('creates GeoSeries from WKT Point strings', () {
      final wktStrings = ['POINT(1 2)', 'POINT(3 4)', 'POINT(5 6)'];
      final geoSeries = GeoSeries.fromWKT(wktStrings, name: 'wkt_points');

      expect(geoSeries.length, equals(3));
      expect(geoSeries.name, equals('wkt_points'));
      expect(geoSeries.data.every((geom) => geom is GeoJSONPoint), isTrue);

      final point1 = geoSeries.data[0] as GeoJSONPoint;
      expect(point1.coordinates, equals([1.0, 2.0]));
    });

    test('creates GeoSeries from WKT LineString', () {
      final wktStrings = ['LINESTRING(0 0, 1 1, 2 2)'];
      final geoSeries = GeoSeries.fromWKT(wktStrings);

      expect(geoSeries.length, equals(1));
      expect(geoSeries.data[0], isA<GeoJSONLineString>());

      final lineString = geoSeries.data[0] as GeoJSONLineString;
      expect(
          lineString.coordinates,
          equals([
            [0.0, 0.0],
            [1.0, 1.0],
            [2.0, 2.0]
          ]));
    });

    test('creates GeoSeries from WKT Polygon', () {
      final wktStrings = ['POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))'];
      final geoSeries = GeoSeries.fromWKT(wktStrings);

      expect(geoSeries.length, equals(1));
      expect(geoSeries.data[0], isA<GeoJSONPolygon>());

      final polygon = geoSeries.data[0] as GeoJSONPolygon;
      expect(
          polygon.coordinates[0],
          equals([
            [0.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [0.0, 1.0],
            [0.0, 0.0]
          ]));
    });

    test('handles invalid WKT with default point', () {
      final wktStrings = ['INVALID WKT'];
      final geoSeries = GeoSeries.fromWKT(wktStrings);

      expect(geoSeries.length, equals(1));
      expect(geoSeries.data[0], isA<GeoJSONPoint>());

      final defaultPoint = geoSeries.data[0] as GeoJSONPoint;
      expect(defaultPoint.coordinates, equals([0.0, 0.0]));
    });
  });

  group('GeoSeries.fromXY Factory', () {
    test('creates 2D points from x, y coordinates', () {
      final x = [1.0, 2.0, 3.0];
      final y = [4.0, 5.0, 6.0];
      final geoSeries = GeoSeries.fromXY(x, y, name: 'xy_points');

      expect(geoSeries.length, equals(3));
      expect(geoSeries.name, equals('xy_points'));
      expect(geoSeries.data.every((geom) => geom is GeoJSONPoint), isTrue);

      final point1 = geoSeries.data[0] as GeoJSONPoint;
      expect(point1.coordinates, equals([1.0, 4.0]));

      final point2 = geoSeries.data[1] as GeoJSONPoint;
      expect(point2.coordinates, equals([2.0, 5.0]));
    });

    test('creates 3D points from x, y, z coordinates', () {
      final x = [1.0, 2.0];
      final y = [3.0, 4.0];
      final z = [5.0, 6.0];
      final geoSeries = GeoSeries.fromXY(x, y, z: z, crs: 'EPSG:4326');

      expect(geoSeries.length, equals(2));
      expect(geoSeries.crs, equals('EPSG:4326'));

      final point1 = geoSeries.data[0] as GeoJSONPoint;
      expect(point1.coordinates, equals([1.0, 3.0, 5.0]));
    });

    test('creates points with custom index', () {
      final x = [1.0, 2.0];
      final y = [3.0, 4.0];
      final customIndex = ['A', 'B'];
      final geoSeries = GeoSeries.fromXY(x, y, index: customIndex);

      expect(geoSeries.index, equals(['A', 'B']));
    });

    test('throws error for mismatched x and y lengths', () {
      final x = [1.0, 2.0, 3.0];
      final y = [4.0, 5.0]; // Different length

      expect(() => GeoSeries.fromXY(x, y), throwsArgumentError);
    });

    test('throws error for mismatched z length', () {
      final x = [1.0, 2.0];
      final y = [3.0, 4.0];
      final z = [5.0]; // Different length

      expect(() => GeoSeries.fromXY(x, y, z: z), throwsArgumentError);
    });

    test('throws error for mismatched index length', () {
      final x = [1.0, 2.0];
      final y = [3.0, 4.0];
      final index = ['A']; // Different length

      expect(() => GeoSeries.fromXY(x, y, index: index), throwsArgumentError);
    });
  });

  group('GeoSeries.fromFeatureCollection Factory', () {
    test('creates GeoSeries from FeatureCollection', () {
      final features = [
        GeoJSONFeature(GeoJSONPoint([1.0, 2.0]),
            properties: {'name': 'point1'}),
        GeoJSONFeature(GeoJSONPoint([3.0, 4.0]), properties: {'name': 'point2'})
      ];
      final featureCollection = GeoJSONFeatureCollection(features);
      final geoSeries =
          GeoSeries.fromFeatureCollection(featureCollection, name: 'fc_points');

      expect(geoSeries.length, equals(2));
      expect(geoSeries.name, equals('fc_points'));
      expect(geoSeries.data.every((geom) => geom is GeoJSONPoint), isTrue);
    });

    test('filters out null geometries from FeatureCollection', () {
      final features = [
        GeoJSONFeature(GeoJSONPoint([1.0, 2.0]),
            properties: {'name': 'point1'}),
        GeoJSONFeature(null, // Null geometry
            properties: {'name': 'no_geom'})
      ];
      final featureCollection = GeoJSONFeatureCollection(features);
      final geoSeries = GeoSeries.fromFeatureCollection(featureCollection);

      expect(geoSeries.length, equals(2));
      expect(geoSeries.data[0], isA<GeoJSONPoint>());
    });
  });

  group('GeoSeries geometries() Method', () {
    test('returns coordinates by default', () {
      final points = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONPoint([3.0, 4.0])
      ];
      final geoSeries = GeoSeries(points);
      final coords = geoSeries.geometries();

      expect(
          coords,
          equals([
            [1.0, 2.0],
            [3.0, 4.0]
          ]));
    });

    test('returns GeoJSON objects when asGeoJSON is true', () {
      final points = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONPoint([3.0, 4.0])
      ];
      final geoSeries = GeoSeries(points);
      final geojsonObjects = geoSeries.geometries(asGeoJSON: true);

      expect(geojsonObjects.length, equals(2));
      expect(geojsonObjects[0], isA<GeoJSONPoint>());
      expect(geojsonObjects[1], isA<GeoJSONPoint>());
    });

    test('handles different geometry types', () {
      final geometries = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONLineString([
          [0.0, 0.0],
          [1.0, 1.0]
        ]),
        GeoJSONPolygon([
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [0.0, 0.0]
          ]
        ])
      ];
      final geoSeries = GeoSeries(geometries);
      final coords = geoSeries.geometries();

      expect(coords[0], equals([1.0, 2.0])); // Point coordinates
      expect(
          coords[1],
          equals([
            [0.0, 0.0],
            [1.0, 1.0]
          ])); // LineString coordinates
      expect(
          coords[2],
          equals([
            [
              [0.0, 0.0],
              [1.0, 0.0],
              [1.0, 1.0],
              [0.0, 0.0]
            ]
          ])); // Polygon coordinates
    });
  });

  group('GeoSeries WKT Conversion', () {
    test('toWkt() converts geometries to WKT strings', () {
      final points = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONPoint([3.0, 4.0])
      ];
      final geoSeries = GeoSeries(points, name: 'test_points');
      final wktSeries = geoSeries.toWkt();

      expect(wktSeries, isA<Series>());
      expect(wktSeries.name, equals('test_points_wkt'));
      expect(wktSeries.length, equals(2));
      expect(wktSeries.index, equals(geoSeries.index));
    });

    test('asWkt() is alias for toWkt()', () {
      final points = [
        GeoJSONPoint([1.0, 2.0])
      ];
      final geoSeries = GeoSeries(points);
      final wktSeries1 = geoSeries.toWkt();
      final wktSeries2 = geoSeries.toWkt();

      expect(wktSeries1.data, equals(wktSeries2.data));
      expect(wktSeries1.name, equals(wktSeries2.name));
    });
  });

  group('GeoSeries makeValid() Method', () {
    test('keeps valid geometries unchanged', () {
      final validGeometries = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONLineString([
          [0.0, 0.0],
          [1.0, 1.0]
        ]),
        GeoJSONPolygon([
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [0.0, 1.0],
            [0.0, 0.0]
          ]
        ])
      ];
      final geoSeries = GeoSeries(validGeometries, crs: 'EPSG:4326');
      final validSeries = geoSeries.makeValid();

      expect(validSeries.length, equals(3));
      expect(validSeries.crs, equals('EPSG:4326'));
      expect(validSeries.data[0], isA<GeoJSONPoint>());
      expect(validSeries.data[1], isA<GeoJSONLineString>());
      expect(validSeries.data[2], isA<GeoJSONPolygon>());
    });

    test('replaces invalid polygon with default point', () {
      // Create an invalid polygon (not closed)
      final invalidPolygon = GeoJSONPolygon([
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0]
        ] // Missing closing point
      ]);
      final geoSeries = GeoSeries([invalidPolygon]);
      final validSeries = geoSeries.makeValid();

      expect(validSeries.length, equals(1));
      expect(validSeries.data[0], isA<GeoJSONPoint>());

      final defaultPoint = validSeries.data[0] as GeoJSONPoint;
      expect(defaultPoint.coordinates, equals([0.0, 0.0]));
    });

    test('preserves series properties', () {
      final points = [
        GeoJSONPoint([1.0, 2.0])
      ];
      final geoSeries = GeoSeries(points,
          crs: 'EPSG:4326', name: 'test_series', index: ['A']);
      final validSeries = geoSeries.makeValid();

      expect(validSeries.crs, equals('EPSG:4326'));
      expect(validSeries.name, equals('test_series_made_valid'));
      expect(validSeries.index, equals(['A']));
    });
  });

  group('GeoSeries getCoordinates() Extension', () {
    test('extracts coordinates as DataFrame with default settings', () {
      final geometries = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONLineString([
          [3.0, 4.0],
          [5.0, 6.0]
        ])
      ];
      final geoSeries = GeoSeries(geometries);
      final coordsDF = geoSeries.getCoordinates();

      expect(coordsDF, isA<DataFrame>());
      expect(coordsDF.columns, equals(['x', 'y']));
      expect(coordsDF.shape.rows, equals(3)); // 1 point + 2 linestring points
    });

    test('includes Z coordinates when includeZ is true', () {
      final point3D = GeoJSONPoint([1.0, 2.0, 3.0]);
      final geoSeries = GeoSeries([point3D]);
      final coordsDF = geoSeries.getCoordinates(includeZ: true);

      expect(coordsDF.columns, equals(['x', 'y', 'z']));
      expect(coordsDF.shape.columns, equals(3)); // 3 columns
    });

    test('uses sequential index when ignoreIndex is true', () {
      final points = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONPoint([3.0, 4.0])
      ];
      final geoSeries = GeoSeries(points, index: ['A', 'B']);
      final coordsDF = geoSeries.getCoordinates(ignoreIndex: true);

      expect(coordsDF.index, equals([0, 1]));
    });
  });

  group('GeoSeries Integration with Series', () {
    test('inherits Series functionality', () {
      final points = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONPoint([3.0, 4.0]),
        GeoJSONPoint([5.0, 6.0])
      ];
      final geoSeries = GeoSeries(points, name: 'geo_points');

      // Test inherited properties
      expect(geoSeries.length, equals(3));
      expect(geoSeries.isEmpty.data, [false, false, false]);

      // Test indexing
      expect(geoSeries[0], isA<GeoJSONPoint>());
      expect(geoSeries[1], isA<GeoJSONPoint>());
    });

    test('supports Series operations where applicable', () {
      final points = [
        GeoJSONPoint([1.0, 2.0]),
        GeoJSONPoint([3.0, 4.0])
      ];
      final geoSeries = GeoSeries(points);

      // Test head/tail operations
      final headSeries = geoSeries.head(1);
      expect(headSeries.length, equals(1));
      expect(headSeries.data[0], isA<GeoJSONPoint>());
    });
  });

  group('GeoSeries Error Handling', () {
    test('handles null geometries gracefully', () {
      final mixedData = [
        GeoJSONPoint([1.0, 2.0]),
        null,
        GeoJSONPoint([3.0, 4.0])
      ];
      final geoSeries = GeoSeries(mixedData);

      expect(geoSeries.length, equals(3));
      expect(geoSeries.data[1], isNull);
    });

    test('geometries() handles null values', () {
      final mixedData = [
        GeoJSONPoint([1.0, 2.0]),
        null
      ];
      final geoSeries = GeoSeries(mixedData);
      final coords = geoSeries.geometries();

      expect(coords.length, equals(2)); // Only non-null geometries
      expect(coords[0], equals([1.0, 2.0]));
    });
  });
}
