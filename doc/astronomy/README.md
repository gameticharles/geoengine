# GeoEngine Astronomy Module

The Astronomy module within GeoEngine is a comprehensive Dart library for a wide array of astronomical calculations. It enables users to determine the positions of celestial bodies, predict significant astronomical events, and perform various coordinate transformations. This library is a port of the highly-regarded [Astronomy Engine](https://github.com/cosinekitty/astronomy) by Don Cross, which is based on the authoritative VSOP87 and NOVAS C 3.1 models, ensuring accuracy to within approximately &plusmn;1 arcminute for many calculations.

## Overview of Capabilities

The library provides functionalities for:
- **Celestial Bodies:** Sun, Moon, Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune, and Pluto.
- **Time Frame:** Calculations can be performed for any calendar date and time, spanning millennia into the past or future.
- **Accuracy:** Rigorously unit-tested against NOVAS, JPL Horizons, and other reliable ephemeris data sources.

This documentation is structured into several key areas to help you navigate the module's features:

## Detailed Documentation Sections

-   **[Core Astronomical Concepts & Observer Class](#core-astronomical-concepts)**: Fundamental concepts and the essential `Observer` class. (Described below)
-   **[Celestial Body Information](./bodies/README.md)**: General information and specific data related to the Sun, Moon, and planets.
-   **[Eclipse Calculations](./eclipses/README.md)**: Predicting solar and lunar eclipses, both globally and for specific observer locations.
-   **[Astronomical Events](./events/README.md)**: Finding events like conjunctions, oppositions, apsides (perihelion/aphelion), transits of inner planets, and maximum elongations.
-   **[Moon-Specific Calculations](./moon_specific/README.md)**: Detailed calculations for moon phases, perigee/apogee, and lunar libration.
-   **[Observer-Related Phenomena](./observer_related/README.md)**: Calculations dependent on an observer's location, such as rise/set times, culmination, apparent horizon coordinates, and twilight times.
-   **[Time, Coordinates, and Orientation](./time_coords/README.md)**: Handling astronomical time (including Julian Dates), understanding equinoxes/solstices, working with various celestial coordinate systems and transformations, identifying constellations, and determining axis orientations of celestial bodies.

---

## Core Astronomical Concepts

A few fundamental concepts are helpful for understanding astronomical calculations:

-   **Celestial Sphere:** An imaginary sphere of arbitrarily large radius, concentric with the Earth, onto which all celestial objects are considered to be projected.
-   **Coordinate Systems:**
    -   **Equatorial System:** Uses Declination (latitude-like) and Right Ascension (longitude-like) based on the projection of Earth's equator and vernal equinox onto the celestial sphere. It's the most common system for cataloging celestial objects.
    -   **Ecliptic System:** Uses Ecliptic Latitude and Ecliptic Longitude, based on the Ecliptic (the plane of Earth's orbit around the Sun). Useful for solar system objects.
    -   **Horizontal System (Altitude-Azimuth):** Uses Altitude (angle above the horizon) and Azimuth (compass direction) based on the observer's local horizon. This is what you directly observe in the sky.
    *(More details can be found in the [Time, Coordinates, and Orientation](./time_coords/README.md#celestial-coordinate-systems) section).*
-   **Astronomical Unit (AU):** A unit of length, roughly the distance from Earth to the Sun. It is approximately 149.6 million kilometers. The library provides `KM_PER_AU`.
-   **Light-Time Correction:** The library accounts for the finite speed of light. The positions of celestial bodies are often calculated for the instant light left them to reach the observer (apparent position), not their instantaneous geometric position.
-   **Julian Date (JD):** A continuous count of days since noon Universal Time on January 1, 4713 BCE. Extensively used in astronomy to simplify time calculations. The `AstroTime` class (see [Time, Coordinates, and Orientation](./time_coords/README.md#astronomical-time-astrotime)) in this library is central to handling time and is often initialized from or converted to Julian Date concepts. For more direct Julian Date manipulations, see the [Julian Dates module](../../julian_dates/README.md).

### Key Astronomical Constants

The library defines several important constants in `lib/src/astro/constant.dart` (accessible via `import 'package:geoengine/src/astro/astronomy.dart';`). Some key ones include:

-   `KM_PER_AU`: The number of kilometers per astronomical unit (149597870.6909893 km).
-   `C_AUDAY`: The speed of light in AU per day (173.1446326846693 AU/day).
-   `DEG2RAD`: Factor to convert degrees to radians (π/180).
-   `RAD2DEG`: Factor to convert radians to degrees (180/π).
-   `HOUR2RAD`: Factor to convert sidereal hours to radians (π/12).
-   `RAD2HOUR`: Factor to convert radians to sidereal hours (12/π).
-   Various gravitational parameters (GM values) for the Sun and planets (e.g., `SUN_GM`, `EARTH_GM`).
-   Radii and flattening factors for Earth and other bodies (e.g., `EARTH_EQUATORIAL_RADIUS_KM`).

### The `Observer` Class

The `Observer` class is fundamental for many astronomical calculations that depend on the specific geographic location of an observer on Earth.

**Purpose:**
Represents an observer's position on the Earth's surface, defined by their geographic latitude, longitude, and elevation above mean sea level.

**Constructor:**
```dart
Observer(double latitude, double longitude, double height)
```
-   `latitude` (double): Geographic latitude in degrees. Positive for North, negative for South. Must be in the range -90 to +90.
-   `longitude` (double): Geographic longitude in degrees. Positive for East, negative for West of the prime meridian. Typically kept in the range -180 to +180.
-   `height` (double): Elevation above mean sea level, in meters.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides Observer via astronomy.dart

void main() {
  // Observer in London, UK (approx. values)
  final double latitude = 51.5074;  // degrees North
  final double longitude = -0.1278; // degrees West
  final double elevation = 35;      // meters above sea level

  Observer londonObserver = Observer(latitude, longitude, elevation);

  print('Observer created for: Lat ${londonObserver.latitude}°, Lon ${londonObserver.longitude}°, Ht ${londonObserver.height}m');
}
```

**Importance:**
The observer's location is crucial for calculating:
-   **Topocentric Coordinates:** The apparent position of celestial objects in the sky as seen from that specific location (e.g., Azimuth/Altitude). Details in [Observer-Related Phenomena](./observer_related/README.md#apparent-horizontal-coordinates-azimuthaltitude).
-   **Rise, Set, and Culmination Times:** These events are local phenomena and depend directly on the observer's horizon. See [Observer-Related Phenomena](./observer_related/README.md#rise-set-and-culmination-times).
-   **Local Eclipse Circumstances:** Details of a solar or lunar eclipse (e.g., timing, magnitude, obscuration) vary significantly based on where the observer is. See [Eclipse Calculations](./eclipses/README.md#local-solar-eclipses).
-   **Parallax Effects:** The apparent shift in position of nearby objects (like the Moon) when viewed from different points on Earth.

The library uses the `Observer` object in conjunction with an `AstroTime` object (representing the time of observation) for these calculations.

The `Observer` class also includes static methods like:
-   `Observer.gravity(double latitude, double height)`: Calculates gravitational acceleration.
-   `Observer.observerVector(dynamic date, Observer observer, bool ofdate)`: Calculates geocentric equatorial coordinates of an observer.
-   `Observer.observerState(dynamic date, Observer observer, bool ofdate)`: Calculates geocentric equatorial position and velocity of an observer.

---

For detailed examples of specific calculations, please refer to the relevant sections linked above and the example code in the `example/astro/` directory of the GeoEngine package.
```yaml
dependencies:
  geoengine: any # Replace with the desired version
```
