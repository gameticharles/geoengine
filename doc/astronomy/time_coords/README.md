# Time, Coordinate Systems, and Orientations

This section covers essential aspects of astronomical calculations related to time, different ways of representing positions in the sky (coordinate systems), transformations between these systems, and other orientational information like constellation identification and planetary axis details. All celestial bodies are referred to using the `Body` enum, detailed in the [Celestial Body Calculations](../bodies/README.md) section.

## Astronomical Time (`AstroTime`)

Consistent and accurate timekeeping is fundamental in astronomy. The GeoEngine library uses the `AstroTime` class as the standard way to represent time for all astronomical calculations.

-   **Purpose**: Encapsulates a specific moment, handling conversions between standard `DateTime` objects and various astronomical timescales, primarily Universal Time (UT) and Terrestrial Time (TT). These are often expressed internally as a number of days since the J2000.0 epoch (January 1, 2000, at 12:00 TT).
-   **Creation**:
    -   `AstroTime(DateTime dt)`: Creates an `AstroTime` object from a Dart `DateTime`. It's recommended to use UTC `DateTime` objects to avoid ambiguity (e.g., `DateTime.now().toUtc()`).
    -   `AstroTime(double j2000DaysUT)`: Creates an `AstroTime` from a numeric value representing UT days since J2000.0.
    -   `AstroTime.fromTerrestrialTime(double ttDaysJ2000)`: Creates an `AstroTime` from Terrestrial Time days since J2000.0.
-   **Key Properties**:
    -   `date` (DateTime): The underlying Dart `DateTime` object (in UTC).
    -   `ut` (double): Universal Time days since J2000.0.
    -   `tt` (double): Terrestrial Time days since J2000.0.
-   **Julian Dates**: While `AstroTime` uses a J2000.0 epoch, Julian Dates (JD) traditionally use an epoch of January 1, 4713 BCE. If you have a Julian Date, you'll need to convert it to `DateTime` or J2000.0 days before creating an `AstroTime` object. See the [Julian Dates documentation](../../julian_dates/README.md) for the `JulianDate` class which can help with these conversions.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides AstroTime

void main() {
  // From current DateTime
  AstroTime now = AstroTime(DateTime.now().toUtc());
  print('Current AstroTime (UTC): ${now.date.toIso8601String(withColon: true)}');
  print('  UT days from J2000: ${now.ut.toStringAsFixed(5)}');
  print('  TT days from J2000: ${now.tt.toStringAsFixed(5)}');

  // From J2000.0 days (e.g., UT)
  // J2000.0 itself is 0 days from J2000.0 UT (noon on Jan 1, 2000 UTC).
  AstroTime epochTime = AstroTime(0.0); 
  print('J2000.0 Epoch AstroTime: ${epochTime.date.toIso8601String(withColon: true)}'); // Output: 2000-01-01T12:00:00.000Z
}
```

## Equinoxes and Solstices

These four events mark the transitions between the Earth's seasons.
-   **Equinoxes**: Times when the Earth's equatorial plane passes through the Sun's center.
    -   March Equinox (Vernal/Spring in Northern Hemisphere): Sun's ecliptic longitude is 0°.
    -   September Equinox (Autumnal in Northern Hemisphere): Sun's ecliptic longitude is 180°.
-   **Solstices**: Times when the Sun reaches its greatest angular distance from the celestial equator.
    -   June Solstice (Summer in Northern Hemisphere): Sun's ecliptic longitude is 90°.
    -   December Solstice (Winter in Northern Hemisphere): Sun's ecliptic longitude is 270°.

**Key Function:**
-   **`SeasonInfo.seasons(int year)`**: Calculates the UTC times of all four seasonal events for the given `year`.
    -   Returns: `SeasonInfo` object.

### `SeasonInfo` Object
-   `marEquinox` (AstroTime): Time of the March equinox.
-   `junSolstice` (AstroTime): Time of the June solstice.
-   `sepEquinox` (AstroTime): Time of the September equinox.
-   `decSolstice` (AstroTime): Time of the December solstice.

**Example (Finding seasons for the current year):**
```dart
import 'package:geoengine/geoengine.dart'; // Provides SeasonInfo, AstroTime

