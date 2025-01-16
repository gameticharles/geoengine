part of '../astronomy.dart';

/// Information about a body's rotation axis at a given time.
///
/// This structure is returned by {@link RotationAxis} to report
/// the orientation of a body's rotation axis at a given moment in time.
/// The axis is specified by the direction in space that the body's north pole
/// points, using angular equatorial coordinates in the J2000 system (EQJ).
///
/// Thus `ra` is the right ascension, and `dec` is the declination, of the
/// body's north pole vector at the given moment in time. The north pole
/// of a body is defined as the pole that lies on the north side of the
/// [Solar System's invariable plane](https://en.wikipedia.org/wiki/Invariable_plane),
/// regardless of the body's direction of rotation.
///
/// The `spin` field indicates the angular position of a prime meridian
/// arbitrarily recommended for the body by the International Astronomical
/// Union (IAU).
///
/// The fields `ra`, `dec`, and `spin` correspond to the variables
/// α0, δ0, and W, respectively, from
/// [Report of the IAU Working Group on Cartographic Coordinates and Rotational Elements: 2015](https://astropedia.astrogeology.usgs.gov/download/Docs/WGCCRE/WGCCRE2015reprint.pdf).
/// The field `north` is a unit vector pointing in the direction of the body's north pole.
/// It is expressed in the J2000 mean equator system (EQJ).
///
/// @property {number} ra
///      The J2000 right ascension of the body's north pole direction, in sidereal hours.
///
/// @property {number} dec
///      The J2000 declination of the body's north pole direction, in degrees.
///
/// @property {number} spin
///      Rotation angle of the body's prime meridian, in degrees.
///
/// @property {Vector} north
///      A J2000 dimensionless unit vector pointing in the direction of the body's north pole.
class AxisInfo {
  double ra;
  double dec;
  double spin;
  AstroVector north;

  AxisInfo(this.ra, this.dec, this.spin, this.north);

  static AxisInfo earthRotationAxis(AstroTime time) {
    // Unlike the other planets, we have a model of precession and nutation
    // for the Earth's axis that provides a north pole vector.
    // So calculate the vector first, then derive the (RA,DEC) angles from the vector.

    // Start with a north pole vector in equator-of-date coordinates: (0,0,1).
    // Convert the vector into J2000 coordinates.
    List<double> pos2 = nutation([0, 0, 1], time, PrecessDirection.Into2000);
    List<double> nvec = precession(pos2, time, PrecessDirection.Into2000);
    AstroVector north = AstroVector(nvec[0], nvec[1], nvec[2], time);

    // Derive angular values: right ascension and declination.
    EquatorialCoordinates equ = EquatorialCoordinates.fromVector(north);

    // Use a modified version of the era() function that does not trim to 0..360 degrees.
    // This expression is also corrected to give the correct angle at the J2000 epoch.
    double spin = 190.41375788700253 + (360.9856122880876 * time.ut);

    return AxisInfo(equ.ra, equ.dec, spin, north);
  }

