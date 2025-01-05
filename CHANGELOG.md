# CHANGE LOGS

## 1.0.0

* **[FEATURE]** Added `Sun` class.
* **[IMPROVEMENT]** Added `bodyPosition` to return `EquatorialCoordinates` and `HorizontalCoordinates`.
* **[IMPROVEMENT]** Improved `Moon` with more functions like `moonRise`, `moonSet`, `illumination`, `moonQuarter`, `nextMoonQuarter`, `nextMoonQuarters`, `moonPhase`.
* **[IMPROVEMENT]** Improved `Eclipse` to search for `lunar`, `solar` or both eclipses.
* **[FEATURE]** Added other kinds of `MoonQuarter` like the `SuperMoon` and `MicroMoon`.
* **[FEATURE]** Added Astronomy to the README.md

## 0.2.3

* **[IMPROVEMENT]** Increased the version of `advance_math` to 4.0.2.

## 0.2.2

* **[FEATURE]** Added Error Ellipse class.
* **[IMPROVEMENT]** Integrated the least squares adjustment class with the error ellipse class.
* **[BUG_FIX]** Fixed the error ellipse calculation.
* **[BUG_FIX]** Fixed bugs and warnings.

## 0.2.1

* **[BUG_FIX]** Fixed astronomical calculations not working well.

## 0.2.0

* **[FEATURE]** Added astronomical calculations.
* **[BUG_FIX]** Fixed getZone to return the hemisphere.
* **[IMPROVEMENT]** Updated to use the new LatLng library format.
* **[IMPROVEMENT]** Update to use the new Dart SDK linting rules.

## 0.1.3

* **[BUG_FIX]** Final bearing not computed properly
* **[IMPROVEMENT]** More logics and constraints in Geocoder.
* **[IMPROVEMENT]** Change the use case of all the strategies to use the create factory.
* **[FEATURE]** Added geo-data reading
* **[FEATURE]** Added search normalization in the query before sending
* **[IMPROVEMENT]** Improved the ReadMe with Geocoder and levelling documentaion
* **[IMPROVEMENT]** Improved geocoder with cache, timeout etc.
* **[IMPROVEMENT]** Added the tracking of query duration.
* **[IMPROVEMENT]** Fixed classes and parameters' naming to the levelling.
* **[IMPROVEMENT]** Added doc-strings to levelling sub-classes
* **[BROKEN]** Measurement is now an abstract class with two specialized classes(i.e. LevellingMeasurement and TraversingMeasurement)
* **[BUG_FIX]** CoordinateType not set to UTM
* **[BUG_FIX]** Removed wrong changelog post in v0.1.2
* **[BUG_FIX]** Allowed web: `'>=0.3.0 <0.5.0'`

## 0.1.2

* **[FEATURE]** Implemented Geocoding (Google, OpenstreetMap, and Local Data)
* **[FEATURE]** Added compute distance in UTM
* **[FEATURE]** Added leveling computeation (Rise & Fall , HPC)
* **[IMPROVEMENT]** Wrote documentation on the remaining classes
* **[IMPROVEMENT]** Improved computation performance
* **[BUG_FIX]** CoordinateType not set to UTM

## 0.1.1

* Fixed bugs
* Removed the export of the included `advance_math` module

## 0.1.0

* Added support for MGRS convertions between UTM and LatLng.
* Added different Point types (Point, PointX, UTM, LatLng, MGRS).
* Added Coordinate conversions (Projections and Transformations).
* Added distance computations
* Added Least Squares Adjustment.
* Implemented Julian Dates as an extension of Datatime.

## 0.0.3

* Fixed README.

## 0.0.2

* Updated the README.
* Added dependencies

## 0.0.1

* Initial version.
