part of '../../../geoengine.dart';

/// Enumeration representing the orientation of an axis.
enum AxisOrientationEnum {
  /// Unknown or unspecified axis orientation.
  /// Used for local or fitted coordinate systems.
  other,

  /// Increasing ordinate values go North.
  /// Typically used for Grid Y coordinates and Latitude.
  north,

  /// Increasing ordinate values go South. Rarely used.
  south,

  /// Increasing ordinate values go East. Rarely used.
  east,

  /// Increasing ordinate values go West.
  /// Typically used for Grid X coordinates and Longitude.
  west,

  /// Increasing ordinate values go up.
  /// Used for vertical coordinate systems.
  up,

  /// Increasing ordinate values go down.
  /// Used for vertical coordinate systems.
  down,
}
