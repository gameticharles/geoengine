# Core Calculations: Distance and Bearings

This module provides a comprehensive set of functions for performing core geospatial calculations, focusing on distances and bearings between geographic coordinates. These functions are essential for a wide range of applications, including navigation, mapping, and location-based services.

The calculations are ported implementations of the Java codes provided by [Movable Type Scripts](https://www.movable-type.co.uk/scripts/latlong.html). 
The `LatLng` class (representing latitude/longitude points) and `Bearing` / `Distance` objects are central to this module.

## Distance Calculation

Calculates the distance between two geographic coordinates using various algorithms.

### `Distance.haversine(LatLng point1, LatLng point2)`

**Purpose:** Calculates the distance between two points using the Haversine formula, which assumes a spherical Earth. This is a common method for calculating distances on the Earth's surface.

**Parameters:**
- `point1` (LatLng): The first geographic point (latitude/longitude).
- `point2` (LatLng): The second geographic point (latitude/longitude).

**Returns:**
- `Distance`: An object representing the distance, which can be converted to various units (e.g., meters, kilometers).

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, Distance, LengthUnits
// Note: LatLng might also be available from 'package:advance_math/advance_math.dart'

void main() {
  var point1 = LatLng(37.7749, -122.4194);
  var point2 = LatLng(34.0522, -118.2437);

  var distance = Distance.haversine(point1, point2);

  print('Distance between points is: ${distance.valueSI} meters'); // Default is meters
  print('Distance between points is: ${distance.valueInUnits(LengthUnits.kilometers)} km');
}
```

### Other Distance Methods

The `distanceTo` method on a `LatLng` object can also be used with different `DistanceMethod` enums:

- `DistanceMethod.greatCircle`: Calculates the distance along the great circle arc between two points. This is the shortest path on a sphere.
- `DistanceMethod.vincenty`: Uses Vincenty's formulae, which are more accurate for an ellipsoidal Earth, especially for long distances.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, DistanceMethod, LengthUnits
import 'package:advance_math/advance_math.dart'; // Required for dms2Degree

void main() {
  var point1 = LatLng(dms2Degree(50, 03, 59), dms2Degree(-5, 42, 53));
  var point2 = LatLng(dms2Degree(58, 38, 38), dms2Degree(-3, 04, 12));

  print('Distance (Haversine): ${point1.distanceTo(point2, method: DistanceMethod.haversine)!.valueInUnits(LengthUnits.kilometers)} km');
  print('Distance (Great Circle): ${point1.distanceTo(point2, method: DistanceMethod.greatCircle)!.valueInUnits(LengthUnits.kilometers)} km');
  print('Distance (Vincenty): ${point1.distanceTo(point2, method: DistanceMethod.vincenty)!.valueInUnits(LengthUnits.kilometers)} km');
}
```

## Bearing Calculation

### `LatLng.initialBearingTo(LatLng otherPoint)`

**Purpose:** Calculates the initial bearing (also known as forward azimuth) from the first point to the second point. The bearing is the angle, measured clockwise from true north, from the first point to the second point.

**Parameters:**
- `otherPoint` (LatLng): The second geographic point.

**Returns:**
- `Bearing`: An object representing the bearing, which can be expressed in degrees or radians.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, Bearing
import 'package:advance_math/advance_math.dart'; // Required for dms2Degree

void main() {
  var point1 = LatLng(dms2Degree(50, 03, 59), dms2Degree(-5, 42, 53));
  var point2 = LatLng(dms2Degree(58, 38, 38), dms2Degree(-3, 04, 12));

  Bearing initialBearing = point1.initialBearingTo(point2);
  print('Initial Bearing: $initialBearing');
  // Example output: Initial Bearing: 9.119818104504077° or 0.15917085310658177 rad or 009° 07' 11.34518"
}
```

### `LatLng.finalBearingTo(LatLng otherPoint)`

**Purpose:** Calculates the final bearing from the first point to the second point. For great circle routes, the bearing usually changes as you travel. The final bearing is the bearing at which you arrive at the destination point.

**Parameters:**
- `otherPoint` (LatLng): The second geographic point.

**Returns:**
- `Bearing`: An object representing the final bearing.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, Bearing
import 'package:advance_math/advance_math.dart'; // Required for dms2Degree

void main() {
  var point1 = LatLng(dms2Degree(50, 03, 59), dms2Degree(-5, 42, 53));
  var point2 = LatLng(dms2Degree(58, 38, 38), dms2Degree(-3, 04, 12));

  Bearing finalBearing = point1.finalBearingTo(point2);
  print('Final Bearing: $finalBearing');
  // Example output: Final Bearing: 11.275201271425715° or 0.19678938601142623 rad or 011° 16' 30.72458"
}
```

## Midpoint Calculation

### `LatLng.midPointTo(LatLng otherPoint)`

**Purpose:** Calculates the midpoint between two geographic points along a great circle arc.

**Parameters:**
- `otherPoint` (LatLng): The second geographic point.

**Returns:**
- `LatLng`: The geographic coordinates of the midpoint.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng
import 'package:advance_math/advance_math.dart'; // Required for dms2Degree

void main() {
  var point1 = LatLng(dms2Degree(50, 03, 59), dms2Degree(-5, 42, 53));
  var point2 = LatLng(dms2Degree(58, 38, 38), dms2Degree(-3, 04, 12));

  LatLng midPoint = point1.midPointTo(point2);
  print('Mid Point: $midPoint'); // Output format might depend on LatLng's toString()
  // Example output from original README: Mid Point: 054° 21' 44.233" N, 004° 31' 50.421" W
}
```

## Destination Point Calculation

### `LatLng.destinationPoint(double distance, double bearing)`

**Purpose:** Calculates the destination point given a starting point, a distance, and an initial bearing. This function determines the coordinates of the point reached by traveling the specified distance along the given bearing from the starting point, following a great circle arc.

**Parameters:**
- `distance` (double): The distance to travel (in meters).
- `bearing` (double): The initial bearing (in degrees).

**Returns:**
- `LatLng`: The geographic coordinates of the destination point.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng

void main() {
  var startPoint = LatLng(53.3206, -1.7297); // e.g., 53°19′14″N, 001°43′47″W
  double bearingDegrees = 96.022222; // e.g., 096°01′18″
  double distanceMeters = 124800; // e.g., 124.8 km

  LatLng destination = startPoint.destinationPoint(distanceMeters, bearingDegrees);
  print('Destination point: $destination');
  // Example output from original README: Destination point: 053° 11' 17.891" N, 000° 07' 59.875" E
}
```

## Intersection Point of Two Paths

### `LatLng.intersectionPoint(LatLng point1, double bearing1, LatLng point2, double bearing2)`

**Purpose:** Calculates the intersection point of two paths, each defined by a starting point and a bearing. This is useful for determining where two great circle paths cross.

**Parameters:**
- `point1` (LatLng): The starting point of the first path.
- `bearing1` (double): The bearing of the first path (in degrees).
- `point2` (LatLng): The starting point of the second path.
- `bearing2` (double): The bearing of the second path (in degrees).

**Returns:**
- `LatLng?`: The geographic coordinates of the intersection point, or `null` if the paths do not intersect or are coincident.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng

void main() {
  var p1 = LatLng(51.8853, 0.2545);
  var brng1 = 108.55; // degrees
  var p2 = LatLng(49.0034, 2.5735);
  var brng2 = 32.44; // degrees

  LatLng? intersection = LatLng.intersectionPoint(p1, brng1, p2, brng2);
  
  if (intersection != null) {
    print('Intersection Point: $intersection');
    // Example output from original README: Intersection Point: 050° 54' 27.387" N, 004° 30' 30.869" E
  } else {
    print('Paths do not intersect or are coincident.');
  }
}
```

## Rhumb Line Calculations

A rhumb line (or loxodrome) is a path of constant bearing, which crosses all meridians at the same angle. Sailors often use rhumb lines because it's easier to follow a constant compass bearing.

### `LatLng.rhumbLineDistance(LatLng endPoint)`

**Purpose:** Calculates the distance between two points along a rhumb line.

**Parameters:**
- `endPoint` (LatLng): The destination point.

**Returns:**
- `Distance`: An object representing the rhumb line distance.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, Distance, LengthUnits

void main() {
  var startPoint = LatLng(50.3667, -4.1340); // e.g., 50°21′59″N, 004°08′02″W
  var endPoint = LatLng(42.3511, -71.0408);   // e.g., 42°21′04″N, 071°02′27″W

  Distance rhumbDist = startPoint.rhumbLineDistance(endPoint);
  print('Rhumb distance: ${rhumbDist.valueInUnits(LengthUnits.kilometers)} km');
  // Example output: Rhumb distance: 5197.982109842136 km
}
```

### `LatLng.rhumbLineBearing(LatLng endPoint)`

**Purpose:** Calculates the constant bearing (rhumb line bearing) from the starting point to the destination point.

**Parameters:**
- `endPoint` (LatLng): The destination point.

**Returns:**
- `Bearing`: An object representing the rhumb line bearing.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng, Bearing

void main() {
  var startPoint = LatLng(50.3667, -4.1340);
  var endPoint = LatLng(42.3511, -71.0408);

  Bearing rhumbBearing = startPoint.rhumbLineBearing(endPoint);
  print('Rhumb bearing: $rhumbBearing');
  // Example output: Rhumb bearing: Bearing: 256.66558069454646° or 4.479659459662955 rad or 256° 39' 56.09050"
}
```

### `LatLng.rhumbMidpoint(LatLng endPoint)`

**Purpose:** Calculates the midpoint between two points along a rhumb line.

**Parameters:**
- `endPoint` (LatLng): The destination point.

**Returns:**
- `LatLng`: The geographic coordinates of the rhumb line midpoint.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng

void main() {
  var startPoint = LatLng(50.3667, -4.1340);
  var endPoint = LatLng(42.3511, -71.0408);

  LatLng rhumbMid = startPoint.rhumbMidpoint(endPoint);
  print('Rhumb midpoint: $rhumbMid');
  // Example output from original README: Rhumb midpoint: 047° 50' 9.060" N, 038° 13' 28.378" W
}
```

### `LatLng.rhumbDestinationPoint(double distance, double bearing)`

**Purpose:** Calculates the destination point when traveling a given distance along a constant rhumb line bearing from a starting point.

**Parameters:**
- `distance` (double): The distance to travel (in meters).
- `bearing` (double): The constant rhumb line bearing (in degrees).

**Returns:**
- `LatLng`: The geographic coordinates of the rhumb line destination point.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides LatLng
import 'package:advance_math/advance_math.dart'; // Required for dms2Degree

void main() {
  var startPt = LatLng(dms2Degree(51, 07, 32), dms2Degree(1, 20, 17));
  var distanceMeters = 40230.0; // 40.23 km
  var bearingDegrees = dms2Degree(116, 38, 10);

  LatLng rhumbDest = startPt.rhumbDestinationPoint(distanceMeters, bearingDegrees);
  print('Rhumb Destination: $rhumbDest');
  // Example output from original README: Rhumb Destination: 050° 57' 48.074" N, 001° 51' 8.774" E
}
```

---
*Note: Ensure you have the `geoengine` package added to your `pubspec.yaml` dependencies. Some examples also use `advance_math` for DMS to Degree conversions. `LatLng` itself might be part of `advance_math` or re-exported by `geoengine`.*
```yaml
dependencies:
  geoengine: any # Replace with the desired version
  advance_math: any # Replace with the desired version, if using dms2Degree or LatLng directly from it
```
