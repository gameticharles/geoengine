part of '../astronomy.dart';

class AstroVector {
  double x;
  double y;
  double z;
  AstroTime time;

  AstroVector(this.x, this.y, this.z, this.time);

  double length() {
    return sqrt(x * x + y * y + z * z);
  }

  static AstroVector fromArray(List<double> av, AstroTime time) {
    return AstroVector(av[0], av[1], av[2], time);
  }

  /// Given apparent angular horizontal coordinates in `sphere`, calculate horizontal vector.
  ///
  /// @param {Spherical} sphere
  ///      A structure that contains apparent horizontal coordinates:
  ///      `lat` holds the refracted altitude angle,
  ///      `lon` holds the azimuth in degrees clockwise from north,
  ///      and `dist` holds the distance from the observer to the object in AU.
  ///
  /// @param {FlexibleDateTime} time
  ///      The date and time of the observation. This is needed because the returned
  ///      vector object requires a valid time value when passed to certain other functions.
  ///
  /// @param {string} refraction
  ///      `"normal"`: correct altitude for atmospheric refraction (recommended).
  ///      `"jplhor"`: for JPL Horizons compatibility testing only; not recommended for normal use.
  ///      `null`: no atmospheric refraction correction is performed.
  ///
  /// @returns {Vector}
  ///      A vector in the horizontal system: `x` = north, `y` = west, and `z` = zenith (up).
  static AstroVector vectorFromHorizon(
      Spherical sphere, dynamic time, RefractionType refraction) {
    time = AstroTime(time);

    // Convert azimuth from clockwise-from-north to counterclockwise-from-north
    double lon = toggleAzimuthDirection(sphere.lon);

    // Reverse any applied refraction
    double lat = sphere.lat + inverseRefraction(refraction, sphere.lat);

    // Create a spherical object with adjusted coordinates
    Spherical adjustedSphere = Spherical(lat, lon, sphere.dist);

    // Convert the adjusted spherical coordinates to a vector
    return vectorFromSphere(adjustedSphere, time);
  }

  /// Converts spherical coordinates to Cartesian coordinates.
  ///
  /// Given spherical coordinates and a time at which they are valid,
  /// returns a vector of Cartesian coordinates. The returned value
  /// includes the time, as required by `AstroTime`.
  ///
  /// @param {Spherical} sphere
  ///      Spherical coordinates to be converted.
  ///
  /// @param {FlexibleDateTime} time
  ///      The time that should be included in the returned vector.
  ///
  /// @returns {Vector}
  ///      The vector form of the supplied spherical coordinates.
  static AstroVector vectorFromSphere(Spherical sphere, dynamic time) {
    time = AstroTime(time);
    final radLat = sphere.lat * DEG2RAD;
    final radLon = sphere.lon * DEG2RAD;
    final rCosLat = sphere.dist * cos(radLat);
    return AstroVector(rCosLat * cos(radLon), rCosLat * sin(radLon),
        sphere.dist * sin(radLat), time);
  }

  /// Applies a rotation to a vector, yielding a rotated vector.
  ///
  /// This function transforms a vector in one orientation to a vector
  /// in another orientation.
  ///
  /// @param {RotationMatrix} rotation
  ///      A rotation matrix that specifies how the orientation of the vector is to be changed.
  ///
  /// @param {Vector} vector
  ///      The vector whose orientation is to be changed.
  ///
  /// @returns {Vector}
  ///      A vector in the orientation specified by `rotation`.
  static AstroVector rotateVector(RotationMatrix rotation, AstroVector vector) {
    return AstroVector(
      rotation.rot[0][0] * vector.x +
          rotation.rot[1][0] * vector.y +
          rotation.rot[2][0] * vector.z,
      rotation.rot[0][1] * vector.x +
          rotation.rot[1][1] * vector.y +
          rotation.rot[2][1] * vector.z,
      rotation.rot[0][2] * vector.x +
          rotation.rot[1][2] * vector.y +
          rotation.rot[2][2] * vector.z,
      vector.time,
    );
  }
}

class TerseVector {
  double x, y, z;

  TerseVector(this.x, this.y, this.z);

  TerseVector clone() {
    return TerseVector(x, y, z);
  }

  AstroVector toAstroVector(AstroTime t) {
    return AstroVector(x, y, z, t);
  }

  static TerseVector zero() {
    return TerseVector(0, 0, 0);
  }

  double quadrature() {
    return x * x + y * y + z * z;
  }

  TerseVector add(TerseVector other) {
    return TerseVector(x + other.x, y + other.y, z + other.z);
  }

  TerseVector sub(TerseVector other) {
    return TerseVector(x - other.x, y - other.y, z - other.z);
  }

  void incr(TerseVector other) {
    x += other.x;
    y += other.y;
    z += other.z;
  }

  void decr(TerseVector other) {
    x -= other.x;
    y -= other.y;
    z -= other.z;
  }

  TerseVector mul(double scalar) {
    return TerseVector(scalar * x, scalar * y, scalar * z);
  }

  TerseVector div(double scalar) {
    return TerseVector(x / scalar, y / scalar, z / scalar);
  }

  TerseVector mean(TerseVector other) {
    return TerseVector(
      (x + other.x) / 2,
      (y + other.y) / 2,
      (z + other.z) / 2,
    );
  }

  TerseVector neg() {
    return TerseVector(-x, -y, -z);
  }

  static TerseVector updatePosition(
      double dt, TerseVector r, TerseVector v, TerseVector a) {
    return TerseVector(r.x + dt * (v.x + dt * a.x / 2),
        r.y + dt * (v.y + dt * a.y / 2), r.z + dt * (v.z + dt * a.z / 2));
  }

  static TerseVector updateVelocity(double dt, TerseVector v, TerseVector a) {
    return TerseVector(v.x + dt * a.x, v.y + dt * a.y, v.z + dt * a.z);
  }
}
