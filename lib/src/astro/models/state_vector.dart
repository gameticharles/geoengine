part of '../astronomy.dart';

/// @brief A combination of a position vector, a velocity vector, and a time.
///
/// Holds the state vector of a body at a given time, including its position,
/// velocity, and the time they are valid.
///
/// @property {number} x        The position x-coordinate expressed in astronomical units (AU).
/// @property {number} y        The position y-coordinate expressed in astronomical units (AU).
/// @property {number} z        The position z-coordinate expressed in astronomical units (AU).
/// @property {number} vx       The velocity x-coordinate expressed in AU/day.
/// @property {number} vy       The velocity y-coordinate expressed in AU/day.
/// @property {number} vz       The velocity z-coordinate expressed in AU/day.
/// @property {AstroTime} t     The time at which the vector is valid.
class StateVector {
  final double x;
  final double y;
  final double z;
  final double vx;
  final double vy;
  final double vz;
  final AstroTime t;

  StateVector(
    this.x,
    this.y,
    this.z,
    this.vx,
    this.vy,
    this.vz,
    this.t,
  );

  /// @brief Applies a rotation to a state vector, yielding a rotated vector.
  ///
  /// This function transforms a state vector in one orientation to a vector
  /// in another orientation.
  ///
  /// @param {RotationMatrix} rotation
  ///      A rotation matrix that specifies how the orientation of the state vector is to be changed.
  ///
  /// @param {StateVector} state
  ///      The state vector whose orientation is to be changed.
  ///      Both the position and velocity components are transformed.
  ///
  /// @return {StateVector}
  ///      A state vector in the orientation specified by `rotation`.
  static StateVector rotateState(RotationMatrix rotation, StateVector state) {
    return StateVector(
        rotation.rot[0][0] * state.x +
            rotation.rot[1][0] * state.y +
            rotation.rot[2][0] * state.z,
        rotation.rot[0][1] * state.x +
            rotation.rot[1][1] * state.y +
            rotation.rot[2][1] * state.z,
        rotation.rot[0][2] * state.x +
            rotation.rot[1][2] * state.y +
            rotation.rot[2][2] * state.z,
        rotation.rot[0][0] * state.vx +
            rotation.rot[1][0] * state.vy +
            rotation.rot[2][0] * state.vz,
        rotation.rot[0][1] * state.vx +
            rotation.rot[1][1] * state.vy +
            rotation.rot[2][1] * state.vz,
        rotation.rot[0][2] * state.vx +
            rotation.rot[1][2] * state.vy +
            rotation.rot[2][2] * state.vz,
        state.t);
  }

  static StateVector precessionPosVel(
      StateVector state, AstroTime time, PrecessDirection dir) {
    final r = RotationMatrix.precessionRot(time, dir);
    return rotateState(r, state);
  }

  static StateVector nutationPosVel(
      StateVector state, AstroTime time, PrecessDirection dir) {
    final r = RotationMatrix.nutationRot(time, dir);
    return rotateState(r, state);
  }

  static StateVector gyrationPosVel(
      StateVector state, AstroTime time, PrecessDirection dir) {
    // Combine nutation and precession into a single operation I call "gyration".
    // The order they are composed depends on the direction,
    // because both directions are mutual inverse functions.
    if (dir == PrecessDirection.Into2000) {
      return precessionPosVel(nutationPosVel(state, time, dir), time, dir);
    } else {
      return nutationPosVel(precessionPosVel(state, time, dir), time, dir);
    }
  }

