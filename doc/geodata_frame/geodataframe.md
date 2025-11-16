# GeoDataFrame Class Documentation

## Table of Contents
- [GeoDataFrame Class Documentation](#geodataframe-class-documentation)
  - [Table of Contents](#table-of-contents)
  - [Relationship with DataFrame](#relationship-with-dataframe)
  - [Creating a GeoDataFrame](#creating-a-geodataframe)
    - [1. Default Constructor (from a `DataFrame`)](#1-default-constructor-from-a-dataframe)
    - [2. `GeoDataFrame.fromFeatureCollection()`](#2-geodataframefromfeaturecollection)
    - [3. `GeoDataFrame.fromDataFrame()`](#3-geodataframefromdataframe)
    - [4. `GeoDataFrame.fromCoordinates()`](#4-geodataframefromcoordinates)
    - [5. `GeoDataFrame.readFile()`](#5-geodataframereadfile)
  - [Accessing Data and Properties](#accessing-data-and-properties)
    - [1. `geometry` (GeoSeries)](#1-geometry-geoseries)
    - [2. `attributes` (DataFrame)](#2-attributes-dataframe)
    - [3. `featureCount` (int)](#3-featurecount-int)
    - [4. `headers` (List)](#4-headers-list)
    - [5. `propertyCount` (int)](#5-propertycount-int)
    - [6. `totalBounds` (List<double>)](#6-totalbounds-listdouble)
    - [7. `centroid` (GeoSeries)](#7-centroid-geoseries)
    - [8. `geometries({bool asGeoJSON = false})` (List<dynamic>)](#8-geometriesbool-asgeojson--false-listdynamic)
    - [9. `featureCollection` (GeoJSONFeatureCollection)](#9-featurecollection-geojsonfeaturecollection)
  - [Modifying Data](#modifying-data)
  - [Geospatial Operations](#geospatial-operations)
    - [1. `toFile()`](#1-tofile)
    - [2. `toFeatureCollection()`](#2-tofeaturecollection)

The `GeoDataFrame` class extends `DataFrame` to provide support for geospatial data. It manages a special "geometry" column alongside other attribute data, similar to libraries like GeoPandas in Python. This allows for the storage and manipulation of geographic features (points, lines, polygons) and their associated properties.

## Relationship with DataFrame

`GeoDataFrame` is a subclass of `DataFrame`. This means it inherits all the standard data manipulation capabilities of a `DataFrame` (like accessing columns, rows, filtering, adding/removing data, etc.) and adds specialized geospatial functionalities. The non-geometric data is referred to as "attributes".

## Creating a GeoDataFrame

There are several ways to create a `GeoDataFrame`:

### 1. Default Constructor (from a `DataFrame`)

You can create a `GeoDataFrame` from an existing `DataFrame` that contains a column with geometry information (e.g., Well-Known Text (WKT) strings or coordinate lists).

**Syntax:**

```dart
GeoDataFrame(
  DataFrame dataFrame, {
  String geometryColumn = 'geometry', // Name of the column holding geometry data
  String? crs,                       // Coordinate Reference System (e.g., 'EPSG:4326')
})
```

**Parameters:**

- `dataFrame`: The input `DataFrame`.
- `geometryColumn`: The name of the column in `dataFrame` that contains the geometry data. This column can contain WKT strings, lists of coordinates, or actual `GeoJSONGeometry` objects.
- `crs`: (Optional) The Coordinate Reference System of the geometries.

**Example:**

```dart
var df = DataFrame(
  columns: ['id', 'name', 'wkt_geometry'],
  [
    [1, 'Point A', 'POINT(0 0)'],
    [2, 'Line B', 'LINESTRING(0 0, 1 1, 2 2)'],
    [3, 'Polygon C', 'POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))']
  ]
);

var gdf = GeoDataFrame(df, geometryColumn: 'wkt_geometry', crs: 'EPSG:4326');
print(gdf);
print(gdf.geometry);
```

During construction, the `geometryColumn` is processed:
- If values are `GeoJSONGeometry` objects, they are used directly.
- If values are `String`, they are parsed as WKT.
- If values are `List`, they are interpreted as coordinates for `GeoJSONPoint`.
- If parsing fails, a default `GeoJSONPoint([0,0])` is used.

### 2. `GeoDataFrame.fromFeatureCollection()`

Creates a `GeoDataFrame` from a `GeoJSONFeatureCollection` object.

**Syntax:**

```dart
factory GeoDataFrame.fromFeatureCollection(
  GeoJSONFeatureCollection featureCollection, {
  String geometryColumn = 'geometry',
  String? crs,
})
```

**Example:**

```dart
// Assume 'featureCollection' is a GeoJSONFeatureCollection object
// (e.g., parsed from a GeoJSON file or created programmatically)

// Example of creating a simple FeatureCollection manually:
var point = GeoJSONPoint([10.0, 20.0]);
var feature = GeoJSONFeature(point, properties: {'name': 'My Point', 'value': 100});
var featureCollection = GeoJSONFeatureCollection([feature]);

var gdf = GeoDataFrame.fromFeatureCollection(featureCollection, crs: 'EPSG:4326');
print(gdf);
```

### 3. `GeoDataFrame.fromDataFrame()`

A static factory method to create a `GeoDataFrame` from a `DataFrame`, with more explicit control over how geometries are derived from columns (either a dedicated geometry column or separate coordinate columns).

**Syntax:**

```dart
static GeoDataFrame fromDataFrame(
  DataFrame dataFrame, {
  String? geometryColumn,          // Name of the column with WKT or parsable geometry strings
  String geometryType = 'point',  // 'point', 'linestring', 'polygon' if deriving from coordinates
  String coordinateType = 'lonlat', // 'lonlat' (looks for 'longitude'/'lat', 'latitude'/'lat')
                                  // or 'xy' (looks for 'x', 'y')
  String? crs,
})
```

**Details:**

- If `geometryColumn` is provided, it attempts to parse geometries from this column (similar to the default constructor).
- If `geometryColumn` is *not* provided, it looks for coordinate columns based on `coordinateType`:
    - `'lonlat'`: Searches for columns named 'longitude' (or 'lon') and 'latitude' (or 'lat'). An 'altitude' (or 'alt', 'elevation') column can also be used for 3D points.
    - `'xy'`: Searches for columns named 'x' and 'y'. A 'z' column can be used for 3D points.
- The `geometryType` helps in constructing the correct geometry (e.g., `GeoJSONPoint`) when using coordinate columns.

**Example (using coordinate columns):**

```dart
var df = DataFrame(
  columns: ['id', 'city_name', 'longitude', 'latitude', 'population'],
  [
    [1, 'City Alpha', -74.0060, 40.7128, 8000000],
    [2, 'City Beta', 2.3522, 48.8566, 2000000],
  ]
);

var gdf = GeoDataFrame.fromDataFrame(
  df,
  coordinateType: 'lonlat', // Will find 'longitude' and 'latitude' columns
  geometryType: 'point',
  crs: 'EPSG:4326',
);
print(gdf);
print(gdf.geometry.getCoordinates());
```

### 4. `GeoDataFrame.fromCoordinates()`

Creates a `GeoDataFrame` (with `Point` geometries) directly from a list of coordinate pairs.

**Syntax:**

```dart
static GeoDataFrame fromCoordinates(
  List<List<double>> coordinates, {
  DataFrame? attributes,        // Optional DataFrame for attribute data
  String coordinateType = 'xy', // 'xy', 'lonlat', etc. (mainly for context, as input is List<double>)
  String? crs,
})
```

**Example:**

```dart
final coordinates = [
  [105.7743099, 21.0717561], // [lon, lat]
  [105.7771289, 21.0715458],
];

final attributeDF = DataFrame(
  columns: ['name', 'type'],
  [
    ['Location 1', 'School'],
    ['Location 2', 'Park'],
  ],
);

final gdf = GeoDataFrame.fromCoordinates(
  coordinates,
  attributes: attributeDF,
  coordinateType: 'lonlat', // Indicates the order in coordinates list
  crs: 'EPSG:4326',
);
print(gdf);
```

### 5. `GeoDataFrame.readFile()`

Reads spatial data from a file, automatically attempting to determine the file type (driver) based on the file extension.

**Syntax:**

```dart
static Future<GeoDataFrame> readFile(
  String filePath, {
  String driver = 'Auto',                 // 'Auto', 'CSV', 'TXT', 'GeoJSON', 'GPX', 'KML', 'ESRI Shapefile' (Shapefile is not fully implemented for reading)
  String delimiter = ',',                 // For CSV/TXT
  bool hasHeader = true,                  // For CSV/TXT
  Map<String, int>? coordinatesColumns, // For CSV/TXT: e.g., {'latitude': 4, 'longitude': 5} (column indices)
  String? geometryColumn,               // For CSV/TXT: Name of column with WKT geometries
  String coordinateType = 'lonlat',       // For CSV/TXT with coordinateColumns: 'lonlat', 'xy', 'lonlatz', 'xyz'
  String? crs,
}) async
```

**Supported Formats (based on implementation):**

- **CSV/TXT:** Reads tabular text files.
    - If `geometryColumn` is provided, it attempts to parse WKT from that column.
    - If `coordinatesColumns` are provided (e.g., `{'latitude': 3, 'longitude': 4}` mapping column names to their 0-based index), it creates Point geometries. `coordinateType` helps interpret these columns.
- **GeoJSON:** Parses GeoJSON files.
- **GPX (GPS Exchange Format):** Parses GPX files, converting waypoints, tracks, and routes to GeoJSON features.
- **KML (Keyhole Markup Language):** Parses KML files, primarily converting placemarks with Point geometries.
- **ESRI Shapefile:** Reading is mentioned but might be unimplemented or partially implemented.

**Examples:**

**Reading a CSV with Latitude/Longitude columns:**

```dart
// Assuming 'data.csv':
// id,name,my_lat,my_lon
// 1,PlaceA,21.071,105.774
// 2,PlaceB,21.072,105.775

final gdfFromCsv = await GeoDataFrame.readFile(
  'data.csv',
  delimiter: ',',
  hasHeader: true,
  coordinatesColumns: {'latitude': 2, 'longitude': 3}, // Column indices for lat/lon
  coordinateType: 'lonlat',
  crs: 'EPSG:4326',
);
print(gdfFromCsv);
```

**Reading a CSV with a WKT geometry column:**

```dart
// Assuming 'data_wkt.csv':
// id,description,geom_wkt
// 1,Feature One,"POINT(10 20)"
// 2,Feature Two,"LINESTRING(0 0, 1 1)"

final gdfFromWktCsv = await GeoDataFrame.readFile(
  'data_wkt.csv',
  geometryColumn: 'geom_wkt',
  crs: 'EPSG:4326',
);
print(gdfFromWktCsv);
```

**Reading a GeoJSON file:**

```dart
// Assuming 'map.geojson' exists
final gdfFromGeoJson = await GeoDataFrame.readFile(
  'map.geojson',
  crs: 'EPSG:4326', // CRS might be in the GeoJSON file, this can be a default/override
);
print(gdfFromGeoJson.head());
```

**Reading a GPX file:**

```dart
// Assuming 'track.gpx' exists
final gdfFromGpx = await GeoDataFrame.readFile('track.gpx');
print(gdfFromGpx.head());
```

## Accessing Data and Properties

### 1. `geometry` (GeoSeries)

Returns the geometry column as a `GeoSeries` object. `GeoSeries` provides geometry-specific operations.

**Example:**

```dart
GeoSeries geometries = gdf.geometry;
print(geometries.area()); // Example: calculate area if polygons
print(geometries.length()); // Example: calculate length if linestrings
print(geometries.getCoordinates(indexParts: true));
```

### 2. `attributes` (DataFrame)

Returns a `DataFrame` containing only the attribute data (all columns except the geometry column).

**Example:**

```dart
DataFrame attributeTable = gdf.attributes;
print(attributeTable.describe());
```

### 3. `featureCount` (int)

Gets the number of features (rows) in the `GeoDataFrame`.

**Example:**

```dart
print('Number of features: ${gdf.featureCount}');
```

### 4. `headers` (List)

Gets the list of all column names, including the geometry column.

**Example:**

```dart
print('Column headers: ${gdf.headers}');
```

### 5. `propertyCount` (int)

Gets the number of properties (columns) in the `GeoDataFrame`. Equivalent to `gdf.columns.length` or `gdf.shape.columns`.

**Example:**

```dart
print('Number of properties: ${gdf.propertyCount}');
```

### 6. Coordinate Reference System (`crs`)

The CRS of a `GeoDataFrame` is determined by the CRS of its active geometry `GeoSeries`.
```dart
// Assuming gdf is a GeoDataFrame
String? currentCrs = gdf.geometry.crs;
print('GeoDataFrame CRS: $currentCrs');

// To set or change the CRS, you would typically create a new GeoSeries 
// with the desired CRS and assign it back to the geometry column,
// or use a dedicated reprojection method if available.
// Example (conceptual, actual reprojection method may vary):
// GeoSeries reprojectedGeoms = gdf.geometry.toCrs('EPSG:3857');
// gdf.geometry = reprojectedGeoms; 
```

### 7. `geometries({bool asGeoJSON = false})` (List<dynamic>)

Extracts the geometries from the active geometry column (`GeoSeries`). This method delegates to the `geometries()` method of the underlying `GeoSeries`.
- If `asGeoJSON` is `true`, returns a list of `GeoJSONGeometry` objects.
- If `asGeoJSON` is `false` (default), returns a list of coordinate lists.

**Example:**
```dart
// Assuming gdf is a GeoDataFrame
List<GeoJSONGeometry> geoJsonGeoms = gdf.geometries(asGeoJSON: true);
// List<dynamic> coordGeoms = gdf.geometries(); // Default (asGeoJSON: false)
```

### 8. `featureCollection` (GeoJSONFeatureCollection)

A getter that converts the `GeoDataFrame` into a `GeoJSONFeatureCollection` object. Equivalent to calling `toFeatureCollection()`.

**Example:**

```dart
GeoJSONFeatureCollection fc = gdf.featureCollection;
// print(fc.toJSON()); // To get the JSON string representation
```

## Modifying Data

Since `GeoDataFrame` extends `DataFrame`, you can use standard `DataFrame` methods to modify attribute data:

- Adding columns: `gdf.addColumn('new_prop', defaultValue: 'someValue');` or `gdf['new_prop'] = Series(['val1', 'val2'], name: 'new_prop');`
- Updating values: `gdf.updateCell(rowIndex, 'propName', newValue);` or by accessing the column Series: `gdf['propName'][rowIndex] = newValue;`
- Dropping columns: `gdf.drop(['propName']);`
- Filtering rows (which returns a new `DataFrame` that can be used to create a new `GeoDataFrame` if desired).

To modify geometries, you typically assign a new `GeoSeries` or a list of new `GeoJSONGeometry` objects to the active geometry column:
```dart
// Example: Creating a new GeoSeries (e.g., by buffering) and assigning it
// GeoSeries bufferedGeometries = gdf.geometry.buffer(distance: 10.0); // Assuming a buffer method exists
// gdf.geometry = bufferedGeometries; // Assign the new GeoSeries

// Or assigning a list of new geometry objects (must match length)
// List<GeoJSONGeometry?> newGeoms = [...]; 
// gdf[gdf.geometryColName] = newGeoms; 
```

## Geospatial Operations

Geospatial operations and analyses on a `GeoDataFrame` are primarily performed by accessing its active geometry column (which is a `GeoSeries`) and then applying methods from the `GeoSeries` class or its `GeoSpatialExtension` (for properties like `area`, `bounds`, `isValid`, etc.).

**Typical Workflow:**
1. Access the geometry `GeoSeries`: `GeoSeries myGeoColumn = gdf.geometry;` (or `gdf[gdf.geometryColName] as GeoSeries;`)
2. Apply `GeoSeries` methods/properties: `Series areas = myGeoColumn.area;`
3. Optionally, assign results back to the `GeoDataFrame`: `gdf['areas'] = areas.data;`

**Example:**
```dart
// Assume 'gdf' is a GeoDataFrame with a geometry column named 'geometry'
// containing Polygon geometries.

// 1. Access the geometry column
GeoSeries geometrySeries = gdf.geometry;

// 2. Perform a spatial operation (e.g., calculate area)
Series<double> areas = geometrySeries.area;

// 3. Assign the results back as a new column in the GeoDataFrame
gdf['calculated_area'] = areas.data; // Assigning the raw list of data

// 4. Perform another operation (e.g., get bounds)
DataFrame bounds = geometrySeries.bounds; // Returns a DataFrame

// Merge bounds back if desired (requires careful index alignment)
// gdf = gdf.join(bounds, leftOn: gdf.indexName, rightOn: bounds.indexName, suffixes: ['_orig', '_bounds']);


// For a comprehensive list of available spatial properties and methods, 
// please refer to the GeoSeries documentation (`doc/geoseries.md`).
```

### Common Geospatial Computations (via GeoSeries)

- **`gdf.geometry.area`**: Computes the area of each geometry. (Returns `Series<double>`)
- **`gdf.geometry.bounds`**: Computes the bounding box of each geometry. (Returns `DataFrame`)
- **`gdf.geometry.isValid`**: Checks validity of each geometry. (Returns `Series<bool>`)
- **`gdf.geometry.isSimple`**: Checks simplicity of each geometry. (Returns `Series<bool>`)
- **`gdf.geometry.toWkt()`**: Converts geometries to WKT strings. (Returns `Series<String>`)
- **`gdf.geometry.makeValid()`**: Attempts to make geometries valid. (Returns `GeoSeries`)
- **`gdf.geometry.getCoordinates()`**: Extracts coordinates into a DataFrame. (Returns `DataFrame`)

Refer to `doc/geoseries.md` for detailed examples of these and other `GeoSeries` methods.

### 1. `toFile()`

Exports the `GeoDataFrame` to various file formats. The driver is auto-detected from the file extension but can be specified.

**Syntax:**

```dart
Future<void> toFile(
  String filePath, {
  String driver = 'Auto',         // 'Auto', 'CSV', 'TXT', 'GeoJSON', 'GPX', 'KML', 'ESRI Shapefile' (Shapefile export is UnimplementedError)
  String delimiter = ',',         // For CSV/TXT
  bool includeHeader = true,      // For CSV/TXT
  // ... other format-specific parameters
}) async
```

**Supported Formats for Writing:**

- **CSV/TXT:** Writes attribute data. Geometries are typically not written directly unless they are in a simple string format (like WKT) in an attribute column.
- **GeoJSON:** Exports the `GeoDataFrame` as a GeoJSON FeatureCollection.
- **GPX:** Converts features to GPX format (Points to waypoints, LineStrings to tracks).
- **KML:** Converts Point features to KML Placemarks.
- **ESRI Shapefile:** Export is currently unimplemented.

**Examples:**

**Writing to GeoJSON:**

```dart
await gdf.toFile('output_map.geojson');
print('Exported to GeoJSON.');
```

**Writing attributes to CSV:**

```dart
// Note: This will primarily save the attribute table.
// For geometries, ensure they are in a WKT string column if you want them in the CSV.
await gdf.attributes.toFile('attributes_output.csv');
print('Attributes exported to CSV.');
```

**Writing to GPX:**
```dart
// Create a GeoDataFrame with some Point and LineString features
// ...
await gdf.toFile('output_track.gpx');
print('Exported to GPX');
```

### 2. `toFeatureCollection()`

Converts the `GeoDataFrame` into a `GeoJSONFeatureCollection` object. This is useful for working with GeoJSON data structures directly or for preparing data for JSON serialization.

**Syntax:**

```dart
GeoJSONFeatureCollection toFeatureCollection()
```

**Example:**

```dart
GeoJSONFeatureCollection featureCollection = gdf.toFeatureCollection();
// You can then iterate through features, access properties, geometries,
// or convert to a JSON string.
// String jsonOutput = featureCollection.toJSON(indent: 2);
// print(jsonOutput);
```

This documentation provides a comprehensive overview of the `GeoDataFrame` class, its functionalities, and how to use it for handling geospatial data within the DartFrame environment. For more specific methods inherited from `DataFrame`, please refer to the `DataFrame` documentation.

---

## General Usage Examples (from README)

This section provides a collection of common usage examples for `GeoDataFrame`, originally from the main README.

### Creating a GeoDataFrame (from README)

#### From a file

```dart
// Read from a CSV file with coordinate columns
// final geoDataFrame = await GeoDataFrame.readFile(
//   'path/to/data.csv',
//   coordinatesColumns: {
//     'longitude': 1,  // column index for longitude
//     'latitude': 2    // column index for latitude
//   },
//   coordinateType: 'lonlat'
// );

// Read from a GeoJSON file
// final geoJson = await GeoDataFrame.readFile('path/to/data.geojson');

// Read from a GPX file
// final gpxData = await GeoDataFrame.readFile('path/to/tracks.gpx');
```
*(Note: `readFile` examples assume the existence of specified files and appropriate data format.)*

#### From coordinates

```dart
// Create from a list of coordinate pairs
final coordinates = [
  [0.0, 0.0],
  [1.0, 0.0],
  [1.0, 1.0],
  [0.0, 1.0]
];

final gdfFromCoords = GeoDataFrame.fromCoordinates(
  coordinates,
  coordinateType: 'xy'  // or 'lonlat'
);
// print(gdfFromCoords);
```

#### From an existing DataFrame

```dart
// Convert a DataFrame with a geometry column (e.g., WKT) to a GeoDataFrame
final dataFrameWithWKT = DataFrame(
  [
    [1, 'Point A', 'POINT(0 0)'],
    [2, 'Point B', 'POINT(1 1)'],
  ],
  columns: ['id', 'name', 'wkt_geom'],
);

final gdfFromDf = GeoDataFrame( // Using default constructor
  dataFrameWithWKT,
  geometryColumn: 'wkt_geom', // Specifies the column containing WKT strings
  crs: 'EPSG:4326'
);
// print(gdfFromDf.geometry);

// The static GeoDataFrame.fromDataFrame can also be used, especially if
// geometries need to be constructed from coordinate columns.
// Example:
// final dfWithXY = DataFrame([
//   [1, 'CityA', 10.0, 20.0],
// ], columns: ['id', 'name', 'x', 'y']);
// final gdfFromXYCols = GeoDataFrame.fromDataFrame(
//   dfWithXY,
//   coordinateType: 'xy', // Will look for 'x' and 'y' columns
//   geometryType: 'point',
//   crs: 'EPSG:4326'
// );
// print(gdfFromXYCols.geometry);
```

#### From GeoJSON String

```dart
// Example: Create from GeoJSON string
final geoJsonString = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"title": "Location A"},
      "geometry": {"type": "Point", "coordinates": [105.77, 21.07]}
    },
    {
      "type": "Feature",
      "properties": {"title": "Line B"},
      "geometry": {"type": "LineString", "coordinates": [[105.0, 21.0],[105.5, 21.5]]}
    }
  ]
}
''';

// Parse the GeoJSON string
final geoJson = GeoJSON.fromJSON(geoJsonString);

// Create a GeoDataFrame from the parsed GeoJSON
GeoDataFrame? fromJsonGeoDF;
if (geoJson is GeoJSONFeatureCollection) {
  // Extract all unique property keys to use as headers for attribute columns
  final jsonHeaders = <String>{};
  for (var feature in geoJson.features) {
    if (feature?.properties != null) {
      jsonHeaders.addAll(feature!.properties!.keys);
    }
  }
  
  fromJsonGeoDF = GeoDataFrame.fromFeatureCollection( // Using the dedicated factory
    geoJson,
    // The GeoDataFrame.fromFeatureCollection constructor automatically handles properties.
    // If using the default GeoDataFrame constructor with a GeoJSONFeatureCollection,
    // you might need to manually construct the DataFrame part first.
    // The example in README was slightly different, adapting to typical constructor patterns.
    crs: 'EPSG:4326',
  );
  
  // print('\nGeoDataFrame from GeoJSON string:');
  // print('Features: ${fromJsonGeoDF?.featureCount}');
  // print('Properties: ${fromJsonGeoDF?.attributes.columns.join(', ')}');
  
  // Demonstrate querying features (if using a method that allows property access, like a custom filter)
  // The findFeatures method shown in README might be a higher-level utility or conceptual.
  // Standard filtering would be on fromJsonGeoDF.attributes:
  if (fromJsonGeoDF != null) {
    var selection = fromJsonGeoDF.attributes.filter((row) {
      // Assuming 'title' column exists in attributes from properties
      return row[fromJsonGeoDF!.attributes.columns.indexOf('title')] == 'Location A';
    });
    // print('Selected features based on title "Location A": ${selection.rowCount}');
  }
}
```

### Accessing Data (from README)

```dart
// Assuming 'gdf' is a created GeoDataFrame
// final gdf = GeoDataFrame.fromCoordinates([[0,0],[1,1]], coordinateType:'xy');

// Get the number of features
// print(gdf.featureCount); // Equivalent to gdf.rowCount or gdf.shape.rows

// Access the attribute table as DataFrame
// DataFrame attributes = gdf.attributes;
// print(attributes);

// Access a specific feature (row)
// This would typically be done using standard DataFrame row access, e.g., gdf.iloc[0] or gdf.loc['some_index']
// The getFeature(index) method is not a standard DataFrame/GeoDataFrame method from the core API.
// Example: Row as Series (iloc)
// if (gdf.rowCount > 0) {
//   Series featureRow = gdf.iloc[0]; 
//   print(featureRow);
// }


// Get all geometries as a GeoSeries
// GeoSeries geometries = gdf.geometry;
// print(geometries);
```

### Manipulating Data (from README)

*(Many of these operations like `addFeature`, `deleteFeature`, `addProperty` are high-level concepts. Standard DataFrame/GeoDataFrame manipulation involves column/row operations.)*

```dart
// Assuming 'gdf' is a GeoDataFrame
final initialCoords = [[0.0,0.0],[1.0,1.0]];
var gdf = GeoDataFrame.fromCoordinates(initialCoords, coordinateType: 'xy', crs: 'EPSG:4326');
gdf['name'] = Series(['Point Zero', 'Point One'], name: 'name');
// print('Initial GDF:\n$gdf');

// Add a new feature (conceptually - requires creating a new GDF or adding a row)
// To add a feature, you'd typically create a new GeoDataFrame by concatenating,
// or prepare a new row and use a method like `addRow` (if available and adapted for GeoDataFrame).
// For simplicity, let's show adding a new geometry and attribute via extending existing Series
// and creating a new GeoDataFrame (a common immutable pattern).

// var newPoint = GeoJSONPoint([10.0, 20.0]);
// var newAttributes = {'name': 'New Point', 'value': 42}; // This would be a new row for attributes DataFrame

// A more direct way to add a row if GDF supports it or via DataFrame methods:
// This is a conceptual example as GeoDataFrame might not have a direct addFeature.
// One might do:
// var newRowData = {'name': 'New Point', 'value': 42, gdf.geometryColName: GeoJSONPoint([10.0, 20.0])};
// (This requires a method to append a map as a new row, which DataFrame might have)


// Delete a feature (row)
// var gdfAfterDelete = gdf.drop([0]); // Drops row at index 0
// print('GDF after deleting first feature:\n$gdfAfterDelete');

// Add a property (column) to all features
gdf['category'] = Series(['default', 'default'], name: 'category'); // Broadcast or set Series
// print('GDF after adding category:\n$gdf');

// Update properties (attributes)
// gdf.attributes['name'][0] = 'Old Point Zero'; // This would modify attributes DataFrame if mutable
// A safer way or if immutable:
var names = gdf['name'].toList(); // Get as list
if (names.isNotEmpty) names[0] = 'Old Point Zero';
gdf['name'] = Series(names, name: 'name'); // Assign back
// print('GDF after updating name property:\n$gdf');


// Use DataFrame operations on attributes
// var filteredAttributes = gdf.attributes.filter((row) => row[gdf.attributes.columns.indexOf('name')] == 'Point One');
// print('Filtered attributes:\n$filteredAttributes');
```

### Spatial Properties in Attributes (from README)

The README mentions that `GeoDataFrame` might automatically calculate and add certain spatial properties to its attribute table. This behavior (if implemented) would typically occur during creation or when a specific method is called. The properties mentioned were: `geometry` (WKT string), `area`, `geom_type`, `is_valid`, `bounds`.

**Conceptual Example if properties are auto-added to attributes:**
```dart
// var gdfWithAutoProps = await GeoDataFrame.readFile('path/to/data.geojson');
// This implies that after reading, gdfWithAutoProps.attributes might contain columns like:
// 'original_prop1', 'original_prop2', ..., 'geometry_wkt', 'area', 'geom_type', 'is_valid_geom', 'bounds_list'

// Accessing these auto-generated attribute columns:
// String wkt = gdfWithAutoProps.attributes['geometry_wkt'][0];
// double area = gdfWithAutoProps.attributes['area'][0];
// String type = gdfWithAutoProps.attributes['geom_type'][0];
// bool isValid = gdfWithAutoProps.attributes['is_valid_geom'][0];
// List<double> bounds = gdfWithAutoProps.attributes['bounds_list'][0];
```
*(**Note**: Standard practice is often to compute these on demand from the primary geometry `GeoSeries` rather than auto-populating them as attribute columns, to avoid data redundancy and ensure they are always up-to-date if geometries change. If this auto-population is a feature, its exact mechanism and when it occurs should be clearly defined in the GeoDataFrame's specific documentation or constructor/method behavior.)*

### Exporting Data (from README)

```dart
// Assuming 'gdf' is a GeoDataFrame
// await gdf.toFile('output.geojson');
// await gdf.toFile('output.csv'); // This would primarily save the attribute table.
// await gdf.toFile('output.gpx');
// await gdf.toFile('output.kml');
```

### Finding Features (from README)

The README mentions a `findFeatures` method. This seems to be a high-level utility. Standard filtering is often done on the `GeoDataFrame` (which is a `DataFrame`) using boolean indexing or `where` clauses, potentially combined with spatial operations on the geometry `GeoSeries`.

```dart
// Example from README (conceptual, as findFeatures might be specific)
// var foundFeatures = gdf.findFeatures((feature) => 
//   feature.properties!['population'] > 1000 && 
//   feature.properties!['area'] < 500 // 'area' here would be an attribute
// );

// Standard filtering approach:
// Assume 'gdf' has 'population' and an 'calculated_area' (from gdf.geometry.area) columns
// Series populationFilter = gdf['population'].apply((pop) => pop != null && pop > 1000);
// Series areaFilter = gdf['calculated_area'].apply((area) => area != null && area < 500);
// GeoDataFrame filteredGDF = gdf[populationFilter & areaFilter]; 
// print('Found features using standard filtering: ${filteredGDF.rowCount}');
```

### Complete Example (from README, adapted)
```dart
Future<void> mainGeoDataFrameExample() async {
  // For this example, let's assume a CSV 'data.csv' exists:
  // id,name,latitude,longitude,population
  // 1,PlaceA,21.071,105.774,50000
  // 2,PlaceB,21.072,105.775,8000
  // 3,PlaceC,21.073,105.776,120000

  // final geoDataFrame = await GeoDataFrame.readFile(
  //   'data.csv', // Replace with actual path or load differently for a runnable example
  //   delimiter: ',',
  //   hasHeader: true,
  //   coordinatesColumns: {
  //     'latitude': 2, // Index of 'latitude' column
  //     'longitude': 3 // Index of 'longitude' column
  //   },
  //   coordinateType: 'lonlat',
  //   crs: 'EPSG:4326'
  // );

  // Create a sample GeoDataFrame for demonstration as readFile is commented out
  var data = {
    'id': [1, 2, 3],
    'name': ['PlaceA', 'PlaceB', 'PlaceC'],
    'latitude': [21.071, 21.072, 21.073],
    'longitude': [105.774, 105.775, 105.776],
    'population': [50000, 8000, 120000]
  };
  var tempDf = DataFrame.fromMap(data);
  final geoDataFrame = GeoDataFrame.fromDataFrame(
    tempDf,
    coordinateType: 'lonlat', // Uses 'latitude' and 'longitude' columns
    crs: 'EPSG:4326'
  );


  print('Number of features: ${geoDataFrame.featureCount}');
  print('Properties (Headers): ${geoDataFrame.headers}');
  
  // Add a new property column
  // geoDataFrame.addProperty('category', defaultValue: 'residential'); // addProperty might be conceptual
  // Using standard DataFrame column assignment:
  List<String> categories = List.filled(geoDataFrame.rowCount, 'residential', growable: true);
  geoDataFrame['category'] = Series(categories, name: 'category');
  
  // Calculate statistics on a numeric column from attributes
  if (geoDataFrame.attributes.columns.contains('population')) {
    print('Population statistics:');
    print(geoDataFrame.attributes['population'].describe());
  }
  
  // Filter features (standard DataFrame filtering)
  // GeoDataFrame urbanAreasGDF = geoDataFrame[geoDataFrame['population'].apply((p) => p!= null && p > 10000)];
  
  // The findFeatures method from README seems custom. A standard way:
  var attributesWithPopulation = geoDataFrame.attributes;
  if (attributesWithPopulation.columns.contains('population')) {
      Series populationSeries = attributesWithPopulation['population'];
      List<bool> filterCriteria = populationSeries.data.map((pop) {
          if (pop is num) return pop > 10000;
          return false;
      }).toList();
      
      GeoDataFrame urbanAreasGDF = geoDataFrame[filterCriteria];
      print('Urban areas count: ${urbanAreasGDF.rowCount}');
      
      // Export the filtered data
      // await urbanAreasGDF.toFile('urban_areas.geojson');
      // print('Urban areas exported to urban_areas.geojson (conceptual)');
  }
}
```

