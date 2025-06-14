# Astronomical Event Prediction

The GeoEngine astronomy module allows for the prediction of various astronomical events involving planets. These events are typically found by searching for specific geometric alignments or conditions. All time inputs are expected as [`AstroTime`](../time_coords/README.md#astronomical-time-astrotime) objects (or types convertible to `AstroTime` like `DateTime`). Celestial bodies are specified using the `Body` enum, documented further in the [Celestial Body Calculations](./../bodies/README.md) section.

## Planetary Conjunctions and Oppositions

These events describe the alignment of a planet relative to the Earth and Sun.

-   **Conjunction**: A planet generally appears close to the Sun in the sky.
    -   *Inferior Conjunction*: An inferior planet (Mercury or Venus) passes between Earth and the Sun.
    -   *Superior Conjunction*: Any planet passes on the far side of the Sun as seen from Earth.
-   **Opposition**: A superior planet (Mars, Jupiter, etc.) is on the opposite side of Earth from the Sun (Sun-Earth-Planet alignment). This is often the best time to observe a superior planet as it's closest to Earth and fully illuminated.

**Key Function:** `searchRelativeLongitude(Body body, double targetRelLon, dynamic startDate)`
-   **Purpose**: Searches for the date and time when the *heliocentric* [ecliptic longitude](../time_coords/README.md#celestial-coordinate-systems) of `body` differs from Earth's heliocentric ecliptic longitude by `targetRelLon`.
-   `body` (Body): The planet (e.g., `Body.Mars`, `Body.Venus`). Cannot be `Body.Earth`.
-   `targetRelLon` (double): The desired heliocentric longitude difference in degrees. The interpretation is based on `direction * (elon_earth - plon_planet)` where `direction` depends on whether the planet is inferior or superior to Earth.
    -   **Opposition** (e.g., Mars, a superior planet): `targetRelLon = 180.0`. (Earth is between Sun and Mars).
    -   **Inferior Conjunction** (e.g., Venus, an inferior planet): `targetRelLon = 0.0`. (Venus is between Sun and Earth).
    -   **Superior Conjunction** (e.g., Venus): `targetRelLon = 180.0`. (Venus is on the far side of the Sun from Earth).
    -   **Superior Conjunction** (e.g., Mars): `targetRelLon = 0.0`. (Mars is on the far side of the Sun from Earth).
-   `startDate` (dynamic): The `AstroTime`, `DateTime` (UTC recommended), or numeric Julian date from which to start the search.
-   Returns: `AstroTime` object representing the time of the event.

**Example (Finding next Mars Opposition and Venus Conjunctions):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime startTime = AstroTime(DateTime.now().toUtc());

  // Mars Opposition: Earth is between Sun and Mars.
  // Heliocentric longitude of Mars and Earth differ by 180 degrees.
  AstroTime? marsOpposition = searchRelativeLongitude(Body.Mars, 180.0, startTime);
  if (marsOpposition != null) {
    print('Next Mars opposition around: ${marsOpposition.date.toIso8601String(withColon: true)}');
  } else {
    print('Mars opposition search failed or not found in reasonable time.');
  }

  // Venus Inferior Conjunction: Venus is between Sun and Earth.
  // Heliocentric longitudes of Venus and Earth are approximately the same.
  AstroTime? venusInferiorConj = searchRelativeLongitude(Body.Venus, 0.0, startTime);
   if (venusInferiorConj != null) {
    print('Next Venus inferior conjunction around: ${venusInferiorConj.date.toIso8601String(withColon: true)}');
  } else {
    print('Venus inferior conjunction search failed.');
  }
  
  // Venus Superior Conjunction: Venus is behind the Sun from Earth.
  // Heliocentric longitudes of Venus and Earth differ by 180 degrees.
  AstroTime? venusSuperiorConj = searchRelativeLongitude(Body.Venus, 180.0, startTime);
  if (venusSuperiorConj != null) {
    print('Next Venus superior conjunction around: ${venusSuperiorConj.date.toIso8601String(withColon: true)}');
  } else {
    print('Venus superior conjunction search failed.');
  }
}
```

## Planetary Apsides (Perihelion/Aphelion)

An apsis is the point in a planet's orbit where it is closest to (perihelion) or farthest from (aphelion) the Sun. This does not apply to the Moon's orbit around Earth (see [Lunar Perigee and Apogee](../moon_specific/README.md#lunar-perigee-and-apogee-apsides)).

**Key Functions:**
-   `Apsis.searchPlanetApsis(Body body, dynamic startTime)`: Finds the next perihelion or aphelion for the given `body` (planet) occurring after `startTime`.
    -   Returns: `Apsis` object.
-   `Apsis.nextPlanetApsis(Body body, Apsis prevApsis)`: Finds the subsequent apsis event (if `prevApsis` was perihelion, it finds aphelion, and vice-versa).
    -   Returns: `Apsis` object.

### `Apsis` Object
-   `time` (AstroTime): Date and time of the apsis.
-   `kind` (ApsisKind): `ApsisKind.Pericenter` (for perihelion) or `ApsisKind.Apocenter` (for aphelion).
-   `distAU` (double): Planet-Sun distance in Astronomical Units (AU).
-   `distKM` (double): Planet-Sun distance in kilometers.

**Example (Finding Mars's next apsides):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime startTime = AstroTime(DateTime.now().toUtc());
  
  print("Searching for Mars's next apsis...");
  Apsis? nextMarsApsis = Apsis.searchPlanetApsis(Body.Mars, startTime);

  if (nextMarsApsis != null) {
    String eventType = nextMarsApsis.kind == ApsisKind.Pericenter ? "Perihelion" : "Aphelion";
    print('Mars next ${eventType.toLowerCase()}:');
    print('  Time: ${nextMarsApsis.time.date.toIso8601String(withColon: true)}');
    print('  Distance: ${nextMarsApsis.distAU.toStringAsFixed(4)} AU (${nextMarsApsis.distKM.toStringAsFixed(0)} km)');

    Apsis? followingMarsApsis = Apsis.nextPlanetApsis(Body.Mars, nextMarsApsis);
     if (followingMarsApsis != null) {
        String nextEventType = followingMarsApsis.kind == ApsisKind.Pericenter ? "Perihelion" : "Aphelion";
        print('Mars following ${nextEventType.toLowerCase()}:');
        print('  Time: ${followingMarsApsis.time.date.toIso8601String(withColon: true)}');
        print('  Distance: ${followingMarsApsis.distAU.toStringAsFixed(4)} AU (${followingMarsApsis.distKM.toStringAsFixed(0)} km)');
     }
  } else {
    print("Could not find Mars's next apsis in the search window.");
  }
}
```

## Transits of Mercury and Venus

A transit occurs when Mercury or Venus passes directly between the Sun and Earth, appearing as a small black dot crossing the Sun's disk.

**Key Functions:**
-   `TransitInfo.searchTransit(Body body, dynamic startTime)`: Searches for the first transit of `body` (must be `Body.Mercury` or `Body.Venus`) after `startTime`.
    -   Returns: `TransitInfo?` (can be null if no transit is found within a reasonable search window).
-   `TransitInfo.nextTransit(Body body, dynamic prevTransitTime)`: Searches for the next transit after a previous one. `prevTransitTime` is typically the `finish` time of the previous `TransitInfo` object.
    -   Returns: `TransitInfo?`.

### `TransitInfo` Object
-   `start` (AstroTime): Time when the transit begins (first contact).
-   `peak` (AstroTime): Time of the midpoint of the transit (greatest transit).
-   `finish` (AstroTime): Time when the transit ends (last contact).
-   `separation` (double): Minimum angular separation in arcminutes between the center of the planet and the center of the Sun, as seen from Earth's center.

**Example (Finding next transit of Mercury):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime startTime = AstroTime(DateTime.now().toUtc()); 
  
  print("Searching for next Mercury transit...");
  try {
    TransitInfo? mercuryTransit = TransitInfo.searchTransit(Body.Mercury, startTime);
    if (mercuryTransit != null) {
      print('Next Mercury Transit:');
      print('  Start: ${mercuryTransit.start.date.toIso8601String(withColon: true)}');
      print('  Peak:  ${mercuryTransit.peak.date.toIso8601String(withColon: true)}');
      print('  Finish: ${mercuryTransit.finish.date.toIso8601String(withColon: true)}');
      print('  Min Separation: ${mercuryTransit.separation.toStringAsFixed(2)} arcmin');
    } else {
      print('No Mercury transit found in the near future.');
    }
  } catch (e) {
    print('Error finding Mercury transit: $e');
  }

  // Note: Venus transits are very rare. The next pair is in December 2117 and December 2125.
  // To search for these, adjust startTime accordingly:
  // AstroTime venusSearchStart = AstroTime(DateTime.utc(2100, 1, 1));
  // try {
  //   TransitInfo? venusTransit = TransitInfo.searchTransit(Body.Venus, venusSearchStart);
  //   if (venusTransit != null) {
  //     print('\\nNext Venus Transit (post-2100):');
  //     print('  Start: ${venusTransit.start.date.toIso8601String(withColon: true)}');
  //   }
  // } catch (e) {
  //   print('Error finding Venus transit: $e');
  // }
}
```

## Maximum Elongations (Mercury & Venus)

Maximum elongation is when an inferior planet (Mercury or Venus) has its greatest angular separation from the Sun as viewed from Earth. This is generally the best time to observe these planets. The angular separation is detailed in [Celestial Body Calculations](../bodies/README.md#other-body-specific-information) via `angleFromSun`.
-   **Eastern Elongation**: Planet visible in the evening sky (after sunset).
-   **Western Elongation**: Planet visible in the morning sky (before sunrise).

**Key Function:**
-   `ElongationEvent.searchMaxElongation(Body body, dynamic startDate)`: Finds the next maximum elongation event for `body` (must be `Body.Mercury` or `Body.Venus`) after `startDate`.
    -   Returns: `ElongationEvent?` (can be null if search fails).

### `ElongationEvent` Object
-   `time` (AstroTime): Date and time of maximum elongation.
-   `visibility` (String): `"morning"` (western elongation) or `"evening"` (eastern elongation).
-   `elongation` (double): The maximum angular separation (degrees) between the planet and Sun.
-   `eclipticSeparation` (double): Absolute difference in ecliptic longitudes of the planet and Sun, as seen from Earth (degrees).

**Example (Finding next maximum elongation for Mercury):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime startTime = AstroTime(DateTime.now().toUtc());
  
  print("Searching for Mercury's next maximum elongation...");
  try {
    ElongationEvent? mercuryElong = ElongationEvent.searchMaxElongation(Body.Mercury, startTime);
    if (mercuryElong != null) {
      print('Next Mercury Maximum Elongation:');
      print('  Time: ${mercuryElong.time.date.toIso8601String(withColon: true)}');
      print('  Visibility: ${mercuryElong.visibility}');
      print('  Elongation: ${mercuryElong.elongation.toStringAsFixed(1)}°');
      print('  Ecliptic Separation: ${mercuryElong.eclipticSeparation.toStringAsFixed(1)}°');
    } else {
      print('Mercury maximum elongation search failed.');
    }
  } catch (e) {
    print('Error finding Mercury elongation: $e');
  }
}
```
