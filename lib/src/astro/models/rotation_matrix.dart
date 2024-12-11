part of '../astronomy.dart';

class RotationMatrix {
  List<List<double>> rot;

  /// @brief Creates a rotation matrix that can be used to transform one coordinate system to another.
  ///
  /// This function verifies that the `rot` parameter is of the correct format:
  /// a number[3][3] array. It throws an exception if `rot` is not of that shape.
  /// Otherwise it creates a new {@link RotationMatrix} object based on `rot`.
  ///
  /// @property {number[][]} rot
  ///      An array [3][3] of numbers. Defines a rotation matrix used to premultiply
  ///      a 3D vector to reorient it into another coordinate system.
  ///
  /// @returns {RotationMatrix}
  RotationMatrix(this.rot) {
    if (!isValidRotationArray(rot)) {
      throw ArgumentError('Argument must be a [3][3] array of numbers');
    }
  }

  static RotationMatrix precessionRot(AstroTime time, PrecessDirection dir) {
    final t = time.tt / 36525;

    double eps0 = 84381.406;

    double psia = (((((-0.0000000951 * t + 0.000132851) * t - 0.00114045) * t -
                    1.0790069) *
                t +
            5038.481507) *
        t);

    double omegaa = (((((0.0000003337 * t - 0.000000467) * t - 0.00772503) * t +
                        0.0512623) *
                    t -
                0.025754) *
            t +
        eps0);

    double chia = (((((-0.0000000560 * t + 0.000170663) * t - 0.00121197) * t -
                    2.3814292) *
                t +
            10.556403) *
        t);

    eps0 *= ASEC2RAD;
    psia *= ASEC2RAD;
    omegaa *= ASEC2RAD;
    chia *= ASEC2RAD;

    final sa = sin(eps0);
    final ca = cos(eps0);
    final sb = sin(-psia);
    final cb = cos(-psia);
    final sc = sin(-omegaa);
    final cc = cos(-omegaa);
    final sd = sin(chia);
    final cd = cos(chia);

    final xx = cd * cb - sb * sd * cc;
    final yx = cd * sb * ca + sd * cc * cb * ca - sa * sd * sc;
    final zx = cd * sb * sa + sd * cc * cb * sa + ca * sd * sc;
    final xy = -sd * cb - sb * cd * cc;
    final yy = -sd * sb * ca + cd * cc * cb * ca - sa * cd * sc;
    final zy = -sd * sb * sa + cd * cc * cb * sa + ca * cd * sc;
    final xz = sb * sc;
    final yz = -sc * cb * ca - sa * cc;
    final zz = -sc * cb * sa + cc * ca;

    if (dir == PrecessDirection.Into2000) {
      // Perform rotation from epoch to J2000.0.
      return RotationMatrix([
        [xx, yx, zx],
        [xy, yy, zy],
        [xz, yz, zz]
      ]);
    }

    if (dir == PrecessDirection.From2000) {
      // Perform rotation from J2000.0 to epoch.
      return RotationMatrix([
        [xx, xy, xz],
        [yx, yy, yz],
        [zx, zy, zz]
      ]);
    }

    throw 'Invalid precess direction';
  }

  static RotationMatrix nutationRot(AstroTime time, PrecessDirection dir) {
    final tilt = eTilt(time);
    final oblm = tilt.mobl * DEG2RAD;
    final oblt = tilt.tobl * DEG2RAD;
    final psi = tilt.dpsi * ASEC2RAD;
    final cobm = cos(oblm);
    final sobm = sin(oblm);
    final cobt = cos(oblt);
    final sobt = sin(oblt);
    final cpsi = cos(psi);
    final spsi = sin(psi);

    final xx = cpsi;
    final yx = -spsi * cobm;
    final zx = -spsi * sobm;
    final xy = spsi * cobt;
    final yy = cpsi * cobm * cobt + sobm * sobt;
    final zy = cpsi * sobm * cobt - cobm * sobt;
    final xz = spsi * sobt;
    final yz = cpsi * cobm * sobt - sobm * cobt;
    final zz = cpsi * sobm * sobt + cobm * cobt;

    if (dir == PrecessDirection.From2000) {
      // convert J2000 to of-date
      return RotationMatrix([
        [xx, xy, xz],
        [yx, yy, yz],
        [zx, zy, zz]
      ]);
    } else if (dir == PrecessDirection.Into2000) {
      // convert of-date to J2000
      return RotationMatrix([
        [xx, yx, zx],
        [xy, yy, zy],
        [xz, yz, zz]
      ]);
    } else {
      throw ArgumentError('Invalid precess direction');
    }
  }

