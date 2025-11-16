import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:geoengine/geoengine.dart';

List<CRS> crsList = [];

void main(List<String> args) {
  test1();
  test2();
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

  //print the total lenght
  print(crsList.length);

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
  final wktStrings = crsList.map((crs) => crs.wktString).toList();
  final uniqueEllipsoids = extractEllipsoidsFromWKTStrings(wktStrings);

  // Now you have a set of unique ellipsoids
  for (Ellipsoid ellipsoid in uniqueEllipsoids.toSet()) {
    print(ellipsoid.toWKT2());
  }
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

/// A list to hold predefined CRS objects once loaded.
List<CRS>? _predefinedCRS;

class CRS {
  final String crsName;
  final int isFavorite;
  final String wktID;
  final String wktString;

  CRS({
    required this.crsName,
    required this.isFavorite,
    required this.wktID,
    required this.wktString,
  });

  static CRS fromJson(Map<String, dynamic> json) {
    return CRS(
      crsName: json['CRSName'],
      isFavorite: json['IsFavorite'],
      wktID: json['WKTID'],
      wktString: json['WKTString'],
    );
  }

  /// Reads a predefined list of CRS objects from a JSON file.
  ///
  /// This function reads a JSON file containing an array of CRS definitions
  /// under the "CRS" key. It parses this data and populates a static list
  /// for later use by functions like `getByWktId`.
  ///
  /// [filePath] The path to the JSON file. Defaults to 'assets/data/PreDefinedCRSTable.json'.
  ///
  /// Returns a `Future<List<CRS>>` containing all the CRS objects from the file.
  static Future<List<CRS>> readPredefinedList(
      {String filePath = 'assets/data/PreDefinedCRSTable.json'}) async {
    if (_predefinedCRS != null) {
      return _predefinedCRS!;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException("CRS data file not found at", filePath);
    }

    final jsonString = await file.readAsString();
    final jsonData = json.decode(jsonString);

    final crsList = (jsonData['CRS'] as List<dynamic>)
        .map((json) => CRS.fromJson(json))
        .toList();

    _predefinedCRS = crsList;
    return crsList;
  }

  /// Gets a CRS object by its WKTID from the predefined list.
  ///
  /// You must call `readPredefinedList()` at least once before using this method.
  ///
  /// [wktId] The Well-Known Text ID of the CRS to find (e.g., "EPSG:4326").
  ///
  /// Returns the matching `CRS` object, or `null` if not found or if the
  /// predefined list has not been loaded.
  static CRS? getByWktId(String wktId) {
    if (_predefinedCRS == null) {
      return null;
    }
    try {
      return _predefinedCRS!.firstWhere((crs) => crs.wktID == wktId);
    } catch (e) {
      return null;
    }
  }
}
