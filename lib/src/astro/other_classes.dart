// ignore_for_file: non_constant_identifier_names

part of 'astronomy.dart';

class PascalArray1 {
  int min;
  List<double> array;
  PascalArray1({required this.min, required this.array});
}

class PascalArray2 {
  int min;
  List<PascalArray1> array;
  PascalArray2({required this.min, required this.array});
}

class ComplexValue {
  double x;
  double y;

  ComplexValue(this.x, this.y);
}

typedef ThetaFunc = Function(double real, double imag);

class PlanetInfo {
  final double orbitalPeriod;

  PlanetInfo(this.orbitalPeriod);
}

class InterpResult {
  final double t;
  final double dfDt;

  InterpResult(this.t, this.dfDt);
}

class SearchOptions {
  final double? dtToleranceSeconds;
  final double? initF1;
  final double? initF2;
  final int? iterLimit;

  SearchOptions({
    this.dtToleranceSeconds,
    this.initF1,
    this.initF2,
    this.iterLimit,
  });
}

/// @ignore
///
/// @brief The state of a body at an incremental step in a gravity simulation.
///
/// This is an internal data structure used to represent the
/// position, velocity, and acceleration vectors of a body
/// in a gravity simulation at a given moment in time.
///
/// @property tt
///      The J2000 terrestrial time of the state `days`.
///
/// @property r
///      The position vector `au`.
///
/// @property v
///      The velocity vector `au/day`.
///
/// @property a
///      The acceleration vector `au/day^2`.
class BodyGravCalc {
  double tt;
  TerseVector r;
  TerseVector v;
  TerseVector a;

  BodyGravCalc(this.tt, this.r, this.v, this.a);

  BodyGravCalc clone() {
    return BodyGravCalc(tt, r.clone(), v.clone(), a.clone());
  }
}

class MajorBodies {
  late BodyState Jupiter;
  late BodyState Saturn;
  late BodyState Uranus;
  late BodyState Neptune;
  late BodyState Sun;

  MajorBodies(double tt) {
    // Accumulate the Solar System Barycenter position.
    var ssb = BodyState(tt, TerseVector(0, 0, 0), TerseVector(0, 0, 0));

    Jupiter = adjustBarycenterPosVel(ssb, tt, Body.Jupiter, JUPITER_GM);
    Saturn = adjustBarycenterPosVel(ssb, tt, Body.Saturn, SATURN_GM);
    Uranus = adjustBarycenterPosVel(ssb, tt, Body.Uranus, URANUS_GM);
    Neptune = adjustBarycenterPosVel(ssb, tt, Body.Neptune, NEPTUNE_GM);

    // Convert planets' [pos, vel] vectors from heliocentric to barycentric.
    Jupiter.r.decr(ssb.r);
    Jupiter.v.decr(ssb.v);

    Saturn.r.decr(ssb.r);
    Saturn.v.decr(ssb.v);

    Uranus.r.decr(ssb.r);
    Uranus.v.decr(ssb.v);

    Neptune.r.decr(ssb.r);
    Neptune.v.decr(ssb.v);

    // Convert heliocentric SSB to barycentric Sun.
    Sun = BodyState(tt, ssb.r.mul(-1), ssb.v.mul(-1));
  }

  TerseVector acceleration(TerseVector pos) {
    // Use barycentric coordinates of the Sun and major planets to calculate
    // the gravitational acceleration vector experienced at location 'pos'.
    var acc = accelerationIncrement(pos, SUN_GM, Sun.r);
    acc.incr(accelerationIncrement(pos, JUPITER_GM, Jupiter.r));
    acc.incr(accelerationIncrement(pos, SATURN_GM, Saturn.r));
    acc.incr(accelerationIncrement(pos, URANUS_GM, Uranus.r));
    acc.incr(accelerationIncrement(pos, NEPTUNE_GM, Neptune.r));
    return acc;
  }
}

class GravSimT {
  MajorBodies bary;
  BodyGravCalc grav;

  GravSimT(this.bary, this.grav);
}

/// @brief Indicates whether a crossing through the ecliptic plane is ascending or descending.
///
/// `Invalid` is a placeholder for an unknown or missing node.
/// `Ascending` indicates a body passing through the ecliptic plane from south to north.
/// `Descending` indicates a body passing through the ecliptic plane from north to south.
///
/// @enum {number}
class NodeEventKind {
  final int value;
  const NodeEventKind._internal(this.value);

  static const invalid = NodeEventKind._internal(0);
  static const ascending = NodeEventKind._internal(1);
  static const descending = NodeEventKind._internal(-1);

  @override
  String toString() {
    switch (value) {
      case 0:
        return 'Invalid';
      case 1:
        return 'Ascending';
      case -1:
        return 'Descending';
      default:
        return 'Unknown';
    }
  }
}