  static bool isValidRotationArray(List<List<double>> rot) {
    if (rot.length != 3) {
      return false;
    }

    for (int i = 0; i < 3; ++i) {
      if (rot[i].length != 3) {
        return false;
      }

      for (int j = 0; j < 3; ++j) {
        if (!rot[i][j].isFinite) {
          return false;
        }
      }
    }

    return true;
  }

  /// @brief Calculates the inverse of a rotation matrix.
  ///
  /// Given a rotation matrix that performs some coordinate transform,
  /// this function returns the matrix that reverses that transform.
  ///
  /// @param {RotationMatrix} rotation
  ///      The rotation matrix to be inverted.
  ///
  /// @returns {RotationMatrix}
  ///      The inverse rotation matrix.
  static RotationMatrix inverseRotation(RotationMatrix rotation) {
    return RotationMatrix([
      [rotation.rot[0][0], rotation.rot[1][0], rotation.rot[2][0]],
      [rotation.rot[0][1], rotation.rot[1][1], rotation.rot[2][1]],
      [rotation.rot[0][2], rotation.rot[1][2], rotation.rot[2][2]]
    ]);
  }

  /// @brief Creates a rotation based on applying one rotation followed by another.
  ///
  /// Given two rotation matrices, returns a combined rotation matrix that is
  /// equivalent to rotating based on the first matrix, followed by the second.
  ///
  /// @param {RotationMatrix} a
  ///      The first rotation to apply.
  ///
  /// @param {RotationMatrix} b
  ///      The second rotation to apply.
  ///
  /// @returns {RotationMatrix}
  ///      The combined rotation matrix.
  static RotationMatrix combineRotation(RotationMatrix a, RotationMatrix b) {
    return RotationMatrix([
      [
        b.rot[0][0] * a.rot[0][0] +
            b.rot[1][0] * a.rot[0][1] +
            b.rot[2][0] * a.rot[0][2],
        b.rot[0][1] * a.rot[0][0] +
            b.rot[1][1] * a.rot[0][1] +
            b.rot[2][1] * a.rot[0][2],
        b.rot[0][2] * a.rot[0][0] +
            b.rot[1][2] * a.rot[0][1] +
            b.rot[2][2] * a.rot[0][2],
      ],
      [
        b.rot[0][0] * a.rot[1][0] +
            b.rot[1][0] * a.rot[1][1] +
            b.rot[2][0] * a.rot[1][2],
        b.rot[0][1] * a.rot[1][0] +
            b.rot[1][1] * a.rot[1][1] +
            b.rot[2][1] * a.rot[1][2],
        b.rot[0][2] * a.rot[1][0] +
            b.rot[1][2] * a.rot[1][1] +
            b.rot[2][2] * a.rot[1][2],
      ],
      [
        b.rot[0][0] * a.rot[2][0] +
            b.rot[1][0] * a.rot[2][1] +
            b.rot[2][0] * a.rot[2][2],
        b.rot[0][1] * a.rot[2][0] +
            b.rot[1][1] * a.rot[2][1] +
            b.rot[2][1] * a.rot[2][2],
        b.rot[0][2] * a.rot[2][0] +
            b.rot[1][2] * a.rot[2][1] +
            b.rot[2][2] * a.rot[2][2],
      ],
    ]);
  }

  /// @brief Creates an identity rotation matrix.
  ///
  /// Returns a rotation matrix that has no effect on orientation.
  /// This matrix can be the starting point for other operations,
  /// such as using a series of calls to {@link Pivot} to
  /// create a custom rotation matrix.
  ///
  /// @returns {RotationMatrix}
  ///      The identity matrix.
  static RotationMatrix identityMatrix() {
    return RotationMatrix([
      [1, 0, 0],
      [0, 1, 0],
      [0, 0, 1],
    ]);
  }

