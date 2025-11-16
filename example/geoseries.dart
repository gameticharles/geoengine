import 'package:geoengine/geoengine.dart';

void main() async {
  var series = GeoSeries([
    GeoJSONLineString([
      [0, 0],
      [1, 1],
      [1, -1],
      [0, 1]
    ]),
    GeoJSONLineString([
      [0, 0],
      [1, 1],
      [1, -1]
    ]),
    GeoJSONPoint([0, 0]),
    GeoJSONPolygon([
      [
        [10, 10],
        [10, 20],
        [20, 20],
        [20, 10],
        [10, 10]
      ]
    ]),
    null
  ]);

  ///
  var counts = series.countCoordinates;
  print(counts);

  series = GeoSeries([
    GeoJSONMultiPoint([
      [0, 0],
      [1, 1],
      [1, -1],
      [0, 1]
    ]),
    GeoJSONMultiLineString([
      [
        [0, 0],
        [1, 1]
      ],
      [
        [-1, 0],
        [1, 0]
      ]
    ]),
    GeoJSONLineString([
      [0, 0],
      [1, 1],
      [1, -1]
    ]),
    GeoJSONPoint([0, 0]),
  ]);

  ///
  counts = series.countGeometries;
  print(counts);

  series = GeoSeries([
    GeoJSONPolygon([
      [
        [0, 0],
        [0, 5],
        [5, 5],
        [5, 0],
        [0, 0]
      ], // Outer ring
      [
        [1, 1],
        [1, 4],
        [4, 4],
        [4, 1],
        [1, 1]
      ], // Inner ring
    ]),
    GeoJSONPolygon([
      [
        [0, 0],
        [0, 5],
        [5, 5],
        [5, 0],
        [0, 0]
      ], // Outer ring
      [
        [1, 1],
        [1, 2],
        [2, 2],
        [2, 1],
        [1, 1]
      ], // First inner ring
      [
        [3, 2],
        [3, 3],
        [4, 3],
        [4, 2],
        [3, 2]
      ], // Second inner ring
    ]),
    GeoJSONPoint([0, 1]),
  ]);

  ///
  counts = series.countInteriorRings;
  print(counts);

  series = GeoSeries([
    GeoJSONPoint([0, 0]), // empty point
    GeoJSONPoint([2, 1]), // non-empty point
    null, // null geometry
  ]);
  final empty = series.isEmpty;
  print(empty);

  series = GeoSeries([
    GeoJSONLineString([
      [0, 0],
      [1, 1],
      [0, 1],
      [0, 0]
    ]), // closed
    GeoJSONLineString([
      [0, 0],
      [1, 1],
      [0, 1]
    ]), // not closed
    GeoJSONPolygon([
      [
        [0, 0],
        [0, 1],
        [1, 1],
        [0, 0]
      ]
    ]), // polygon (returns false)
    GeoJSONPoint([3, 3]), // point (returns false)
  ]);
  final closed = series.isClosed;
  print(closed);

  series = GeoSeries([
    GeoJSONLineString([
      [0, 0],
      [1, 1],
      [1, -1]
    ]), // not closed
    GeoJSONLineString([
      [0, 0],
      [1, 1],
      [1, -1],
      [0, 0]
    ]), // closed
    GeoJSONPoint([3, 3]), // point (returns false)
  ]);
  final rings = series.isRing;
  print(rings);

  series = GeoSeries([
    GeoJSONPoint([0, 1]), // 2D point
    GeoJSONPoint([0, 1, 2]), // 3D point with z-component
  ]);
  final hasZ = series.hasZ;
  print(hasZ);

  series = GeoSeries([
    GeoJSONLineString([
      [0, 0],
      [1, 1],
      [0, 1]
    ]),
    GeoJSONLineString([
      [10, 0],
      [10, 5],
      [0, 0]
    ]),
    GeoJSONMultiLineString([
      [
        [0, 0],
        [1, 0]
      ],
      [
        [-1, 0],
        [1, 0]
      ]
    ]),
    GeoJSONPolygon([
      [
        [0, 0],
        [1, 1],
        [0, 1],
        [0, 0]
      ]
    ]),
    GeoJSONPoint([0, 1]),
    GeoJSONGeometryCollection([
      GeoJSONPoint([0, 1]),
      GeoJSONLineString([
        [10, 0],
        [10, 5],
        [0, 0]
      ])
    ])
  ]);
  final lengths = series.geomLength;
  print(lengths);

  // Create two GeoSeries
  final series1 = GeoSeries([
    GeoJSONPolygon([
      [
        [0, 0],
        [1, 1],
        [0, 1],
        [0, 0]
      ]
    ]),
    GeoJSONLineString([
      [0, 0],
      [0, 2]
    ]),
    GeoJSONLineString([
      [0, 0],
      [0, 1]
    ]),
    GeoJSONPoint([0, 1]),
  ]);

  ///
  final series2 = GeoSeries([
    GeoJSONPolygon([
      [
        [0, 0],
        [2, 2],
        [0, 2],
        [0, 0]
      ]
    ]),
    GeoJSONPolygon([
      [
        [0, 0],
        [1, 2],
        [0, 2],
        [0, 0]
      ]
    ]),
    GeoJSONLineString([
      [0, 0],
      [0, 2]
    ]),
    GeoJSONPoint([0, 1]),
  ]);

  ///
  // Check if each geometry contains a point
  final point = GeoJSONPoint([0, 1]);
  final containsPoint = series1.contains(point);
  print(containsPoint);
  // Check if each geometry in series2 contains the corresponding geometry in series1
  // with alignment based on indices
  final containsAligned = series2.contains(series1, align: true);
  print(containsAligned);
  // Check if each geometry in series2 contains the corresponding geometry in series1
  // without alignment (just by position)
  final containsUnaligned = series2.contains(series1, align: false);
  print(containsUnaligned);

  final x = [2.5, 5, -3.0];
  final y = [0.5, 1, 1.5];
  final points = GeoSeries.fromXY(x, y, crs: "EPSG:4326");
  print(points.toWkt());
}
