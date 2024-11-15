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
  Penumbral,
  Partial,
  Annular,
  Total,
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