  /// @brief Re-orients a rotation matrix by pivoting it by an angle around one of its axes.
  ///
  /// Given a rotation matrix, a selected coordinate axis, and an angle in degrees,
  /// this function pivots the rotation matrix by that angle around that coordinate axis.
  ///
  /// For example, if you have rotation matrix that converts ecliptic coordinates (ECL)
  /// to horizontal coordinates (HOR), but you really want to convert ECL to the orientation
  /// of a telescope camera pointed at a given body, you can use `Astronomy_Pivot` twice:
  /// (1) pivot around the zenith axis by the body's azimuth, then (2) pivot around the
  /// western axis by the body's altitude angle. The resulting rotation matrix will then
  /// reorient ECL coordinates to the orientation of your telescope camera.
  ///
  /// @param {RotationMatrix} rotation
  ///      The input rotation matrix.
  ///
  /// @param {number} axis
  ///      An integer that selects which coordinate axis to rotate around:
  ///      0 = x, 1 = y, 2 = z. Any other value will cause an exception.
  ///
  /// @param {number} angle
  ///      An angle in degrees indicating the amount of rotation around the specified axis.
  ///      Positive angles indicate rotation counterclockwise as seen from the positive
  ///      direction along that axis, looking towards the origin point of the orientation system.
  ///      Any finite number of degrees is allowed, but best precision will result from
  ///      keeping `angle` in the range [-360, +360].
  ///
  /// @returns {RotationMatrix}
  ///      A pivoted matrix object.
  static RotationMatrix pivot(RotationMatrix rotation, int axis, double angle) {
    // Check for an invalid coordinate axis.
    if (axis != 0 && axis != 1 && axis != 2) {
      throw 'Invalid axis $axis. Must be 0, 1, or 2.';
    }

    final radians = angle * DEG2RAD;
    final c = cos(radians);
    final s = sin(radians);

    // Determine the order of axes for right-hand rule.
    final i = (axis + 1) % 3;
    final j = (axis + 2) % 3;
    final k = axis;

    var rot = List.generate(3, (_) => List<double>.filled(3, 0));

    rot[i][i] = c * rotation.rot[i][i] - s * rotation.rot[i][j];
    rot[i][j] = s * rotation.rot[i][i] + c * rotation.rot[i][j];
    rot[i][k] = rotation.rot[i][k];

    rot[j][i] = c * rotation.rot[j][i] - s * rotation.rot[j][j];
    rot[j][j] = s * rotation.rot[j][i] + c * rotation.rot[j][j];
    rot[j][k] = rotation.rot[j][k];

    rot[k][i] = c * rotation.rot[k][i] - s * rotation.rot[k][j];
    rot[k][j] = s * rotation.rot[k][i] + c * rotation.rot[k][j];
    rot[k][k] = rotation.rot[k][k];

    return RotationMatrix(rot);
  }

  /// @brief Calculates a rotation matrix from J2000 mean equator (EQJ) to J2000 mean ecliptic (ECL).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: EQJ = equatorial system, using equator at J2000 epoch.
  /// Target: ECL = ecliptic system, using equator at J2000 epoch.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQJ to ECL.
  static RotationMatrix rotationEQJtoECL() {
    // ob = mean obliquity of the J2000 ecliptic = 0.40909260059599012 radians
    double c = 0.9174821430670688; // cos(ob)
    double s = 0.3977769691083922; // sin(ob)

    return RotationMatrix([
      [1, 0, 0],
      [0, c, -s],
      [0, s, c]
    ]);
  }

  /// @brief Calculates a rotation matrix from J2000 mean ecliptic (ECL) to J2000 mean equator (EQJ).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: ECL = ecliptic system, using equator at J2000 epoch.
  /// Target: EQJ = equatorial system, using equator at J2000 epoch.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts ECL to EQJ.
  static RotationMatrix rotationECLtoEQJ() {
    // ob = mean obliquity of the J2000 ecliptic = 0.40909260059599012 radians
    double c = 0.9174821430670688; // cos(ob)
    double s = 0.3977769691083922; // sin(ob)

    return RotationMatrix([
      [1, 0, 0],
      [0, c, s],
      [0, -s, c]
    ]);
  }

