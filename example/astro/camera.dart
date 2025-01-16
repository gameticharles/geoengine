/*
    camera.dart  -  by Don Cross - 2021-03-26

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    Given an observer's location on the Earth and a date/time,
    calculates the angle of the sunlit side of the Moon as
    seen through a camera aimed at it.

    To execute, run the command:
    dart camera latitude longitude [date]
*/

import 'dart:math';
import 'package:geoengine/geoengine.dart';

void camera(Observer observer, AstroTime time) {
  const tolerance = 1.0e-15;

  // Calculate the topocentric equatorial coordinates of date for the Moon.
  // Assume aberration does not matter because the Moon is so close and has such a small relative velocity.
  var moonEqu = equator(Body.Moon, time, observer, true, false);

  // Also calculate the Sun's topocentric position in the same coordinate system.
  var sunEqu = equator(Body.Sun, time, observer, true, false);

  // Get the Moon's horizontal coordinates, so we know how much to pivot azimuth and altitude.
  var moonHor = HorizontalCoordinates.horizon(
      time, observer, moonEqu.ra, moonEqu.dec, RefractionType.airless);
  print(
      'Moon horizontal position: azimuth = ${moonHor.azimuth.toStringAsFixed(3)}, altitude = ${moonHor.altitude.toStringAsFixed(3)}');

  // Get the rotation matrix that converts equatorial to horizontal coordinates for this place and time.
  var rot = RotationMatrix.rotationEQDtoHOR(time, observer);

  // Modify the rotation matrix in two steps:
  // First, rotate the orientation so we are facing the Moon's azimuth.
  // We do this by pivoting around the zenith axis.
  // Horizontal axes are: 0 = north, 1 = west, 2 = zenith.
  // Tricky: because the pivot angle increases counterclockwise, and azimuth
  // increases clockwise, we undo the azimuth by adding the positive value.
  rot = RotationMatrix.pivot(rot, 2, moonHor.azimuth);

  // Second, pivot around the leftward axis to bring the Moon to the camera's altitude level.
  // From the point of view of the leftward axis, looking toward the camera,
  // adding the angle is the correct sense for subtracting the altitude.
  rot = RotationMatrix.pivot(rot, 1, moonHor.altitude);

  // As a sanity check, apply this rotation to the Moon's equatorial (EQD) coordinates and verify x=0, y=0.
  var vec = AstroVector.rotateVector(rot, moonEqu.vec);

  // Convert to unit vector.
  var radius = vec.length();
  vec.x /= radius;
  vec.y /= radius;
  vec.z /= radius;
  print(
      'Moon check: x = ${vec.x.toStringAsFixed(6)}, y = ${vec.y.abs().toStringAsFixed(6)}, z = ${vec.z.abs().toStringAsFixed(6)}');
  if (!vec.x.isFinite || (vec.x - 1.0).abs() > tolerance) {
    print("Excessive error in moon check (x).");
    return;
  }

  if (!vec.y.isFinite || vec.y.abs() > tolerance) {
    print("Excessive error in moon check (y).");
    return;
  }

  if (!vec.z.isFinite || vec.z.abs() > tolerance) {
    print("Excessive error in moon check (z).");
    return;
  }

  // Apply the same rotation to the Sun's equatorial vector.
  // The x- and y-coordinates now tell us which side appears sunlit in the camera!

  vec = AstroVector.rotateVector(rot, sunEqu.vec);

  // Don't bother normalizing the Sun vector, because in AU it will be close to unit anyway.
  print(
      'Sun vector: x = ${vec.x.toStringAsFixed(6)}, y = ${vec.y.toStringAsFixed(6)}, z = ${vec.z.toStringAsFixed(6)}');

  // Calculate the tilt angle of the sunlit side, as seen by the camera.
  // The x-axis is now pointing directly at the object, z is up in the camera image, y is to the left.
  var tilt = RAD2DEG * atan2(vec.y, vec.z);
  print(
      'Tilt angle of sunlit side of the Moon = ${tilt.toStringAsFixed(3)} degrees counterclockwise from up.');

  var illum = IlluminationInfo.getBodyIllumination(Body.Moon, time);

  print(
      'Moon magnitude = ${illum.mag.toStringAsFixed(2)}, phase angle = ${illum.phaseAngle.toStringAsFixed(2)} degrees.');

  var angle = angleFromSun(Body.Moon, time);

  print(
      'Angle between Moon and Sun as seen from Earth = ${angle.toStringAsFixed(2)} degrees.');
}

void main() {
  final latitude = 6.56784;
  final longitude = -1.5674;
  final observer = Observer(latitude, longitude, 0);
  final time = AstroTime(DateTime.now());
  camera(observer, time);
}