void main() {
  int currentYear = DateTime.now().year;
  SeasonInfo seasons = SeasonInfo.seasons(currentYear);

  print('Seasons for $currentYear (UTC times):');
  print('  March Equinox:    ${seasons.marEquinox.date.toIso8601String(withColon: true)}');
  print('  June Solstice:    ${seasons.junSolstice.date.toIso8601String(withColon: true)}');
  print('  September Equinox: ${seasons.sepEquinox.date.toIso8601String(withColon: true)}');
  print('  December Solstice: ${seasons.decSolstice.date.toIso8601String(withColon: true)}');
}
```
(The underlying function `searchSunLongitude`, used by `SeasonInfo.seasons`, can also find when the Sun reaches arbitrary ecliptic longitudes.)

## Celestial Coordinate Systems

The library supports several standard astronomical coordinate systems:

-   **Equatorial J2000 (EQJ)**: Based on Earth's mean equator and equinox at epoch J2000.0. Uses Right Ascension (RA) and Declination (Dec).
-   **Equatorial of Date (EQD)**: Based on Earth's true equator and equinox at a specific date, accounting for precession and nutation.
-   **Ecliptic Coordinates**: Based on the Ecliptic (the plane of Earth's orbit). Uses ecliptic latitude and longitude.
-   **Horizontal Coordinates (Azimuth/Altitude)**: Local to an [`Observer`](../README.md#the-observer-class) on Earth. See details in [Observer-Dependent Calculations](../observer_related/README.md#apparent-horizontal-coordinates-azimuthaltitude).
-   **Galactic Coordinates**: Uses the plane of the Milky Way galaxy as its fundamental plane.

## Coordinate Transformations

The library provides functions to transform vectors and coordinates between these systems. These transformations often involve `AstroVector` (Cartesian x,y,z) and `RotationMatrix` objects.

-   **Equatorial (J2000 or of-date) to Horizontal**:
    -   `HorizontalCoordinates.horizon(...)`: Converts RA/Dec *of date* to Azimuth/Altitude. See [Observer-Related Calculations](../observer_related/README.md#apparent-horizontal-coordinates-azimuthaltitude).
    -   `bodyPosition(...)` utility: Provides J2000 RA/Dec and Horizontal Az/Alt. See [Observer-Related Calculations](../observer_related/README.md#apparent-horizontal-coordinates-azimuthaltitude).

-   **Equatorial J2000 to Equatorial of Date (and vice-versa)**:
    -   `gyration(List<double> posJ2000, AstroTime time, PrecessDirection.From2000)`: Converts a J2000 Cartesian vector `posJ2000` to equator-of-date.
    -   `gyration(List<double> posOfDate, AstroTime time, PrecessDirection.Into2000)`: Converts an equator-of-date Cartesian vector `posOfDate` to J2000.
    -   These internally use `RotationMatrix.rotationEQJtoEQD(time)` and `AstroVector.rotateVector(matrix, vector)`.

-   **Equatorial of Date to Ecliptic of Date**:
    -   `ecliptic(AstroVector equ)`: Converts an *equator-of-date* `AstroVector` to `EclipticCoordinates`.
    -   `EclipticCoordinates.rotateEquatorialToEcliptic(AstroVector equVecEQD, double cosObliquity, double sinObliquity)` uses the obliquity of the ecliptic for conversion.

-   **Galactic to Equatorial J2000 (and vice-versa)**:
    -   The library provides `RotationMatrix.rotationGALtoEQJ()` and `RotationMatrix.rotationEQJtoGAL()`. These matrices are then applied to vectors using `AstroVector.rotateVector()`.

-   **Vector to Spherical/Equatorial Angles (and vice-versa)**:
    -   `EquatorialCoordinates.fromVector(AstroVector vec)`: Converts a Cartesian vector to RA/Dec/distance.
    -   `AstroVector.vectorFromSphere(Spherical sphereAngles, AstroTime time)`: Converts spherical angles (lon, lat, dist) to a Cartesian vector.

**Example (J2000 Geocentric RA/Dec of Mars to Horizontal Az/Alt for London):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime time = AstroTime(DateTime.now().toUtc());
  Observer observer = Observer(51.5074, -0.1278, 35.0); // London

  // 1. Get Mars's J2000 geocentric Cartesian vector (details in [Celestial Body Calculations](../bodies/README.md#geocentric-coordinates))
  AstroVector marsGeoJ2000 = geoVector(Body.Mars, time, true);

  // 2. Convert J2000 vector to Equator-of-Date Cartesian vector
  List<double> marsEqdList = gyration(
    [marsGeoJ2000.x, marsGeoJ2000.y, marsGeoJ2000.z], 
    time, 
    PrecessDirection.From2000
  );
  AstroVector marsGeoEqdVec = AstroVector.fromArray(marsEqdList, time);
  
  // 3. Convert EQD vector to RA/Dec of Date (angular coordinates)
  EquatorialCoordinates marsEqdAng = EquatorialCoordinates.fromVector(marsGeoEqdVec);

  // 4. Convert RA/Dec of Date to Horizontal Az/Alt
  HorizontalCoordinates marsHorizontal = HorizontalCoordinates.horizon(
    time,
    observer,
    marsEqdAng.ra,    // RA for equator of date
    marsEqdAng.dec,   // Dec for equator of date
    RefractionType.normal 
  );

  print('Mars Az/Alt (London): Az=${marsHorizontal.azimuth.toStringAsFixed(2)}°, Alt=${marsHorizontal.altitude.toStringAsFixed(2)}°');
}
```