  /// @brief Calculates a rotation matrix from J2000 mean equator (EQJ) to equatorial of-date (EQD).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: EQJ = equatorial system, using equator at J2000 epoch.
  /// Target: EQD = equatorial system, using equator of the specified date/time.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time at which the Earth's equator defines the target orientation.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQJ to EQD at `time`.
  static RotationMatrix rotationEQJtoEQD(dynamic time) {
    time = AstroTime(
        time); // Ensure AstroTime function adjusts for FlexibleDateTime

    // Calculate precession and nutation matrices
    RotationMatrix prec = precessionRot(time, PrecessDirection.From2000);
    RotationMatrix nut = nutationRot(time, PrecessDirection.From2000);

    // Combine precession and nutation matrices
    return combineRotation(prec, nut);
  }

  /// @brief Calculates a rotation matrix from J2000 mean equator (EQJ) to true ecliptic of date (ECT).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: EQJ = equatorial system, using equator at J2000 epoch.
  /// Target: ECT = ecliptic system, using true equinox of the specified date/time.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time at which the Earth's equator defines the target orientation.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQJ to ECT at `time`.
  static RotationMatrix rotationEQJtoECT(dynamic time) {
    final t = AstroTime(time);
    final rot = rotationEQJtoEQD(t);
    final step = rotationEQDtoECT(t);
    return combineRotation(rot, step);
  }

  /// @brief Calculates a rotation matrix from true ecliptic of date (ECT) to J2000 mean equator (EQJ).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: ECT = ecliptic system, using true equinox of the specified date/time.
  /// Target: EQJ = equatorial system, using equator at J2000 epoch.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time at which the Earth's equator defines the target orientation.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts ECT to EQJ at `time`.
  static RotationMatrix rotationECTtoEQJ(dynamic time) {
    final t = AstroTime(time);
    final rot = rotationECTtoEQD(t);
    final step = rotationEQDtoEQJ(t);
    return combineRotation(rot, step);
  }

  /// @brief Calculates a rotation matrix from equatorial of-date (EQD) to J2000 mean equator (EQJ).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: EQD = equatorial system, using equator of the specified date/time.
  /// Target: EQJ = equatorial system, using equator at J2000 epoch.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time at which the Earth's equator defines the source orientation.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQD at `time` to EQJ.
  static RotationMatrix rotationEQDtoEQJ(dynamic time) {
    final t = AstroTime(time);
    final nut = nutationRot(t, PrecessDirection.Into2000);
    final prec = precessionRot(t, PrecessDirection.Into2000);
    return combineRotation(nut, prec);
  }

  /// @brief Calculates a rotation matrix from equatorial of-date (EQD) to horizontal (HOR).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: EQD = equatorial system, using equator of the specified date/time.
  /// Target: HOR = horizontal system.
  ///
  /// Use `HorizonFromVector` to convert the return value
  /// to a traditional altitude/azimuth pair.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time at which the Earth's equator applies.
  ///
  /// @param {Observer} observer
  ///      A location near the Earth's mean sea level that defines the observer's horizon.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQD to HOR at `time` and for `observer`.
  ///      The components of the horizontal vector are:
  ///      x = north, y = west, z = zenith (straight up from the observer).
  ///      These components are chosen so that the "right-hand rule" works for the vector
  ///      and so that north represents the direction where azimuth = 0.
  static RotationMatrix rotationEQDtoHOR(dynamic time, Observer observer) {
    final t = AstroTime(time);
    final sinLat = sin(observer.latitude * pi / 180);
    final cosLat = cos(observer.latitude * pi / 180);
    final sinLon = sin(observer.longitude * pi / 180);
    final cosLon = cos(observer.longitude * pi / 180);

    final List<double> uze = [cosLat * cosLon, cosLat * sinLon, sinLat];
    final List<double> une = [-sinLat * cosLon, -sinLat * sinLon, cosLat];
    final List<double> uwe = [sinLon, -cosLon, 0];

    final spinAngle = -15 * siderealTime(t);
    final uz = spin(spinAngle, uze);
    final un = spin(spinAngle, une);
    final uw = spin(spinAngle, uwe);

    return RotationMatrix([
      [un[0], uw[0], uz[0]],
      [un[1], uw[1], uz[1]],
      [un[2], uw[2], uz[2]],
    ]);
  }

