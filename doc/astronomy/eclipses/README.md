# Eclipse Prediction

The GeoEngine astronomy module provides functions to search for and obtain information about solar and lunar eclipses. Eclipses are significant astronomical events that occur when one celestial body blocks the light from another. All time parameters and returns are typically handled using [`AstroTime`](../time_coords/README.md#astronomical-time-astrotime) objects.

For local eclipse predictions, an [`Observer`](../README.md#the-observer-class) object defining the viewer's location is required.

## Lunar Eclipses

A lunar eclipse occurs when the [Moon](../bodies/README.md#moon) passes directly behind Earth and into its shadow (umbra). This can only occur during a full moon when the Sun, Earth, and Moon are aligned (in syzygy) with Earth between the other two.

### Searching for Lunar Eclipses

-   **`Eclipse.searchLunarEclipse(dynamic date)`**: Finds the first lunar eclipse that occurs after the specified `date`.
    -   `date` (dynamic): An `AstroTime` object, `DateTime` (UTC recommended), or numeric Julian Date indicating when to start the search.
    -   Returns: `LunarEclipseInfo` object detailing the found eclipse.

-   **`Eclipse.nextLunarEclipse(dynamic prevEclipseTime)`**: Finds the next lunar eclipse after a previously found one.
    -   `prevEclipseTime` (dynamic): The `peak` time (an `AstroTime` object) from a `LunarEclipseInfo` object of a previous eclipse.
    -   Returns: `LunarEclipseInfo`.

### `LunarEclipseInfo` Object

This object contains detailed information about a found lunar eclipse:

-   `kind` (EclipseKind): The type of eclipse: `EclipseKind.Penumbral` (Moon passes through Earth's faint outer shadow), `EclipseKind.Partial` (part of the Moon passes through Earth's dark umbral shadow), or `EclipseKind.Total` (entire Moon passes through Earth's umbral shadow).
-   `obscuration` (double?): The peak fraction (0 to 1) of the Moon's apparent disc area covered by Earth's umbra. This is 0 for penumbral eclipses.
-   `peak` (AstroTime): The date and time of the eclipse's maximum phase.
-   `sdPenum` (double): Semi-duration (half of the total duration) of the penumbral phase in minutes.
-   `sdPartial` (double): Semi-duration of the partial phase in minutes (0 if not a partial or total eclipse).
-   `sdTotal` (double): Semi-duration of the total phase in minutes (0 if not a total eclipse).
-   `magnitude` (double?): The fraction of the Moon's diameter obscured by the Earth's umbra at the instant of greatest eclipse.

The `LunarEclipseInfo` class also has a comprehensive `toString()` method that provides a formatted summary of the eclipse details, including phase start and end times.

**Example (Finding the next few lunar eclipses):**
```dart
import 'package:geoengine/geoengine.dart'; // Provides AstroTime, Eclipse, LunarEclipseInfo, etc.

void main() {
  AstroTime startTime = AstroTime(DateTime.now().toUtc());
  print('Searching for lunar eclipses after ${startTime.date.toIso8601String(withColon: true)}');

  LunarEclipseInfo? currentEclipse = Eclipse.searchLunarEclipse(startTime);
  for (int i = 0; i < 5; ++i) {
    if (currentEclipse == null) {
      print("No further lunar eclipses found in a reasonable search period.");
      break;
    }
    print('\\n--- Lunar Eclipse ---');
    // The toString() method of LunarEclipseInfo provides a detailed summary.
    print(currentEclipse.toString()); 
    
    // To get the next one:
    currentEclipse = Eclipse.nextLunarEclipse(currentEclipse.peak);
  }
}
```

## Solar Eclipses

A solar eclipse occurs when the [Moon](../bodies/README.md#moon) passes between the [Sun](../bodies/README.md#sun) and Earth, and the Moon fully or partially blocks ("occults") the Sun.

### Global Solar Eclipses

These functions search for solar eclipses that are visible *somewhere* on Earth. The location of maximum eclipse is provided.

-   **`Eclipse.searchGlobalSolarEclipse(dynamic startTime)`**: Finds the first global solar eclipse occurring after `startTime`.
    -   `startTime` (dynamic): The date and time to start searching from.
    -   Returns: `GlobalSolarEclipseInfo`.

-   **`Eclipse.nextGlobalSolarEclipse(dynamic prevEclipseTime)`**: Finds the next global solar eclipse after a previously found one.
    -   `prevEclipseTime` (dynamic): The `peak` time (an `AstroTime` object) from a `GlobalSolarEclipseInfo` of a previous eclipse.
    -   Returns: `GlobalSolarEclipseInfo`.

### `GlobalSolarEclipseInfo` Object

Provides details about a globally visible solar eclipse:
-   `kind` (EclipseKind): Type of eclipse: `EclipseKind.Partial` (Moon only partially obscures the Sun from all locations), `EclipseKind.Annular` (Moon's apparent diameter is smaller than the Sun's, leaving a ring of the Sun visible), or `EclipseKind.Total` (Sun is completely obscured by the Moon for observers in the umbral path).
-   `obscuration` (double?): Peak fraction (0 to 1] of the Sun's apparent disc area obscured by the Moon, as seen from the peak location on Earth. Defined for total (1.0) and annular (<1.0) eclipses; can be `null` for partial eclipses in some contexts of this object.
-   `peak` (AstroTime): Date and time of the eclipse's maximum phase (when the shadow axis is closest to Earth's center).
-   `distance` (double): Distance in km between the Moon's shadow cone axis and Earth's center at `peak` time.
-   `latitude` (double?): Geographic latitude (degrees) of the peak shadow center on Earth (for total/annular).
-   `longitude` (double?): Geographic longitude (degrees) of the peak shadow center on Earth (for total/annular).

The `GlobalSolarEclipseInfo` class also has a `toString()` method for a formatted summary.

**Example (Finding the next few global solar eclipses):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime startTime = AstroTime(DateTime.now().toUtc());
  print('Searching for global solar eclipses after ${startTime.date.toIso8601String(withColon: true)}');

  GlobalSolarEclipseInfo? currentEclipse = Eclipse.searchGlobalSolarEclipse(startTime);
  for (int i = 0; i < 3; ++i) {
    if (currentEclipse == null) {
        print("No further global solar eclipses found in a reasonable search period.");
        break;
    }
    print('\\n--- Global Solar Eclipse ---');
    print(currentEclipse.toString()); // toString() provides a formatted summary.
        
    currentEclipse = Eclipse.nextGlobalSolarEclipse(currentEclipse.peak);
  }
}
```

### Local Solar Eclipses

These functions determine solar eclipse visibility and details for a specific [`Observer`](../README.md#the-observer-class) location on Earth.

-   **`Eclipse.searchLocalSolarEclipse(dynamic startTime, Observer observer)`**: Finds the first solar eclipse visible at the `observer`'s location after `startTime`.
    -   Returns: `LocalSolarEclipseInfo?` (can be null if no eclipse is visible for the observer in the search window).
-   **`Eclipse.nextLocalSolarEclipse(dynamic prevEclipsePeakTime, Observer observer)`**: Finds the next local solar eclipse for the `observer` after the `prevEclipsePeakTime`.
    -   `prevEclipsePeakTime` (dynamic): The `peak.time` from a previous `LocalSolarEclipseInfo`.
    -   Returns: `LocalSolarEclipseInfo?`.

### `LocalSolarEclipseInfo` Object

Provides event times and Sun altitudes for a local observer:
-   `kind` (EclipseKind): Type of eclipse observed locally (Partial, Annular, or Total).
-   `obscuration` (double?): Maximum fraction of Sun's disc area obscured locally.
-   `partialBegin` (EclipseEvent): Time and Sun's altitude when partial eclipse begins.
-   `totalBegin` (EclipseEvent?): Time and Sun's altitude when total/annular phase begins (if applicable).
-   `peak` (EclipseEvent): Time and Sun's altitude at maximum eclipse locally.
-   `totalEnd` (EclipseEvent?): Time and Sun's altitude when total/annular phase ends (if applicable).
-   `partialEnd` (EclipseEvent): Time and Sun's altitude when partial eclipse ends.

Each `EclipseEvent` object contains:
-   `time` (AstroTime): The date and time of the specific event.
-   `altitude` (double): The angular altitude of the center of the Sun above/below the horizon, in degrees, corrected for atmospheric refraction. A negative altitude means the event occurs when the Sun is below the horizon.

The `LocalSolarEclipseInfo` class also has a `toString()` method for a formatted summary.

**Example (Finding a local solar eclipse for a specific location):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  AstroTime startTime = AstroTime(DateTime.now().toUtc());
  Observer observer = Observer(34.0522, -118.2437, 70.0); // Los Angeles

  print('Searching for local solar eclipse for observer at Lat ${observer.latitude.toStringAsFixed(2)}, Lon ${observer.longitude.toStringAsFixed(2)} after ${startTime.date.toIso8601String(withColon:true)}');
  LocalSolarEclipseInfo? localEclipse = Eclipse.searchLocalSolarEclipse(startTime, observer);
  
  if (localEclipse != null) {
    print('\\n--- Local Solar Eclipse Details ---');
    print(localEclipse.toString()); // toString() provides a formatted summary.
  } else {
    print('No local solar eclipse found soon for the specified observer.');
  }
}
```

### General Eclipse Search Function

-   **`Eclipse.search({dynamic startTime, Eclipses eclipses = Eclipses.all, Observer? observer, int eclipseCount = 10})`**:
    -   A versatile function to search for a specified number (`eclipseCount`) of eclipses.
    -   `eclipses` (enum `Eclipses`): Can be `Eclipses.solar`, `Eclipses.lunar`, or `Eclipses.all`.
    -   If `observer` is provided, solar eclipses are specific to that location; otherwise, global solar eclipses are found.
    -   Returns: `List<EclipseInfo>`, where each item can be `LunarEclipseInfo`, `GlobalSolarEclipseInfo`, or `LocalSolarEclipseInfo`.

**Example (from `example/astro/eclipse.dart`, adapted):**
```dart
import 'package:geoengine/geoengine.dart'; 

// Helper for printing (if not using a custom logger)
void printLine([String text = '']) => print(text);

void main() {
  AstroTime startTime = AstroTime(DateTime.now().toUtc());
  final observer = Observer(6.56784, -1.5674, 230.0); // Example observer in Ghana

  printLine("===============");
  printLine("Upcoming Global Eclipses (Max 5, All Types)");
  printLine("===============");
  List<EclipseInfo> globalEclipses = Eclipse.search(startTime: startTime, eclipses: Eclipses.all, eclipseCount: 5);

  for (var eclipse in globalEclipses) {
    // Each object in the list will be one of LunarEclipseInfo, GlobalSolarEclipseInfo, or LocalSolarEclipseInfo.
    // Their respective toString() methods provide good summaries.
    print(eclipse.toString()); 
    printLine();
  }

  printLine("==============");
  printLine("Upcoming Local Eclipses for Observer (Max 5, All Types)");
  printLine("==============");
  List<EclipseInfo> localEclipses = Eclipse.search(observer: observer, startTime: startTime, eclipses: Eclipses.all, eclipseCount: 5);
  for (var eclipse in localEclipses) {
    print(eclipse.toString());
    printLine();
  }
}
```
