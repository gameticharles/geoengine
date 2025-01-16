part of '../astronomy.dart';

class GravSimEndpoint {
  AstroTime time;
  Map<String, BodyState> gravitators;
  List<BodyGravCalc> bodies;

  GravSimEndpoint(this.time, this.gravitators, this.bodies);
}

/// A simulation of zero or more small bodies moving through the Solar System.
///
/// This class calculates the movement of arbitrary small bodies,
/// such as asteroids or comets, that move through the Solar System.
/// It does so by calculating the gravitational forces on the small bodies
/// from the Sun and planets. The user of this class supplies a
/// list of initial positions and velocities for the small bodies.
/// Then the class can update the positions and velocities over small
/// time steps.
class GravitySimulator {
  late Body originBody;
  late GravSimEndpoint prev;
  late GravSimEndpoint curr;

  GravitySimulator(
      this.originBody, dynamic date, List<StateVector> bodyStates) {
    final time = AstroTime(date);

    // Verify that the state vectors have matching times.
    for (var b in bodyStates) {
      if (b.t.tt != time.tt) {
        throw 'Inconsistent times in bodyStates';
      }
    }

    // Create a stub list that we append to later.
    // We just need the stub to put into `this.curr`.
    final smallBodyList = <BodyGravCalc>[];

    // Calculate the states of the Sun and planets.
    final largeBodyDict = GravitySimulator.calcSolarSystem(time);
    curr = GravSimEndpoint(time, largeBodyDict, smallBodyList);

    // Convert origin-centric bodyStates vectors into barycentric body_grav_calc_t array.
    final o = internalBodyState(originBody);
    for (var b in bodyStates) {
      final r = TerseVector(b.x + o.r.x, b.y + o.r.y, b.z + o.r.z);
      final v = TerseVector(b.vx + o.v.x, b.vy + o.v.y, b.vz + o.v.z);
      final a = TerseVector.zero();
      smallBodyList.add(BodyGravCalc(time.tt, r, v, a));
    }

    // Calculate the net acceleration experienced by the small bodies.
    calcBodyAccelerations();

    // To prepare for a possible swap operation, duplicate the current state into the previous state.
    prev = duplicate();
  }

  Body get bodyOrigin => originBody;

  AstroTime get time => curr.time;

  List<StateVector> update(dynamic date) {
    final time = AstroTime(date);
    final dt = time.tt - curr.time.tt;
    if (dt == 0.0) {
      // Special case: the time has not changed, so skip the usual physics calculations.
      // This allows another way for the caller to query the current body states.
      // It is also necessary to avoid dividing by `dt` if `dt` is zero.
      // To prepare for a possible swap operation, duplicate the current state into the previous state.
      prev = duplicate();
    } else {
      // Exchange the current state with the previous state. Then calculate the new current state.
      swap();

      // Update the current time.
      curr.time = time;

      // Calculate the positions and velocities of the Sun and planets at the given time.
      curr.gravitators = GravitySimulator.calcSolarSystem(time);

      // Estimate the positions of the small bodies as if their existing
      // accelerations apply across the whole time interval.
      for (var i = 0; i < curr.bodies.length; ++i) {
        final p = prev.bodies[i];
        curr.bodies[i].r = TerseVector.updatePosition(dt, p.r, p.v, p.a);
      }

      // Calculate the acceleration experienced by the small bodies at
      // their respective approximate next locations.
      calcBodyAccelerations();

      for (var i = 0; i < curr.bodies.length; ++i) {
        // Calculate the average of the acceleration vectors
        // experienced by the previous body positions and
        // their estimated next positions.
        // These become estimates of the mean effective accelerations
        // over the whole interval.
        final p = prev.bodies[i];
        final c = curr.bodies[i];
        final acc = p.a.mean(c.a);

        // Refine the estimates of position and velocity at the next time step,
        // using the mean acceleration as a better approximation of the
        // continuously changing acceleration acting on each body.
        c.tt = time.tt;
        c.r = TerseVector.updatePosition(dt, p.r, p.v, acc);
        c.v = TerseVector.updateVelocity(dt, p.v, acc);
      }

      // Re-calculate accelerations experienced by each body.
      // These will be needed for the next simulation step (if any).
      // Also, they will be potentially useful if some day we add
      // a function to query the acceleration vectors for the bodies.
      calcBodyAccelerations();
    }

    // Translate our internal calculations of body positions and velocities
    // into state vectors that the caller can understand.
    // We have to convert the internal type body_grav_calc_t to the public type StateVector.
    // Also convert from barycentric coordinates to coordinates based on the selected origin body.
    final bodyStates = <StateVector>[];
    final ostate = internalBodyState(originBody);
    for (var bCalc in curr.bodies) {
      bodyStates.add(StateVector(
        bCalc.r.x - ostate.r.x,
        bCalc.r.y - ostate.r.y,
        bCalc.r.z - ostate.r.z,
        bCalc.v.x - ostate.v.x,
        bCalc.v.y - ostate.v.y,
        bCalc.v.z - ostate.v.z,
        time,
      ));
    }
    return bodyStates;
  }

