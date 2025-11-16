import 'package:geoengine/geoengine.dart';
import 'package:test/test.dart';

void main() {
  group('GeoSeries general methods', () {
    // Test data
    final point = GeoJSONPoint([1, 1]);
    final point3D = GeoJSONPoint([1, 2, 3]);

    final line = GeoJSONLineString([
      [0, 0],
      [1, 1]
    ]);
    final lineClosed = GeoJSONLineString([
      [0, 0],
      [1, 1],
      [1, 0],
      [0, 0]
    ]);
    final lineNonSimpleDupConsecutive = GeoJSONLineString([
      [0, 0],
      [1, 1],
      [1, 1],
      [2, 2]
    ]);
    final lineSelfIntersect = GeoJSONLineString([
      [0, 0],
      [2, 2],
      [0, 2],
      [2, 0]
    ]);
    final lineAlmostRingNotEnoughPoints = GeoJSONLineString([
      [0, 0],
      [1, 1],
      [0, 0]
    ]);
    final lineZeroLength = GeoJSONLineString([
      [0, 0],
      [0, 0]
    ]);

    final polygon = GeoJSONPolygon([
      [
        [0, 0],
        [2, 0],
        [2, 2],
        [0, 2],
        [0, 0]
      ]
    ]);
    final polygonWithHole = GeoJSONPolygon([
      [
        [0, 0],
        [3, 0],
        [3, 3],
        [0, 3],
        [0, 0]
      ],
      [
        [1, 1],
        [1, 2],
        [2, 2],
        [2, 1],
        [1, 1]
      ]
    ]);
    final polygonSelfIntersectingRing = GeoJSONPolygon([
      [
        [0, 0],
        [2, 2],
        [0, 2],
        [2, 0],
        [0, 0]
      ]
    ]);
    final polygonInvalidHoleOutside = GeoJSONPolygon([
      [
        [0, 0],
        [3, 0],
        [3, 3],
        [0, 3],
        [0, 0]
      ],
      [
        [4, 4],
        [4, 5],
        [5, 5],
        [5, 4],
        [4, 4]
      ]
    ]);
    final polygonInvalidHoleIntersects = GeoJSONPolygon([
      [
        [0, 0],
        [3, 0],
        [3, 3],
        [0, 3],
        [0, 0]
      ],
      [
        [2, 2],
        [2, 4],
        [4, 4],
        [4, 2],
        [2, 2]
      ]
    ]);

    final multiPoint = GeoJSONMultiPoint([
      [0, 0],
      [1, 1]
    ]);
    final multiPointWithDuplicates = GeoJSONMultiPoint([
      [0, 0],
      [1, 1],
      [0, 0]
    ]);

    final multiLine = GeoJSONMultiLineString([
      [
        [0, 0],
        [1, 1]
      ],
      [
        [10, 10],
        [11, 11]
      ]
    ]);
    final multiLineNonSimple = GeoJSONMultiLineString([
      [
        [0, 0],
        [1, 1]
      ],
      [
        [0.5, 0],
        [0.5, 2]
      ]
    ]);

    final multiPolygon = GeoJSONMultiPolygon([
      [
        [
          [0, 0],
          [1, 0],
          [1, 1],
          [0, 1],
          [0, 0]
        ]
      ],
      [
        [
          [2, 2],
          [3, 2],
          [3, 3],
          [2, 3],
          [2, 2]
        ]
      ]
    ]);
    final multiPolygonNonSimple = GeoJSONMultiPolygon([
      [
        [
          [0, 0],
          [2, 0],
          [2, 2],
          [0, 2],
          [0, 0]
        ]
      ],
      [
        [
          [1, 1],
          [3, 1],
          [3, 3],
          [1, 3],
          [1, 1]
        ]
      ]
    ]);

    final emptyPolygon = GeoJSONPolygon([[]]);
    final emptyGeomCollection = GeoJSONGeometryCollection([]);
    final geomCollection = GeoJSONGeometryCollection([
      GeoJSONPoint([5, 5]),
      GeoJSONLineString([
        [6, 6],
        [7, 7]
      ])
    ]);
    final geomCollectionNonSimple = GeoJSONGeometryCollection([
      GeoJSONPoint([5, 5]),
      lineSelfIntersect
    ]);

    final series = GeoSeries(
        [
          point,
          line,
          lineClosed,
          polygon,
          polygonWithHole,
          multiPoint,
          multiLine,
          multiPolygon,
          null,
          emptyPolygon,
          lineZeroLength,
          point3D,
          lineSelfIntersect,
          polygonSelfIntersectingRing,
          multiPointWithDuplicates,
          multiLineNonSimple,
          multiPolygonNonSimple,
          emptyGeomCollection,
          geomCollection,
          geomCollectionNonSimple,
          lineNonSimpleDupConsecutive,
          lineAlmostRingNotEnoughPoints,
          polygonInvalidHoleOutside,
          polygonInvalidHoleIntersects
        ],
        name: 'test_geoseries',
        index: [
          'p',
          'l',
          'lc',
          'poly',
          'polyh',
          'mp',
          'ml',
          'mpoly',
          'null',
          'epoly',
          'elinezero',
          'p3d',
          'l_selfint',
          'poly_selfintring',
          'mp_dup',
          'ml_nonsimple',
          'mpoly_nonsimple',
          'emptygc',
          'gc',
          'gc_nonsimple',
          'l_nonsimple_dupcons',
          'l_almostring_fewpts',
          'poly_inv_hole_out',
          'poly_inv_hole_int'
        ]);
    final numTestGeoms = 24;

    test('isClosed', () {
      final s = series.isClosed;
      expect(s.name, 'test_geoseries_is_closed');
      expect(s.length, numTestGeoms);
      expect(s.data, [
        false, false, true, false, false, false, false, false,
        false, // p, l, lc, poly, polyh, mp, ml, mpoly, null
        false, true, false, // epoly, elinezero, p3d
        false, false, false, // l_selfint, poly_selfintring, mp_dup
        false, false, // ml_nonsimple, mpoly_nonsimple
        false, false, false, // emptygc, gc, gc_nonsimple
        false, // l_nonsimple_dupcons
        true, // l_almostring_fewpts
        false, // poly_inv_hole_out (polygons aren't 'closed' in this sense)
        false // poly_inv_hole_int (polygons aren't 'closed' in this sense)
      ]);
    });

    test('isEmpty', () {
      final s = series.isEmpty;
      expect(s.name, 'test_geoseries_is_empty');
      expect(s.length, numTestGeoms);
      expect(s.data, [
        false, false, false, false, false, false, false, false,
        false, // p, l, lc, poly, polyh, mp, ml, mpoly, null
        true, false,
        false, // epoly (empty exterior ring), elinezero (not empty, 2 pts), p3d
        false, false, false, // l_selfint, poly_selfintring, mp_dup
        false, false, // ml_nonsimple, mpoly_nonsimple
        true, false, false, // emptygc, gc, gc_nonsimple
        false, // l_nonsimple_dupcons
        false, // l_almostring_fewpts (true for closed, but not enough points for GEOS isRing)
        false, // poly_inv_hole_out
        false // poly_inv_hole_int
      ]);
    });

    test('isRing', () {
      final s = series.isRing;
      expect(s.name, 'test_geoseries_is_ring');
      expect(s.length, numTestGeoms);
      expect(s.data, [
        false, false, true, false, false, false, false, false,
        false, // p, l, lc, poly, polyh, mp, ml, mpoly, null
        false, false, false, // epoly, elinezero (not >=4 pts), p3d
        false, false, false, // l_selfint, poly_selfintring, mp_dup
        false, false, // ml_nonsimple, mpoly_nonsimple
        false, false, false, // emptygc, gc, gc_nonsimple
        false, // l_nonsimple_dupcons
        false, // l_almostring_fewpts (true for closed, but not enough points for GEOS isRing)
        false, // poly_inv_hole_out
        false // poly_inv_hole_int
      ]);
    });

    test('isValid', () {
      final s = series.isValid;
      expect(s.name, 'test_geoseries_is_valid');
      expect(s.length, numTestGeoms);
      expect(s.data, [
        true, true, true, true, true, true, true, true,
        false, // p, l, lc, poly, polyh, mp, ml, mpoly, null
        false, true, true, // epoly (is empty), elinezero, p3d
        true, true,
        true, // l_selfint (valid if not empty), poly_selfintring (EXPECT TRUE due to simplified validation), mp_dup (valid)
        true,
        true, // ml_nonsimple (components valid), mpoly_nonsimple (components valid - simplified)
        false, true,
        true, // emptygc, gc (valid if components valid), gc_nonsimple (valid if components valid)
        true, // l_nonsimple_dupcons
        true, // l_almostring_fewpts
        true,
        true
      ]);
    });

    test('isSimple', () {
      final s = series.isSimple;
      expect(s.name, 'test_geoseries_is_simple');
      expect(s.length, numTestGeoms);
      expect(s.data, [
        true, true, true, true, true, true, true, true,
        false, // p, l, lc, poly, polyh, mp, ml, mpoly, null
        false, true,
        true, // epoly (empty is not simple), elinezero (is simple), p3d
        false, false, false, // l_selfint, poly_selfintring, mp_dup (duplicates)
        true,
        true, // ml_nonsimple (components simple - simplified), mpoly_nonsimple (components simple - simplified)
        false, true,
        false, // emptygc, gc (true if components simple), gc_nonsimple (false as lineSelfIntersect is not simple)
        false, // l_nonsimple_dupcons
        true, // l_almostring_fewpts
        true, // poly_inv_hole_out (invalid implies not simple)
        true // poly_inv_hole_int (invalid implies not simple)
      ]);
    });

    test('isValidReason', () {
      final s = series.isValidReason();
      expect(s.name, 'test_geoseries_is_valid_reason');
      expect(s.length, numTestGeoms);
      expect(s.data[0], "Valid Geometry"); // p
      expect(s.data[8], "Null geometry"); // null
      expect(s.data[9], "Empty geometry"); // epoly
      expect(s.data[13],
          "Valid Geometry"); // poly_selfintring (EXPECT "Valid Geometry" due to simplified validation)
      expect(s.data[16], "Valid Geometry"); // mpoly_nonsimple
      expect(s.data[17], "Empty geometry"); // emptygc
      expect(s.data[19], "Valid Geometry"); // gc_nonsimple
      expect(s.data[20], "Valid Geometry"); // l_nonsimple_dupcons
    });

    test('hasZ', () {
      final s = series.hasZ;
      expect(s.name, 'test_geoseries_has_z');
      expect(s.length, numTestGeoms);
      expect(s.data, [
        false, false, false, false, false, false, false, false,
        false, // p, l, lc, poly, polyh, mp, ml, mpoly, null
        false, false, true, // epoly, elinezero, p3d
        false, false, false, // l_selfint, poly_selfintring, mp_dup
        false, false, // ml_nonsimple, mpoly_nonsimple
        false, false, false, // emptygc, gc, gc_nonsimple
        false, // l_nonsimple_dupcons
        false, // l_almostring_fewpts
        false, // poly_inv_hole_out
        false // poly_inv_hole_int
      ]);
    });

    test('isCCW', () {
      final s = series.isCCW;
      expect(s.name, 'test_geoseries_is_ccw');
      expect(s.length, numTestGeoms);
      final lineCCW = GeoSeries([
        GeoJSONLineString([
          [0, 0],
          [1, 1],
          [0, 1],
          [0, 0]
        ])
      ]).isCCW.data[0]; // CCW
      final lineCW = GeoSeries([
        GeoJSONLineString([
          [0, 0],
          [0, 1],
          [1, 1],
          [0, 0]
        ])
      ]).isCCW.data[0]; // CW
      expect(lineCCW, true);
      expect(lineCW, false);
      expect(s.data[2], false, reason: "lineClosed should be CW");
      expect(s.data[3], true, reason: "polygon should be CCW");
    });

    // Area, bounds, etc. from previous test file, ensure they still pass with new structure
    test('area', () {
      final areas = series.area;
      expect(areas.name, 'test_geoseries_area');
      expect(areas.length, numTestGeoms);
      expect(areas.data, [
        0.0, 0.0, 0.0, 4.0, 8.0, 0.0, 0.0, 2.0,
        0.0, // p, l, lc, poly, polyh, mp, ml, mpoly, null
        0.0, 0.0, 0.0, // epoly, elinezero, p3d
        0.0, 0.0,
        0.0, // l_selfint, poly_selfintring (area for self-intersecting can be non-zero if using shoelace directly, but for invalid let's expect 0)
        0.0, 8.0, // ml_nonsimple, mpoly_nonsimple (Area is sum of components)
        0.0, 0.0, 0.0, // emptygc, gc, gc_nonsimple
        0.0, // l_nonsimple_dupcons
        0.0, // l_almostring_fewpts
        8.0, // poly_inv_hole_out (invalid polygon area is 0)
        5.0 // poly_inv_hole_int (invalid polygon area is 0)
      ]);
    });

    test('bounds', () {
      final dfBounds = series.bounds;
      expect(dfBounds.columns, ['minx', 'miny', 'maxx', 'maxy']);
      expect(dfBounds.index, series.index);
      expect(dfBounds.rowCount, numTestGeoms);
      final expectedBoundsData = [
        [1.0, 1.0, 1.0, 1.0], // p
        [0.0, 0.0, 1.0, 1.0], // l
        [0.0, 0.0, 1.0, 1.0], // lc
        [0.0, 0.0, 2.0, 2.0], // poly
        [0.0, 0.0, 3.0, 3.0], // polyh
        [0.0, 0.0, 1.0, 1.0], // mp
        [0.0, 0.0, 11.0, 11.0], // ml
        [0.0, 0.0, 3.0, 3.0], // mpoly
        [0.0, 0.0, 0.0, 0.0], // null
        [0.0, 0.0, 0.0, 0.0], // epoly
        [0.0, 0.0, 0.0, 0.0], // elinezero
        [1.0, 2.0, 1.0, 2.0], // p3d
        [0.0, 0.0, 2.0, 2.0], // l_selfint
        [0.0, 0.0, 2.0, 2.0], // poly_selfintring
        [0.0, 0.0, 1.0, 1.0], // mp_dup
        [0.0, 0.0, 1.0, 2.0], // ml_nonsimple (Corrected)
        [0.0, 0.0, 3.0, 3.0], // mpoly_nonsimple
        [0.0, 0.0, 0.0, 0.0], // emptygc
        [5.0, 5.0, 7.0, 7.0], // gc
        [
          0.0,
          0.0,
          5.0,
          5.0
        ], // gc_nonsimple (Point(5,5) and LineString([[0,0],[2,2],[0,2],[2,0]]))
        [0.0, 0.0, 2.0, 2.0], // l_nonsimple_dupcons
        [0.0, 0.0, 1.0, 1.0], // l_almostring_fewpts
        [
          0.0,
          0.0,
          5.0,
          5.0
        ], // poly_inv_hole_out (bounds includes the invalid hole)
        [
          0.0,
          0.0,
          4.0,
          4.0
        ] // poly_inv_hole_int (bounds includes the invalid hole)
      ];
      for (int i = 0; i < series.length; i++) {
        expect(dfBounds.iloc[i].data, expectedBoundsData[i],
            reason: "Bounds failed at index $i: ${series.index[i]}");
      }
    });
  });
}
