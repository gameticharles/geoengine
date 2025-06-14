# Levelling Module

The `Levelling` class in GeoEngine is designed to represent and process data from a levelling survey. Levelling is a surveying technique used to determine differences in elevation between points. This module allows users to input levelling measurements, perform calculations using different methods (Rise & Fall or Height of Plane of Collimation), apply adjustments for misclosure, and obtain a formatted summary of the results.

## `Levelling` Class

This class encapsulates all aspects of a levelling run, from initial setup to final adjusted elevations.

### Initialization

To start working with a levelling survey, you first need to create an instance of the `Levelling` class.

**Constructor:**
```dart
Levelling({
  required double startingTBM, // The known elevation of the starting Temporary Bench Mark (TBM)
  double? closingTBM,          // The known elevation of the closing TBM (optional, for closed traverses)
  required int accuracy,        // The accuracy class of the levelling run (e.g., 5 for 5mm * sqrt(km))
  int roundDigits = 3,          // The number of decimal places to round calculations to
  LevellingMethod method = LevellingMethod.riseFall, // The calculation method to use
})
```

**Parameters:**
-   `startingTBM` (double): The known elevation of the starting benchmark.
-   `closingTBM` (double, optional): The known elevation of the closing benchmark. If provided, it's used to calculate misclosure and adjust the levels.
-   `accuracy` (int): Defines the allowable misclosure for the survey, typically in mm per km (e.g., an accuracy of `5` means the allowable misclosure is `5mm * sqrt(distance_in_km)`). The actual calculation of total distance may require additional input or is based on the number of setups.
-   `roundDigits` (int, optional): The number of decimal places to which results and intermediate calculations should be rounded. Defaults to `3`.
-   `method` (LevellingMethod, optional): The method to be used for calculating reduced levels. Can be `LevellingMethod.riseFall` or `LevellingMethod.hpc` (Height of Plane of Collimation). Defaults to `LevellingMethod.riseFall`.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides Levelling, LevellingMethod

void main() {
  // For a closed levelling run
  final levellingRun = Levelling(
    startingTBM: 100.000, // Starting TBM elevation
    closingTBM: 98.050,   // Closing TBM elevation
    accuracy: 5,          // e.g., 5mm * sqrt(km) accuracy
    roundDigits: 3,
    method: LevellingMethod.riseFall,
  );

  // For an open levelling run (or if closing TBM is unknown initially)
  final openLevellingRun = Levelling(
    startingTBM: 100.000,
    accuracy: 3, // A different accuracy class
    method: LevellingMethod.hpc,
  );
  
  print('Levelling run initialized. Starting TBM: ${levellingRun.startingTBM}');
  print('Open levelling run initialized. Starting TBM: ${openLevellingRun.startingTBM}');
}
```

### Adding Measurements

Observations from the field are added to the `Levelling` object. Each measurement typically consists of a station name/identifier and staff readings (Backsight, Intersight, Foresight).

There are two ways to add measurement data:

#### 1. `addMeasurement(LevellingMeasurement measurement)`

**Purpose:** Adds a single measurement using a `LevellingMeasurement` object.

**Parameters:**
-   `measurement` (LevellingMeasurement): An object containing the details of the observation.
    -   `station` (String?): Identifier for the observed station.
    -   `bs` (double?): Backsight reading.
    -   `is_` (double?): Intersight reading (named `is_` because `is` is a reserved keyword in Dart).
    -   `fs` (double?): Foresight reading.

#### 2. `addData(String? station, double? bs, double? is_, double? fs)`

**Purpose:** Adds a single measurement by providing individual values directly.

**Parameters:**
-   `station` (String?): Identifier for the observed station.
-   `bs` (double?): Backsight reading.
-   `is_` (double?): Intersight reading.
-   `fs` (double?): Foresight reading.

**Example Data Format and Usage:**
Field data is often recorded in a table format. The following example shows how to represent this data in Dart and add it to the `Levelling` object.

```dart
import 'package:geoengine/geoengine.dart';

void main() {
  final levellingRun = Levelling(
    startingTBM: 100.000,
    closingTBM: 98.050,
    accuracy: 5,
    roundDigits: 3,
  );

  // Sample observation data: [Station_ID, Backsight, Intersight, Foresight]
  final List<List<Object?>> data = [
    ['A', 1.751, null, null],    // Starting point on TBM1 (RL=100.000)
    ['B', null, 0.540, null],    // Intermediate point
    ['C', 0.300, null, 2.100],   // Change point
    ['D', null, 1.100, null],    // Intermediate point
    ['E', null, 1.260, null],    // Intermediate point
    ['F', 1.500, null, 2.300],   // Change point
    ['G', null, null, 1.110]     // Closing point on TBM2 (RL should be 98.050)
  ];

  // Add data using the addData method
  for (var entry in data) {
    levellingRun.addData(
      entry[0] as String?, // Station ID
      entry[1] as double?, // Backsight (BS)
      entry[2] as double?, // Intersight (IS)
      entry[3] as double?, // Foresight (FS)
    );
  }
  
  // Alternatively, using addMeasurement with LevellingMeasurement objects:
  // for (var entry in data) {
  //   levellingRun.addMeasurement(LevellingMeasurement(
  //     station: entry[0] as String?,
  //     bs: entry[1] as double?,
  //     is_: entry[2] as double?, // Note the underscore for 'is_'
  //     fs: entry[3] as double?,
  //   ));
  // }
  print('All ${data.length} measurements added to levelling run.');
}
```

### Performing Calculations

After all measurements have been added, calculations can be performed to determine reduced levels and assess the survey's accuracy.

#### `computeReducedLevels([LevellingMethod? method])`

**Purpose:** Calculates the reduced levels (elevations) for all observed points using the specified or default levelling method. It also computes misclosure, applies corrections if applicable, and performs arithmetic checks.
**Parameters:**
-   `method` (LevellingMethod, optional): If provided, this method (`LevellingMethod.riseFall` or `LevellingMethod.hpc`) will be used for the current computation, overriding the method specified at initialization.
**Returns:** `void` (The results are stored as properties of the `Levelling` object).

**Example:**
```dart
import 'package:geoengine/geoengine.dart';
// Assuming levellingRun is initialized and data added as in the previous example.
// void main() {
//   final levellingRun = Levelling( startingTBM: 100.000, closingTBM: 98.050, accuracy: 5);
//   // ... add data ...

   levellingRun.computeReducedLevels(); // Uses method specified at initialization (default: Rise & Fall)
   print('Reduced levels computed using default method.');

