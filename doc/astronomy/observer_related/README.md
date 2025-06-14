# Observer-Dependent Calculations

Many astronomical phenomena are observed from a specific point on Earth. These calculations require an [`Observer`](../README.md#the-observer-class) object, which specifies the latitude, longitude, and elevation of the observer.

All times returned by search functions in this section are [`AstroTime`](../time_coords/README.md#astronomical-time-astrotime) objects. For display, you can convert the `AstroTime.date` (which is UTC) to local time using `.toLocal()`. Celestial bodies are specified using the `Body` enum, documented further in the [Celestial Body Calculations](../bodies/README.md) section.

## Rise, Set, and Culmination Times

These functions determine when a celestial body crosses the horizon or reaches its highest/lowest point in the sky for a given observer.

### Rise and Set Times

-   **`searchRiseSet(Body body, Observer observer, double direction, dynamic dateStart, double limitDays, {double metersAboveGround = 0.0})`**:
    -   **Purpose**: Finds the next rise or set time of a celestial body.
        -   Rise time (`direction = +1.0`): When the top of the body first appears above the horizon.
        -   Set time (`direction = -1.0`): When the top of the body completely disappears below the horizon.
        -   Accounts for the body's apparent angular radius and standard atmospheric refraction.
    -   **Parameters**:
        -   `body` (Body): The celestial body (e.g., `Body.Sun`, `Body.Moon`).
        -   `observer` (Observer): The observer's location.
        -   `direction` (double): `+1.0` for rise, `-1.0` for set.
        -   `dateStart` (dynamic): The `AstroTime` or `DateTime` (UTC recommended) to start the search.
        -   `limitDays` (double): Days forward (positive) or backward (negative) to search.
        -   `metersAboveGround` (double, optional): Observer's height above local ground. Defaults to `0.0`.
    -   **Returns**: `AstroTime?` - The time of the event, or `null` if not found.

**Example (Sunrise and Moonset for a given location):**
```dart
import 'package:geoengine/geoengine.dart'; // Provides AstroTime, Observer, Body, searchRiseSet

void main() {
  Observer londonObserver = Observer(51.5074, -0.1278, 35.0); // London, UK
  AstroTime searchPoint = AstroTime(DateTime.now().toUtc());

  AstroTime? sunrise = searchRiseSet(Body.Sun, londonObserver, 1.0, searchPoint, 1);
  if (sunrise != null) {
    print('Next sunrise in London: ${sunrise.date.toLocal().toIso8601String(withColon: true)}');
  } else {
    print('Sunrise not found for the next day in London.');
  }

  AstroTime? moonset = searchRiseSet(Body.Moon, londonObserver, -1.0, searchPoint, 1);
  if (moonset != null) {
    print('Next moonset in London: ${moonset.date.toLocal().toIso8601String(withColon: true)}');
  } else {
    print('Moonset not found for the next day in London.');
  }
}
```

### Culmination and Meridian Passage (Hour Angle)

Culmination is when a celestial body crosses the observer's meridian.
-   **Upper Culmination**: Highest point in the sky (Hour Angle = 0).
-   **Lower Culmination**: Lowest point/nadir passage (Hour Angle = 12).

-   **`searchHourAngle(Body body, Observer observer, double hourAngle, dynamic dateStart, {double direction = 1})`**:
    -   **Purpose**: Searches for the time a body reaches a specified `hourAngle`.
    -   **Parameters**:
        -   `hourAngle` (double): Target hour angle in sidereal hours [0, 24).
        -   Other parameters similar to `searchRiseSet`.
    -   **Returns**: `HourAngleEvent` (contains `time` (AstroTime) and `horizontal` ([`HorizontalCoordinates`](../time_coords/README.md#celestial-coordinate-systems)) of the body).

**Example (Sun's Culmination for a given location):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  Observer observer = Observer(51.5074, -0.1278, 35.0); // London
  AstroTime searchStart = AstroTime(DateTime.now().toUtc());

  HourAngleEvent culmination = searchHourAngle(Body.Sun, observer, 0, searchStart); // hourAngle = 0 for upper culmination
  print('Sun culmination (highest point) in London:');
  print('  Time: ${culmination.time.date.toLocal().toIso8601String(withColon: true)}');
  print('  Altitude: ${culmination.horizontal.altitude.toStringAsFixed(2)}°');
  print('  Azimuth: ${culmination.horizontal.azimuth.toStringAsFixed(2)}°');
}
```

## Apparent Horizontal Coordinates (Azimuth/Altitude)

Determines a body's apparent position relative to the observer's local horizon. See [Horizontal Coordinates](../time_coords/README.md#celestial-coordinate-systems) for more system details.

-   **`HorizontalCoordinates.horizon(dynamic date, Observer observer, double raOfDate, double decOfDate, [RefractionType refraction = RefractionType.airless])`**:
    -   **Purpose**: Converts equatorial coordinates of date (RA & Dec) to horizontal coordinates (Azimuth & Altitude).
    -   **Parameters**:
        -   `raOfDate`, `decOfDate`: Must be for the equator and equinox of the observation `date`.
        -   `refraction` (RefractionType, optional): Refraction correction type.
    -   **Returns**: `HorizontalCoordinates` object.

-   **`bodyPosition(Body body, dynamic date, Observer observer)`**:
    -   **Purpose**: Utility returning J2000 RA/Dec and horizontal Az/Alt (with `RefractionType.normal`).
    -   **Returns**: Record `({double ra, double dec, double azimuth, double altitude})`.

### `HorizontalCoordinates` Object
-   `azimuth` (double): Compass direction in degrees (0°=N, 90°=E, 180°=S, 270°=W).
-   `altitude` (double): Angle in degrees above (+) or below (-) the horizon.
-   `ra`, `dec` (double): Input RA/Dec, potentially adjusted by refraction.

**Example (Current Azimuth/Altitude of Mars):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  Observer myLocation = Observer(34.0522, -118.2437, 70.0); // Los Angeles
  AstroTime now = AstroTime(DateTime.now().toUtc());

  // Using bodyPosition utility:
  var marsPos = bodyPosition(Body.Mars, now, myLocation);
  print('Mars current position (Los Angeles - via bodyPosition):');
  print('  Azimuth: ${marsPos.azimuth.toStringAsFixed(2)}°');
  print('  Altitude: ${marsPos.altitude.toStringAsFixed(2)}°');

  // Manual conversion for more control:
  // 1. Get Equatorial coordinates of date using the 'equator' function (see [Celestial Body Calculations](../bodies/README.md#topocentric-coordinates-observer-specific-radec)).
  EquatorialCoordinates marsEquatorialOfDate = equator(Body.Mars, now, myLocation, true, true);
  // 2. Convert to Horizontal
  HorizontalCoordinates marsHorizontalCustom = HorizontalCoordinates.horizon(
    now, myLocation, marsEquatorialOfDate.ra, marsEquatorialOfDate.dec, RefractionType.normal
  );
  print('\\nMars Horizontal (custom calculation): Az: ${marsHorizontalCustom.azimuth.toStringAsFixed(2)}°, Alt: ${marsHorizontalCustom.altitude.toStringAsFixed(2)}°');
}
```

## Twilight Times

Twilight is when the Sun is below the horizon but its light still illuminates the sky.

-   **`searchAltitude(Body body, Observer observer, double direction, dynamic dateStart, double limitDays, double altitude)`**:
    -   **Purpose**: Used for twilight by finding when the Sun's center reaches specific altitudes below the horizon. Refraction is conventionally not applied.
    -   **Parameters for Twilight**:
        -   `body`: Must be `Body.Sun`.
        -   `direction`: `+1.0` for dawn (Sun ascending), `-1.0` for dusk (Sun descending).
        -   `altitude` (double):
            -   **Civil Twilight**: -6°.
            -   **Nautical Twilight**: -12°.
            -   **Astronomical Twilight**: -18°.
    -   **Returns**: `AstroTime?`.

**Example (Calculating today's Civil, Nautical, and Astronomical Dusk):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  Observer newYork = Observer(40.7128, -74.0060, 10.0); // New York City
  AstroTime today = AstroTime(DateTime.now().toUtc());

  AstroTime? civilDusk = searchAltitude(Body.Sun, newYork, -1.0, today, 1, -6.0);
  AstroTime? nauticalDusk = searchAltitude(Body.Sun, newYork, -1.0, today, 1, -12.0);
  AstroTime? astronomicalDusk = searchAltitude(Body.Sun, newYork, -1.0, today, 1, -18.0);

  if (civilDusk != null) {
    print('Civil Dusk in New York (Sun at -6°): ${civilDusk.date.toLocal().toIso8601String(withColon: true)}');
  }
  if (nauticalDusk != null) {
    print('Nautical Dusk in New York (Sun at -12°): ${nauticalDusk.date.toLocal().toIso8601String(withColon: true)}');
  }
  if (astronomicalDusk != null) {
    print('Astronomical Dusk in New York (Sun at -18°): ${astronomicalDusk.date.toLocal().toIso8601String(withColon: true)}');
  }
}
```