  /// @brief Calculates one of the 5 Lagrange points from body masses and state vectors.
  ///
  /// Given a more massive "major" body and a much less massive "minor" body,
  /// calculates one of the five Lagrange points in relation to the minor body's
  /// orbit around the major body. The parameter `point` is an integer that
  /// selects the Lagrange point as follows:
  ///
  /// 1 = the Lagrange point between the major body and minor body.
  /// 2 = the Lagrange point on the far side of the minor body.
  /// 3 = the Lagrange point on the far side of the major body.
  /// 4 = the Lagrange point 60 degrees ahead of the minor body's orbital position.
  /// 5 = the Lagrange point 60 degrees behind the minor body's orbital position.
  ///
  /// The caller passes in the state vector and mass for both bodies.
  /// The state vectors can be in any orientation and frame of reference.
  /// The body masses are expressed as GM products, where G = the universal
  /// gravitation constant and M = the body's mass. Thus the units for
  /// `major_mass` and `minor_mass` must be au^3/day^2.
  /// Use {@link MassProduct} to obtain GM values for various solar system bodies.
  ///
  /// The function returns the state vector for the selected Lagrange point
  /// using the same orientation as the state vector parameters `major_state` and `minor_state`,
  /// and the position and velocity components are with respect to the major body's center.
  ///
  /// Consider calling {@link LagrangePoint}, instead of this function, for simpler usage in most cases.
  ///
  /// @param {number} point
  ///      A value 1..5 that selects which of the Lagrange points to calculate.
  ///
  /// @param {StateVector} major_state
  ///      The state vector of the major (more massive) of the pair of bodies.
  ///
  /// @param {number} major_mass
  ///      The mass product GM of the major body.
  ///
  /// @param {StateVector} minor_state
  ///      The state vector of the minor (less massive) of the pair of bodies.
  ///
  /// @param {number} minor_mass
  ///      The mass product GM of the minor body.
  ///
  /// @returns {StateVector}
  ///      The position and velocity of the selected Lagrange point with respect to the major body's center.
  static StateVector lagrangePointFast(
    int point,
    StateVector majorState,
    double majorMass,
    StateVector minorState,
    double minorMass,
  ) {
    const double cos60 = 0.5;
    const double sin60 = 0.8660254037844386; // sqrt(3) / 2

    if (point < 1 || point > 5) {
      throw Exception('Invalid lagrange point $point');
    }

    if (!majorMass.isFinite || majorMass <= 0.0) {
      throw Exception('Major mass must be a positive number.');
    }

    if (!minorMass.isFinite || minorMass <= 0.0) {
      throw Exception('Minor mass must be a positive number.');
    }

    // Find the relative position vector <dx, dy, dz>.
    var dx = minorState.x - majorState.x;
    var dy = minorState.y - majorState.y;
    var dz = minorState.z - majorState.z;
    final R2 = (dx * dx + dy * dy + dz * dz);

    // R = Total distance between the bodies.
    final R = sqrt(R2);

    // Find the relative velocity vector <vx, vy, vz>.
    final vx = minorState.vx - majorState.vx;
    final vy = minorState.vy - majorState.vy;
    final vz = minorState.vz - majorState.vz;

    StateVector p;
    if (point == 4 || point == 5) {
      // For L4 and L5, we need to find points 60 degrees away from the
      // line connecting the two bodies and in the instantaneous orbital plane.
      // Define the instantaneous orbital plane as the unique plane that contains
      // both the relative position vector and the relative velocity vector.

      // Take the cross product of position and velocity to find a normal vector <nx, ny, nz>.
      final nx = dy * vz - dz * vy;
      final ny = dz * vx - dx * vz;
      final nz = dx * vy - dy * vx;

      // Take the cross product normal*position to get a tangential vector <ux, uy, uz>.
      var ux = ny * dz - nz * dy;
      var uy = nz * dx - nx * dz;
      var uz = nx * dy - ny * dx;

      // Convert the tangential direction vector to a unit vector.
      final U = sqrt(ux * ux + uy * uy + uz * uz);
      ux /= U;
      uy /= U;
      uz /= U;

      // Convert the relative position vector into a unit vector.
      dx /= R;
      dy /= R;
      dz /= R;

      // Now we have two perpendicular unit vectors in the orbital plane: 'd' and 'u'.

      // Create new unit vectors rotated (+/-)60 degrees from the radius/tangent directions.
      final vert = (point == 4) ? sin60 : -sin60;

      // Rotated radial vector
      final Dx = cos60 * dx + vert * ux;
      final Dy = cos60 * dy + vert * uy;
      final Dz = cos60 * dz + vert * uz;

      // Rotated tangent vector
      final Ux = cos60 * ux - vert * dx;
      final Uy = cos60 * uy - vert * dy;
      final Uz = cos60 * uz - vert * dz;

      // Calculate L4/L5 positions relative to the major body.
      final px = R * Dx;
      final py = R * Dy;
      final pz = R * Dz;

      // Use dot products to find radial and tangential components of the relative velocity.
      final vrad = vx * dx + vy * dy + vz * dz;
      final vtan = vx * ux + vy * uy + vz * uz;

      // Calculate L4/L5 velocities.
      final pvx = vrad * Dx + vtan * Ux;
      final pvy = vrad * Dy + vtan * Uy;
      final pvz = vrad * Dz + vtan * Uz;

      p = StateVector(px, py, pz, pvx, pvy, pvz, majorState.t);
    } else {
      // Calculate the distances of each body from their mutual barycenter.
      // r1 = negative distance of major mass from barycenter (e.g. Sun to the left of barycenter)
      // r2 = positive distance of minor mass from barycenter (e.g. Earth to the right of barycenter)
      final r1 = -R * (minorMass / (majorMass + minorMass));
      final r2 = R * (majorMass / (majorMass + minorMass));

      // Calculate the square of the angular orbital speed in [rad^2 / day^2].
      final omega2 = (majorMass + minorMass) / (R2 * R);

      // Use Newton's Method to numerically solve for the location where
      // outward centrifugal acceleration in the rotating frame of reference
      // is equal to net inward gravitational acceleration.
      // First derive a good initial guess based on approximate analysis.
      double scale, numer1, numer2;
      if (point == 1 || point == 2) {
        scale = (majorMass / (majorMass + minorMass)) *
            pow(minorMass / (3.0 * majorMass), 1 / 3);
        numer1 = -majorMass; // The major mass is to the left of L1 and L2.
        if (point == 1) {
          scale = 1.0 - scale;
          numer2 = minorMass; // The minor mass is to the right of L1.
        } else {
          scale = 1.0 + scale;
          numer2 = -minorMass; // The minor mass is to the left of L2.
        }
      } else if (point == 3) {
        scale =
            ((7.0 / 12.0) * minorMass - majorMass) / (minorMass + majorMass);
        numer1 = majorMass; // major mass is to the right of L3.
        numer2 = minorMass; // minor mass is to the right of L3.
      } else {
        throw Exception(
            'Invalid Langrage point $point. Must be an integer 1..5.');
      }

      // Iterate Newton's Method until it converges.
      var x = R * scale - r1;
      double deltax;
      do {
        final dr1 = x - r1;
        final dr2 = x - r2;
        final accel = omega2 * x + numer1 / (dr1 * dr1) + numer2 / (dr2 * dr2);
        final deriv = omega2 -
            2 * numer1 / (dr1 * dr1 * dr1) -
            2 * numer2 / (dr2 * dr2 * dr2);
        deltax = accel / deriv;
        x -= deltax;
      } while ((deltax / R).abs() > 1.0e-14);
      scale = (x - r1) / R;
      p = StateVector(scale * dx, scale * dy, scale * dz, scale * vx,
          scale * vy, scale * vz, majorState.t);
    }
    return p;
  }

