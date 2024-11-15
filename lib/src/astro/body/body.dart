// ignore_for_file: constant_identifier_names

import 'package:advance_math/advance_math.dart';

enum BodyType {
  Planet,
  Star,
  Barycenter,
  UserDefinedStar,
}

class Body {
  ///  A string representing the name of the body (e.g., "Sun," "Mars," "Star1")
  final String name;

  /// An enum or string representing the category of the body (e.g., "Planet," "Star," "Barycenter").
  final BodyType type;

  /// The product of mass and universal gravitational constant for the body.
  final double GM;

  /// The physical radius of the body (optional).
  final double? radius; // Optional

  /// The mass of the body (optional, may be inferred from GM)
  final double? mass; // Optional (may be inferred from GM)

  /// The radius of the body at the equator (optional).
  final double? equatorialRadius;

  /// The radius of the body at the poles (optional)
  final double? polarRadius;

  /// The difference between the equatorial and polar radius (optional).
  final double? flattening;

  // Constructor to initialize a Body object
  Body({
    required this.name,
    required this.type,
    required this.GM,
    this.radius,
    this.mass,
    this.equatorialRadius,
    this.polarRadius,
    this.flattening,
  });

  // Methods to calculate astronomical properties (examples)

  // Placeholder for calculating position in space
  Vector? calculatePosition(DateTime time) {
    // Placeholder logic (would likely involve specific astronomical calculations)
    return null;
  }

  // Placeholder for calculating velocity in space
  Vector? calculateVelocity(DateTime time) {
    // Placeholder logic (would likely involve specific astronomical calculations)
    return null;
  }

  // Placeholder for calculating phase angle (for Moon or other bodies)
  double? calculatePhase(DateTime time, Vector observerPosition) {
    // Placeholder logic (would likely involve specific astronomical calculations)
    return null;
  }

  // Placeholder for calculating rise and set times (for Sun or Moon)
  List<DateTime>? calculateRiseSet(DateTime time, Vector observerPosition) {
    // Placeholder logic (would likely involve specific astronomical calculations)
    return null;
  }

  // Placeholder for calculating angular size
  double? calculateAngularSize(Vector observerPosition) {
    // Placeholder logic (would likely involve specific astronomical calculations)
    return null;
  }
}
