# Julian Dates Module

Julian Dates provide a continuous count of days and fractions since noon Universal Time on January 1, 4713 BCE (on the Julian calendar). This system is extensively used in astronomy and other scientific fields to simplify calculations involving time, as it avoids the complexities of standard calendar systems with varying month lengths and leap years.

The `JulianDate` class in GeoEngine offers a convenient way to work with Julian Dates in Dart.

For astronomical calculations, the GeoEngine [Astronomy Module's time handling](../astronomy/time_coords/README.md#astronomical-time-astrotime) primarily uses its internal `AstroTime` class, which is based on J2000.0 Julian days. However, the `JulianDate` class described here can be useful for converting to/from traditional Julian Dates if needed for external data or other specific contexts.

## `JulianDate` Class

This class encapsulates a Julian Date and provides methods for initialization, comparison, and conversion to and from standard `DateTime` objects.

### Initialization

You can create a `JulianDate` object in a couple of ways:

#### 1. From a specific calendar date: `JulianDate.fromDate()`

**Purpose:** Creates a `JulianDate` object from specified year, month, and day.

**Parameters:**
- `year` (int): The year.
- `month` (int): The month (1-12).
- `day` (int): The day of the month.
- `hour` (int, optional): The hour (0-23). Defaults to 0 (midnight UTC).
- `minute` (int, optional): The minute (0-59). Defaults to 0.
- `second` (int, optional): The second (0-59). Defaults to 0.
- `millisecond` (int, optional): The millisecond (0-999). Defaults to 0.
- `microsecond` (int, optional): The microsecond (0-999). Defaults to 0.

**Returns:**
- `JulianDate`: An instance representing the given calendar date.

**Example:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides JulianDate

void main() {
  // Represents August 15, 2023, 00:00:00 UTC
  JulianDate jdFromYMD = JulianDate.fromDate(year: 2023, month: 8, day: 15); 
  print('JD from YMD (midnight): ${jdFromYMD.toJulianDate()}');

  // Represents October 26, 2023, 12:30:00 UTC
  JulianDate jdWithTime = JulianDate.fromDate(year: 2023, month: 10, day: 26, hour: 12, minute: 30);
  print('JD from YMD (with time): ${jdWithTime.toJulianDate()}');
}
```

#### 2. Using a `DateTime` object: `JulianDate()`

**Purpose:** Creates a `JulianDate` object from a standard Dart `DateTime` object.

**Parameters:**
- `dateTime` (DateTime): The `DateTime` object to convert. It's recommended to use UTC `DateTime` objects for clarity (e.g., `DateTime.now().toUtc()` or `DateTime.utc(...)`).

**Returns:**
- `JulianDate`: An instance representing the given `DateTime`.

**Example:**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  var nowUtc = DateTime.now().toUtc(); 
  JulianDate jdFromDateTime = JulianDate(nowUtc);
  
  print('Current DateTime (UTC): ${nowUtc.toIso8601String(withColon: true)}');
  print('JD from DateTime: ${jdFromDateTime.toJulianDate()}');
}
```

### Comparing Julian Dates

`JulianDate` objects can be compared using standard comparison operators.

**Example:**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  JulianDate date1 = JulianDate.fromDate(year: 2023, month: 8, day: 15);
  JulianDate date2 = JulianDate.fromDate(year: 2023, month: 8, day: 20);
  JulianDate date1Again = JulianDate.fromDate(year: 2023, month: 8, day: 15);

  print('date1 == date2: ${date1 == date2}'); // false
  print('date1 < date2: ${date1 < date2}');    // true
  print('date1 == date1Again: ${date1 == date1Again}'); // true
}
```

### Conversion Functions

#### `toJulianDate()`

**Purpose:** Converts the `JulianDate` object to its standard Julian Date numerical value.
**Returns:** `double` - The Julian Date.

**Example:**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  // August 15, 2023, 00:00:00 UTC
  JulianDate dateAtMidnight = JulianDate(DateTime.utc(2023, 8, 15, 0, 0, 0)); 
  // Standard JD for 2023-08-15 00:00:00 UTC is 2460170.5
  print('JD for ${dateAtMidnight.dateTime.toIso8601String(withColon: true)}: ${dateAtMidnight.toJulianDate()}'); 
  
  // August 15, 2023, 12:00:00 UTC (Noon)
  JulianDate dateAtNoon = JulianDate(DateTime.utc(2023, 8, 15, 12, 0, 0)); 
  // Standard JD for 2023-08-15 12:00:00 UTC is 2460171.0
  print('JD for ${dateAtNoon.dateTime.toIso8601String(withColon: true)}: ${dateAtNoon.toJulianDate()}');
}
```

#### `toModifiedJulianDate({DateTime? referenceDate})`

**Purpose:** Converts to Modified Julian Date (MJD). Standard MJD is `JD - 2,400,000.5` (epoch: 1858-11-17 00:00 UTC). A custom `referenceDate` can also be used.
**Returns:** `double` - The MJD.

**Example (Standard MJD):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  // JD for 2023-08-16 00:00:00 UTC is 2460171.5
  JulianDate dateForMJD = JulianDate.fromJulianDate(2460171.5); 
  double mjd = dateForMJD.toModifiedJulianDate();
  print('MJD for JD 2460171.5 (standard epoch): $mjd'); // Expected: 60171.0
}
```

**Example (MJD with Custom Reference Date):**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  // JD for 2023-08-16 00:00 UTC is 2460171.5
  JulianDate originalDate = JulianDate.fromJulianDate(2460171.5); 
  // Reference date: Jan 1, 1960, 00:00:00 UTC
  DateTime customRef = DateTime.utc(1960, 1, 1); 

  double mjdReferenced = originalDate.toModifiedJulianDate(referenceDate: customRef);
  // JD for 1960-01-01 00:00:00 UTC is 2436934.5
  // Expected: 2460171.5 - 2436934.5 = 23237.0
  print('Referenced MJD (from ${customRef.toIso8601String(withColon: true)}): $mjdReferenced');
}
```

### Converting Back to `DateTime`

#### `JulianDate.fromJulianDate(double jd)`

**Purpose:** Creates a `JulianDate` object from a numerical Julian Date. Access its `dateTime` property for the `DateTime` object (in UTC).
**Returns:** `JulianDate`.

**Example:**
```dart
import 'package:geoengine/geoengine.dart';

void main() {
  double jdValue = 2460171.5; // Represents 2023-08-16 00:00:00 UTC
  JulianDate convertedDate = JulianDate.fromJulianDate(jdValue);
  
  print('Julian Date value: $jdValue');
  print('Converted back to DateTime (UTC): ${convertedDate.dateTime.toIso8601String(withColon: true)}');
  // Expected Output: Converted back to DateTime (UTC): 2023-08-16T00:00:00.000Z
}
```

---
*Always ensure that the specific epoch and time system (e.g., UTC) are consistently understood when working with Julian Dates.*
```yaml
dependencies:
  geoengine: any # Replace with the desired version
```