  /// @brief Calculates one of the 5 Lagrange points for a pair of co-orbiting bodies.
  ///
  /// Given a more massive "major" body and a much less massive "minor" body,
  /// calculates one of the five Lagrange points in relation to the minor body's
  /// orbit around the major body. The parameter `point` is an integer that
  /// selects the Lagrange point as follows:
  ///
  /// 1 = the Lagrange point between the major body and minor body.
  /// 2 = the Lagrange point on the far side of the minor body.
  /// 3 = the Lagrange point on the far side of the major body.
  /// 4 = the Lagrange point 60 degrees ahead of the minor body's orbital position.
  /// 5 = the Lagrange point 60 degrees behind the minor body's orbital position.
  ///
  /// The function returns the state vector for the selected Lagrange point
  /// in J2000 mean equator coordinates (EQJ), with respect to the center of the
  /// major body.
  ///
  /// To calculate Sun/Earth Lagrange points, pass in `Body.Sun` for `major_body`
  /// and `Body.EMB` (Earth/Moon barycenter) for `minor_body`.
  /// For Lagrange points of the Sun and any other planet, pass in that planet
  /// (e.g. `Body.Jupiter`) for `minor_body`.
  /// To calculate Earth/Moon Lagrange points, pass in `Body.Earth` and `Body.Moon`
  /// for the major and minor bodies respectively.
  ///
  /// In some cases, it may be more efficient to call {@link LagrangePointFast},
  /// especially when the state vectors have already been calculated, or are needed
  /// for some other purpose.
  ///
  /// @param {number} point
  ///      An integer 1..5 that selects which of the Lagrange points to calculate.
  ///
  /// @param {FlexibleDateTime} date
  ///      The time at which the Lagrange point is to be calculated.
  ///
  /// @param {Body} major_body
  ///      The more massive of the co-orbiting bodies: `Body.Sun` or `Body.Earth`.
  ///
  /// @param {Body} minor_body
  ///      The less massive of the co-orbiting bodies. See main remarks.
  ///
  /// @returns {StateVector}
  ///      The position and velocity of the selected Lagrange point with respect to the major body's center.
  static StateVector lagrangePoint(
    int point,
    dynamic date,
    Body majorBody,
    Body minorBody,
  ) {
    final time = AstroTime(date);
    final majorMass = massProduct(majorBody);
    final minorMass = massProduct(minorBody);

    StateVector majorState;
    StateVector minorState;

    // Calculate the state vectors for the major and minor bodies.
    if (majorBody == Body.Earth && minorBody == Body.Moon) {
      // Use geocentric calculations for more precision.
      // The Earth's geocentric state is trivial.
      majorState = StateVector(0, 0, 0, 0, 0, 0, time);
      minorState = Moon.geoMoonState(time);
    } else {
      majorState = helioState(majorBody, time);
      minorState = helioState(minorBody, time);
    }

    return lagrangePointFast(
      point,
      majorState,
      majorMass,
      minorState,
      minorMass,
    );
  }
}
