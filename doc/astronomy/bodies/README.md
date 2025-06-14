# Celestial Body Calculations

This section details how to calculate positions and other physical information for the Sun, Moon, and planets using the GeoEngine astronomy module. Calculations generally require a specific time, often provided as an [`AstroTime`](../time_coords/README.md#astronomical-time-astrotime) object, and for some, the `Body` enum to specify the celestial object.

For calculations that depend on the observer's specific location on Earth (e.g., apparent position influenced by parallax), an [`Observer`](../README.md#the-observer-class) object is required.

## General Position Vectors

The library provides functions to obtain Cartesian vectors (x, y, z) representing the positions of bodies. These are fundamental for many other calculations. For more details on coordinate systems, see the [Time, Coordinates, and Orientation](./../time_coords/README.md#celestial-coordinate-systems) documentation.

### Heliocentric Coordinates

Heliocentric coordinates are positions relative to the center of the Sun.

-   **`helioVector(Body body, dynamic date)`**: Calculates heliocentric Cartesian coordinates (J2000 equatorial system) of a body. The position is not corrected for light travel time or aberration.
    -   `body` (Body): The celestial body (e.g., `Body.Mars`, `Body.Venus`).
    -   `date` (dynamic): An `AstroTime` object, `DateTime` (preferably UTC), or numeric Julian Date.
    -   Returns: `AstroVector` (contains x, y, z in AU, and the `AstroTime` t).

-   **`helioState(Body body, dynamic date)`**: Calculates heliocentric position and velocity vectors (J2000 EQJ).
    -   Returns: `StateVector` (contains x,y,z in AU and vx,vy,vz in AU/day).

**Example (Heliocentric Vector & State):**
```dart
import 'package:geoengine/geoengine.dart'; // Main import for astronomy functions

void main() {
  AstroTime time = AstroTime(DateTime.now().toUtc()); // Use UTC for consistency

  // Heliocentric position vector of Venus
  AstroVector venusHelio = helioVector(Body.Venus, time);
  print('Venus heliocentric position: x=${venusHelio.x.toStringAsFixed(6)} AU, y=${venusHelio.y.toStringAsFixed(6)} AU, z=${venusHelio.z.toStringAsFixed(6)} AU');

  // Heliocentric position and velocity state vector of Mars
  StateVector marsHelioState = helioState(Body.Mars, time);
  print('Mars heliocentric position: x=${marsHelioState.x.toStringAsFixed(6)} AU');
  print('Mars heliocentric velocity: vx=${marsHelioState.vx.toStringAsFixed(8)} AU/day');
}
```

### Geocentric Coordinates

Geocentric coordinates are positions relative to the center of the Earth. These are crucial for determining how we see objects from Earth.

-   **`geoVector(Body body, dynamic date, bool aberration)`**: Calculates geocentric Cartesian coordinates (J2000 equatorial system). Corrected for light travel time.
    -   `body` (Body): The celestial body.
    -   `date` (dynamic): The time of observation.
    -   `aberration` (bool): `true` to correct for aberration of light.
    -   Returns: `AstroVector`.

**Example (Geocentric Vector):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime time = AstroTime(DateTime.now().toUtc());
  
  // Get geocentric vector of Mars, corrected for aberration
  AstroVector marsGeo = geoVector(Body.Mars, time, true);
  print('Mars geocentric position (aberration corrected): x=${marsGeo.x.toStringAsFixed(6)} AU, y=${marsGeo.y.toStringAsFixed(6)} AU, z=${marsGeo.z.toStringAsFixed(6)} AU');
}
```

### Converting Vectors to Angular Coordinates (RA/Dec)

The `AstroVector` objects obtained from `helioVector` or `geoVector` can be converted to spherical/equatorial coordinates (Right Ascension and Declination). See more on [Equatorial Coordinates here](../time_coords/README.md#celestial-coordinate-systems).

-   **`EquatorialCoordinates.fromVector(AstroVector vec)`**: Converts a J2000 equatorial vector to `EquatorialCoordinates`.
    -   `vec` (AstroVector): The input vector.
    -   Returns: `EquatorialCoordinates` (contains `ra` in hours, `dec` in degrees, `dist` in AU, and the original `vec`).

**Example (Geocentric RA/Dec):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime time = AstroTime(DateTime.now().toUtc());
  AstroVector marsGeoVec = geoVector(Body.Mars, time, true); // Corrected for light travel & aberration
  EquatorialCoordinates marsEquatorial = EquatorialCoordinates.fromVector(marsGeoVec);
  
  print('Mars Geocentric J2000 RA: ${marsEquatorial.ra.toStringAsFixed(4)} hours');
  print('Mars Geocentric J2000 Dec: ${marsEquatorial.dec.toStringAsFixed(4)} degrees');
  print('Mars Geocentric J2000 Dist: ${marsEquatorial.dist.toStringAsFixed(6)} AU');
}
```

### Topocentric Coordinates (Observer-Specific RA/Dec)

For positions as seen from a specific location on Earth's surface (topocentric), use the `equator` function. This function also accounts for parallax and can provide coordinates in J2000 or of-date systems. Requires an [`Observer`](../README.md#the-observer-class) object.

-   **`equator(Body body, dynamic date, Observer observer, bool ofdate, bool aberration)`**: Calculates topocentric equatorial coordinates.
    -   `body` (Body): The celestial body.
    -   `date` (dynamic): Time of observation.
    -   `observer` (Observer): The observer's location.
    -   `ofdate` (bool): `true` for coordinates of date (corrected for precession/nutation), `false` for J2000.
    -   `aberration` (bool): `true` to correct for aberration.
    -   Returns: `EquatorialCoordinates`.

**Example (Topocentric RA/Dec for Moon):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime time = AstroTime(DateTime.now().toUtc());
  Observer observer = Observer(51.5074, -0.1278, 35.0); // London

  // Get topocentric RA/Dec of the Moon, for the equator and equinox of date, with aberration correction
  EquatorialCoordinates moonTopoOfDate = equator(Body.Moon, time, observer, true, true);
  print('Moon Topocentric RA (of date): ${moonTopoOfDate.ra.toStringAsFixed(4)} hours');
  print('Moon Topocentric Dec (of date): ${moonTopoOfDate.dec.toStringAsFixed(4)} degrees');
  print('Moon Topocentric Dist (of date): ${moonTopoOfDate.dist.toStringAsFixed(6)} AU');

  // Get topocentric RA/Dec of the Moon, for J2000 equator and equinox
  EquatorialCoordinates moonTopoJ2000 = equator(Body.Moon, time, observer, false, true);
  print('\\nMoon Topocentric RA (J2000): ${moonTopoJ2000.ra.toStringAsFixed(4)} hours');
  print('Moon Topocentric Dec (J2000): ${moonTopoJ2000.dec.toStringAsFixed(4)} degrees');
}
```

## Apparent Visual Magnitude

The apparent visual magnitude of a celestial body is how bright it appears to an observer on Earth.

-   **`IlluminationInfo.getBodyIllumination(Body body, dynamic date)`**: This is the primary function to get illumination details, including magnitude.
    -   `body` (Body): The celestial body.
    -   `date` (dynamic): The time of observation using an `AstroTime` object or convertible type.
    -   Returns: `IlluminationInfo` object. The `mag` property holds the visual magnitude.

The `IlluminationInfo` object also contains:
-   `time` (AstroTime): The time of observation.
-   `phaseAngle` (double): Angle in degrees (0-180) between Sun and Earth as seen from the body.
-   `phaseFraction` (double): Fraction of the body's face illuminated (0-1).
-   `helioDist` (double): Heliocentric distance in AU.
-   `geoDist` (double): Geocentric distance in AU.
-   `gc` (AstroVector): Geocentric J2000 coordinate vector.
-   `hc` (AstroVector): Heliocentric J2000 coordinate vector.
-   `ringTilt` (double?): For Saturn, the angular tilt of the planet's rings in degrees (viewed from Earth).

**Example (Visual Magnitude of Venus and Mars):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime time = AstroTime(DateTime.now().toUtc());

  IlluminationInfo venusIllum = IlluminationInfo.getBodyIllumination(Body.Venus, time);
  print('Venus: Magnitude=${venusIllum.mag.toStringAsFixed(2)}, Phase Angle=${venusIllum.phaseAngle.toStringAsFixed(1)}°, Illuminated=${(venusIllum.phaseFraction * 100).toStringAsFixed(1)}%');

  IlluminationInfo marsIllum = IlluminationInfo.getBodyIllumination(Body.Mars, time);
  print('Mars: Magnitude=${marsIllum.mag.toStringAsFixed(2)}, Phase Angle=${marsIllum.phaseAngle.toStringAsFixed(1)}°');
  
  IlluminationInfo moonIllum = IlluminationInfo.getBodyIllumination(Body.Moon, time);
  print('Moon: Magnitude=${moonIllum.mag.toStringAsFixed(2)}, Illuminated=${(moonIllum.phaseFraction * 100).toStringAsFixed(1)}%');
}
```