  /// @brief Calculates a rotation matrix from horizontal (HOR) to equatorial of-date (EQD).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: HOR = horizontal system (x=North, y=West, z=Zenith).
  /// Target: EQD = equatorial system, using equator of the specified date/time.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time at which the Earth's equator applies.
  ///
  /// @param {Observer} observer
  ///      A location near the Earth's mean sea level that defines the observer's horizon.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts HOR to EQD at `time` and for `observer`.
  static RotationMatrix rotationHORtoEQD(dynamic time, Observer observer) {
    final rot = rotationEQDtoHOR(time, observer);
    return inverseRotation(rot);
  }

  /// @brief Calculates a rotation matrix from horizontal (HOR) to J2000 equatorial (EQJ).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: HOR = horizontal system (x=North, y=West, z=Zenith).
  /// Target: EQJ = equatorial system, using equator at the J2000 epoch.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time of the observation.
  ///
  /// @param {Observer} observer
  ///      A location near the Earth's mean sea level that defines the observer's horizon.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts HOR to EQJ at `time` and for `observer`.
  static RotationMatrix rotationHORtoEQJ(dynamic time, Observer observer) {
    final t = AstroTime(time);
    final horToEqd = rotationHORtoEQD(t, observer);
    final eqdToEqj = rotationEQDtoEQJ(t);
    return combineRotation(horToEqd, eqdToEqj);
  }

  /// @brief Calculates a rotation matrix from J2000 mean equator (EQJ) to horizontal (HOR).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: EQJ = equatorial system, using the equator at the J2000 epoch.
  /// Target: HOR = horizontal system.
  ///
  /// Use {@link HorizonFromVector} to convert the return value
  /// to a traditional altitude/azimuth pair.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time of the desired horizontal orientation.
  ///
  /// @param {Observer} observer
  ///      A location near the Earth's mean sea level that defines the observer's horizon.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQJ to HOR at `time` and for `observer`.
  ///      The components of the horizontal vector are:
  ///      x = north, y = west, z = zenith (straight up from the observer).
  ///      These components are chosen so that the "right-hand rule" works for the vector
  ///      and so that north represents the direction where azimuth = 0.
  static RotationMatrix rotationEQJtoHOR(dynamic time, Observer observer) {
    final rot = rotationHORtoEQJ(time, observer);
    return inverseRotation(rot);
  }

  /// @brief Calculates a rotation matrix from equatorial of-date (EQD) to J2000 mean ecliptic (ECL).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: EQD = equatorial system, using equator of date.
  /// Target: ECL = ecliptic system, using equator at J2000 epoch.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time of the source equator.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQD to ECL.
  static RotationMatrix rotationEQDtoECL(dynamic time) {
    final eqdToEqj = rotationEQDtoEQJ(time);
    final eqjToEcl = rotationEQJtoECL();
    return combineRotation(eqdToEqj, eqjToEcl);
  }

  /// @brief Calculates a rotation matrix from J2000 mean ecliptic (ECL) to equatorial of-date (EQD).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: ECL = ecliptic system, using equator at J2000 epoch.
  /// Target: EQD = equatorial system, using equator of date.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time of the desired equator.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts ECL to EQD.
  static RotationMatrix rotationECLtoEQD(dynamic time) {
    final rot = rotationEQDtoECL(time);
    return inverseRotation(rot);
  }

  /// @brief Calculates a rotation matrix from J2000 mean ecliptic (ECL) to horizontal (HOR).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: ECL = ecliptic system, using equator at J2000 epoch.
  /// Target: HOR = horizontal system.
  ///
  /// Use {@link HorizonFromVector} to convert the return value
  /// to a traditional altitude/azimuth pair.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time of the desired horizontal orientation.
  ///
  /// @param {Observer} observer
  ///      A location near the Earth's mean sea level that defines the observer's horizon.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts ECL to HOR at `time` and for `observer`.
  ///      The components of the horizontal vector are:
  ///      x = north, y = west, z = zenith (straight up from the observer).
  ///      These components are chosen so that the "right-hand rule" works for the vector
  ///      and so that north represents the direction where azimuth = 0.
  static RotationMatrix rotationECLtoHOR(dynamic time, Observer observer) {
    final t = AstroTime(time);
    final eclToEqd = rotationECLtoEQD(t);
    final eqdToHor = rotationEQDtoHOR(t, observer);
    return combineRotation(eclToEqd, eqdToHor);
  }

