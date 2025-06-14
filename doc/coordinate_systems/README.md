# Coordinate Systems Module

This module provides functionalities for working with various geographic and projected coordinate systems. It allows for conversions between different systems like Latitude/Longitude (often represented by a `LatLng` class, see [Core Calculations](../core/README.md)), Universal Transverse Mercator (UTM), and Military Grid Reference System (MGRS). Additionally, it supports datum transformations and map projections to ensure accurate geospatial data handling.

## UTM Zones

The Universal Transverse Mercator (UTM) system divides the Earth into 60 zones, each 6 degrees of longitude in width. This system is widely used for detailed mapping.

### `UTMZones().getZone({required double latitude, required double longitude})`

**Purpose:** Calculates the UTM zone number and letter for a given latitude and longitude.

**Parameters:**
- `latitude` (double): The latitude of the point.
- `longitude` (double): The longitude of the point.

**Returns:**
- `String`: The UTM zone, represented as a number followed by a letter (e.g., "30P").

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides UTMZones

void main() {
  var u = UTMZones();
  var uZone = u.getZone(latitude: 6.5655, longitude: -1.5646);
  print('UTM Zone: $uZone'); // Output: UTM Zone: 30P
}
```

### `UTMZones().getHemisphere(String zone)`

**Purpose:** Determines the hemisphere (North 'N' or South 'S') from a given UTM zone string.

**Parameters:**
- `zone` (String): The UTM zone string (e.g., "30P").

**Returns:**
- `String`: 'N' for Northern Hemisphere, 'S' for Southern Hemisphere.

**Example:**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  var u = UTMZones();
  var uZone = "30P";
  print('Hemisphere: ${u.getHemisphere(uZone)}'); // Output: Hemisphere: N
}
```

### `UTMZones().getLatZone(double latitude)`

**Purpose:** Determines the latitude zone letter for a given latitude.

**Parameters:**
- `latitude` (double): The latitude of the point.

**Returns:**
- `String`: The latitude zone letter (e.g., "P").

**Example:**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  var u = UTMZones();
  print('Latitude Zone: ${u.getLatZone(6.5655)}'); // Output: Latitude Zone: P
}
```

## MGRS Coordinates

The Military Grid Reference System (MGRS) is a geocoordinate standard used by NATO militaries for locating points on Earth. It's derived from UTM and UPS (Universal Polar Stereographic) grid systems.

### `MGRS.parse(String mgrsString)`

**Purpose:** Parses an MGRS string into an `MGRS` object. It can handle MGRS strings with or without spaces.

**Parameters:**
- `mgrsString` (String): The MGRS coordinate string (e.g., "31U DQ 48251 11932" or "31UDQ4825111932").

**Returns:**
- `MGRS`: An `MGRS` object representing the parsed coordinate.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides MGRS

void main() {
  var mgrs1 = MGRS.parse('31U DQ 48251 11932');
  var mgrs2 = MGRS.parse('31UDQ4825111932');
  
  print('MGRS1: $mgrs1'); // Output: MGRS1: 31U DQ 48251 11932
  print('MGRS2: $mgrs2'); // Output: MGRS2: 31U DQ 48251 11932
}
```

## Coordinate Conversions

This section covers conversions between `LatLng` (Latitude/Longitude), UTM, and MGRS coordinate systems.

### `LatLng.toMGRS()`

**Purpose:** Converts `LatLng` coordinates to MGRS coordinates.

**Parameters:** None (operates on a `LatLng` object).

**Returns:**
- `String`: The MGRS coordinate string.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng and its extensions

void main() {
  var ll = LatLng(6.5655, -1.5646);
  String mgrsString = ll.toMGRS();
  print('LatLng to MGRS: $mgrsString'); // Output: LatLng to MGRS: 30N XN 58699 25944
}
```

### `LatLng.toUTM()`

**Purpose:** Converts `LatLng` coordinates to UTM coordinates.

**Parameters:** None (operates on a `LatLng` object).

**Returns:**
- `UTM`: A `UTM` object representing the coordinates.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng and UTM

void main() {
  var ll = LatLng(6.5655, -1.5646);
  UTM utmCoords = ll.toUTM();
  print('LatLng to UTM: $utmCoords'); // Output: LatLng to UTM: 30 N 658699.0 725944.0 0.0
}
```

### `UTM.toLatLng()`

