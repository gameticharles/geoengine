
# GeoEngine

![GeoEngine Logo](link-to-logo.png)

[![pub package](https://img.shields.io/pub/v/geoengine.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/geoengine)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![likes](https://img.shields.io/pub/likes/geoengine)](https://pub.dartlang.org/packages/geoengine/score)
[![points](https://img.shields.io/pub/points/geoengine)](https://pub.dartlang.org/packages/geoengine/score)
[![popularity](https://img.shields.io/pub/popularity/geoengine)](https://pub.dartlang.org/packages/geoengine/score)
[![sdk version](https://badgen.net/pub/sdk-version/geoengine)](https://pub.dartlang.org/packages/geoengine)

[![Last Commits](https://img.shields.io/github/last-commit/gameticharles/geoengine?ogo=github&logoColor=white)](https://github.com/gameticharles/geoengine/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gameticharles/geoengine?ogo=github&logoColor=white)](https://github.com/gameticharles/geoengine/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gameticharles/geoengine?ogo=github&logoColor=white)](https://github.com/gameticharles/geoengine)
[![License](https://img.shields.io/github/license/gameticharles/geoengine?ogo=github&logoColor=white)](https://github.com/gameticharles/geoengine/blob/main/LICENSE)

[![stars](https://img.shields.io/github/stars/gameticharles/geoengine)](https://github.com/gameticharles/geoengine/stargazers)
[![forks](https://img.shields.io/github/forks/gameticharles/geoengine)](https://github.com/gameticharles/geoengine/network/members)
[![CI](https://img.shields.io/github/workflow/status/gameticharles/geoengine/Dart%20CI/master?logo=github-actions&logoColor=white)](https://github.com/gameticharles/matrix/actions)

GeoEngine is a comprehensive Dart library designed for geospatial and geomatic calculations. It provides a wide range of functionalities including distance calculations, coordinate conversions, geocoding, polygon operations, geodetic network analysis, and much more. Whether you are a GIS professional, a geomatics engineer, or a developer working on geospatial applications, GeoEngine is the ultimate toolkit for all your geospatial needs.

## Features

### Core Calculations
- **Distance Calculation**: Calculate the distance between two geographic coordinates using various algorithms like Haversine, Vincenty, and Great Circle.
- **Bearing Calculation**: Calculate the initial and final bearing between two points on the Earth's surface.
- **Geodesic Calculations**: Find the shortest path between two points on the Earth's surface, taking into account the Earth's curvature.

### Coordinate Systems
- **Coordinate Conversion**: Convert between different coordinate systems, such as latitude/longitude to UTM or MGRS.
- **Datum Transformations**: Transform coordinates between different geodetic datums.

### Geocoding
- **Geocoding and Reverse Geocoding**: Convert addresses into geographic coordinates and vice versa.

### Polygon Operations
- **Polygon Operations**: Create, manipulate, and analyze polygons, including point-in-polygon checks, area calculations, and finding centroids.

### Map Projections
- **Map Projections**: Support for various map projections and functions to transform coordinates between different projections.

### Spatial Indexing
- **Spatial Indexing**: Utilize spatial indexing techniques like R-trees or Quad-trees for efficient querying of spatial data.

### Geomatic Calculations
- **Error Propagation**: Estimate the uncertainty in spatial measurements.
- **Least Squares Adjustment**: Perform least squares adjustment for surveying measurements.
- **Traverse Calculations**: Perform closed and open traverse calculations.
- **Geodetic Networks**: Design and analyze geodetic networks.
- **Land Parcel Management**: Manage land parcels including subdivision and legal description generation.

### Remote Sensing
- **Remote Sensing Calculations**: Perform calculations such as NDVI, radiometric correction, and image classification.

### Digital Elevation Models
- **DEM Analysis**: Work with Digital Elevation Models, including slope, aspect, and watershed analysis.

### Route Planning
- **Route Planning**: Algorithms for route planning and optimization.

### GIS File Support
- **GIS File Support**: Read and write common GIS file formats like Shapefiles, GeoJSON, and KML.

### Integration with Mapping Services
- **Integration with Mapping Services**: Integrate with popular mapping services like Google Maps, OpenStreetMap, and Bing Maps.

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  geoengine: any
```

### Usage

Here's a simple example to calculate the distance between two geographic coordinates:

```dart
import 'package:geoengine/geoengine.dart';

void main() {
  var point1 = LatLng(37.7749, -122.4194);
  var point2 = LatLng(34.0522, -118.2437);

  var distance = GeoEngine.calculateDistance(point1, point2);

  print('Distance between points is: ${distance} meters');
}
```

## Documentation

For detailed documentation and examples for each feature, please visit the [GeoEngine Documentation](link-to-documentation).

## Contributing

Contributions are welcome! If you find a bug or would like to request a new feature, please open an issue. For major changes, please open an issue first to discuss what you would like to change.

## Testing

Tests are located in the test directory. To run tests, execute dart test in the project root.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gameticharles/geoengine/issues

## Author

Charles Gameti: [gameticharles@GitHub][github_cg].

[github_cg]: https://github.com/gameticharles

## License

GeoEngine is licensed under the [Apache License - Version 2.0][apache_license].

[apache_license]: https://www.apache.org/licenses/LICENSE-2.0.txt