  /// @brief Calculates a rotation matrix from horizontal (HOR) to J2000 mean ecliptic (ECL).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: HOR = horizontal system.
  /// Target: ECL = ecliptic system, using equator at J2000 epoch.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time of the horizontal observation.
  ///
  /// @param {Observer} observer
  ///      The location of the horizontal observer.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts HOR to ECL.
  static RotationMatrix rotationHORtoECL(dynamic time, Observer observer) {
    final rot = rotationECLtoHOR(time, observer);
    return inverseRotation(rot);
  }

  /// @brief Calculates a rotation matrix from J2000 mean equator (EQJ) to galactic (GAL).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: EQJ = equatorial system, using the equator at the J2000 epoch.
  /// Target: GAL = galactic system (IAU 1958 definition).
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQJ to GAL.
  static RotationMatrix rotationEQJtoGAL() {
    return RotationMatrix([
      [-0.0548624779711344, 0.4941095946388765, -0.8676668813529025],
      [-0.8734572784246782, -0.4447938112296831, -0.1980677870294097],
      [-0.4838000529948520, 0.7470034631630423, 0.4559861124470794]
    ]);
  }

  /// @brief Calculates a rotation matrix from galactic (GAL) to J2000 mean equator (EQJ).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: GAL = galactic system (IAU 1958 definition).
  /// Target: EQJ = equatorial system, using the equator at the J2000 epoch.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts GAL to EQJ.
  static RotationMatrix rotationGALtoEQJ() {
    return RotationMatrix([
      [-0.0548624779711344, -0.8734572784246782, -0.4838000529948520],
      [0.4941095946388765, -0.4447938112296831, 0.7470034631630423],
      [-0.8676668813529025, -0.1980677870294097, 0.4559861124470794]
    ]);
  }

  /// @brief Calculates a rotation matrix from true ecliptic of date (ECT) to equator of date (EQD).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: ECT = true ecliptic of date
  /// Target: EQD = equator of date
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time of the ecliptic/equator conversion.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts ECT to EQD.
  static RotationMatrix rotationECTtoEQD(dynamic time) {
    final et = eTilt(AstroTime(time));
    final tobl = et.tobl * DEG2RAD;
    final c = cos(tobl);
    final s = sin(tobl);
    return RotationMatrix([
      [1.0, 0.0, 0.0],
      [0.0, c, s],
      [0.0, -s, c]
    ]);
  }

  /// @brief Calculates a rotation matrix from equator of date (EQD) to true ecliptic of date (ECT).
  ///
  /// This is one of the family of functions that returns a rotation matrix
  /// for converting from one orientation to another.
  /// Source: EQD = equator of date
  /// Target: ECT = true ecliptic of date
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time of the equator/ecliptic conversion.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQD to ECT.
  static RotationMatrix rotationEQDtoECT(dynamic time) {
    final et = eTilt(AstroTime(time));
    final tobl = et.tobl * DEG2RAD;
    final c = cos(tobl);
    final s = sin(tobl);
    return RotationMatrix([
      [1.0, 0.0, 0.0],
      [0.0, c, -s],
      [0.0, s, c]
    ]);
  }

  /// @brief Calculates a rotation matrix from Jupiter's equatorial orientation (EQJ) to Jupiter's equatorial orientation (EQJ).
  ///
  /// This rotation matrix is used to convert coordinates between Jupiter's equatorial orientation (EQJ) and itself.
  ///
  /// @returns {RotationMatrix}
  ///      A rotation matrix that converts EQJ to EQJ.
  static RotationMatrix get rotationJUPtoEQJ => RotationMatrix([
        [9.99432765338654e-01, -3.36771074697641e-02, 0.00000000000000e+00],
        [3.03959428906285e-02, 9.02057912352809e-01, 4.30543388542295e-01],
        [-1.44994559663353e-02, -4.30299169409101e-01, 9.02569881273754e-01]
      ]);
}
