import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:geoengine/geoengine.dart';

void main(List<String> args) {
  test1();
  // test2();
}

Set<Ellipsoid> extractEllipsoidsFromWKTStrings(List<String> wktStrings) {
  Set<Ellipsoid> uniqueEllipsoids = HashSet<Ellipsoid>();

  for (String wktString in wktStrings) {
    // Extract relevant information from the WKT string (You may need to adjust this parsing logic)
    final RegExp regExp = RegExp(
        r'SPHEROID\["(.+?)",(\d+\.\d+),(\d+\.\d+),AUTHORITY\["(.+?)","(.+?)"\]\]'
        r'.*?UNIT\["(.+?)",(\d+\.\d+),AUTHORITY\["(.+?)","(.+?)"\]\]');
    final Match? match = regExp.firstMatch(wktString);

    if (match != null) {
      String ellipsoidName = match.group(1)!;
      double semiMajorAxis = double.parse(match.group(2)!);
      double invFlattening = double.parse(match.group(3)!);
      String authority = match.group(4)!;
      int code = int.parse(match.group(5)!);

      // Create an Ellipsoid object
      Ellipsoid ellipsoid = Ellipsoid(
          a: semiMajorAxis,
          invF: invFlattening,
          name: ellipsoidName,
          authority: authority,
          authorityCode: code,
          linearUnit: LinearUnit.meter,
          isIvfDefinitive: true
          // AngularUnit(
          //   name: match.group(6)!,
          //   radiansPerUnit: double.parse(match.group(7)!),
          //   authority: match.group(8)!,
          //   authorityCode: int.parse(match.group(9)!),
          // ), // You may need to adjust this based on your data
          );

      // Add the ellipsoid to the set if it's not a duplicate
      uniqueEllipsoids.add(ellipsoid);
    }
  }

  return uniqueEllipsoids.toSet();
}

Ellipsoid? extractEllipsoidFromWKTString(String wktString) {
  // Extract relevant information from the WKT string (You may need to adjust this parsing logic)
  final RegExp regExp = RegExp(
      r'SPHEROID\["(.+?)",(\d+\.\d+),(\d+\.\d+),AUTHORITY\["(.+?)","(.+?)"\]\]');
  final Match? match = regExp.firstMatch(wktString);

  if (match != null) {
    String ellipsoidName = match.group(1)!;
    double semiMajorAxis = double.parse(match.group(2)!);
    double invFlattening = double.parse(match.group(3)!);
    String authority = match.group(4)!;
    int code = int.parse(match.group(5)!);

    return Ellipsoid(
      a: semiMajorAxis,
      invF: invFlattening,
      name: ellipsoidName,
      authority: authority,
      authorityCode: code,
      linearUnit:
          LinearUnit.meter, // You may need to adjust this based on your data
    );
  }

  return null;
}

void test1() {
  // Read the JSON data from the file
  final file = File('assets/data/PreDefinedCRSTable.json');
  final jsonString = file.readAsStringSync();
  final jsonData = json.decode(jsonString);

  // Extract unique ellipsoids from the WKT strings
  final crsList = (jsonData['CRS'] as List<dynamic>)
      .map((json) => CRS.fromJson(json))
      .toList();

  final uniqueEllipsoids = <Ellipsoid>{};

  for (CRS crs in crsList) {
    final ellipsoid = extractEllipsoidFromWKTString(crs.wktString);
    if (ellipsoid != null) {
      uniqueEllipsoids.add(ellipsoid);
    }
  }

  // Now you have a set of unique ellipsoids
  for (Ellipsoid ellipsoid in uniqueEllipsoids) {
    print(ellipsoid.toGeoServer());
  }
}

void test2() {
  // Read the JSON data from the file
  final file = File('assets/data/PreDefinedCRSTable.json');
  final jsonString = file.readAsStringSync();
  final jsonData = json.decode(jsonString);

  // Extract ellipsoids from the WKT strings
  final crsList = (jsonData['CRS'] as List<dynamic>)
      .map((json) => CRS.fromJson(json))
      .toList();

  final wktStrings = crsList.map((crs) => crs.wktString).toList();
  final uniqueEllipsoids = extractEllipsoidsFromWKTStrings(wktStrings);

  // Now you have a set of unique ellipsoids
  for (Ellipsoid ellipsoid in uniqueEllipsoids.toSet()) {
    print(ellipsoid.toWKT2());
  }
}
