part of '../../../geoengine.dart';

/// Represents details of an axis, used for labeling and indicating orientation.
class AxisInfo {
  String name;
  AxisOrientationEnum orientation;

  /// Initializes a new instance of [AxisInfo].
  ///
  /// [name] is the human-readable name for the axis.
  /// [orientation] is the axis orientation represented as [AxisOrientationEnum].
  AxisInfo(this.name, this.orientation);

  /// Returns the Well-known Text (WKT) representation of this axis.
  String toWKT() {
    return 'AXIS["$name", ${orientation.toString().toUpperCase()}]';
  }

  /// Returns an XML representation of this axis.
  String toXML() {
    return '<CS_AxisInfo Name="$name" Orientation="${orientation.toString().toUpperCase()}"/>';
  }
}
