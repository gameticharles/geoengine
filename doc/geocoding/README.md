# Geocoding Module

Geocoding is the process of transforming a description of a location—such as a place name, address, or postal code—into geographic coordinates (latitude and longitude). These coordinates are often represented using a `LatLng` object (see [Core Calculations](../core/README.md) for more on `LatLng`). Reverse geocoding, conversely, converts geographic coordinates into a human-readable address or place name. This module provides tools to perform these operations using various online and offline strategies.

## The `Geocoder` Class

The central piece of this module is the `Geocoder` class. It acts as a unified interface for different geocoding providers or strategies. You initialize a `Geocoder` instance by providing a `strategyFactory` (which defines the geocoding engine to use) and optional configurations.

**Initialization:**
```dart
Geocoder({
  required Map<String, dynamic> strategyFactory, // Specifies the geocoding strategy
  Map<String, dynamic> config = const {},        // Common or strategy-specific configurations
  Duration throttleDuration = const Duration(seconds: 1), // Throttling for requests
})
```

## Geocoding Strategies

The `GeoEngine` library offers several strategies for geocoding:

### 1. GoogleStrategy

Uses the Google Maps Geocoding API. This is a powerful and widely used service.

**Key Features:**
- Requires a Google Cloud Platform API key.
- Offers high accuracy and extensive global coverage.

**Creation:**
```dart
import 'package:geoengine/geoengine.dart'; // Provides Geocoder, GoogleStrategy, LatLng

// ...
var googleGeocoder = Geocoder(
  strategyFactory: GoogleStrategy.create('YOUR_GOOGLE_API_KEY'), 
  // Replace 'YOUR_GOOGLE_API_KEY' with your actual API key
  config: {
    // Common Configurations
    'language': 'en', // Preferred language for results
    'requestTimeout': const Duration(seconds: 10), // Timeout for API requests

    // Google-Specific Configurations
    'regionBias': 'US',               // Bias results towards a specific region (e.g., US)
    'resultType': 'address',          // Restrict results to certain types
    'locationType': 'ROOFTOP',        // Preferred accuracy of results
    'components': 'country:US',       // Restrict results to specific components
    'rateLimit': 10,                  // Client-side rate limiting (requests per second)
  }
);
```

**Configuration Options:**
- **Common:**
    - `language` (String): The language in which to return results.
    - `requestTimeout` (Duration): Timeout for the geocoding request.
- **Google-Specific:**
    - `regionBias` (String): A region code (e.g., "US", "GB") to bias results.
    - `resultType` (String): One or more address types to filter results (e.g., "street_address", "locality").
    - `locationType` (String): Specifies the preferred accuracy of the returned result (e.g., `ROOFTOP`, `APPROXIMATE`).
    - `components` (String): A component filter, formatted as `component:value|component:value`.
    - `rateLimit` (int): Client-side requests per second limit.

**Usage:**

**Search (Address to Coordinates):**
```dart
import 'package:geoengine/geoengine.dart';

void main() async {
  var googleGeocoder = Geocoder(
    strategyFactory: GoogleStrategy.create('YOUR_GOOGLE_API_KEY'), // Replace with your key
    config: {'language': 'en'}
  );

  try {
    GeocoderRequestResponse searchResult = await googleGeocoder.search('Kwame Nkrumah University of Science & Technology');
    if (searchResult.success) {
      print('Google Search Success:');
      searchResult.result.forEach((res) {
        // Example: Extracting coordinates and formatted address
        final location = res['geometry']['location'];
        print('  Location: ${location['lat']}, ${location['lng']}');
        print('  Formatted Address: ${res['formatted_address']}');
      });
    } else {
      print('Google Search Failed: ${searchResult.errorMessage}');
    }
  } catch (e) {
    print('Error during Google search: $e');
  }
}
```
*Example Output (summarized):*
```
Google Search Success:
  Location: 6.673006, -1.5653335
  Formatted Address: Kwame Nkrumah University of Science and Technology (KNUST), Kumasi, Ghana
```

