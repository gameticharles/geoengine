import 'package:advance_math/advance_math.dart';
import 'package:geoengine/geoengine.dart';
import 'package:geoengine/src/geocoder/geocoder.dart';
import 'dart:io';

void main(List<String> args) async {
  // var geocoding = Geocoder(
  //   serviceProvider: GeocoderService.openStreetMap,
  //   requestTimeout: Duration(seconds: 10),
  //   retries: 3,
  // );

  // var jsonData = await parseTxtFileToJson('lib/src/geocoder/GH.csv');
  // print(jsonData[1]);

  List<Map<String, double>> points = [
    {'latitude': 5.80736, 'longitude': 0.41074},
    {'latitude': 6.13373, 'longitude': 0.81585},
    {'latitude': 11.01667, 'longitude': -0.5},
    {'latitude': 10.08587, 'longitude': -0.13587},
    {'latitude': 9.35, 'longitude': -0.88333},
    {'latitude': 10.73255, 'longitude': -1.05917},
  ];

  final file = File('lib/src/geocoder/GH.csv');
  final geoData = await GeoData.read(
    file: file,
    delimiter: ',',
    hasHeader: false,
    coordinatesColumns: {'latitude': 4, 'longitude': 5},
  );
  print(geoData.data[2]);

  var geocoding = Geocoder(
      strategy: LocalGeocodingStrategy(
    entries: points,
    coordinatesColumnNames: (y: 'latitude', x: 'longitude'),
    maxTopResults: 2,
    // maxDistance: 3,
  ));

  // var geocoding =
  //     Geocoder.fromStrategy(strategy: LocalGeocodingStrategy(geoData.data));

  // GeocoderRequestResponse u = await geocoding.search('Ashanti');
  // print(u);
  var point2 = LatLng(6, 0.7);
  GeocoderRequestResponse rex = await geocoding.reverse(point2);
  print(rex);
  print('');

  rex.result.forEach((x) {
    var point1 = LatLng.fromMap(x[0]);
    var distance = x[1];
    print(distance);
    print('Initial Bearing: ${point1.initialBearingTo(point2)}');
    print('Final Bearing: ${point1.finalBearingTo(point2)}');
    print(
        'Distance (Haversine): ${point1.distanceTo(point2, method: DistanceMethod.haversine)!.valueInUnits(LengthUnits.kilometers)} km');
    print(
        'Distance (Great Circle): ${point1.distanceTo(point2, method: DistanceMethod.greatCircle)!.valueInUnits(LengthUnits.kilometers)} km');
    print(
        'Distance (Vincenty): ${point1.distanceTo(point2, method: DistanceMethod.vincenty)!.valueInUnits(LengthUnits.kilometers)} km');
    print('');
  });
}

class GeoData {
  final List<Map<String, dynamic>> data;

  GeoData._(this.data);

  static Future<GeoData> read({
    required File file,
    String delimiter = ',',
    bool hasHeader = true,
    required Map<String, int> coordinatesColumns,
  }) async {
    final lines = await file.readAsLines();
    final headers = hasHeader
        ? lines.first.split(delimiter).map((e) => e.trim()).toList()
        : null;
    final List<Map<String, dynamic>> data = [];

    for (final line in lines.skip(hasHeader ? 1 : 0)) {
      final values = line.split(delimiter).map((e) => e.trim()).toList();
      final entryData = <String, dynamic>{};

      // Convert coordinate columns to double and check for null or empty
      final latitudeIndex = coordinatesColumns['latitude']!;
      final longitudeIndex = coordinatesColumns['longitude']!;
      final latitudeValue = double.tryParse(values[latitudeIndex]);
      final longitudeValue = double.tryParse(values[longitudeIndex]);

      // Skip the entry if latitude or longitude is null
      if (latitudeValue == null || longitudeValue == null) continue;

      if (headers != null) {
        for (var i = 0; i < values.length; i++) {
          entryData[headers[i]] = values[i];
        }
      } else {
        for (var i = 0; i < values.length; i++) {
          entryData[i.toString()] = values[i];
        }
      }

      // Assign the parsed coordinates to the data map
      entryData[latitudeIndex.toString()] = latitudeValue;
      entryData[longitudeIndex.toString()] = longitudeValue;

      data.add(entryData);
    }

    return GeoData._(data);
  }
}