// To compute or re-compute using a different method:
   levellingRun.computeReducedLevels(LevellingMethod.hpc);
   print('Reduced levels re-computed using HPC method.');
// }
```

### Accessing Results

Once `computeReducedLevels()` has been called, various results can be accessed through the properties of the `Levelling` object:

-   **`numberSTN` (int):** The total number of instrument stations (setups where backsights and foresights are taken).
-   **`allowableMisclose` (double?):** The calculated allowable misclosure in millimeters, based on the specified `accuracy` and total distance (or number of setups if distance isn't explicitly handled). This might be null if it cannot be computed (e.g., for an open traverse without a closing TBM or if distance information is missing).
-   **`misclose` (double?):** The actual misclosure of the levelling run in meters. This is the difference between the known closing RL and the calculated closing RL. Null for open traverses.
-   **`correction` (double?):** The total correction to be applied due to misclosure, in meters. Null if no misclosure.
-   **`adjustmentPerStation` (double?):** The correction applied per instrument station if misclosure is distributed. Null if no misclosure.
-   **`reducedLevels` (List<double>):** A list containing the unadjusted reduced levels (elevations) for all stations.
-   **`adjustedReducedLevels` (List<double>):** A list containing the adjusted reduced levels for all stations after applying corrections. If no correction is applied, this will be the same as `reducedLevels`.
-   **`isWorkAccepted` (bool):** Indicates whether the levelling work meets the specified accuracy criteria (i.e., if `abs(misclose * 1000) <= allowableMisclose`). For open traverses without a closing TBM, this might always be true or depend on other checks.
-   **`arithmeticCheckResult` (String):** A string summarizing the arithmetic checks (e.g., Sum of BS - Sum of FS vs. Last RL - First RL).

**Example:**
```dart
import 'package:geoengine/geoengine.dart';
// Assuming levellingRun is initialized, data added, and computeReducedLevels() called.
// void main() {
//   final levellingRun = Levelling( startingTBM: 100.000, closingTBM: 98.050, accuracy: 5);
//   // ... add data & computeReducedLevels() ...

  print('Number of Instrument Stations: ${levellingRun.numberSTN}');
  if (levellingRun.allowableMisclose != null) {
    print('Allowable Misclose: ${levellingRun.allowableMisclose!.toStringAsFixed(levellingRun.roundDigits)} mm');
  }
  if (levellingRun.misclose != null) {
    print('Actual Misclose: ${(levellingRun.misclose! * 1000).toStringAsFixed(levellingRun.roundDigits)} mm');
    print('Correction: ${(levellingRun.correction! * 1000).toStringAsFixed(levellingRun.roundDigits)} mm');
  }
  print('Is Work Accepted: ${levellingRun.isWorkAccepted}');
  print('\\nArithmetic Checks:\\n${levellingRun.arithmeticCheckResult}');
  // print('Adjusted Reduced Levels: ${levellingRun.adjustedReducedLevels}');
// }
```

### Getting Formatted Output

#### `getDataFrame()`

**Purpose:** Returns the levelling field book data, including calculated rises, falls, and reduced levels, in a structured format suitable for display or further processing. The exact type might be a `List<Map<String, dynamic>>` or a custom table-like object.
**Returns:** A representation of the levelling table.

**Example:**
```dart
// ... (after levellingRun.computeReducedLevels())
// var dataFrame = levellingRun.getDataFrame();
// This usually requires a custom way to print the DataFrame, e.g.:
// dataFrame.forEach((row) => print(row)); 
// For simple display, printing the Levelling object is often easier (see below).
```

#### Printing the `Levelling` Object

**Purpose:** Provides a comprehensive, formatted summary of the entire levelling survey, including input parameters, calculated values, checks, and the field book table with adjusted levels.
**Usage:** Simply use `print(levellingObject)`. The `toString()` method of the `Levelling` class is overridden to produce this summary.

**Example (Output from main README):**
```dart
// Assuming levellingRun is initialized, data added, and computeReducedLevels() called:
// print(levellingRun); 
// Output would be similar to:

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

---
*Note: For precise calculation of `allowableMisclose`, the total distance of the levelling run or the number of instrument setups is typically used. The library handles this based on the input data. Ensure all measurements are correctly entered for accurate results.*
```yaml
dependencies:
  geoengine: any # Replace with the desired version
```