  /// Calculates information about a body's rotation axis at a given time.
  /// Calculates the orientation of a body's rotation axis, along with
  /// the rotation angle of its prime meridian, at a given moment in time.
  ///
  /// This function uses formulas standardized by the IAU Working Group
  /// on Cartographics and Rotational Elements 2015 report, as described
  /// in the following document:
  ///
  /// https://astropedia.astrogeology.usgs.gov/download/Docs/WGCCRE/WGCCRE2015reprint.pdf
  ///
  /// See {@link AxisInfo} for more detailed information.
  ///
  /// @param {Body} body
  ///      One of the following values:
  ///      `Body.Sun`, `Body.Moon`, `Body.Mercury`, `Body.Venus`, `Body.Earth`, `Body.Mars`,
  ///      `Body.Jupiter`, `Body.Saturn`, `Body.Uranus`, `Body.Neptune`, `Body.Pluto`.
  ///
  /// @param {FlexibleDateTime} date
  ///      The time at which to calculate the body's rotation axis.
  ///
  /// @returns {AxisInfo}
  static AxisInfo rotationAxis(Body body, dynamic date) {
    final time = AstroTime(date);
    final d = time.tt;
    final T = d / 36525.0;
    double ra, dec, w;

    switch (body) {
      case Body.Sun:
        ra = 286.13;
        dec = 63.87;
        w = 84.176 + (14.1844 * d);
        break;

      case Body.Mercury:
        ra = 281.0103 - (0.0328 * T);
        dec = 61.4155 - (0.0049 * T);
        w = 329.5988 +
            (6.1385108 * d) +
            (0.01067257 * sin(DEG2RAD * (174.7910857 + 4.092335 * d))) -
            (0.00112309 * sin(DEG2RAD * (349.5821714 + 8.184670 * d))) -
            (0.00011040 * sin(DEG2RAD * (164.3732571 + 12.277005 * d))) -
            (0.00002539 * sin(DEG2RAD * (339.1643429 + 16.369340 * d))) -
            (0.00000571 * sin(DEG2RAD * (153.9554286 + 20.461675 * d)));
        break;

      case Body.Venus:
        ra = 272.76;
        dec = 67.16;
        w = 160.20 - (1.4813688 * d);
        break;

      case Body.Earth:
        return earthRotationAxis(time);

      case Body.Moon:
        final e1 = DEG2RAD * (125.045 - 0.0529921 * d);
        final e2 = DEG2RAD * (250.089 - 0.1059842 * d);
        final e3 = DEG2RAD * (260.008 + 13.0120009 * d);
        final e4 = DEG2RAD * (176.625 + 13.3407154 * d);
        final e5 = DEG2RAD * (357.529 + 0.9856003 * d);
        final e6 = DEG2RAD * (311.589 + 26.4057084 * d);
        final e7 = DEG2RAD * (134.963 + 13.0649930 * d);
        final e8 = DEG2RAD * (276.617 + 0.3287146 * d);
        final e9 = DEG2RAD * (34.226 + 1.7484877 * d);
        final e10 = DEG2RAD * (15.134 - 0.1589763 * d);
        final e11 = DEG2RAD * (119.743 + 0.0036096 * d);
        final e12 = DEG2RAD * (239.961 + 0.1643573 * d);
        final e13 = DEG2RAD * (25.053 + 12.9590088 * d);

        ra = 269.9949 +
            0.0031 * T -
            3.8787 * sin(e1) -
            0.1204 * sin(e2) +
            0.0700 * sin(e3) -
            0.0172 * sin(e4) +
            0.0072 * sin(e6) -
            0.0052 * sin(e10) +
            0.0043 * sin(e13);

        dec = 66.5392 +
            0.0130 * T +
            1.5419 * cos(e1) +
            0.0239 * cos(e2) -
            0.0278 * cos(e3) +
            0.0068 * cos(e4) -
            0.0029 * cos(e6) +
            0.0009 * cos(e7) +
            0.0008 * cos(e10) -
            0.0009 * cos(e13);

        w = 38.3213 +
            (13.17635815 - 1.4e-12 * d) * d +
            3.5610 * sin(e1) +
            0.1208 * sin(e2) -
            0.0642 * sin(e3) +
            0.0158 * sin(e4) +
            0.0252 * sin(e5) -
            0.0066 * sin(e6) -
            0.0047 * sin(e7) -
            0.0046 * sin(e8) +
            0.0028 * sin(e9) +
            0.0052 * sin(e10) +
            0.0040 * sin(e11) +
            0.0019 * sin(e12) -
            0.0044 * sin(e13);
        break;

      case Body.Mars:
        ra = 317.269202 -
            0.10927547 * T +
            0.000068 * sin(DEG2RAD * (198.991226 + 19139.4819985 * T)) +
            0.000238 * sin(DEG2RAD * (226.292679 + 38280.8511281 * T)) +
            0.000052 * sin(DEG2RAD * (249.663391 + 57420.7251593 * T)) +
            0.000009 * sin(DEG2RAD * (266.183510 + 76560.6367950 * T)) +
            0.419057 * sin(DEG2RAD * (79.398797 + 0.5042615 * T));

        dec = 54.432516 -
            0.05827105 * T +
            0.000051 * cos(DEG2RAD * (122.433576 + 19139.9407476 * T)) +
            0.000141 * cos(DEG2RAD * (43.058401 + 38280.8753272 * T)) +
            0.000031 * cos(DEG2RAD * (57.663379 + 57420.7517205 * T)) +
            0.000005 * cos(DEG2RAD * (79.476401 + 76560.6495004 * T)) +
            1.591274 * cos(DEG2RAD * (166.325722 + 0.5042615 * T));

        w = 176.049863 +
            350.891982443297 * d +
            0.000145 * sin(DEG2RAD * (129.071773 + 19140.0328244 * T)) +
            0.000157 * sin(DEG2RAD * (36.352167 + 38281.0473591 * T)) +
            0.000040 * sin(DEG2RAD * (56.668646 + 57420.9295360 * T)) +
            0.000001 * sin(DEG2RAD * (67.364003 + 76560.2552215 * T)) +
            0.000001 * sin(DEG2RAD * (104.792680 + 95700.4387578 * T)) +
            0.584542 * sin(DEG2RAD * (95.391654 + 0.5042615 * T));
        break;

      case Body.Jupiter:
        final ja = DEG2RAD * (99.360714 + 4850.4046 * T);
        final jb = DEG2RAD * (175.895369 + 1191.9605 * T);
        final jc = DEG2RAD * (300.323162 + 262.5475 * T);
        final jd = DEG2RAD * (114.012305 + 6070.2476 * T);
        final je = DEG2RAD * (49.511251 + 64.3000 * T);

        ra = 268.056595 -
            0.006499 * T +
            0.000117 * sin(ja) +
            0.000938 * sin(jb) +
            0.001432 * sin(jc) +
            0.000030 * sin(jd) +
            0.002150 * sin(je);

        dec = 64.495303 +
            0.002413 * T +
            0.000050 * cos(ja) +
            0.000404 * cos(jb) +
            0.000617 * cos(jc) -
            0.000013 * cos(jd) +
            0.000926 * cos(je);

        w = 284.95 + 870.536 * d;
        break;

      case Body.Saturn:
        ra = 40.589 - 0.036 * T;
        dec = 83.537 - 0.004 * T;
        w = 38.90 + 810.7939024 * d;
        break;

      case Body.Uranus:
        ra = 257.311;
        dec = -15.175;
        w = 203.81 - 501.1600928 * d;
        break;

      case Body.Neptune:
        final N = DEG2RAD * (357.85 + 52.316 * T);
        ra = 299.36 + 0.70 * sin(N);
        dec = 43.46 - 0.51 * cos(N);
        w = 249.978 + 541.1397757 * d - 0.48 * sin(N);
        break;

      case Body.Pluto:
        ra = 132.993;
        dec = -6.163;
        w = 302.695 + 56.3625225 * d;
        break;

      default:
        throw 'Invalid body: $body';
    }

    // Calculate the north pole vector using the given angles.
    final radLat = DEG2RAD * dec;
    final radLon = DEG2RAD * ra;
    final rCosLat = cos(radLat);
    final north = AstroVector(
      rCosLat * cos(radLon),
      rCosLat * sin(radLon),
      sin(radLat),
      time,
    );

    return AxisInfo(ra / 15, dec, w, north);
  }
}