  void swap() {
    final swap = curr;
    curr = prev;
    prev = swap;
  }

  StateVector solarSystemBodyState(Body body) {
    final bState = internalBodyState(body);
    final oState = internalBodyState(originBody);
    return exportState(bState.sub(oState), curr.time);
  }

  BodyState internalBodyState(Body body) {
    if (body == Body.SSB) {
      return BodyState(curr.time.tt, TerseVector.zero(), TerseVector.zero());
    }

    final bState = curr.gravitators[body.name];
    if (bState != null) {
      return bState;
    }

    throw 'Invalid body: $body';
  }

  static Map<String, BodyState> calcSolarSystem(AstroTime time) {
    final dict = <String, BodyState>{};

    // Start with the SSB at zero position and velocity.
    final ssb = BodyState(time.tt, TerseVector.zero(), TerseVector.zero());

    // Calculate the heliocentric position of each planet, and adjust the SSB
    // based each planet's pull on the Sun.
    dict[Body.Mercury.name] =
        adjustBarycenterPosVel(ssb, time.tt, Body.Mercury, MERCURY_GM);
    dict[Body.Venus.name] =
        adjustBarycenterPosVel(ssb, time.tt, Body.Venus, VENUS_GM);
    dict[Body.Earth.name] =
        adjustBarycenterPosVel(ssb, time.tt, Body.Earth, EARTH_GM + MOON_GM);
    dict[Body.Mars.name] =
        adjustBarycenterPosVel(ssb, time.tt, Body.Mars, MARS_GM);
    dict[Body.Jupiter.name] =
        adjustBarycenterPosVel(ssb, time.tt, Body.Jupiter, JUPITER_GM);
    dict[Body.Saturn.name] =
        adjustBarycenterPosVel(ssb, time.tt, Body.Saturn, SATURN_GM);
    dict[Body.Uranus.name] =
        adjustBarycenterPosVel(ssb, time.tt, Body.Uranus, URANUS_GM);
    dict[Body.Neptune.name] =
        adjustBarycenterPosVel(ssb, time.tt, Body.Neptune, NEPTUNE_GM);

    // Convert planet states from heliocentric to barycentric.
    for (var body in dict.keys.toList()) {
      dict[body.toString().split('.').last]!.r.decr(ssb.r);
      dict[body.toString().split('.').last]!.v.decr(ssb.v);
    }

    // Convert heliocentric SSB to barycentric Sun.
    dict[Body.Sun.toString().split('.').last] =
        BodyState(time.tt, ssb.r.neg(), ssb.v.neg());

    return dict;
  }

  void calcBodyAccelerations() {
    // Calculate the gravitational acceleration experienced by the simulated small bodies.
    for (var b in curr.bodies) {
      b.a = TerseVector.zero();
      addAcceleration(b.a, b.r, curr.gravitators[Body.Sun.name]!.r, SUN_GM);
      addAcceleration(
          b.a, b.r, curr.gravitators[Body.Mercury.name]!.r, MERCURY_GM);
      addAcceleration(b.a, b.r, curr.gravitators[Body.Venus.name]!.r, VENUS_GM);
      addAcceleration(
          b.a, b.r, curr.gravitators[Body.Earth.name]!.r, EARTH_GM + MOON_GM);
      addAcceleration(b.a, b.r, curr.gravitators[Body.Mars.name]!.r, MARS_GM);
      addAcceleration(
          b.a, b.r, curr.gravitators[Body.Jupiter.name]!.r, JUPITER_GM);
      addAcceleration(
          b.a, b.r, curr.gravitators[Body.Saturn.name]!.r, SATURN_GM);
      addAcceleration(
          b.a, b.r, curr.gravitators[Body.Uranus.name]!.r, URANUS_GM);
      addAcceleration(
          b.a, b.r, curr.gravitators[Body.Neptune.name]!.r, NEPTUNE_GM);
    }
  }

  static void addAcceleration(
      TerseVector acc, TerseVector smallPos, TerseVector majorPos, double gm) {
    final dx = majorPos.x - smallPos.x;
    final dy = majorPos.y - smallPos.y;
    final dz = majorPos.z - smallPos.z;
    final r2 = dx * dx + dy * dy + dz * dz;
    final pull = gm / (r2 * sqrt(r2));
    acc.x += dx * pull;
    acc.y += dy * pull;
    acc.z += dz * pull;
  }

  GravSimEndpoint duplicate() {
    // Copy the current state into the previous state, so that both become the same moment in time.
    final gravitators = <String, BodyState>{};
    for (var body in curr.gravitators.keys) {
      gravitators[body] = curr.gravitators[body]!.clone();
    }

    final bodies = <BodyGravCalc>[];
    for (var b in curr.bodies) {
      bodies.add(b.clone());
    }

    return GravSimEndpoint(curr.time, gravitators, bodies);
  }
}
