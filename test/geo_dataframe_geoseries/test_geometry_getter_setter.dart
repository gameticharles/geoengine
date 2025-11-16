import 'package:geoengine/geoengine.dart';

void main() {
  print('=== Testing GeoDataFrame Geometry Getter and Setter ===\n');

  // Test 1: Basic getter functionality
  print('1. Testing Geometry Getter');
  print('=' * 40);

  final gdf1 = GeoDataFrame.fromCoordinates([
    [0.0, 0.0],
    [1.0, 1.0],
    [2.0, 2.0]
  ],
      attributes: DataFrame.fromRows([
        {'id': 1, 'name': 'Point A'},
        {'id': 2, 'name': 'Point B'},
        {'id': 3, 'name': 'Point C'}
      ]));

  print('Original GeoDataFrame:');
  print(gdf1.head());
  print('');

  // Get geometry as GeoSeries
  final geomSeries = gdf1.geometry;
  print('Geometry Series:');
  print('Type: ${geomSeries.runtimeType}');
  print('Length: ${geomSeries.length}');
  print('CRS: ${geomSeries.crs}');
  print('Name: ${geomSeries.name}');
  print('Data: ${geomSeries.data}');
  print('');

  // Test 2: Setting geometry with GeoSeries
  print('2. Testing Geometry Setter with GeoSeries');
  print('=' * 40);

  final newGeometries = GeoSeries([
    GeoJSONPoint([10.0, 10.0]),
    GeoJSONPoint([20.0, 20.0]),
    GeoJSONPoint([30.0, 30.0])
  ], crs: 'EPSG:4326');

  print('New geometries to set:');
  print('${newGeometries.data}');

  gdf1.geometry = newGeometries;

  print('GeoDataFrame after setting new geometries:');
  print(gdf1.head());
  print('');

  // Test 3: Setting geometry with List of geometries
  print('3. Testing Geometry Setter with List of Geometries');
  print('=' * 40);

  final geometryList = [
    GeoJSONPoint([100.0, 100.0]),
    GeoJSONPoint([200.0, 200.0]),
    GeoJSONPoint([300.0, 300.0])
  ];

  print('Setting geometry with list: $geometryList');
  gdf1.geometry = geometryList;

  print('GeoDataFrame after setting geometry list:');
  print(gdf1.head());
  print('');

  // Test 4: Setting geometry with different geometry types
  print('4. Testing Different Geometry Types');
  print('=' * 40);

  final mixedGeometries = [
    GeoJSONPoint([0.0, 0.0]),
    GeoJSONLineString([
      [1.0, 1.0],
      [2.0, 2.0]
    ]),
    GeoJSONPolygon([
      [
        [3.0, 3.0],
        [4.0, 3.0],
        [4.0, 4.0],
        [3.0, 4.0],
        [3.0, 3.0]
      ]
    ])
  ];

  gdf1.geometry = mixedGeometries;

  print('GeoDataFrame with mixed geometry types:');
  print(gdf1.head());
  print('');

  // Test 5: Adding more geometries than existing rows
  print('5. Testing Adding More Geometries Than Rows');
  print('=' * 40);

  final moreGeometries = [
    GeoJSONPoint([1.0, 1.0]),
    GeoJSONPoint([2.0, 2.0]),
    GeoJSONPoint([3.0, 3.0]),
    GeoJSONPoint([4.0, 4.0]),
    GeoJSONPoint([5.0, 5.0]) // This should add new rows
  ];

  print('Original row count: ${gdf1.featureCount}');
  gdf1.geometry = moreGeometries;
  print('Row count after adding more geometries: ${gdf1.featureCount}');
  print('GeoDataFrame with expanded rows:');
  print(gdf1.head());
  print('');

  // Test 6: Setting fewer geometries than existing rows
  print('6. Testing Fewer Geometries Than Rows');
  print('=' * 40);

  final fewerGeometries = [
    GeoJSONPoint([10.0, 10.0]),
    GeoJSONPoint([20.0, 20.0])
  ];

  print('Setting only 2 geometries for ${gdf1.featureCount} rows');
  gdf1.geometry = fewerGeometries;
  print('GeoDataFrame after setting fewer geometries:');
  print(gdf1.head());
  print('');

  // Test 7: Geometry operations after setter
  print('7. Testing Geometry Operations After Setter');
  print('=' * 40);

  final operationGeometries = [
    GeoJSONPoint([0.0, 0.0]),
    GeoJSONPoint([1.0, 1.0]),
    GeoJSONPoint([2.0, 2.0])
  ];

  gdf1.geometry = operationGeometries;

  // Test area calculation
  final areas = gdf1.geometry.area;
  print('Areas: ${areas.data}');

  // Test centroid calculation
  final centroids = gdf1.geometry.centroid;
  print('Centroids: ${centroids.data}');

  // Test buffer operation
  final buffered = gdf1.geometry.buffer(distance: 0.1);
  print('Buffered geometries count: ${buffered.length}');
  print('');

  // Test 8: Error handling
  print('8. Testing Error Handling');
  print('=' * 40);

  try {
    gdf1.geometry = "invalid_value";
    print('ERROR: Should have thrown an exception');
  } catch (e) {
    print('Correctly caught error: $e');
  }

  try {
    gdf1.geometry = 123;
    print('ERROR: Should have thrown an exception');
  } catch (e) {
    print('Correctly caught error: $e');
  }
  print('');

  // Test 9: Creating new GeoDataFrame without geometry column
  print('9. Testing GeoDataFrame Without Initial Geometry');
  print('=' * 40);

  final df = DataFrame.fromRows([
    {'id': 1, 'name': 'Test A'},
    {'id': 2, 'name': 'Test B'}
  ]);

  final gdf2 = GeoDataFrame(df);
  print('GeoDataFrame without initial geometry:');
  print('Columns: ${gdf2.columns}');
  print('Has geometry column: ${gdf2.columns.contains(gdf2.geometryColumn)}');

  // Set geometry on GeoDataFrame without geometry column
  gdf2.geometry = [
    GeoJSONPoint([5.0, 5.0]),
    GeoJSONPoint([6.0, 6.0])
  ];

  print('After setting geometry:');
  print('Columns: ${gdf2.columns}');
  print(gdf2.head());
  print('');

  // Test 10: Verify getter returns updated values
  print('10. Testing Getter Returns Updated Values');
  print('=' * 40);

  final testGeometries = [
    GeoJSONPoint([99.0, 99.0]),
    GeoJSONPoint([88.0, 88.0])
  ];

  gdf2.geometry = testGeometries;
  final retrievedGeometry = gdf2.geometry;

  print('Set geometries: $testGeometries');
  print('Retrieved geometries: ${retrievedGeometry.data}');
  print(
      'Geometries match: ${_compareGeometries(testGeometries, retrievedGeometry.data)}');
  print('');

  print('=== All Geometry Getter/Setter Tests Complete ===');
}

bool _compareGeometries(List<GeoJSONGeometry> list1, List<dynamic> list2) {
  if (list1.length != list2.length) return false;

  for (int i = 0; i < list1.length; i++) {
    if (list1[i].runtimeType != list2[i].runtimeType) return false;

    if (list1[i] is GeoJSONPoint && list2[i] is GeoJSONPoint) {
      final p1 = list1[i] as GeoJSONPoint;
      final p2 = list2[i] as GeoJSONPoint;
      if (p1.coordinates.length != p2.coordinates.length) return false;
      for (int j = 0; j < p1.coordinates.length; j++) {
        if ((p1.coordinates[j] - p2.coordinates[j]).abs() > 1e-10) return false;
      }
    }
  }

  return true;
}
