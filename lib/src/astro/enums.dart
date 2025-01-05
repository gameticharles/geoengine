// ignore_for_file: constant_identifier_names

part of 'astronomy.dart';

/// @brief String constants that represent the solar system bodies supported by Astronomy Engine.
///
/// The following strings represent solar system bodies supported by various Astronomy Engine functions.
/// Not every body is supported by every function; consult the documentation for each function
/// to find which bodies it supports.
///
/// "Sun", "Moon", "Mercury", "Venus", "Earth", "Mars", "Jupiter",
/// "Saturn", "Uranus", "Neptune", "Pluto",
/// "SSB" (Solar System Barycenter),
/// "EMB" (Earth/Moon Barycenter)
///
/// You can also use enumeration syntax for the bodies, like
/// `Astronomy.Body.Moon`, `Astronomy.Body.Jupiter`, etc.
///
/// @enum {string}
enum Body {
  Sun,
  Moon,
  Mercury,
  Venus,
  Earth,
  Mars,
  Jupiter,
  Saturn,
  Uranus,
  Neptune,
  Pluto,
  SSB,
  EMB,
  // User-defined fixed locations in the sky...
  Star1,
  Star2,
  Star3,
  Star4,
  Star5,
  Star6,
  Star7,
  Star8,
}

enum PrecessDirection { From2000, Into2000 }

/// @brief The different kinds of lunar/solar eclipses..
///
/// `Penumbral`: A lunar eclipse in which only the Earth's penumbra falls on the Moon. (Never used for a solar eclipse.)
/// `Partial`: A partial lunar/solar eclipse.
/// `Annular`: A solar eclipse in which the entire Moon is visible against the Sun, but the Sun appears as a ring around the Moon. (Never used for a lunar eclipse.)
/// `Total`: A total lunar/solar eclipse.
///
/// @enum {string}
enum EclipseKind {
  /// A lunar eclipse in which only the Earth's penumbra falls on the Moon. (Never used for a solar eclipse.)
  Penumbral,

  /// A partial lunar/solar eclipse.
  Partial,

  /// A solar eclipse in which the entire Moon is visible against the Sun, but the Sun appears as a ring around the Moon. (Never used for a lunar eclipse.)
  Annular,

  /// A total lunar/solar eclipse.
  Total,
}

enum Eclipses {
  /// A lunar eclipse.
  lunar,

  /// A solar eclipse.
  solar,

  /// A lunar/solar eclipse.
  all
}

/// @brief The two kinds of apsis: pericenter (closest) and apocenter (farthest).
///
/// `Pericenter`: The body is at its closest distance to the object it orbits.
/// `Apocenter`:  The body is at its farthest distance from the object it orbits.
///
/// @enum {number}
enum ApsisKind {
  Pericenter,
  Apocenter,
}

///  A Full or New Moon that occurs when the center of the Moon is
/// less than 360,000 kilometers (ca. 223,694 miles) from the center of Earth.
///
///  A Full Moon or New Moon that takes place when the center of the Moon
/// is farther than 405,000 kilometers (ca. 251,655 miles) from the center of Earth.
/// 
/// source: https://en.wikipedia.org/wiki/Moon_phases, https://timeanddate.com
enum SpecialMoon {
  /// When a Full Moon takes place when the Moon is near its closest approach
  /// to Earth, it is called a Super Full Moon.
  SuperFullMoon,

  /// When there is a New Moon around the closest point to Earth,
  /// it is known as a Super New Moon.
  SuperNewMoon,

  /// When a Full Moon takes place when the Moon is near its farthest approach
  /// to Earth, it is called a Micro Full Moon.
  MicroFullMoon,

  /// When there is a New Moon around the farthest point to Earth,
  /// it is known as a Micro New Moon.
  MicroNewMoon,
}