**Purpose:** Converts UTM coordinates to `LatLng` coordinates.

**Parameters:** None (operates on a `UTM` object).

**Returns:**
- `LatLng`: A `LatLng` object representing the coordinates.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, UTM, MGRS

void main() {
  // Example: Create a UTM object first (e.g., from an MGRS string or known values)
  var llForMgrs = LatLng(6.5655, -1.5646); // Reference point
  var utm = UTM.fromMGRS(llForMgrs.toMGRS()); // Create UTM via MGRS for this example
  
  LatLng latLngCoords = utm.toLatLng();
  print('UTM to LatLng: $latLngCoords'); 
  // Example Output: UTM to LatLng: 006° 33' 55.795" N, 001° 33' 52.586" W (may vary slightly due to precision)
}
```

### `UTM.toMGRS()`

**Purpose:** Converts UTM coordinates to MGRS coordinates.

**Parameters:** None (operates on a `UTM` object).

**Returns:**
- `String`: The MGRS coordinate string.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, UTM, MGRS

void main() {
  var llForMgrs = LatLng(6.5655, -1.5646); // Reference point
  var utm = UTM.fromMGRS(llForMgrs.toMGRS()); // Create UTM via MGRS for this example

  String mgrsString = utm.toMGRS();
  print('UTM to MGRS: $mgrsString'); // Output: UTM to MGRS: 30N XN 58699 25944
}
```

### `MGRS.toLatLng()`

**Purpose:** Converts MGRS coordinates to `LatLng` coordinates.

**Parameters:** None (operates on an `MGRS` object).

**Returns:**
- `LatLng`: A `LatLng` object representing the coordinates.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, MGRS

void main() {
  var llOriginal = LatLng(6.5655, -1.5646);
  var mgrs = MGRS.parse(llOriginal.toMGRS()); // Parse the MGRS string derived from LatLng

  LatLng latLngCoords = mgrs.toLatLng();
  print('MGRS to LatLng: $latLngCoords');
  // Example Output: MGRS to LatLng: 006° 33' 55.795" N, 001° 33' 52.586" W (may vary slightly)
}
```

### `MGRS.toUTM()`

**Purpose:** Converts MGRS coordinates to UTM coordinates.

**Parameters:** None (operates on an `MGRS` object).

**Returns:**
- `UTM`: A `UTM` object representing the coordinates.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, MGRS, UTM

void main() {
  var llOriginal = LatLng(6.5655, -1.5646);
  var mgrs = MGRS.parse(llOriginal.toMGRS()); // Parse the MGRS string derived from LatLng

  UTM utmCoords = mgrs.toUTM();
  print('MGRS to UTM: $utmCoords'); 
  // Example Output: MGRS to UTM: 30 N 658699.0 725944.0 (height might be 0.0 or based on MGRS precision)
}
```

## Datum Transformations

A geodetic datum is a reference from which measurements are made. Datum transformations are necessary when working with coordinates from different datums to ensure accuracy. GeoEngine allows transforming coordinates between different datums using their EPSG codes or WKT (Well-Known Text) definitions for `Projection` objects.

### `CoordinateConversion().convert()`

**Purpose:** Performs coordinate transformation between a source and a target Coordinate Reference System (CRS), which includes datum transformations.

**Parameters:**
- `point` (Point): The input point to transform (can be `LatLng` for geodetic or `PointX` for projected coordinates, though `Point` is the general type).
- `projSrc` (Projection): The source projection/CRS.
- `projDst` (Projection): The target projection/CRS.
- `conversion` (ConversionType): The type of conversion to perform (e.g., `geodeticToGeodetic`, `projectedToGeodetic`).

**Returns:**
- `Point`: The transformed point. You might need to cast it or use methods like `asLatLng()` depending on the expected output type.

**Example (Geodetic to Geodetic Transformation):**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, CoordinateConversion, Projection, ConversionType, PointX