## Constellations

The library can determine which of the 88 modern IAU constellations a given point in the sky belongs to.

-   **`ConstellationInfo.constellation(double ra, double dec)`**:
    -   `ra` (double): Right Ascension in J2000 sidereal hours.
    -   `dec` (double): Declination in J2000 degrees.
    -   Returns: `ConstellationInfo` object.

### `ConstellationInfo` Object
-   `symbol` (String): The 3-letter IAU abbreviation (e.g., "Ori").
-   `name` (String): The full Latin name (e.g., "Orion").
-   `ra1875`, `dec1875` (double): Coordinates in the B1875 system (used for historical boundary definitions).

**Example (Find constellation for Betelgeuse):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  // Betelgeuse (approx. J2000 coordinates)
  double betelgeuseRA = 5.9195;    // hours
  double betelgeuseDec = 7.407;  // degrees

  ConstellationInfo betelgeuseConst = ConstellationInfo.constellation(betelgeuseRA, betelgeuseDec);
  print('Betelgeuse is in: ${betelgeuseConst.name} (${betelgeuseConst.symbol})');
  // Expected Output: Betelgeuse is in: Orion (Ori)
}
```

## Planetary Axis Orientation

Calculates the orientation of a celestial body's rotation axis (North Pole direction) and the rotation of its prime meridian.

-   **`AxisInfo.rotationAxis(Body body, dynamic date)`**:
    -   `body` (Body): Sun, Moon, or any planet.
    -   `date` (dynamic): The `AstroTime`, `DateTime` (UTC recommended), or numeric Julian date.
    -   Returns: `AxisInfo` object.

### `AxisInfo` Object
-   `ra` (double): J2000 Right Ascension of the body's North Pole (in sidereal hours).
-   `dec` (double): J2000 Declination of the body's North Pole (in degrees).
-   `spin` (double): Rotation angle of the body's prime meridian in degrees (W in IAU reports).
-   `north` (AstroVector): J2000 unit vector pointing towards the body's North Pole.

**Example (Mars's axis orientation):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime now = AstroTime(DateTime.now().toUtc());
  AxisInfo marsAxis = AxisInfo.rotationAxis(Body.Mars, now);

  print('Mars Axis Information (${now.date.toIso8601String(withColon: true)}):');
  print('  North Pole RA (J2000): ${marsAxis.ra.toStringAsFixed(4)} h');
  print('  North Pole Dec (J2000): ${marsAxis.dec.toStringAsFixed(4)}°');
  print('  Prime Meridian Spin Angle: ${marsAxis.spin.toStringAsFixed(2)}°');
}
```
