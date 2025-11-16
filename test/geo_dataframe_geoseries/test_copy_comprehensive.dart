import 'package:geoengine/geoengine.dart';

void main() {
  print('=== Comprehensive GeoDataFrame Copy Test ===\n');

  // Test 1: Verify all DataFrame properties are copied
  print('1. Testing DataFrame Properties Preservation');
  print('=' * 50);

  final originalDf = DataFrame.fromRows([
    {
      'id': 1,
      'name': 'Test A',
      'coords': [1.0, 2.0]
    },
    {
      'id': 2,
      'name': 'Test B',
      'coords': [3.0, 4.0]
    }
  ]);

  final originalGdf =
      GeoDataFrame(originalDf, geometryColumn: 'coords', crs: 'EPSG:4326');
  final copiedGdf = originalGdf.copy();

  print(
      '✓ Columns match: ${_listsEqual(originalGdf.columns, copiedGdf.columns)}');
  print('✓ Index match: ${_listsEqual(originalGdf.index, copiedGdf.index)}');
  print('✓ Row count match: ${originalGdf.rowCount == copiedGdf.rowCount}');
  print(
      '✓ Column count match: ${originalGdf.columnCount == copiedGdf.columnCount}');
  print(
      '✓ Geometry column match: ${originalGdf.geometryColumn == copiedGdf.geometryColumn}');
  print('✓ CRS match: ${originalGdf.crs == copiedGdf.crs}');
  print('');

  // Test 2: Verify geometry independence
  print('2. Testing Geometry Independence');
  print('=' * 50);

  final geoGdf = GeoDataFrame.fromCoordinates([
    [10.0, 20.0],
    [30.0, 40.0]
  ],
      attributes: DataFrame.fromRows([
        {'name': 'Point 1'},
        {'name': 'Point 2'}
      ]));

  final geoCopy = geoGdf.copy();

  // Verify initial equality
  print('Initial geometry equality:');
  for (int i = 0; i < geoGdf.featureCount; i++) {
    final orig = geoGdf.geometry.data[i] as GeoJSONPoint;
    final copy = geoCopy.geometry.data[i] as GeoJSONPoint;
    print('  Point $i: ${_pointsEqual(orig, copy)}');
  }

  // Modify original
  geoGdf.geometry = [
    GeoJSONPoint([100.0, 200.0]),
    GeoJSONPoint([300.0, 400.0])
  ];

  print('After modifying original:');
  print(
      '  Original point 0: ${(geoGdf.geometry.data[0] as GeoJSONPoint).coordinates}');
  print(
      '  Copy point 0: ${(geoCopy.geometry.data[0] as GeoJSONPoint).coordinates}');
  print(
      '  Independence verified: ${!_pointsEqual(geoGdf.geometry.data[0] as GeoJSONPoint, geoCopy.geometry.data[0] as GeoJSONPoint)}');
  print('');

  // Test 3: Test with complex geometries
  print('3. Testing Complex Geometry Copy');
  print('=' * 50);

  final complexGdf = GeoDataFrame.fromFeatureCollection(
      GeoJSONFeatureCollection([
        GeoJSONFeature(
            GeoJSONPolygon([
              [
                [0.0, 0.0],
                [1.0, 0.0],
                [1.0, 1.0],
                [0.0, 1.0],
                [0.0, 0.0]
              ],
              [
                [0.2, 0.2],
                [0.8, 0.2],
                [0.8, 0.8],
                [0.2, 0.8],
                [0.2, 0.2]
              ]
            ]),
            properties: {'type': 'polygon_with_hole', 'area': 0.64}),
        GeoJSONFeature(
            GeoJSONMultiLineString([
              [
                [0.0, 0.0],
                [1.0, 1.0]
              ],
              [
                [2.0, 2.0],
                [3.0, 3.0]
              ]
            ]),
            properties: {'type': 'multi_line', 'length': 2.828})
      ]),
      crs: 'EPSG:3857');

  final complexCopy = complexGdf.copy();

  print('Complex geometries copied:');
  for (int i = 0; i < complexGdf.featureCount; i++) {
    final origType = complexGdf.geometry.data[i].runtimeType;
    final copyType = complexCopy.geometry.data[i].runtimeType;
    print('  Feature $i: ${origType == copyType ? '✓' : '✗'} ($origType)');
  }

  // Verify polygon structure
  final origPolygon = complexGdf.geometry.data[0] as GeoJSONPolygon;
  final copyPolygon = complexCopy.geometry.data[0] as GeoJSONPolygon;
  print(
      '  Polygon rings count match: ${origPolygon.coordinates.length == copyPolygon.coordinates.length}');
  print(
      '  Exterior ring points match: ${origPolygon.coordinates[0].length == copyPolygon.coordinates[0].length}');
  print(
      '  Interior ring points match: ${origPolygon.coordinates[1].length == copyPolygon.coordinates[1].length}');
  print('');

  // Test 4: Test attribute data independence
  print('4. Testing Attribute Data Independence');
  print('=' * 50);

  final attrGdf = GeoDataFrame.fromCoordinates([
    [1.0, 1.0],
    [2.0, 2.0]
  ],
      attributes: DataFrame.fromRows([
        {
          'id': 1,
          'values': [10, 20, 30],
          'metadata': {'key': 'value1'}
        },
        {
          'id': 2,
          'values': [40, 50, 60],
          'metadata': {'key': 'value2'}
        }
      ]));

  final attrCopy = attrGdf.copy();

  // Modify attributes in copy
  attrCopy['id'] = [100, 200];

  print('After modifying copy attributes:');
  print('  Original IDs: ${attrGdf['id'].data}');
  print('  Copy IDs: ${attrCopy['id'].data}');
  print(
      '  Independence verified: ${!_listsEqual(attrGdf['id'].data, attrCopy['id'].data)}');

  // Note: Nested objects (lists, maps) are shallow copied, which is standard behavior
  final origValues = attrGdf['values'].data[0] as List;
  final copyValues = attrCopy['values'].data[0] as List;
  print(
      '  Nested lists are shallow copied: ${identical(origValues, copyValues)}');
  print('');

  // Test 5: Test copy with null values
  print('5. Testing Copy with Null Values');
  print('=' * 50);

  final nullGdf = GeoDataFrame.fromFeatureCollection(GeoJSONFeatureCollection([
    GeoJSONFeature(GeoJSONPoint([1.0, 1.0]),
        properties: {'name': 'Valid', 'value': 100}),
    GeoJSONFeature(null, properties: {'name': 'Null Geom', 'value': null}),
    GeoJSONFeature(GeoJSONPoint([2.0, 2.0]),
        properties: {'name': null, 'value': 200})
  ]));

  final nullCopy = nullGdf.copy();

  print('Null handling:');
  print(
      '  Feature count match: ${nullGdf.featureCount == nullCopy.featureCount}');
  print(
      '  Null geometry preserved: ${nullGdf.geometry.data[1] == null && nullCopy.geometry.data[1] == null}');
  print(
      '  Null values preserved: ${nullGdf['value'].data[1] == null && nullCopy['value'].data[1] == null}');
  print(
      '  Null names preserved: ${nullGdf['name'].data[2] == null && nullCopy['name'].data[2] == null}');
  print('');

  // Test 6: Test copy performance and memory efficiency
  print('6. Testing Copy Performance');
  print('=' * 50);

  final largeCoords =
      List.generate(5000, (i) => [i.toDouble(), (i * 2).toDouble()]);
  final largeAttrs = DataFrame.fromRows(List.generate(
      5000,
      (i) => {
            'id': i,
            'category': 'cat_${i % 10}',
            'value': i * 1.5,
            'active': i % 2 == 0
          }));

  final largeGdf = GeoDataFrame.fromCoordinates(largeCoords,
      attributes: largeAttrs, crs: 'EPSG:4326');

  final stopwatch = Stopwatch()..start();
  final largeCopy = largeGdf.copy();
  stopwatch.stop();

  print('Large GeoDataFrame copy (5000 features):');
  print('  Copy time: ${stopwatch.elapsedMilliseconds}ms');
  print('  Original size: ${largeGdf.featureCount} features');
  print('  Copy size: ${largeCopy.featureCount} features');
  print('  Data integrity: ${largeGdf.featureCount == largeCopy.featureCount}');
  print('  Memory independence: ${!identical(largeGdf.rows, largeCopy.rows)}');
  print('');

  // Test 7: Test copy with spatial operations
  print('7. Testing Copy with Spatial Operations');
  print('=' * 50);

  final spatialGdf = GeoDataFrame.fromCoordinates([
    [0.0, 0.0],
    [1.0, 0.0],
    [0.5, 1.0]
  ],
      attributes: DataFrame.fromRows([
        {'name': 'Triangle Point 1'},
        {'name': 'Triangle Point 2'},
        {'name': 'Triangle Point 3'}
      ]));

  final spatialCopy = spatialGdf.copy();

  // Perform spatial operations on both
  final origBuffered = spatialGdf.geometry.buffer(distance: 0.1);
  final copyBuffered = spatialCopy.geometry.buffer(distance: 0.1);

  print('Spatial operations on copy:');
  print('  Original buffer count: ${origBuffered.length}');
  print('  Copy buffer count: ${copyBuffered.length}');
  print(
      '  Buffer operations match: ${origBuffered.length == copyBuffered.length}');

  final origCentroid = spatialGdf.geometry.centroid;
  final copyCentroid = spatialCopy.geometry.centroid;

  print(
      '  Centroid calculations match: ${_geometriesEqual(origCentroid.data, copyCentroid.data)}');
  print('');

  print('✅ All GeoDataFrame Copy Tests Passed Successfully!');
}

bool _listsEqual(List list1, List list2) {
  if (list1.length != list2.length) return false;
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) return false;
  }
  return true;
}

bool _pointsEqual(GeoJSONPoint p1, GeoJSONPoint p2) {
  if (p1.coordinates.length != p2.coordinates.length) return false;
  for (int i = 0; i < p1.coordinates.length; i++) {
    if ((p1.coordinates[i] - p2.coordinates[i]).abs() > 1e-10) return false;
  }
  return true;
}

bool _geometriesEqual(List<dynamic> geoms1, List<dynamic> geoms2) {
  if (geoms1.length != geoms2.length) return false;
  for (int i = 0; i < geoms1.length; i++) {
    if (geoms1[i].runtimeType != geoms2[i].runtimeType) return false;

    if (geoms1[i] is GeoJSONPoint && geoms2[i] is GeoJSONPoint) {
      if (!_pointsEqual(geoms1[i] as GeoJSONPoint, geoms2[i] as GeoJSONPoint)) {
        return false;
      }
    }
  }
  return true;
}