**Reverse Geocoding (Coordinates to Address):**
```dart
import 'package:geoengine/geoengine.dart';

void main() async {
  var googleGeocoder = Geocoder(
    strategyFactory: GoogleStrategy.create('YOUR_GOOGLE_API_KEY'), // Replace with your key
    config: {'language': 'en'}
  );
  var point = LatLng(6.673006, -1.5653335); // Example coordinates

  try {
    GeocoderRequestResponse reverseResult = await googleGeocoder.reverse(point);
    if (reverseResult.success) {
      print('Google Reverse Success:');
      reverseResult.result.forEach((res) {
        print('  Formatted Address: ${res['formatted_address']}');
      });
    } else {
      print('Google Reverse Failed: ${reverseResult.errorMessage}');
    }
  } catch (e) {
    print('Error during Google reverse geocoding: $e');
  }
}
```
*Example Output (summarized):*
```
Google Reverse Success:
  Formatted Address: PVVW+6V5, Kumasi, Ghana
```

### 2. OpenStreetMapStrategy

Uses the OpenStreetMap Nominatim service. Nominatim is a free, open-source geocoding service based on OpenStreetMap data.

**Key Features:**
- Free to use, no API key required.
- Adheres to Nominatim's usage policy (providing a valid email in requests is good practice and may be required by their terms).

**Creation:**
```dart
import 'package:geoengine/geoengine.dart';

// ...
var openStreetMapGeocoder = Geocoder(
  strategyFactory: OpenStreetMapStrategy.create(),
  config: {
    'email': 'your.app.contact@example.com', // Important for Nominatim usage policy
    'language': 'en', 
    'requestTimeout': const Duration(seconds: 10),
    // Other OpenStreetMap-Specific Configurations:
    // 'countryCodes': 'gh,us',          
    // 'viewBox': '-2.5,5.5,-0.5,7.5',   
    // 'boundedViewBox': '1',            
    // 'limit': 5,                       
    // 'addressDetails': 1,              
  }
);
```
*(See full list of configuration options in the main README or directly from Nominatim's documentation).*

**Usage:**
*(Examples are similar in structure to GoogleStrategy, using `osmGeocoder.search()` and `osmGeocoder.reverse()`)*

### 3. LocalStrategy

Performs geocoding and reverse geocoding using a predefined, local dataset. Ideal for offline scenarios or custom datasets.

**Key Features:**
- Works offline.
- Requires a dataset (e.g., from CSV, JSON, or `List<Map<String, dynamic>>`).
- Uses indexing (e.g., KDTree) for efficient searching.

**Data Preparation using `GeoData.readFile()`:**
*(Ensure the data file is accessible by your application, e.g., via Flutter assets or direct file path in Dart scripts.)*
```dart
// final geoData = await GeoData.readFile(
//   'assets/my_geodata.txt', // Example path for a Flutter asset
//   delimiter: '\t', 
//   hasHeader: false, 
//   coordinatesColumns: {'latitude': 4, 'longitude': 5}, 
// );
// List<Map<String, dynamic>> localDataEntries = geoData.rows;
```

**Creation:**
```dart
import 'package:geoengine/geoengine.dart';

// Assume localDataEntries is a List<Map<String, dynamic>>
// List<Map<String, dynamic>> localDataEntries = [
//   {'name': 'City Hall', 'latitude': 40.7128, 'longitude': -74.0060, 'id': 'nyc_ch'},
//   // ... more data
// ];

// var localGeocoder = Geocoder(
//   strategyFactory: LocalStrategy.create(
//     entries: localDataEntries, 
//     coordinatesColumnNames: (y: 'latitude', x: 'longitude'), 
//   ),
//   config: {
//     'isGeodetic': true,
//     'searchRadius': 2000, // meters for reverse geocoding
//     'limit': 5,
//     'indexingStrategy': 'KDTree', 
//   }
// );
```
*(See full list of configuration options in the main README).*

**Usage:**
*(Examples are similar in structure, using `localGeocoder.search()` and `localGeocoder.reverse()`)*

### 4. CustomStrategy

Allows integration of your own custom geocoding service. This involves defining a class that implements the required strategy interface and providing its factory to the `Geocoder`.

*(Refer to GeoEngine's source code for the specific interface requirements for custom strategies.)*

---
*Note: Ensure you have the `geoengine` package in your `pubspec.yaml`. When using `LocalStrategy` with `GeoData.readFile()`, manage file paths appropriately for your application environment (e.g., Flutter assets, server file paths).*
```yaml
dependencies:
  geoengine: any # Replace with the desired version
```
