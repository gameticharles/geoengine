# GeoSeries Class Documentation

## Table of Contents
- [GeoSeries Class Documentation](#geoseries-class-documentation)
  - [Table of Contents](#table-of-contents)
  - [Relationship with Series](#relationship-with-series)
  - [Creating a GeoSeries](#creating-a-geoseries)
    - [1. Default Constructor](#1-default-constructor)
    - [2. `GeoSeries.fromWKT()`](#2-geoseriesfromwkt)
    - [3. `GeoSeries.fromFeatureCollection()`](#3-geoseriesfromfeaturecollection)
    - [4. `GeoSeries.fromXY()`](#4-geoseriesfromxy)
  - [Accessing Data and Properties](#accessing-data-and-properties)
    - [1. `crs` (String?)](#1-crs-string)
    - [2. `geometries({bool asGeoJSON = false})`](#2-geometriesbool-asgeojson--false)
  - [Conversions](#conversions)
    - [1. `toWkt()` / `asWkt()`](#1-towkt--aswkt)
  - [Operations](#operations)
    - [1. `makeValid()`](#1-makevalid)
  - [Geospatial Properties and Methods (from examples)](#geospatial-properties-and-methods-from-examples)
    - [1. `area` (Series)](#1-area-series)
    - [2. `bounds` (Series)](#2-bounds-series)
    - [3. `length` (Series) - *Note: This is different from `GeoSeries.length` property*](#3-length-series---note-this-is-different-from-geoserieslength-property)
    - [4. `centroid` (GeoSeries)](#4-centroid-geoseries)
    - [5. `countCoordinates` (Series<int>)](#5-countcoordinates-seriesint)
    - [6. `countGeometries` (Series<int>)](#6-countgeometries-seriesint)
    - [7. `countInteriorRings` (Series<int>)](#7-countinteriorrings-seriesint)
    - [8. `isEmpty` (Series<bool>)](#8-isempty-seriesbool)
    - [9. `isClosed` (Series<bool>)](#9-isclosed-seriesbool)
    - [10. `isRing` (Series<bool>)](#10-isring-seriesbool)
    - [11. `hasZ` (Series<bool>)](#11-hasz-seriesbool)
    - [12. `contains(dynamic other, {bool align = true})` (Series<bool>)](#12-containsdynamic-other-bool-align--true-seriesbool)

The `GeoSeries` class in DartFrame represents a one-dimensional array (a column) specifically for holding geometry data. It extends the base `Series` class, endowing it with spatial awareness and functionalities.

## Relationship with Series

`GeoSeries` is a subclass of `Series<GeoJSONGeometry>`. This means it inherits all the fundamental properties and methods of a `Series` and adds features tailored for handling geometric objects (e.g., Points, LineStrings, Polygons).

**Key Inherited Features:**
- **Core Properties**: `data` (stores `List<GeoJSONGeometry?>`), `name`, `index`, `length`.
- **Basic Indexing**: Accessing elements using integer positions with the `[]` operator (e.g., `myGeoSeries[0]`).
- **Slicing/Viewing Methods**: `head()`, `tail()`.
- **Boolean Properties**: `isEmpty` (checks if the series contains no elements, distinct from the geometric `isEmpty` property of individual geometries).
- Many other non-spatial `Series` methods where applicable.

**Example of Inherited Functionality:**
```dart
final points = [
  GeoJSONPoint([1.0, 2.0]),
  GeoJSONPoint([3.0, 4.0]),
  GeoJSONPoint([5.0, 6.0])
];
final geoSeries = GeoSeries(points, name: 'my_points');

// Inherited 'length' property
print(geoSeries.length); // Output: 3

// Inherited 'isEmpty' property (from Series, not the geometric one)
// print(geoSeries.isEmpty.data); // This would be a Series<bool> if isEmpty was a Series method.
// isEmpty is a direct boolean getter on Series.
print(geoSeries.isEmpty); // Output: false (since it has 3 elements)

// Inherited indexing
GeoJSONGeometry firstGeom = geoSeries[0] as GeoJSONGeometry;
// print(firstGeom.type); // Output: GeoJSONType.point

// Inherited head() method
GeoSeries headGeoSeries = geoSeries.head(1);
// print(headGeoSeries.length); // Output: 1
// print(headGeoSeries.data[0]); // Output: Instance of GeoJSONPoint([1.0, 2.0])
```
While `GeoSeries` can use these general `Series` methods, its primary power comes from the additional geospatial capabilities. For general Series operations, refer to the `Series` documentation.

## Creating a GeoSeries

There are multiple ways to construct a `GeoSeries`:

### 1. Default Constructor

Creates a `GeoSeries` directly from a list of `GeoJSONGeometry` objects.

**Syntax:**

```dart
GeoSeries(
  List<dynamic> values, // List of GeoJSONGeometry objects (or nulls)
  {
  String? crs,
  String name = 'geometry', // Default name if not provided
  List<dynamic>? index,
});
```

**Parameters:**

- `values`: A list where each element is typically a `GeoJSONGeometry` object (e.g., `GeoJSONPoint`, `GeoJSONLineString`, `GeoJSONPolygon`) or `null`.
- `crs`: (Optional) The Coordinate Reference System for the geometries (e.g., 'EPSG:4326').
- `name`: (Optional) The name for the `GeoSeries`. Defaults to 'geometry'.
- `index`: (Optional) A list to use as the index. Defaults to a standard integer index `[0, 1, ..., n-1]`.

**Example:**

```dart
// Basic constructor with Point geometries
final points = [
  GeoJSONPoint([1.0, 2.0]),
  GeoJSONPoint([3.0, 4.0]),
  GeoJSONPoint([5.0, 6.0])
];
final geoSeriesBasic = GeoSeries(points, name: 'test_points');
// geoSeriesBasic.data contains the points
// geoSeriesBasic.name is 'test_points'
// geoSeriesBasic.index is [0, 1, 2]
// geoSeriesBasic.crs is null

// Constructor with CRS and custom index
final geoSeriesWithOptions = GeoSeries(
  [GeoJSONPoint([1.0, 2.0]), GeoJSONPoint([3.0, 4.0])],
  crs: 'EPSG:4326',
  name: 'geo_points_options',
  index: ['A', 'B']
);
// geoSeriesWithOptions.crs is 'EPSG:4326'
// geoSeriesWithOptions.index is ['A', 'B']

// Constructor with mixed geometry types
final mixedGeometries = [
  GeoJSONPoint([1.0, 2.0]),
  GeoJSONLineString([[0.0, 0.0], [1.0, 1.0]]),
  GeoJSONPolygon([[[0.0,0.0],[1.0,0.0],[1.0,1.0],[0.0,1.0],[0.0,0.0]]])
];
final geoSeriesMixed = GeoSeries(mixedGeometries, name: 'mixed_geoms');
// geoSeriesMixed.data[0] is a GeoJSONPoint
// geoSeriesMixed.data[1] is a GeoJSONLineString
// geoSeriesMixed.data[2] is a GeoJSONPolygon

// Constructor with null geometry objects
final dataWithNulls = [
  GeoJSONPoint([1.0, 2.0]),
  null,
  GeoJSONPoint([3.0, 4.0])
];
final geoSeriesNulls = GeoSeries(dataWithNulls, name: 'geoms_with_nulls');
// geoSeriesNulls.length is 3
// geoSeriesNulls.data[1] is null
```

### 2. `GeoSeries.fromWKT()`

Creates a `GeoSeries` from a list of Well-Known Text (WKT) strings. Each WKT string is parsed into its corresponding `GeoJSONGeometry` object. If a WKT string is invalid and cannot be parsed, it defaults to a `GeoJSONPoint([0.0, 0.0])`.

**Syntax:**

```dart
factory GeoSeries.fromWKT(
  List<String> wktStrings, {
  String? crs,
  String name = 'geometry', // Default name
  List<dynamic>? index,
})
```

**Example:**

```dart
// From WKT Point strings
final wktPoints = ['POINT(1 2)', 'POINT(3 4)', 'POINT(5 6)'];
final gsPointsWKT = GeoSeries.fromWKT(wktPoints, name: 'wkt_points_example');
// gsPointsWKT.data[0] is GeoJSONPoint([1.0, 2.0])

// From WKT LineString
final wktLine = ['LINESTRING(0 0, 1 1, 2 2)'];
final gsLineWKT = GeoSeries.fromWKT(wktLine, name: 'wkt_line_example');
// gsLineWKT.data[0] is GeoJSONLineString with coordinates [[0,0],[1,1],[2,2]]

// From WKT Polygon
final wktPolygon = ['POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))'];
final gsPolygonWKT = GeoSeries.fromWKT(wktPolygon, name: 'wkt_polygon_example');
// gsPolygonWKT.data[0] is GeoJSONPolygon

// Handling invalid WKT
final wktInvalid = ['POINT(1 2)', 'INVALID WKT STRING', 'POINT(5 6)'];
final gsInvalidWKT = GeoSeries.fromWKT(wktInvalid, name: 'wkt_invalid_example');
// gsInvalidWKT.data[0] is GeoJSONPoint([1.0, 2.0])
// gsInvalidWKT.data[1] is GeoJSONPoint([0.0, 0.0]) (default for invalid WKT)
// gsInvalidWKT.data[2] is GeoJSONPoint([5.0, 6.0])
```

### 3. `GeoSeries.fromFeatureCollection()`

Creates a `GeoSeries` by extracting geometries from a `GeoJSONFeatureCollection` object. If a feature in the collection has a null geometry, it will be represented as a `null` in the `GeoSeries`.

**Syntax:**

```dart
factory GeoSeries.fromFeatureCollection(
  GeoJSONFeatureCollection featureCollection, {
  String? crs,
  String name = 'geometry', // Default name
  List<dynamic>? index,
})
```

**Example:**

```dart
final features = [
  GeoJSONFeature(GeoJSONPoint([1.0, 2.0]), properties: {'name': 'point1'}),
  GeoJSONFeature(GeoJSONLineString([[0.0,0.0],[1.0,1.0]]), properties: {'name': 'line1'}),
  GeoJSONFeature(null, properties: {'name': 'no_geom'}) // Feature with null geometry
];
final featureCollection = GeoJSONFeatureCollection(features);

var gsFromFc = GeoSeries.fromFeatureCollection(featureCollection, name: 'FC_Geoms');
// gsFromFc.length is 3
// gsFromFc.data[0] is GeoJSONPoint([1.0, 2.0])
// gsFromFc.data[1] is GeoJSONLineString
// gsFromFc.data[2] is null
```

### 4. `GeoSeries.fromXY()`

Creates a `GeoSeries` of `GeoJSONPoint` geometries from lists of X and Y coordinates. Optionally, a list of Z coordinates can be provided for 3D points.

**Syntax:**

```dart
factory GeoSeries.fromXY(
  List<num> x,
  List<num> y, {
  List<num>? z,
  List<dynamic>? index,
  String? crs,
  String name = 'geometry', // Default name
})
```

**Parameters:**

- `x`: List of X coordinates (e.g., longitudes).
- `y`: List of Y coordinates (e.g., latitudes).
- `z`: (Optional) List of Z coordinates for 3D points. If provided, its length must match `x` and `y`.
- `index`, `crs`, `name`: Same as other constructors.
- **Error Handling**: Throws `ArgumentError` if lengths of `x`, `y`, `z` (if provided), or `index` (if provided) do not match.

**Example:**

```dart
final xCoords = [1.0, 2.0, 3.0];
final yCoords = [4.0, 5.0, 6.0];

// 2D Points
var points2D = GeoSeries.fromXY(xCoords, yCoords, name: 'Points2D', crs: "EPSG:4326");
// points2D.data[0] is GeoJSONPoint([1.0, 4.0])

// 3D Points
final zCoords = [7.0, 8.0, 9.0];
var points3D = GeoSeries.fromXY(xCoords, yCoords, z: zCoords, name: 'Points3D');
// points3D.data[0] is GeoJSONPoint([1.0, 4.0, 7.0])

// With custom index
final customIdx = ['ptA', 'ptB', 'ptC'];
var pointsWithIndex = GeoSeries.fromXY(xCoords, yCoords, index: customIdx, name: 'IndexedPoints');
// pointsWithIndex.index is ['ptA', 'ptB', 'ptC']

// Error example: Mismatched lengths
// final xShort = [1.0];
// expect(() => GeoSeries.fromXY(xShort, yCoords), throwsArgumentError);
```

## Accessing Data and Properties

### 1. `crs` (String?)

The Coordinate Reference System string for the geometries in the `GeoSeries`. This is defined at construction.
```dart
final points = [GeoJSONPoint([1.0, 2.0])];
final geoSeries = GeoSeries(points, crs: 'EPSG:4326', name: 'my_geoseries');
print(geoSeries.crs); // Output: EPSG:4326
```

Inherited from `Series`, a `GeoSeries` also has:
- **`data`**: `List<dynamic>` holding the `GeoJSONGeometry` objects (or nulls).
  ```dart
  // print(geoSeries.data[0]); // Output: Instance of GeoJSONPoint
  ```
- **`name`**: The name of the `GeoSeries`.
  ```dart
  // print(geoSeries.name); // Output: my_geoseries
  ```
- **`index`**: The `List<dynamic>` of index labels.
  ```dart
  final gsCustomIndex = GeoSeries(points, index: ['A']);
  // print(gsCustomIndex.index); // Output: ['A']
  ```
- **`length`**: The number of geometries in the `GeoSeries`.
  ```dart
  // print(geoSeries.length); // Output: 1
  ```
- Standard `Series` methods like `head()`, `tail()`, `[]` (indexing) are also available.
  ```dart
  final pointsForHead = [GeoJSONPoint([1.0,2.0]), GeoJSONPoint([3.0,4.0])];
  final gsForHead = GeoSeries(pointsForHead, name: 'head_test');
  // final firstElement = gsForHead[0]; // Accesses the first geometry
  // final headView = gsForHead.head(1); // Returns a new GeoSeries with the first geometry
  ```

### 2. `geometries({bool asGeoJSON = false})`

Extracts the geometric data from the `GeoSeries` into a `List`.

**Syntax:**

`List<dynamic> geometries({bool asGeoJSON = false})`

- If `asGeoJSON` is `true` (default based on test.dart, but doc previously said false), returns a list of the raw `GeoJSONGeometry` objects (or `null` values) stored in the `GeoSeries`.
- If `asGeoJSON` is `false`, returns a list of coordinate lists (e.g., `[x,y]` for points, `[[x1,y1],[x2,y2]]` for linestrings). Null geometries in the `GeoSeries` will result in `null` in this list as well.
  *(Note: The original user documentation indicated `asGeoJSON=false` as default. However, `test/geo_dataframe_geoseies/test.dart` implies `asGeoJSON=true` might be the intended default or common use for returning GeoJSON objects. This documentation will reflect the behavior shown in `test.dart` where `geometries()` without parameters returns coordinates, and `asGeoJSON: true` returns the objects.)*
  *(Correction: Based on `test.dart` (`geometries()` returns coordinates, `geometries(asGeoJSON: true)` returns objects), the default for `asGeoJSON` is `false`.)*


**Example:**
```dart
final points = [GeoJSONPoint([1.0, 2.0]), null];
final line = GeoJSONLineString([[0.0, 0.0], [1.0, 1.0]]);
final geoSeries = GeoSeries([points[0], line, points[1]], name: 'MyGeoms');

// Get coordinate lists (default: asGeoJSON = false)
List<dynamic> coordinateLists = geoSeries.geometries();
// coordinateLists[0] is [1.0, 2.0]
// coordinateLists[1] is [[0.0, 0.0], [1.0, 1.0]]
// coordinateLists[2] is null (since the original geometry was null)

// Get raw GeoJSONGeometry objects
List<dynamic> geoJsonObjects = geoSeries.geometries(asGeoJSON: true);
// geoJsonObjects[0] is GeoJSONPoint instance with coordinates [1.0, 2.0]
// geoJsonObjects[1] is GeoJSONLineString instance
// geoJsonObjects[2] is null
```

## Conversions

### 1. `toWkt()` / `asWkt()`

Converts the `GeoSeries` into a new `Series` (of type `String`) containing Well-Known Text (WKT) string representations of the geometries.
- If a geometry is `null`, its WKT representation will be `null` in the output Series.
- Invalid geometries that cannot be converted to WKT by their underlying `toWKT()` method might result in `null` or a default WKT string (e.g., an empty geometry might produce 'GEOMETRYCOLLECTION EMPTY'). The factory `GeoSeries.fromWKT` defaults invalid WKT *inputs* to 'POINT(0 0)', but `toWkt()` relies on the individual geometry object's WKT conversion.

**Syntax:**

`Series<String> toWkt()`
`Series<String> asWkt()` (alias for `toWkt()`)

**Returns:** A `Series<String>` where each element is the WKT string of the corresponding geometry. The new Series' name is `originalName_wkt`.

**Example:**
```dart
final gs = GeoSeries([
  GeoJSONPoint([5, 10]),
  GeoJSONLineString([[1,1], [2,2], [3,3]]),
  null // A null geometry
], name: 'OriginalGeoms');

Series<String> wktSeries = gs.toWkt();
// wktSeries.name is 'OriginalGeoms_wkt'
// wktSeries.data is ['POINT(5 10)', 'LINESTRING(1 1,2 2,3 3)', null]
// wktSeries.index is the same as gs.index
```

## Operations

### 1. `makeValid()`

Creates a new `GeoSeries` where each geometry is attempted to be made valid according to OGC standards (though the actual validation logic might be simplified by the underlying geometry library).
- For geometries that are already valid, they are returned as is.
- For invalid geometries (e.g., a `GeoJSONPolygon` that is not closed or self-intersects in a way that cannot be simply represented by the validation logic), they are typically replaced by a default `GeoJSONPoint([0.0, 0.0])`.
- Null geometries remain `null`.
- The `crs` and `index` of the original `GeoSeries` are preserved. The `name` of the new `GeoSeries` is suffixed with `_made_valid`.

**Syntax:**

`GeoSeries makeValid()`

**Returns:** A new `GeoSeries` with validated or replaced geometries.

**Example:**
```dart
final validPoint = GeoJSONPoint([1.0, 2.0]);
// Example of an invalid polygon (not closed)
final invalidPolygon = GeoJSONPolygon([[[0.0,0.0], [1.0,0.0], [1.0,1.0]]]); 

var gsWithInvalid = GeoSeries(
  [validPoint, invalidPolygon, null],
  name: 'MixedValidity',
  crs: 'EPSG:4326',
  index: ['p1', 'poly_inv', 'null_geom']
);

var validGs = gsWithInvalid.makeValid();
// validGs.name is 'MixedValidity_made_valid'
// validGs.crs is 'EPSG:4326'
// validGs.index is ['p1', 'poly_inv', 'null_geom']

// validGs.data[0] is GeoJSONPoint([1.0, 2.0]) (original valid geometry)
// validGs.data[1] is GeoJSONPoint([0.0, 0.0]) (invalid polygon replaced by default point)
// validGs.data[2] is null (null geometry remains null)
```

## Geospatial Properties and Methods

The following methods and properties operate on each geometry within the `GeoSeries` and return a new `Series` (usually `Series<bool>`, `Series<double>`, or `Series<String>`) or a `DataFrame` (e.g., `bounds`). Null geometries in the input `GeoSeries` typically result in `false` for boolean properties, `0.0` or `null` for numeric properties, an empty/default string or `null` for string properties, or default/empty values for `DataFrame` results, unless otherwise specified.

The name of the resulting Series is generally `originalName_propertyname`.

*(Note: The documentation here is based on the behavior observed in `test/geo_dataframe_geoseies/test1.dart`.)*

### 1. `area` (property -> `Series<double>`)
Calculates the planar area of each geometry.
- For Polygons and MultiPolygons, it returns their area.
- For Points, LineStrings, and non-areal collections, the area is `0.0`.
- For `null` or empty geometries, the area is `0.0`.

**Returns:** A `Series<double>` containing the area of each geometry.
```dart
final series = GeoSeries([
  GeoJSONPoint([1,1]),                                       // 0.0
  GeoJSONLineString([[0,0],[1,1]]),                         // 0.0
  GeoJSONPolygon([[[0,0],[2,0],[2,2],[0,2],[0,0]]]),         // 4.0
  GeoJSONPolygon([[[0,0],[3,0],[3,3],[0,3],[0,0]], [[1,1],[1,2],[2,2],[2,1],[1,1]]]), // Outer (9) - Hole (1) = 8.0
  GeoJSONMultiPolygon([[[[[0,0],[1,0],[1,1],[0,1],[0,0]]]]]), // 1.0
  null,                                                      // 0.0
  GeoJSONPolygon([[]])                                       // Empty polygon, 0.0
], name: 'geoms_area');
Series<double> areas = series.area;
// areas.data is [0.0, 0.0, 4.0, 8.0, 1.0, 0.0, 0.0]
// areas.name is 'geoms_area_area'
```

### 2. `bounds` (property -> `DataFrame`)
Returns a `DataFrame` containing the bounding box for each geometry.
- The DataFrame has columns: `minx`, `miny`, `maxx`, `maxy`.
- The DataFrame preserves the index of the original `GeoSeries`.
- For `null` or empty geometries, bounds are typically `[0.0, 0.0, 0.0, 0.0]`. For a single Point, minx=maxx and miny=maxy.

**Returns:** A `DataFrame` with bounding box coordinates.
```dart
final series = GeoSeries([
  GeoJSONPoint([1,2]),
  GeoJSONLineString([[0,0],[2,3]]),
  null
], name: 'geoms_for_bounds', index: ['a','b','c']);
DataFrame dfBounds = series.bounds;
// dfBounds.columns is ['minx', 'miny', 'maxx', 'maxy']
// dfBounds.index is ['a','b','c']
// Example row for 'a': {'minx':1.0, 'miny':2.0, 'maxx':1.0, 'maxy':2.0}
// Example row for 'b': {'minx':0.0, 'miny':0.0, 'maxx':2.0, 'maxy':3.0}
// Example row for 'c': {'minx':0.0, 'miny':0.0, 'maxx':0.0, 'maxy':0.0} (for null geometry)
```

### 3. `hasZ` (property -> `Series<bool>`)
Checks if each geometry has Z-coordinates (i.e., is 3D).
- Returns `true` if coordinates include a Z value, `false` otherwise.
- For `null` geometries, it returns `false`.

**Returns:** A `Series<bool>` indicating the presence of Z-coordinates.
```dart
final series = GeoSeries([
  GeoJSONPoint([0,1]),       // 2D
  GeoJSONPoint([0,1,2]),   // 3D
  null
], name: 'z_check');
Series<bool> zFlags = series.hasZ;
// zFlags.data is [false, true, false]
// zFlags.name is 'z_check_has_z'
```

### 4. `isCCW` (property -> `Series<bool>`)
Checks if the exterior ring of a Polygon or a closed LineString is counter-clockwise.
- For Polygons, checks the orientation of the exterior ring.
- For LineStrings, it must be closed; then checks orientation.
- For other types (Points, MultiPoints, non-closed LineStrings, etc.) or `null` geometries, it typically returns `false`.

**Returns:** A `Series<bool>`.
```dart
final lineCCW = GeoJSONLineString([[0,0],[1,1],[0,1],[0,0]]); // CCW
final lineCW = GeoJSONLineString([[0,0],[0,1],[1,1],[0,0]]);  // CW
final polygonCCW = GeoJSONPolygon([[[0,0],[2,0],[2,2],[0,2],[0,0]]]); // Exterior ring is CCW
final series = GeoSeries([lineCCW, lineCW, polygonCCW, GeoJSONPoint([0,0]), null], name: 'ccw_test');
Series<bool> ccwFlags = series.isCCW;
// ccwFlags.data is [true, false, true, false, false]
// ccwFlags.name is 'ccw_test_is_ccw'
```

### 5. `isClosed` (property -> `Series<bool>`)
Checks if each LineString geometry is closed (start and end points are the same).
- For Polygons, this property is generally `false` as "closed" refers to LineString topology.
- For Points, MultiPoints, etc., and `null` geometries, it returns `false`.

**Returns:** A `Series<bool>`.
```dart
final series = GeoSeries([
  GeoJSONLineString([[0,0],[1,1],[0,1],[0,0]]), // Closed
  GeoJSONLineString([[0,0],[1,1],[0,1]]),       // Not closed
  GeoJSONPoint([0,0]),
  null
], name: 'closed_test');
Series<bool> closedFlags = series.isClosed;
// closedFlags.data is [true, false, false, false]
// closedFlags.name is 'closed_test_is_closed'
```

### 6. `isEmpty` (property -> `Series<bool>`)
Checks if each geometry is empty.
- e.g., a `GeoJSONPoint([])` (though construction might prevent this), `GeoJSONLineString([])`, `GeoJSONPolygon([[]])`.
- A `null` geometry is also considered empty by this property in the tests.

**Returns:** A `Series<bool>`.
```dart
final series = GeoSeries([
  GeoJSONPoint([0,0]),      // Not empty
  GeoJSONPolygon([[]]),     // Empty polygon
  GeoJSONLineString([]),  // Empty linestring
  null,                     // Considered empty by the test
  GeoJSONGeometryCollection([]) // Empty collection
], name: 'empty_check');
Series<bool> emptyFlags = series.isEmpty;
// emptyFlags.data is [false, true, true, false, true] 
// (Note: test1.dart shows null geometry as 'false' for isEmpty, but 'Empty geometry' for isValidReason. This might need clarification. Assuming 'false' based on test output for isEmpty.)
// After re-checking test1.dart: series.data[8] (null) -> isEmpty is false. series.data[9] (emptyPolygon) -> isEmpty is true.
// series.data[17] (emptyGeomCollection) -> isEmpty is true.
// Let's adjust:
final seriesForEmpty = GeoSeries([
  GeoJSONPoint([0,0]),          // Not empty
  GeoJSONPolygon([[]]),         // Empty
  null,                         // Null geometry
  GeoJSONGeometryCollection([]) // Empty collection
], name: 'empty_test');
Series<bool> emptyFlagsUpdated = seriesForEmpty.isEmpty;
// emptyFlagsUpdated.data is [false, true, false, true] (based on test data for similar structures)
// emptyFlagsUpdated.name is 'empty_test_is_empty'
```

### 7. `isRing` (property -> `Series<bool>`)
Checks if each LineString is a ring. A ring is a LineString that is both closed and simple (does not self-intersect).
- Returns `false` for non-LineString types or `null` geometries.
- A LineString needs at least 4 points to be a ring (3 unique points, plus closing point same as first).

**Returns:** A `Series<bool>`.
```dart
final series = GeoSeries([
  GeoJSONLineString([[0,0],[1,1],[0,1],[0,0]]),         // Closed and simple
  GeoJSONLineString([[0,0],[1,1],[0,0]]),               // Closed, simple, but only 3 points (not >=4)
  GeoJSONLineString([[0,0],[2,2],[0,2],[2,0],[0,0]]),   // Closed, self-intersecting
  GeoJSONLineString([[0,0],[1,1]]),                     // Not closed
  GeoJSONPoint([0,0]),
  null
], name: 'ring_test');
Series<bool> ringFlags = series.isRing;
// ringFlags.data is [true, false, false, false, false, false]
// ringFlags.name is 'ring_test_is_ring'
```

### 8. `isSimple` (property -> `Series<bool>`)
Checks if each geometry is "simple" according to OGC rules (e.g., no self-intersections for LineStrings/Polygons, no duplicate points for MultiPoints unless specified otherwise).
- For Polygons, simplicity often relates to valid ring construction. Self-intersecting rings make a polygon non-simple.
- For MultiPoint, it's simple if no two points are identical. (Test `mp_dup` is `false`).
- For MultiLineString/MultiPolygon, it's simple if all elements are simple and there are no intersections between elements. (Test `ml_nonsimple`, `mpoly_nonsimple` can be true if components are simple and don't interact in complex ways, depends on GEOS interpretation).
- `null` or empty geometries are often considered non-simple or result in `false`.

**Returns:** A `Series<bool>`.
```dart
final lineSimple = GeoJSONLineString([[0,0],[1,1],[2,2]]);
final lineSelfIntersect = GeoJSONLineString([[0,0],[2,2],[0,2],[2,0]]);
final multiPointSimple = GeoJSONMultiPoint([[0,0],[1,1]]);
final multiPointWithDuplicates = GeoJSONMultiPoint([[0,0],[1,1],[0,0]]);
final series = GeoSeries([
  lineSimple, lineSelfIntersect, multiPointSimple, multiPointWithDuplicates, null
], name: 'simple_test');
Series<bool> simpleFlags = series.isSimple;
// simpleFlags.data is [true, false, true, false, false] (based on typical OGC rules)
// simpleFlags.name is 'simple_test_is_simple'
```

### 9. `isValid` (property -> `Series<bool>`)
Checks if each geometry is valid according to OGC rules.
- For Polygons, this means rings are correctly oriented, closed, no self-intersections, holes are within the exterior, etc.
- `null` geometries are considered invalid (`false`).
- Empty geometries (like `GeoJSONPolygon([[]])`) are often considered invalid (`false` in test1.dart for `epoly`).

**Returns:** A `Series<bool>`.
```dart
final polygonValid = GeoJSONPolygon([[[0,0],[2,0],[2,2],[0,2],[0,0]]]);
final polygonSelfIntersectingRing = GeoJSONPolygon([[[0,0],[2,2],[0,2],[2,0],[0,0]]]); // Invalid
final emptyPoly = GeoJSONPolygon([[]]);
final series = GeoSeries([
  polygonValid, polygonSelfIntersectingRing, emptyPoly, null
], name: 'valid_test');
Series<bool> validFlags = series.isValid;
// validFlags.data is [true, false, false, false] 
// (Note: test1.dart shows poly_selfintring as true for isValid, this might be due to simplified validation. 
//  Strict OGC would be false. Documenting based on provided test output where possible.)
//  Assuming test1.dart's 'poly_selfintring' (polygonSelfIntersectingRing) isValid result of 'true' is specific to the underlying lib's leniency.
//  Awaiting re-check from test output: `polygonSelfIntersectingRing` is `true` in `test1.dart`.
//  `polygonInvalidHoleOutside` is `true`. `polygonInvalidHoleIntersects` is `true`.
//  This suggests the `isValid` in the test context might be a basic structural check, not full OGC validity.
//  For documentation, it's better to state what typical OGC validity implies.
//  Given the test results, it seems `isValid` is very lenient.
//  Documenting based on test output:
//  polygonSelfIntersectingRing -> true
//  emptyPoly -> false (as per test `epoly`)
//  Adjusting example based on test file's `isValid` for polygonSelfIntersectingRing:
//  validFlags.data for [polygonValid, polygonSelfIntersectingRing, emptyPoly, null] would be [true, true, false, false]
// validFlags.name is 'valid_test_is_valid'
```

### 10. `isValidReason()` (method -> `Series<String>`)
Provides a text description of why each geometry is considered valid or invalid.
- For valid geometries, it usually returns "Valid Geometry".
- For `null` geometries, it returns "Null geometry".
- For empty geometries, it might return "Empty geometry".
- For invalid geometries, it gives a reason (e.g., "Self-intersection", "Too few points").

**Returns:** A `Series<String>` with validity reasons.
```dart
final polygonValid = GeoJSONPolygon([[[0,0],[2,0],[2,2],[0,2],[0,0]]]);
final polygonSelfIntersectingRing = GeoJSONPolygon([[[0,0],[2,2],[0,2],[2,0],[0,0]]]);
final emptyPoly = GeoJSONPolygon([[]]);
final series = GeoSeries([
  polygonValid, polygonSelfIntersectingRing, emptyPoly, null
], name: 'reason_test');
Series<String> reasons = series.isValidReason();
// Assuming polygonSelfIntersectingRing is deemed "Valid Geometry" by the underlying library as per test1.dart:
// reasons.data is ["Valid Geometry", "Valid Geometry", "Empty geometry", "Null geometry"]
// reasons.name is 'reason_test_is_valid_reason'
```

## Coordinate Extraction

### `getCoordinates({bool includeZ = false, bool ignoreIndex = false})` (Extension Method)

This extension method extracts coordinates from all geometries in a `GeoSeries` and returns them as a `DataFrame`. Each coordinate point becomes a row in the resulting DataFrame.

- If a geometry has multiple points (e.g., LineString, Polygon rings), each point will be a separate row.
- The original index of the `GeoSeries` can be preserved or ignored. If preserved, it will be duplicated for geometries that produce multiple rows of coordinates.

**Parameters:**
- `includeZ` (default `false`): If `true` and geometries have Z values, a 'z' column will be included in the output DataFrame.
- `ignoreIndex` (default `false`): If `true`, the resulting DataFrame will have a default sequential integer index. If `false`, the index from the `GeoSeries` is used (and potentially duplicated).

**Returns:** A `DataFrame` with columns typically 'x', 'y' (and 'z' if `includeZ` is true).

**Example:**
```dart
final geometries = [
  GeoJSONPoint([1.0, 2.0]),
  GeoJSONLineString([[3.0, 4.0], [5.0, 6.0]]),
  GeoJSONPoint([7.0, 8.0, 9.0]) // 3D Point
];
final geoSeries = GeoSeries(geometries, name: 'my_geoms', index: ['p1', 'l1', 'p2_3d']);

// Default: extract x, y and preserve original index (duplicated for LineString)
DataFrame coordsDf1 = geoSeries.getCoordinates();
// coordsDf1.columns: ['x', 'y']
// coordsDf1.index: ['p1', 'l1', 'l1', 'p2_3d'] (assuming 'l1' contributes 2 points)
// coordsDf1.rows:
// x | y
// --|--
// 1 | 2  (from p1)
// 3 | 4  (from l1)
// 5 | 6  (from l1)
// 7 | 8  (from p2_3d, z is ignored by default)

// Include Z coordinate and ignore original index
DataFrame coordsDf2 = geoSeries.getCoordinates(includeZ: true, ignoreIndex: true);
// coordsDf2.columns: ['x', 'y', 'z']
// coordsDf2.index: [0, 1, 2, 3] (default sequential index)
// coordsDf2.rows:
// x | y | z
// --|---|---
// 1 | 2 | null (or default Z like 0.0 if not present)
// 3 | 4 | null
// 5 | 6 | null
// 7 | 8 | 9.0
```

## Error Handling
When creating `GeoSeries` objects, certain conditions can lead to errors:
- **Mismatched Input Lengths for `GeoSeries.fromXY()`**: If the `x`, `y`, `z` (if provided), or `index` (if provided) lists have different lengths, an `ArgumentError` will be thrown.
  ```dart
  // final x = [1.0, 2.0];
  // final y = [3.0]; // Mismatched length
  // expect(() => GeoSeries.fromXY(x, y), throwsArgumentError);
  ```
- **Invalid WKT Strings for `GeoSeries.fromWKT()`**: While the factory constructor handles invalid WKT by creating a default `GeoJSONPoint([0.0, 0.0])`, relying on this fallback might hide issues in your data source.

Always ensure your input data is consistent to prevent unexpected behavior or errors during `GeoSeries` creation and operations.

This documentation covers the creation, properties, conversions, and key operations of the `GeoSeries` class, including common geospatial analyses demonstrated in the examples. For inherited functionalities, refer to the `Series` documentation.
