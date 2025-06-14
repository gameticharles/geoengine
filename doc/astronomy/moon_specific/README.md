# Moon-Specific Calculations and Events

This section focuses on calculations and event predictions that are specific to Earth's [Moon](../bodies/README.md#moon). All time parameters and returns are typically handled using [`AstroTime`](../time_coords/README.md#astronomical-time-astrotime) objects.

## Moon Phases

The phase of the Moon depends on the relative positions of the Sun, Earth, and Moon. Conventional phases are New Moon, First Quarter, Full Moon, and Third Quarter, defined by the difference in geocentric [ecliptic longitude](../time_coords/README.md#celestial-coordinate-systems) between the Moon and the Sun.

-   **`moonPhase(dynamic date)`**: Calculates the Moon's ecliptic phase angle for a given `date`.
    -   `date` (dynamic): An `AstroTime` object, `DateTime` (preferably UTC), or numeric Julian Date.
    -   Returns: `double` - The phase angle in degrees [0, 360).
        -   0° ≈ New Moon
        -   90° ≈ First Quarter
        -   180° ≈ Full Moon
        -   270° ≈ Third Quarter

-   **`searchMoonPhase(double targetLon, dynamic dateStart, double limitDays)`**: Searches for the date and time the Moon reaches a specific `targetLon` phase angle.
    -   `targetLon` (double): The desired ecliptic longitude difference (0-360). E.g., 0 for New Moon, 180 for Full Moon.
    -   `dateStart` (dynamic): Time to start searching from.
    -   `limitDays` (double): Number of days to search forward (if positive) or backward (if negative).
    -   Returns: `AstroTime?` - The time of the event, or null if not found.

-   **`MoonQuarter.searchMoonQuarter(dynamic dateStart)`**: Finds the first primary quarter lunar phase (New, Q1, Full, or Q3) that occurs after `dateStart`.
    -   Returns: `MoonQuarter` object.

-   **`MoonQuarter.nextMoonQuarter(MoonQuarter prevMoonQuarter)`**: Finds the next quarter phase after a previously found `MoonQuarter`.
    -   Returns: `MoonQuarter` object.

### `MoonQuarter` Object
-   `quarterIndex` (int): Integer representing the phase (0: New, 1: First Quarter, 2: Full Moon, 3: Third Quarter).
-   `time` (AstroTime): The date and time of this quarter phase.
-   `get quarter` (String): Name of the quarter (e.g., "New Moon").

**Example (Calculating current phase and next few quarter phases):**
```dart
import 'package:geoengine/geoengine.dart'; // Provides AstroTime, moonPhase, MoonQuarter, IlluminationInfo, Body etc.

void main() {
  AstroTime currentTime = AstroTime(DateTime.now().toUtc());
  
  double currentPhaseAngle = moonPhase(currentTime);
  print('Current Moon phase angle: ${currentPhaseAngle.toStringAsFixed(2)}°');

  // For illuminated fraction and magnitude, use IlluminationInfo
  IlluminationInfo moonIllum = IlluminationInfo.getBodyIllumination(Body.Moon, currentTime);
  print('Current Moon illuminated fraction: ${(moonIllum.phaseFraction * 100).toStringAsFixed(1)}%');
  print('Current Moon magnitude: ${moonIllum.mag.toStringAsFixed(2)}');
  
  print('\\nSearching for next few quarter Moon phases:');
  MoonQuarter? mq = MoonQuarter.searchMoonQuarter(currentTime); // Find the current or next quarter
  for (int i = 0; i < 8; ++i) { // Iterate to find the next 8 quarters
    if (mq == null) {
      print("Could not determine next moon quarter.");
      break;
    }
    print('${mq.time.date.toIso8601String(withColon: true)} : ${mq.quarter}');
    mq = MoonQuarter.nextMoonQuarter(mq); // Get the *next* one
  }
}
```

## Lunar Perigee and Apogee (Apsides)

These are the points in the Moon's orbit where it is closest to Earth (perigee) or farthest from Earth (apogee). The general concept of an apsis is also covered in [Planetary Apsides](../events/README.md#planetary-apsides-perihelionaphelion).

-   **`Moon(dynamic date).searchLunarApsis([dynamic startDate])`**: Finds the next perigee or apogee of the Moon.
    -   The `Moon` object is initialized with a date, e.g., `Moon(AstroTime(DateTime.now().toUtc()))`.
    -   `startDate` (dynamic, optional): The date and time to start searching from. If null, uses the `Moon` object's initialization date.
    -   Returns: `Apsis` object.

-   **`Moon(dynamic date).nextLunarApsis([Apsis? prevApsis])`**: Finds the next lunar apsis event after `prevApsis`. If `prevApsis` is null, it first calls `searchLunarApsis`.
    -   Returns: `Apsis` object.

### `Apsis` Object
-   `time` (AstroTime): Date and time of the apsis.
-   `kind` (ApsisKind): `ApsisKind.Pericenter` (for perigee) or `ApsisKind.Apocenter` (for apogee).
-   `distAU` (double): Distance between Earth and Moon in Astronomical Units (AU).
-   `distKM` (double): Distance in kilometers.

**Example (Finding next lunar perigee and apogee):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime startTime = AstroTime(DateTime.now().toUtc());
  Moon moonInstance = Moon(startTime); // Create a Moon instance based on current time

  print("Searching for Moon's next apsis...");
  Apsis? nextApsis = moonInstance.searchLunarApsis(); 
  
  if (nextApsis != null) {
    String eventType = nextApsis.kind == ApsisKind.Pericenter ? "Perigee" : "Apogee";
    print('Next lunar ${eventType.toLowerCase()}:');
    print('  Time: ${nextApsis.time.date.toIso8601String(withColon: true)}');
    print('  Distance: ${nextApsis.distKM.toStringAsFixed(0)} km');

    Apsis? followingApsis = moonInstance.nextLunarApsis(nextApsis);
    if (followingApsis != null) {
      String nextEventType = followingApsis.kind == ApsisKind.Pericenter ? "Perigee" : "Apogee";
      print('Following lunar ${nextEventType.toLowerCase()}:');
      print('  Time: ${followingApsis.time.date.toIso8601String(withColon: true)}');
      print('  Distance: ${followingApsis.distKM.toStringAsFixed(0)} km');
    }
  } else {
    print("Could not find Moon's next apsis.");
  }
}
```

## Lunar Libration

Libration is the apparent "wobble" of the Moon as seen from Earth. This phenomenon allows us to see slightly more than 50% of the Moon's surface over time. It has components in both ecliptic latitude and longitude.

-   **`Libration(dynamic date)`**: Calculates the Moon's libration angles and related positional data for the given `date`.
    -   `date` (dynamic): An `AstroTime` object, `DateTime` (UTC recommended), or numeric Julian Date for the time of observation.
    -   Returns: `LibrationInfo` object.

### `LibrationInfo` Object
-   `eLat` (double): Sub-Earth libration ecliptic latitude angle, in degrees. This is the Moon's libration in latitude.
-   `eLon` (double): Sub-Earth libration ecliptic longitude angle, in degrees. This is the Moon's libration in longitude.
-   `mLat` (double): Moon's geocentric [ecliptic latitude](../time_coords/README.md#celestial-coordinate-systems), in degrees.
-   `mLon` (double): Moon's geocentric [ecliptic longitude](../time_coords/README.md#celestial-coordinate-systems), in degrees.
-   `dist_km` (double): Distance between the centers of the Earth and Moon in kilometers.
-   `diam_deg` (double): Apparent angular diameter of the Moon in degrees, as seen from Earth's center.

**Example (Calculating current lunar libration):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime currentTime = AstroTime(DateTime.now().toUtc());
  LibrationInfo libration = Libration(currentTime); // Calculate libration for the current time

  print('Lunar Libration at ${currentTime.date.toIso8601String(withColon: true)}:');
  print('  Libration in Ecliptic Latitude (eLat): ${libration.eLat.toStringAsFixed(2)}°');
  print('  Libration in Ecliptic Longitude (eLon): ${libration.eLon.toStringAsFixed(2)}°');
  print('  Moon Geocentric Ecliptic Latitude (mLat): ${libration.mLat.toStringAsFixed(2)}°');
  print('  Moon Geocentric Ecliptic Longitude (mLon): ${libration.mLon.toStringAsFixed(2)}°');
  print('  Distance to Moon: ${libration.dist_km.toStringAsFixed(0)} km');
  print('  Moon Apparent Diameter: ${libration.diam_deg.toStringAsFixed(3)}°');
}
```
