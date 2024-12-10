part of '../astronomy.dart';

class SaturnMagnitudeResult {
  double mag;
  double ringTilt;

  SaturnMagnitudeResult(this.mag, this.ringTilt);
}

SaturnMagnitudeResult saturnMagnitude(double phase, double helioDist,
    double geoDist, AstroVector gc, AstroTime time) {
  // Based on formulas by Paul Schlyter found here:
  // http://www.stjarnhimlen.se/comp/ppcomp.html#15

  // We must handle Saturn's rings as a major component of its visual magnitude.
  // Find geocentric ecliptic coordinates of Saturn.
  final eclip = ecliptic(gc);
  double ir =
      DEG2RAD * 28.06; // tilt of Saturn's rings to the ecliptic, in radians
  double nr = DEG2RAD *
      (169.51 +
          (3.82e-5 * time.tt)); // ascending node of Saturn's rings, in radians

  // Find tilt of Saturn's rings, as seen from Earth.
  double lat = DEG2RAD * eclip.eLat;
  double lon = DEG2RAD * eclip.eLon;
  double tilt = asin(sin(lat) * cos(ir) - cos(lat) * sin(ir) * sin(lon - nr));
  double sinTilt = sin(tilt.abs());

  double mag = -9.0 + 0.044 * phase;
  mag += sinTilt * (-2.6 + 1.2 * sinTilt);
  mag += 5 * log(helioDist * geoDist);

  return SaturnMagnitudeResult(mag, RAD2DEG * tilt);
}
