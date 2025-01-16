import 'package:advance_math/advance_math.dart';
import 'package:geoengine/src/astro/astronomy.dart';

/// Converts galactic coordinates to horizontal coordinates.
///
/// This function takes galactic latitude and longitude and converts them
/// into horizontal coordinates based on the provided time and observer.
///
/// - [time]: The observation time.
/// - [observer]: The observer's location.
/// - [gLat]: Galactic latitude in degrees.
/// - [gLon]: Galactic longitude in degrees.
///
/// Returns a tuple of [lat, lon] representing the horizontal coordinates.
({double altitude, double azimuth}) galacticToHorizontal(
    DateTime time, Observer observer, double gLat, double gLon) {
  // Calculate a matrix that converts galactic coordinates
  // to J2000 equatorial coordinates.
  final rot = RotationMatrix.rotationGALtoEQJ();

  // Adjust the rotation matrix to convert galactic to horizontal.
  final adjustRot = RotationMatrix.rotationEQJtoHOR(time, observer);
  final combinedRot = RotationMatrix.combineRotation(rot, adjustRot);

  // Convert the galactic coordinates from angles to a unit vector.
  final gSphere = Spherical(gLat, gLon, 1.0);
  final gVec = AstroVector.vectorFromSphere(gSphere, time);

  // Use the rotation matrix to convert the galactic vector to a horizontal vector.
  final hVec = AstroVector.rotateVector(combinedRot, gVec);

  // Convert the horizontal vector back to angular coordinates.
  // Assume this is a radio source (not optical), do not correct for refraction.
  final hSphere = Spherical.fromVector(hVec, RefractionType.airless);

  // Return the horizontal coordinates as latitude and longitude.
  return (altitude: hSphere.lat, azimuth: hSphere.lon);
}

void main(List<String> args) {
  var date = DateTime.now();
  final latitude = 6.56784;
  final longitude = -1.5674;

  final observer = Observer(latitude, longitude, 230);

  var gLat = 45.0;
  var gLon = 180.0;

  var hor = galacticToHorizontal(date, observer, gLat, gLon);
  print(
      'altitude = ${hor.altitude.roundTo(3)}, azimuth = ${hor.azimuth.roundTo(3)}');
}