## Other Body-Specific Information

-   **`massProduct(Body body)`**: Returns the product GM (Gravitational constant * Mass) in au^3/day^2 for the specified `body`.
    ```dart
    import 'package:geoengine/geoengine.dart';
    // ...
    double earthGM = massProduct(Body.Earth);
    print('Earth GM: $earthGM au^3/day^2');
    ```

-   **`defineStar(Body body, double ra, double dec, double distanceLightYears)`**: Allows defining coordinates for user-defined stars (`Body.Star1` through `Body.Star8`) for use in other calculations.
    ```dart
    import 'package:geoengine/geoengine.dart';
    // ...
    // Define a custom star (e.g., Sirius)
    defineStar(Body.Star1, 6.7525, -16.7161, 8.6); // RA in hours, Dec in degrees, Distance in light-years
    AstroVector starVec = geoVector(Body.Star1, AstroTime(DateTime.now().toUtc()), true);
    print('Custom Star1 Geocentric Vector: x=${starVec.x}');
    ```

-   **`eclipticLongitude(Body body, dynamic date)`**: Calculates heliocentric [ecliptic longitude](../time_coords/README.md#celestial-coordinate-systems) of a `body` (cannot be `Body.Sun`).
    ```dart
    import 'package:geoengine/geoengine.dart';
    // ...
    double marsHelioLon = eclipticLongitude(Body.Mars, AstroTime(DateTime.now().toUtc()));
    print('Mars Heliocentric Ecliptic Longitude: ${marsHelioLon.toStringAsFixed(3)}°');
    ```

-   **`angleFromSun(Body body, dynamic date)`**: Calculates the angular separation (elongation) in degrees between the Sun and a `body`, as seen from Earth. See also [Astronomical Events](./../events/README.md#maximum-elongations-mercury--venus).
    ```dart
    import 'package:geoengine/geoengine.dart';
    // ...
    double venusElongation = angleFromSun(Body.Venus, AstroTime(DateTime.now().toUtc()));
    print('Venus elongation from Sun: ${venusElongation.toStringAsFixed(2)}°');
    ```

Refer to the specific documentation sections for [Moon](./../moon_specific/README.md), [Eclipses](./../eclipses/README.md), and general [Astronomical Events](./../events/README.md) for more specialized calculations.
The [Observer-Related Phenomena section](./../observer_related/README.md) provides more detail on topocentric calculations like rise/set times and horizontal coordinates.
For details on `AstroTime` and coordinate systems, see [Time, Coordinates, and Orientation](./../time_coords/README.md).
