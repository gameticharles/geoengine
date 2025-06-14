
# GeoEngine

![GeoEngine Logo](link-to-logo.png)

[![pub package](https://img.shields.io/pub/v/geoengine.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/geoengine)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![likes](https://img.shields.io/pub/likes/geoengine)](https://pub.dartlang.org/packages/geoengine/score)
[![points](https://img.shields.io/pub/points/geoengine)](https://pub.dartlang.org/packages/geoengine/score)
[![popularity](https://img.shields.io/pub/popularity/geoengine)](https://pub.dartlang.org/packages/geoengine/score)
[![sdk version](https://badgen.net/pub/sdk-version/geoengine)](https://pub.dartlang.org/packages/geoengine)

[![Last Commits](https://img.shields.io/github/last-commit/gameticharles/geoengine?ogo=github&logoColor=white)](https://github.com/gameticharles/geoengine/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gameticharles/geoengine?ogo=github&logoColor=white)](https://github.com/gameticharles/geoengine/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gameticharles/geoengine?ogo=github&logoColor=white)](https://github.com/gameticharles/geoengine)
[![License](https://img.shields.io/github/license/gameticharles/geoengine?ogo=github&logoColor=white)](https://github.com/gameticharles/geoengine/blob/main/LICENSE)

[![stars](https://img.shields.io/github/stars/gameticharles/geoengine)](https://github.com/gameticharles/geoengine/stargazers)
[![forks](https://img.shields.io/github/forks/gameticharles/geoengine)](https://github.com/gameticharles/geoengine/network/members)
[![Github watchers](https://img.shields.io./github/watchers/gameticharles/geoengine)](https://github.com/gameticharles/geoengine/MyBadges)
[![Issues](https://img.shields.io./github/issues-raw/gameticharles/geoengine)](https://github.com/gameticharles/geoengine/issues)

GeoEngine is a comprehensive Dart library designed for geospatial and geomatic calculations. It provides a wide range of functionalities including distance calculations, coordinate conversions, geocoding, polygon operations, geodetic network analysis, and much more.

Astronomy: GeoEngine also provides a comprehensive astronomy library for calculating celestial coordinates, moon phases, and eclipses. Predicts lunar phases, eclipses, transits, oppositions, conjunctions, equinoxes, solstices, rise/set times, and other events. Provides vector and angular coordinate transforms among equatorial, ecliptic, horizontal, and galactic orientations.

Whether you are a GIS professional, a geomatics engineer, or a developer working on geospatial applications, GeoEngine is the ultimate toolkit for all your geospatial needs.

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  geoengine: any
```

### Usage

Here's a simple example to calculate the distance between two geographic coordinates:

```dart
import 'package:geoengine/geoengine.dart';

void main() {
  var point1 = LatLng(37.7749, -122.4194);
  var point2 = LatLng(34.0522, -118.2437);

  var distance = Distance.haversine(point1, point2);

  print('Distance between points is: ${distance.valueSI} meters');
}
```

## Features

<details>
<summary>Core Calculations</summary>

# Distance and Bearings

These are ported implementations of the java codes provided by [Movable Type Scripts]. This page presents a variety of calculations for lati­tude/longi­tude points, with the formulas and code fragments for implementing them.

[Movable Type Scripts]:https://www.movable-type.co.uk/scripts/latlong.html

- **Distance Calculation**: Calculate the distance between two geographic coordinates using various algorithms like Haversine, Vincenty, and Great Circle.

```dart
var point1 = LatLng(dms2Degree(50, 03, 59), dms2Degree(-5, 42, 53));
var point2 = LatLng(dms2Degree(58, 38, 38), dms2Degree(-3, 04, 12));

print('Distance (Haversine): ${point1.distanceTo(point2, method: DistanceMethod.haversine)!.valueInUnits(LengthUnits.kilometers)} km');
print('Distance (Great Circle): ${point1.distanceTo(point2, method: DistanceMethod.greatCircle)!.valueInUnits(LengthUnits.kilometers)} km');
print('Distance (Vincenty): ${point1.distanceTo(point2, method: DistanceMethod.vincenty)!.valueInUnits(LengthUnits.kilometers)} km');

// Distance (Haversine): 968.8535467131387 km
// Distance (Great Circle): 968.8535467131394 km
// Distance (Vincenty): 969.9329875845247 km
```

- **Bearing Calculation**: Calculate the initial and final bearing between two points on the Earth's surface.

```dart
var point1 = LatLng(dms2Degree(50, 03, 59), dms2Degree(-5, 42, 53));
var point2 = LatLng(dms2Degree(58, 38, 38), dms2Degree(-3, 04, 12));

print('Initial Bearing: ${point1.initialBearingTo(point2)}');
print('Final Bearing: ${point1.finalBearingTo(point2)}');
print('Mid Point: ${point1.midPointTo(point2)}');

// Initial Bearing: 9.119818104504077° or 0.15917085310658177 rad or 009° 07' 11.34518"
// Final Bearing: 11.275201271425715° or 0.19678938601142623 rad or 011° 16' 30.72458"
// Mid Point: 054° 21' 44.233" N, 004° 31' 50.421"
```

- **Destination Point**: Given a start point, initial bearing, and distance, this will calculate the destina­tion point and final bearing travelling along a (shortest distance) great circle arc.

```dart
var startPoint = LatLng(53.3206, -1.7297); // 53°19′14″N, 001°43′47″W
double bearing = 96.022222; // 096°01′18″
double distance = 124800; // 124.8 km

LatLng destinationPoint = startPoint.destinationPoint(distance, bearing);
var finalBearing = startPoint.finalBearingTo(destinationPoint);

print('Destination point: $destinationPoint');
print('Final bearing: $finalBearing');

// Destination point: 053° 11' 17.891" N, 000° 07' 59.875" E
// Final bearing: 97.51509150337512° or 1.7019594171174142 rad or 097° 30' 54.32941"
```

- **Interception**: Intersection of two paths given start points and bearings
This is a rather more complex calculation than most others on this page, but I've been asked for it a number of times. This comes from Ed William’s aviation formulary.

```dart
var point1 = LatLng(51.8853, 0.2545);
var bearing1 = 108.55;
var point2 = LatLng(49.0034, 2.5735);
var bearing2 = 32.44;

var intercept = LatLng.intersectionPoint(point1, bearing1, point2, bearing2)!;
  
print('Interception Point: $intercept');

// Interception Point: 050° 54' 27.387" N, 004° 30' 30.869" E
```

- **Rhumb line**: A ‘rhumb line’ (or loxodrome) is a path of constant bearing, which crosses all meridians at the same angle.

Sailors used to (and sometimes still) navigate along rhumb lines since it is easier to follow a constant compass bearing than to be continually adjusting the bearing, as is needed to follow a great circle. Rhumb lines are straight lines on a Mercator Projec­tion map (also helpful for naviga­tion).

```dart
var startPoint = LatLng(50.3667, -4.1340); // 50 21 59N, 004 08 02W
var endPoint = LatLng(42.3511, -71.0408); // 42 21 04N, 071 02 27W

var rhumbDist = startPoint.rhumbLineDistance(endPoint);
Bearing rhumbBearing = startPoint.rhumbLineBearing(endPoint);
LatLng rhumbMid = startPoint.rhumbMidpoint(endPoint);

print('Rhumb distance: ${rhumbDist.valueInUnits(LengthUnits.kilometers)} km');
print('Rhumb bearing: $rhumbBearing');
print('Rhumb midpoint: $rhumbMid');

// Rhumb distance: 5197.982109842136 km
// Rhumb bearing: Bearing: 256.66558069454646° or 4.479659459662955 rad or 256° 39' 56.09050"
// Rhumb midpoint: 047° 50' 9.060" N, 038° 13' 28.378" W
```

Given a start point and a distance d along constant bearing θ, this will calculate the destina­tion point. If you maintain a constant bearing along a rhumb line, you will gradually spiral in towards one of the poles.

```dart
var sPt = LatLng(dms2Degree(51, 07, 32), dms2Degree(1, 20, 17));
var dist = 40230;
var bearing = dms2Degree(116, 38, 10);
print('Rhumb Destination: ${sPt.rhumbDestinationPoint(dist, bearing)}');

// Rhumb Destination: 050° 57' 48.074" N, 001° 51' 8.774" E
```

- **Geodesic Calculations**: Find the shortest path between two points on the Earth's surface, taking into account the Earth's curvature which uses the Vincenty approach.

</details>

<details>
<summary>Coordinate Systems</summary>

# Coordinate Systems

- **Coordinate Conversion**: Convert between different coordinate systems, such as latitude/longitude to UTM or MGRS.

Get the UTM zone number and letter

```dart
var u = UTMZones();
var uZone = u.getZone(latitude: 6.5655, longitude: -1.5646);

print(uZone); // 30P
print(u.getHemisphere(uZone)); // N
print(u.getLatZone(6.5655)); // P
```

Parse MGRS coordinates

```dart
print(MGRS.parse('31U DQ 48251 11932')); // 31U DQ 48251 11932
print(MGRS.parse('31UDQ4825111932'));  // 31U DQ 48251 11932
```

Coordinate conversions

```dart
var ll = LatLng(6.5655, -1.5646);
print(ll.toMGRS());
print(ll.toUTM());

// 30N XN 58699 25944
// 30 N 658699.0 725944.0 0.0

print('');
var utm = UTM.fromMGRS(ll.toMGRS());
print(utm);
print(utm.toLatLng());
print(utm.toMGRS());

// 30 N 658699.0 725944.0 0.0
// 006° 33' 55.795" N, 001° 33' 52.586" W
// 30N XN 58699 25944

print('');
var mgrs = MGRS.parse(ll.toMGRS());
print(mgrs.toLatLng());
print(mgrs.toUTM());
print(mgrs);

// 006° 33' 55.795" N, 001° 33' 52.586" W
// 30 N 658699.0 725944.0
// 30N XN 58699 25944
```

- **Datum Transformations**: Transform coordinates between different geodetic datums.

```dart
final LatLng pp = LatLng(6.65412, -1.54651, 200);

CoordinateConversion transCoordinate = CoordinateConversion();

Projection sourceProjection = Projection.get('EPSG:4326')!; // Geodetic
// Add a new CRS from WKT
Projection targetProjection = Projection.parse(
      'PROJCS["Accra / Ghana National Grid",GEOGCS["Accra",DATUM["Accra",SPHEROID["War Office",6378300,296,AUTHORITY["EPSG","7029"]],TOWGS84[-199,32,322,0,0,0,0],AUTHORITY["EPSG","6168"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4168"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",4.666666666666667],PARAMETER["central_meridian",-1],PARAMETER["scale_factor",0.99975],PARAMETER["false_easting",900000],PARAMETER["false_northing",0],UNIT["Gold Coast foot",0.3047997101815088,AUTHORITY["EPSG","9094"]],AXIS["Easting",EAST],AXIS["Northing",NORTH],AUTHORITY["EPSG","2136"]]');

var res = transCoordinate.convert(
  point: pp,
  projSrc: sourceProjection,
  projDst: targetProjection,
  conversion: ConversionType.geodeticToGeodetic, // Geodetic to Geodetic conversion
);

print(pp);  
// 006° 39' 14.832" N, 001° 32' 47.436" W, 200.000
print(res.asLatLng());
// 006° 39' 4.889" N, 001° 32' 48.303" W, 200.331
```

- **Map Projections**: Support for various map projections and functions to transform coordinates between different projections.

```dart
final LatLng pp = LatLng(6.65412, -1.54651, 200);

CoordinateConversion transCoordinate = CoordinateConversion();
CoordinateType sourceCoordinateType = CoordinateType.geodetic;
CoordinateType targetCoordinateType = CoordinateType.projected;

// Get WGS84 Geographic Coordinate System
Projection sourceProjection = Projection.get('EPSG:4326')!;
// Get UTM CRS
Projection targetProjectionUTM =
    transCoordinate.getUTMProjection(pp.longitude); 

var res = transCoordinate.convert(
  point: pp,
  projSrc: sourceProjection,
  projDst: targetProjectionUTM,
  conversion: transCoordinate.getConversionType(
      sourceCoordinateType, targetCoordinateType),
  //conversion: ConversionType.geodeticToProjected,
);

print(pp);  
// 006° 39' 14.832" N, 001° 32' 47.436" W, 200.000
print(res);
// Eastings: 660671.6505858237
// Northings: 735749.4963174305
// Height: 200.0
```

</details>

<details>
<summary>Julian Dates</summary>

# Julian Date Functions

The `JulianDate` class in GeoEngine provides an interface to work with Julian Dates, a continuous count of days since the beginning of the Julian Period on January 1, 4713 BCE. This system is widely used in astronomy and other fields. Here's how you can utilize some of the main functions of this class:

## Initialization

You can create a `JulianDate` object in different ways:

### From a specific date

```dart
JulianDate date1 = JulianDate.fromDate(year: 2023, month: 8, day: 15);
```

### Using a DateTime object

```dart
var date = DateTime(2023, 8, 15);
JulianDate originalDate = JulianDate(date);
```

## Comparing Julian Dates

You can compare two `JulianDate` objects using the common comparison operators:

```dart
JulianDate date2 = JulianDate.fromDate(year: 2023, month: 8, day: 20);

print(date1 == date2); // false
print(date1 < date2);  // true
print(date1 <= date2); // true
print(date1 > date2);  // false
print(date1 >= date2); // false
```

## Conversion Functions

### To Julian Date

```dart
double jd = originalDate.toJulianDate();
print('Julian Date: $jd');

// Julian Date: 2460171.5
```

### To Modified Julian Date

The Modified Julian Date (MJD) is calculated by subtracting 2,400,000.5 from the Julian Date. It's used for convenience and starts from November 17, 1858.

```dart
print('Modified Julian Date (1858/11/17): ${originalDate.toModifiedJulianDate()}');

// Modified Julian Date (1858/11/17): 60171.0
```

### Referenced Julian Date

You can also get a referenced Julian Date by specifying a reference date:

```dart
print('Referenced Julian Date (1960/01/01): ${originalDate.toModifiedJulianDate(referenceDate: DateTime(1960, 1, 1))}');

// Referenced Julian Date (1960/01/01): 23237.0
```

## Converting Back to DateTime

If you have a Julian Date and wish to get the corresponding Gregorian date:

```dart
JulianDate convertedDate = JulianDate.fromJulianDate(jd);
print(convertedDate.dateTime);

// 2023-08-15 00:00:00.000
```

## Example

To get the Modified Julian Date with a specific reference date:

```dart
print(JulianDate(DateTime(2023, 1, 1)).toModifiedJulianDate(referenceDate: DateTime(1960, 1, 11)));

// 23001.0
```

Remember, always refer to the documentation or source code for any additional functions or nuances with the `JulianDate` class in the GeoEngine library.

</details>

<details>
<summary>Least Squares Adjustment</summary>

# Least Squares Adjustment

The `LeastSquaresAdjustment` class in GeoEngine provides a robust way to perform least squares adjustments on geodetic and other types of data. This documentation breaks down the core components and usage of the class.

## Overview

Least squares adjustment is a statistical method to solve an overdetermined system of equations. In the context of GeoEngine, this class can handle various scaling methods, and can be utilized for various geodetic computations including network adjustments.

## Initialization

To initialize the `LeastSquaresAdjustment` class, you need to provide the design matrix `A`, the observation vector `B`, and an optional weight matrix `W`.

```dart
var lsa = LeastSquaresAdjustment(A: A, B: B);
```

## Key Properties

Here are some of the core properties of the class:

- `x`: Unknown parameters.
- `v`: Residuals.
- `uv`: Unit variance.
- `N`: The normal matrix.
- `qxx`: Misclosure matrix
- `cx`: Variance-Covariance of the Adjusted Heights
- `cv`: Variance-Covariance of the Residuals
- `cl`: Variance-Covariance of the Observations
- `standardDeviation`: Standard deviation of the observations.
- `standardError`: Standard error of the observations.
- `standardErrorsOfUnknowns`: Standard errors of the unknowns.
- `standardErrorsOfResiduals`: Standard errors of the residuals.
- `standardErrorsOfObservations`: Standard errors of the observations.
- `chiSquared`: Chi-squared value for the least squares adjustment.
- `rejectionCriterion`: Rejection criterion for outlier detection, using the specified confidence level.
- `outliers`: List of boolean values indicating whether each observation is an outlier (true) or not (false).

## Methods

### Chi-Square Test

To perform a Chi-Square goodness-of-fit test:

```dart
var chiSquareTest = lsa.chiSquareTest();
```

### Covariance

To compute the covariance matrix:

```dart
var covMatrix = lsa.covariance();
```

### Error Ellipse

Compute error ellipse parameters:

```dart
var eig = lsa.errorEllipse();
```

### Outliers

Automatically remove outliers:

```dart
var newLsa = lsa.removeOutliersIteratively();
print(newLsa);
```

### Confidence Intervals

Compute confidence intervals for the unknown parameters:

```dart
var lsa = LeastSquaresAdjustment(A: A, B: B);
var intervals = lsa.computeConfidenceIntervals();
print(intervals);  // Output: [(lower1, upper1), (lower2, upper2), ...]
```

### Custom Auto Scaling

Automatically scales or normalizes the matrices based on custom functions:

```dart
var scaledLsa = lsa.customAutoScale(
  matrixNormalizationFunction: (Matrix A) => A.normalize(),
  columnNormalizationFunction: (ColumnMatrix B) => B.normalize(),
  diagonalNormalizationFunction: (DiagonalMatrix W) => W.normalize()
);
```

## Examples

Here's an example to get you started:

```dart
var A = Matrix([
  [-1, 0, 0, 0],
  [-1, 1, 0, 0],
  [0, -1, 1, 0],
  [0, 0, -1, 0],
  [0, 0, -1, 1],
  [0, 0, 0, -1],
  [1, 0, 0, -1],
]);
var W = DiagonalMatrix([1 / 16, 1 / 9, 1 / 49, 1 / 36, 1 / 16, 1 / 9, 1 / 25]);
var B = ColumnMatrix([0, 0, 0.13, 0, 0, -0.32, -0.53]);

var lsa = LeastSquaresAdjustment(A: A, B: B, W: W, confidenceLevel: 40);
var c = lsa.chiSquareTest();
print(c); // (chiSquared: 0.00340817748488164, degreesOfFreedom: 3)

print(lsa);
// Least Squares Adjustment Results:
// ---------------------------------
// Normal (N):
// Matrix: 4x4
// ┌  0.2136111111111111  -0.1111111111111111                  0.0              -0.04 ┐
// │ -0.1111111111111111  0.13151927437641722 -0.02040816326530612                0.0 │
// │                 0.0 -0.02040816326530612   0.1106859410430839            -0.0625 │
// └               -0.04                  0.0              -0.0625 0.2136111111111111 ┘
// 
// Unknown Parameters (x):
// Matrix: 4x1
// ┌  -0.06513489902716646 ┐
// │ -0.045703714070040764 │
// │    0.1900882929187552 │
// └   0.30911630747309227 ┘
// 
// Residuals (v):
// Matrix: 7x1
// ┌  0.06513489902716646 ┐
// │ 0.019431184957125695 │
// │  0.10579200698879596 │
// │  -0.1900882929187552 │
// │  0.11902801455433706 │
// │  0.01088369252690774 │
// └   0.1557487934997413 ┘
// 
// Unit Variance (σ²): 0.0011360591616272134
// 
// Standard Deviation (σ): 0.033705476730454556
// 
// Chi-squared Test (Goodness-of-fit Test):
// Chi-squared value(χ²): 0.00340817748488164
// Degrees of Freedom: 3
// 
// Standard Errors of Unknowns (Cx): 
// [0.10509275934271714, 0.13339652325953671, 0.11787096037126248, 0.08536738678162376]
// 
// Standard Errors of Residuals (Cv): 
// [0.08445388398273435, 0.0340385190674456, 0.1853208260338704, 0.16433066214111094, 0.08042190803509813, 0.054193558000204894, 0.12767979681503475]
// 
// Standard Errors of Observations (Cl): 
// [0.10509275934271714, 0.09521508112867448, 0.14602428002855353, 0.11787096037126248, 0.10820934938363522, 0.08536738678162376, 0.1099970387144662]
// 
// Rejection Criterion (Confidence Level 40.0): 0.01766173284889808
// 
// Outliers (false = accepted, true = rejected): 
// [false, true, false, false, true, false, false]
// 
// Error Ellipse: 
// [0.029441222484548304, 0.01187530402393495, 0.005032048784758579, 0.0036716992155236177]
// 
// ---------------------------------
```

</details>

<details>
<summary>Levelling</summary>

# Levelling

This file describes the `Levelling` class, which represents a levelling survey. It allows you to define various parameters and perform calculations related to the survey. The class contains properties for the starting benchmark (TBM), closing TBM, accuracy, rounding digits, levelling method, etc. You can add measurements, compute reduced levels, get arithmetic checks, and print a summary of the results.

## Initialization

To initialize the `Levelling` class, you need to provide the accuracy `accuracy`, method `method`, starting TBM and an optional closing TBM.

```dart
var levelling = Levelling(
  startingTBM: 100.0,
  accuracy: 3,
  roundDigits: 3,
  method: LevellingMethod.riseFall,
);
```

## Usage

You can start with or with the closing TBM.

```dart
// Initialize with starting TBM
final startingTBM = 100.000;

// Initialize with closing TBM
final closingTBM = 98.050;

// Create a new instance of Levelling with starting TBM, closing TBM, accuracy, method, rounding digits
final leveling = Levelling(
  startingTBM: startingTBM,
  closingTBM: closingTBM,
  accuracy: 5,
  method: LevellingMethod.riseFall,
  roundDigits: 3,
);
```

The can be in a form of `List<List<Object?>>` or list of `LevellingMeasurement` objects.

```dart
// Create the sample observation data
final data = [
  ['A', 1.751, null, null],
  ['B', null, 0.540, null],
  ['C', 0.300, null, 2.100],
  ['D', null, 1.100, null],
  ['E', null, 1.260, null],
  ['F', 1.500, null, 2.300],
  ['G', null, null, 1.110]
];

// Add the data to the levelling object
for (int i = 0; i < data.length; i++) {
  final row = data[i];
  levelling.addMeasurement(LevellingMeasurement(
      bs: row[1], is_: row[2], fs: row[3], station: row[0]));
}

// or use this
for (var entry in data) {
  leveling.addData(entry[0].toString(), entry[1], entry[2], entry[3]);
}
```

You can get the result as a data frame or as a list of maps.

```dart
leveling.computeReducedLevels();
print("Rise & Fall:");
print(leveling.getDataFrame());

// Calculate reduced levels using Rise & Fall algorithm
leveling.computeReducedLevels(LevellingMethod.hpc);

print("\n\nHPC:");
print(leveling.getDataFrame());
```

Once the data are added to the `Levelling` object, you can perform calculations. You can access all the results through the `Levelling` object.
You can access all the properties of the object.

```dart
print(leveling.numberSTN); // 3
print(leveling.allowableMisclose); // 5.196
print(leveling.misclose); // -0.009
print(leveling.correction); // 0.009
print(leveling.adjustmentPerStation); // 0.003
print(leveling.reducedLevels); // [100.0, 101.211, 99.651, 98.851, 98.691, 97.651, 98.041]
print(leveling.isWorkAccepted); // Work is not accepted

print(leveling.arithmeticCheckResult);
// Arithmetic Checks:
// Sum of BS = 3.551
// Sum of FS = 5.510
// First RL = 100.000
// Last RL = 98.041
// Sum of BS - Sum of FS = -1.959
// Last RL - First RL = -1.959
// Arithmetic Checks are OK.
```

This can simply be printed by just calling the `levelling` object for more detailed result.

```dart
print(leveling);

// ------ Levelling Summary -------
// 
// Total measurements = 7
// Number of instrument stations = 3
// Starting TBM = 100.0
// Closing TBM = 98.05
// 
// Allowable misclose = 8.660 mm
// Misclose = -0.009 m (-9.000 mm)
// Correction = 0.009
// Adjustment per station = 0.003
// Leveling Status: Work is not accepted.
// 
// Arithmetic Checks:
// Sum of BS = 3.551
// Sum of FS = 5.510
// First RL = 100.000
// Last RL = 98.041
// Sum of BS - Sum of FS = -1.959
// Last RL - First RL = -1.959
// Arithmetic Checks are OK.
// 
// BS     IS    FS   Rise   Fall    Reduced Level (RL)  Adjustment  Adjusted RL  Remarks
// ---------------------------------------------------------------------
// 1.751                                100.000       0.000         100.000       A
//      0.540        1.211                 101.211       0.003         101.214       B
// 0.300    2.100      -1.560             99.651       0.006          99.657       C
//      1.100             -0.800             98.851       0.006          98.857       D
//      1.260             -0.160             98.691       0.006          98.697       E
// 1.500    2.300      -1.040             97.651       0.009          97.660       F
//           1.110 0.390                  98.041       0.009          98.050       G
```

</details>

<details>
<summary>Geocoding</summary>

# Geocoding

Geocoding is the process of converting addresses or place names into geographic coordinates (latitude and longitude). This allows you to perform various spatial operations, such as finding distances between locations or visualizing data on a map. In this readme, I will introduce a Dart class library for geocoding that provides different strategies for using geocoding services.

## initialize Geocoding

The GeoCoding library is designed to help you easily perform geocoding tasks in your Dart applications. It provides a set of classes and methods for working with geographic coordinates, addresses, and place names. The library supports multiple geocoding services and allows you to switch between them based on your needs.

```dart
Geocoder({
  required Map<String, dynamic> strategyFactory,
  Map<String, dynamic> config = const {},
  Duration throttleDuration = const Duration(seconds: 1),
})
```

## Strategies

The `GeoCoder` library offers different strategies for using geocoding services:

1. `GoogleStrategy`: This strategy uses the Google Maps Geocoding API to perform geocoding. You will need an API key from Google Cloud Platform to use this strategy.
2. `OpenStreetMapStrategy`: This strategy uses the OpenStreetMap Nominatim service for geocoding. It is a free and open-source service that does not require any API keys.
3. `LocalStrategy`: This strategy uses the local database of the device to perform geocoding. It is a fast and efficient way to perform geocoding.
4. `CustomStrategy`: This strategy allows you to provide your own geocoding service implementation. You can create a custom class that implements the required methods and use it as a strategy in the `GeoCoding` library.

## Usage GoogleStrategy

Google strategy is the default strategy that is used by the `GeoCoder` library. It uses the Google Maps Geocoding API to perform geocoding. You will need an API key from Google Cloud Platform to use this strategy.

```dart
 var point2 = LatLng(6, 0.7);

var googleGeocoder = Geocoder(
  strategyFactory: GoogleStrategy.create('YOUR_GOOGLE_API_KEY'),
  config: {
    // Common Configurations
    'language': 'en',
    'requestTimeout': const Duration(seconds: 10),

    // Google-Specific Configurations
    'regionBias': 'US',
    'resultType': 'address',
    'locationType': 'ROOFTOP',
    'components': 'country:US',
    'rateLimit': 10, // Requests per second
    }
);

GeocoderRequestResponse search = await googleGeocoder.search('Kotei');
print(search);
print('');

GeocoderRequestResponse rev = await googleGeocoder.reverse(point2);
print(rev);
print('');
```

## Usage OpenStreetMapStrategy

```dart
var openStreetMapGeocoder =
    Geocoder(strategyFactory: OpenStreetMapStrategy.create(), config: {
  // Common Configurations
  'language': 'en',
  'requestTimeout': const Duration(seconds: 10),

  // OpenStreetMap-Specific Configurations
  'email': 'contact@example.com', // For Nominatim usage policy
  'countryCodes': 'us,uk',
  'viewBox': 'left,bottom,right,top',
  'boundedViewBox': '1', //bounded to viewbox
  'limit': 5,
  'addressDetails': 1,
});

// Geocode an address
GeocoderRequestResponse search = await openStreetMapGeocoder.search('KNUST');
print(search);
print('');

// Reverse geocode coordinates to get the address
GeocoderRequestResponse rev = await openStreetMapGeocoder.reverse(point2);
print(rev);
print('');
```

Result:

```txt
Geocoding Search Query: knust, Success: true, Timestamp: 2024-02-19 04:56:54.024349
GeocoderRequestResponse:
Success: true
Duration: 1035ms
Result: [{place_id: 125221183, licence: Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright, osm_type: way, osm_id: 32197062, lat: 53.741931199999996, lon: 9.842065240044334, class: natural, type: wood, place_rank: 22, importance: 0.2000099999999999, addresstype: wood, name: Knust, display_name: Knust, Quickborn, Kreis Pinneberg, Schleswig-Holstein, 25451, Germany, boundingbox: [53.7398546, 53.7444675, 9.8384852, 9.8500422]}, {place_id: 258247195, licence: Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright, osm_type: way, osm_id: 378466289, lat: 6.6785135, lon: -1.5754220088808766, class: amenity, type: university, place_rank: 30, importance: 0.3752824455605189, addresstype: amenity, name: Kwame Nkrumah University of Science & Technology, display_name: Kwame Nkrumah University of Science & Technology, Osei Tutu II Boulevard, Ayigya, Kumasi, Oforikrom Municipal District, Ashanti Region, AK385, Ghana, boundingbox: [6.6617810, 6.6953608, -1.5894842, -1.5323729]}, {place_id: 108558563, licence: Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright, osm_type: node, osm_id: 3362954799, lat: 49.5656112, lon: 9.4330658, class: place, type: locality, place_rank: 25, importance: 0.12500999999999995, addresstype: locality, name: Knust, display_name: Knust, Fuchsenloch, Waldstetten, Höpfingen, Verwaltungsverband Hardheim-Walldürn, Neckar-Odenwald-Kreis, Baden-Württemberg, 74746, Germany, boundingbox: [49.5556112, 49.5756112, 9.4230658, 9.4430658]}, {place_id: 122049626, licence: Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright, osm_type: node, osm_id: 4874767389, lat: 51.3722208, lon: 8.7031219, class: highway, type: bus_stop, place_rank: 30, importance: 0.00000999999999995449, addresstype: highway, name: Knust, display_name: Knust, L 3393, Heringhausen, Diemelsee, Landkreis Waldeck-Frankenberg, Hesse, 34519, Germany, boundingbox: [51.3721708, 51.3722708, 8.7030719, 8.7031719]}, {place_id: 379344893, licence: Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright, osm_type: node, osm_id: 1525291987, lat: 53.5581388, lon: 9.9679333, class: amenity, type: nightclub, place_rank: 30, importance: 0.00000999999999995449, addresstype: amenity, name: Knust, display_name: Knust, 30, Neuer Kamp, Karolinenviertel, St. Pauli, Hamburg-Mitte, Hamburg, 20357, Germany, boundingbox: [53.5580888, 53.5581888, 9.9678833, 9.9679833]}, {place_id: 98501560, licence: Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright, osm_type: node, osm_id: 1979116123, lat: 51.3126212, lon: 7.9976981, class: highway, type: bus_stop, place_rank: 30, importance: 0.00000999999999995449, addresstype: highway, name: Knust, display_name: Knust, Silmecke, Seidfeld (Sauerland), Sundern, Hochsauerlandkreis, North Rhine-Westphalia, 59846, Germany, boundingbox: [51.3125712, 51.3126712, 7.9976481, 7.9977481]}]

Reverse Geocoding Query: Location(6.0, 0.7), Success: true, Timestamp: 2024-02-19 04:56:55.029766
GeocoderRequestResponse:
Success: true
Duration: 1003ms
Result: {place_id: 34177377, licence: Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright, osm_type: way, osm_id: 517183740, lat: 5.999405087489885, lon: 0.7000142714680313, class: highway, type: unclassified, place_rank: 26, importance: 0.10000999999999993, addresstype: road, name: , display_name: Dabala, South Tongu District, Volta Region, Ghana, address: {town: Dabala, county: South Tongu District, state: Volta Region, ISO3166-2-lvl4: GH-TV, country: Ghana, country_code: gh}, boundingbox: [5.9949293, 5.9994108, 0.6890045, 0.7032672]}
```

## Usage LocalStrategy

The `LocalStrategy` in the `GeoCoding` library allows you to use a pre-defined dataset for geocoding and reverse geocoding. This is useful when you want to work with an offline dataset or need to process large amounts of data quickly without relying on network requests to external services. The Local Strategy requires you to provide a set of coordinates along with their associated addresses, places, or locations.

To create a `GeoCoder` instance using the Local Strategy, you can use the following code for dataset strategy:

```dart
List<Map<String, double>> points = [
  {'latitude': 5.80736, 'longitude': 0.41074},
  {'latitude': 6.13373, 'longitude': 0.81585},
  {'latitude': 11.01667, 'longitude': -0.5},
  {'latitude': 10.08587, 'longitude': -0.13587},
  {'latitude': 9.35, 'longitude': -0.88333},
  {'latitude': 10.73255, 'longitude': -1.05917},
];
```

Or using downloaded data from [GeoNames data][geonames]  file with all world cities and population.

[geonames]: https://download.geonames.org/export/dump/

```dart
final geoData = await GeoData.readFile(
  'example/GH.txt',
  delimiter: '\t',
  hasHeader: false,
  coordinatesColumns: {
    'latitude': 4,
    'longitude': 5
  }, // Specify column names and indices
);

// Print the number of records in the file
print(geoData.rows.length); // 23232
```

With the data created, geocoder can be used to create a local strategy using `KDTree` indexing. Other indexing methods will be implemented soon.
The only difference is the connection to data and associating the coordinates to `x` and `y` axis.

In this example, the `geoData` list contains the addresses, latitudes, and longitudes of different locations. The `LocalStrategy.create()` function is used to create a geocoding strategy using the provided data and specify the column names for coordinates. You can customize various configuration options for the Local Strategy, including search radius, limit, data preprocessing logic, cache size, and indexing strategy.

Once you have created the `localGeocoder` instance, you can use it to geocode an address or reverse geocode coordinates:

```dart
var localGeocoder = Geocoder(
  strategyFactory: LocalStrategy.create(
    entries: geoData.rows,
    coordinatesColumnNames: (y: 'latitude', x: 'longitude'),
  ),
  config: {
    // Common Configurations
    'language': 'en',
    'requestTimeout': const Duration(seconds: 10),

    // Local-Specific Configurations
    'isGeodetic': true,
    'searchRadius': 2000, // in meters
    'limit': 5, // Number of results to return
    'dataPreprocessing': (data) => {/* preprocessing logic */},
    'cacheSize': 100,
    'indexingStrategy': 'KDTree', // or 'RTree will be implemented soon'
});

// Geocode an address
GeocoderRequestResponse u = await localGeocoder.search('Kotei');
print(u);
print('');

// Reverse geocode coordinates to get the address
GeocoderRequestResponse rex = await localGeocoder.reverse(point2);
print(rex);
print('');
```

```txt
Geocoding Search Query: kotei, Success: true, Timestamp: 2024-02-19 05:13:55.706794
GeocoderRequestResponse:
Success: true
Duration: 42ms
Result: [{latitude: 6.66308, longitude: -1.55893, 0: 2299299, 1: Kotei, 2: Kotei, 3: Kotei, 4: 6.66308, 5: -1.55893, 6: P, 7: PPL, 8: GH, 9: , 10: 2, 11: 614, 12: , 13: , 14: 0, 15: , 16: 270, 17: Africa/Accra, 18: 06/12/2019}, {latitude: 6.60296, longitude: -1.66005, 0: 11780246, 1: Kotei, 2: Kotei, 3: "Kotei,Kotwi", 4: 6.60296, 5: -1.66005, 6: P, 7: PPL, 8: GH, 9: , 10: 2, 11: 613, 12: , 13: , 14: 0, 15: , 16: 242, 17: Africa/Accra, 18: 05/12/2019}]

Reverse Geocoding Query: Location(6.0, 0.7), Success: true, Timestamp: 2024-02-19 05:13:56.671350
GeocoderRequestResponse:
Success: true
Duration: 6ms
Result: [[{latitude: 5.98333, longitude: 0.7, 0: 2302105, 1: Dabala, 2: Dabala, 3: , 4: 5.98333, 5: 0.7, 6: H, 7: LK, 8: GH, 9: , 10: 0, 11: , 12: , 13: , 14: 0, 15: , 16: 1, 17: Africa/Accra, 18: 06/01/1994}, 1853.6194271649065], [{latitude: 5.98306, longitude: 0.69745, 0: 2305576, 1: Agbogbla, 2: Agbogbla, 3: "Agbogbla,Agoblan", 4: 5.98306, 5: 0.69745, 6: P, 7: PPL, 8: GH, 9: , 10: 8, 11: 401, 12: , 13: , 14: 0, 15: , 16: 3, 17: Africa/Accra, 18: 06/12/2019}, 1904.6339152449402]]

Initial Bearing: Bearing: 0.0° or 0.0 rad or 000° 00' 0.00000"
Final Bearing: Bearing: 180.0° or 3.1415926535897403 rad or 180° 00' 0.00000"
Distance (Haversine): 1.8536194271649065 km
Distance (Great Circle): 1.8536194278434843 km
Distance (Vincenty): 1.8434748739484934 km

Initial Bearing: Bearing: 8.514324846934187° or 0.14860300216336128 rad or 008° 30' 51.56945"
Final Bearing: Bearing: 188.51459101961586° or 3.2902003013427756 rad or 188° 30' 52.52767"
Distance (Haversine): 1.9046339152449403 km
Distance (Great Circle): 1.9046339162803452 km
```

The `localGeocoder.search()` and `localGeocoder.reverse()` functions work similarly to their online counterparts, allowing you to easily geocode addresses or reverse geocode coordinates from your pre-defined dataset.

</details>

<details>
<summary>Astronomy</summary>

# Astronomy

## Overview

Astronomy is a library for calculating the positions of
the Sun, Moon, and planets, and for predicting interesting events like oppositions,
conjunctions, rise and set times, lunar phases, eclipses, transits, and more.

Astronomy library is designed to be small, fast, and accurate to within &plusmn;1 arcminute. It is
ported from the [Astronomy Engine](https://github.com/cosinekitty/astronomy) which written to support various popular programming languages.

It is based on the authoritative and well-tested models
[VSOP87](https://en.wikipedia.org/wiki/VSOP_(planets))
and
[NOVAS C 3.1](https://aa.usno.navy.mil/software/novas/novas_c/novasc_info.php).
These libraries are rigorously unit-tested against NOVAS,
[JPL Horizons](https://ssd.jpl.nasa.gov/horizons.cgi),
and other reliable sources of ephemeris data.
Calculations are also verified to be identical among all the supported programming languages.

## Features

- Provides calculations for the Sun, Moon, Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune, and Pluto.

- Calculates all supported objects for any calendar date and time for millennia
  before or after the present.

- Provides heliocentric and geocentric Cartesian vectors of all the above bodies.

- Determines apparent horizon-based positions for an observer anywhere on the Earth,
  given that observer's latitude, longitude, and elevation in meters.
  Optionally corrects for atmospheric refraction.

- Calculates rise, set, and culmination times of Sun, Moon, and planets.

- Finds civil, nautical, and astronomical twilight times (dusk and dawn).

- Finds date and time of Moon phases: new, first quarter, full, third quarter
  (or anywhere in between as expressed in degrees of ecliptic longitude).

- Predicts lunar and solar eclipses.

- Predicts transits of Mercury and Venus.

- Predicts lunar apogee and perigee dates, times, and distances.

- Predicts date and time of equinoxes and solstices for a given calendar year.

- Determines apparent visual magnitudes of all the supported celestial bodies.

- Predicts dates of planetary conjunctions, oppositions, and apsides.

- Predicts dates of Venus' peak visual magnitude.

- Predicts dates of maximum elongation for Mercury and Venus.

- Calculates the positions of Jupiter's four largest moons: Io, Europa, Ganymede, and Callisto.

- Allows custom simulation of the movements of user-defined small bodies,
  such as asteroids and comets, through the Solar System.

- Converts angular and vector coordinates among the following orientations:
  - Equatorial J2000
  - Equatorial equator-of-date
  - Ecliptic J2000
  - Topocentric Horizontal
  - Galactic (IAU 1958)

- Determines which constellation contains a given point in the sky.

- Calculates libration of the Moon.

- Calculates axis orientation and rotation angles for the Sun, Moon, and planets.

</details>

## Documentation

For detailed documentation and examples for each feature, please visit the [GeoEngine Documentation] (https://github.com/gameticharles/geoengine/blob/main/doc/README.md).

## Contributing

### :beer: Pull requests are welcome

Don't forget that `open-source` makes no sense without contributors. No matter how big your changes are, it helps us a lot even it is a line of change.

There might be a lot of grammar issues in the docs. It's a big help to us to fix them if you are fluent in English. Reporting bugs and issues are contribution too, yes it is. Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gameticharles/geoengine/issues

## Testing

Tests are located in the test directory. To run tests, execute dart test in the project root.

## Author

Charles Gameti: [gameticharles@GitHub][github_cg].

[github_cg]: https://github.com/gameticharles

## License

GeoEngine is licensed under the [Apache License - Version 2.0][apache_license].

[apache_license]: https://www.apache.org/licenses/LICENSE-2.0.txt
