/*
    vernal_point.dart  -  by Don Cross  -  2023-02-20

    Calculate the movement of the vernal equinox point
    between two different moments in time.
    Given two times, calculate how much the equinox
    point moves from the first time to the second time,
    relative to true ecliptic coordinates (ECT) expressed
    at the first time.
*/

import 'package:geoengine/src/astro/astronomy.dart';

import 'dart:io';

DateTime parseDate(String text) {
  try {
    final d = DateTime.parse(text);
    return d;
  } catch (e) {
    stderr.writeln('ERROR: Not a valid date: "$text"');
    exit(1);
  }
}

double vernalPointLongitudeChange(dynamic time1, AstroTime time2) {
  print('time1 = $time1');
  print('time2 = $time2');

  // Create a vector pointing toward the vernal point at time2.
  var vec2 = AstroVector(1, 0, 0, time2);

  // Find the rotation matrix that converts true ecliptic of date (ECT)
  // coordinates from the second time to the first time.
  // We accomplish this in two rotations: ECT(t2) --> EQJ --> ECT(t1).
  var rot = RotationMatrix.combineRotation(
    RotationMatrix.rotationECTtoEQJ(time2),
    RotationMatrix.rotationEQJtoECT(time1),
  );

  // Apply the rotation matrix to `vec2` to obtain `vec1`: the
  // second time's vernal point expressed in the first time's ecliptic system.
  var vec1 = AstroVector.rotateVector(rot, vec2);

  // Convert ecliptic direction from a vector to angles.
  var sphere = Spherical.sphereFromVector(vec1);

  return (sphere.lon > 180) ? (360 - sphere.lon) : sphere.lon;
}

void demo() {
  final arguments = Platform.environment['args']?.split(' ') ?? [];
  if (arguments.length == 4) {
    AstroTime time1 = AstroTime(parseDate(arguments[2]));
    AstroTime time2 = AstroTime(parseDate(arguments[3]));
    double longitudeChange = vernalPointLongitudeChange(time1, time2);
    print(
        "The vernal point's ecliptic longitude changed by ${longitudeChange.toStringAsFixed(4)} degrees.");
    exit(0);
  } else {
    print('USAGE: dart run vernal_point.dart time1 time2');
    print(
        'where the times are in the format yyyy-mm-dd or yyyy-mm-ddThh:mm:ssZ');
    exit(1);
  }
}

void main() {
  demo();
}