/// @brief Information about an ascending or descending node of a body.
///
/// This object is returned by {@link SearchMoonNode} and {@link NextMoonNode}
/// to report information about the center of the Moon passing through the ecliptic plane.
///
/// @property {NodeEventKind} kind   Whether the node is ascending (south to north) or descending (north to south).
/// @property {AstroTime} time       The time when the body passes through the ecliptic plane.
class NodeEventInfo {
  final NodeEventKind kind;
  final AstroTime time;

  NodeEventInfo(this.kind, this.time);
}

class InferiorPlanetEntry {
  final double s1;
  final double s2;

  InferiorPlanetEntry(this.s1, this.s2);
}

class InferiorPlanetTable {
  final Map<String, InferiorPlanetEntry> table;

  InferiorPlanetTable(this.table);

  InferiorPlanetEntry? operator [](Body body) {
    return table[body.toString()];
  }
}

class AscentInfo {
  final AstroTime tx;
  final AstroTime ty;
  final double ax;
  final double ay;

  AscentInfo(this.tx, this.ty, this.ax, this.ay);

  static AscentInfo? findAscent(int depth, double Function(AstroTime t) altdiff,
      double maxDerivAlt, AstroTime t1, AstroTime t2, double a1, double a2) {
    // See if we can find any time interval where the altitude-diff function
    // rises from non-positive to positive.

    if (a1 < 0.0 && a2 >= 0.0) {
      // Trivial success case: the endpoints already rise through zero.
      return AscentInfo(t1, t2, a1, a2);
    }

    if (a1 >= 0.0 && a2 < 0.0) {
      // Trivial failure case: Assume Nyquist condition prevents an ascent.
      return null;
    }

    if (depth > 17) {
      // Safety valve: do not allow unlimited recursion.
      // This should never happen if the rest of the logic is working correctly,
      // so fail the whole search if it does happen. It's a bug!
      throw Exception('Excessive recursion in rise/set ascent search.');
    }

    // Both altitudes are on the same side of zero: both are negative, or both are non-negative.
    // There could be a convex "hill" or a concave "valley" that passes through zero.
    // In polar regions sometimes there is a rise/set or set/rise pair within minutes of each other.
    // For example, the Moon can be below the horizon, then the very top of it becomes
    // visible (moonrise) for a few minutes, then it moves sideways and down below
    // the horizon again (moonset). We want to catch these cases.
    // However, for efficiency and practicality concerns, because the rise/set search itself
    // has a 0.1 second threshold, we do not worry about rise/set pairs that are less than
    // one second apart. These are marginal cases that are rendered highly uncertain
    // anyway, due to unpredictable atmospheric refraction conditions (air temperature and pressure).

    final dt = t2.ut - t1.ut;
    if (dt * SECONDS_PER_DAY < 1.0) {
      return null;
    }

    // Is it possible to reach zero from the altitude that is closer to zero?
    final da = a1.abs().compareTo(a2.abs()) <= 0 ? a1.abs() : a2.abs();

    // Without loss of generality, assume |a1| <= |a2|.
    // (Reverse the argument in the case |a2| < |a1|.)
    // Imagine you have to "drive" from a1 to 0, then back to a2.
    // You can't go faster than max_deriv_alt. If you can't reach 0 in half the time,
    // you certainly don't have time to reach 0, turn around, and still make your way
    // back up to a2 (which is at least as far from 0 than a1 is) in the time interval dt.
    // Therefore, the time threshold is half the time interval, or dt/2.
    if (da > maxDerivAlt * (dt / 2)) {
      // Prune: the altitude cannot change fast enough to reach zero.
      return null;
    }

    // Bisect the time interval and evaluate the altitude at the midpoint.
    final tmid = AstroTime((t1.ut + t2.ut) / 2);
    final amid = altdiff(tmid);

    // Use recursive bisection to search for a solution bracket.
    return findAscent(depth + 1, altdiff, maxDerivAlt, t1, tmid, a1, amid) ??
        findAscent(depth + 1, altdiff, maxDerivAlt, tmid, t2, amid, a2);
  }
}

/// @brief Horizontal position of a body upon reaching an hour angle.
///
/// Returns information about an occurrence of a celestial body
/// reaching a given hour angle as seen by an observer at a given
/// location on the surface of the Earth.
///
/// @property {AstroTime} time
///      The date and time of the celestial body reaching the hour angle.
///
/// @property {HorizontalCoordinates} hor
///      Topocentric horizontal coordinates for the body
///      at the time indicated by the `time` property.
class HourAngleEvent {
  AstroTime time;
  HorizontalCoordinates hor;

  HourAngleEvent(this.time, this.hor);
}