void main() {
  final LatLng pointWGS84 = LatLng(6.65412, -1.54651, 200); // WGS84 coordinates

  CoordinateConversion transCoordinate = CoordinateConversion();

  // Source CRS: WGS84 (EPSG:4326)
  Projection sourceProjection = Projection.get('EPSG:4326')!; 
  
  // Target CRS: Accra / Ghana National Grid (EPSG:2136) defined by WKT
  // WKT strings define the full CRS including datum, ellipsoid, prime meridian, projection, units, etc.
  Projection targetProjection = Projection.parse(
        'PROJCS["Accra / Ghana National Grid",GEOGCS["Accra",DATUM["Accra",SPHEROID["War Office",6378300,296,AUTHORITY["EPSG","7029"]],TOWGS84[-199,32,322,0,0,0,0],AUTHORITY["EPSG","6168"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4168"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",4.666666666666667],PARAMETER["central_meridian",-1],PARAMETER["scale_factor",0.99975],PARAMETER["false_easting",900000],PARAMETER["false_northing",0],UNIT["Gold Coast foot",0.3047997101815088,AUTHORITY["EPSG","9094"]],AXIS["Easting",EAST],AXIS["Northing",NORTH],AUTHORITY["EPSG","2136"]]');

  var transformedPoint = transCoordinate.convert(
    point: pointWGS84,
    projSrc: sourceProjection,
    projDst: targetProjection,
    conversion: ConversionType.geodeticToGeodetic, // Geodetic (Lat/Lng) to Geodetic (Lat/Lng)
  );

  print('Original WGS84: $pointWGS84');  
  print('Transformed to Accra Grid: ${transformedPoint.asLatLng()}');
  // Example Output:
  // Original WGS84: 006° 39' 14.832" N, 001° 32' 47.436" W, 200.000
  // Transformed to Accra Grid: 006° 39' 4.889" N, 001° 32' 48.303" W, 200.331 (Coordinates will differ due to datum shift)
}
```

## Map Projections

Map projections are techniques to represent the Earth's curved surface on a flat map. This inevitably involves distortions. GeoEngine can convert coordinates between geographic (latitude/longitude) and projected coordinate systems (like UTM).

### `CoordinateConversion().convert()` (for Projections)

**Purpose:** Converts coordinates from a geographic system to a projected system, or vice-versa.

**Parameters:** (Same as Datum Transformations)
- `point` (Point): The input point.
- `projSrc` (Projection): The source projection.
- `projDst` (Projection): The target projection.
- `conversion` (ConversionType): The type of conversion (e.g., `geodeticToProjected`, `projectedToGeodetic`).

### `CoordinateConversion().getUTMProjection(double longitude)`

**Purpose:** Gets the appropriate UTM projection for a given longitude. This is useful when you need to project `LatLng` to its corresponding UTM zone.

**Parameters:**
- `longitude` (double): The longitude for which to determine the UTM projection.

**Returns:**
- `Projection`: The UTM projection object.

**Example (Geodetic to Projected - UTM):**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, CoordinateConversion, Projection, ConversionType, PointX

void main() {
  final LatLng pointWGS84 = LatLng(6.65412, -1.54651, 200); // WGS84 coordinates

  CoordinateConversion transCoordinate = CoordinateConversion();
  
  // Source CRS: WGS84 Geographic Coordinate System
  Projection sourceProjection = Projection.get('EPSG:4326')!;
  
  // Target CRS: UTM zone corresponding to the longitude of pointWGS84
  Projection targetUTMProjection = transCoordinate.getUTMProjection(pointWGS84.longitude); 

  var projectedUTMPoint = transCoordinate.convert(
    point: pointWGS84,
    projSrc: sourceProjection,
    projDst: targetUTMProjection,
    conversion: ConversionType.geodeticToProjected, // Geodetic (Lat/Lng) to Projected (UTM)
  );

  print('Original WGS84: $pointWGS84');  
  // The result of a geodeticToProjected conversion is typically a PointX or similar projected coordinate type.
  // Access its x, y (easting, northing) and z (height, if applicable) properties.
  print('Projected to UTM: Easting=${projectedUTMPoint.x}, Northing=${projectedUTMPoint.y}, Height=${projectedUTMPoint.z}'); 
  // Example Output:
  // Original WGS84: 006° 39' 14.832" N, 001° 32' 47.436" W, 200.000
  // Projected to UTM: Easting=660671.6505858237, Northing=735749.4963174305, Height=200.0 
  // (Zone will be determined by longitude, e.g. Zone 30N for -1.56° longitude)
}
```

---
*Note: Ensure you have the `geoengine` package added to your `pubspec.yaml` dependencies. Some functionalities might also depend on how `Projection` objects are defined or loaded (e.g., from EPSG codes or WKT strings). The `LatLng` class is fundamental for representing geographic coordinates.*
```yaml
dependencies:
  geoengine: any # Replace with the desired version
```
