part of '../../../geoengine.dart';

/// Definition of angular units.
class AngularUnit extends Info {
  /// Equality tolerance value. Values with a difference less than this are considered equal.
  static const double equalityTolerance = 2.0e-17;

  /// Radians per unit.
  double radiansPerUnit;

  /// Initializes a new instance of an angular unit with additional information.
  AngularUnit(
    this.radiansPerUnit, {
    required super.name,
    required super.authority,
    required super.authorityCode,
    super.alias,
    super.abbreviation,
    super.remarks,
  });

  /// Predefined angular unit for degrees.
  static AngularUnit get degrees {
    return AngularUnit(
      0.017453292519943295769236907684886,
      name: 'degree',
      authority: 'EPSG',
      authorityCode: 9102,
      alias: 'deg',
      remarks: '=pi/180 radians',
    );
  }

  /// Predefined angular unit for radians.
  static AngularUnit get radian {
    return AngularUnit(
      1,
      name: 'radian',
      authority: 'EPSG',
      authorityCode: 9101,
      alias: 'rad',
      remarks: 'SI standard unit.',
    );
  }

  /// Predefined angular unit for grads.
  static AngularUnit get grad {
    return AngularUnit(
      0.015707963267948966192313216916398,
      name: 'grad',
      authority: 'EPSG',
      authorityCode: 9105,
      alias: 'gr',
      remarks: '=pi/200 radians.',
    );
  }

  /// Predefined angular unit for gradians.
  static AngularUnit get gon {
    return AngularUnit(
      0.015707963267948966192313216916398,
      name: 'gon',
      authority: 'EPSG',
      authorityCode: 9106,
      alias: 'g',
      remarks: '=pi/200 radians.',
    );
  }

  /// Gets or sets the number of radians per AngularUnit.
  double get radiansPerAngularUnit => radiansPerUnit;

  /// Returns the Well-known text for this object
  /// as defined in the simple features specification.
  @override
  String get wkt {
    final sb = StringBuffer();
    sb.write('UNIT["$name", $radiansPerUnit');
    if (authority.isNotEmpty && authorityCode > 0) {
      sb.write(', AUTHORITY["$authority", "$authorityCode"]');
    }
    sb.write(']');
    return sb.toString();
  }

  /// Gets an XML representation of this object.
  @override
  String get xml {
    return '<CS_AngularUnit RadiansPerUnit="$radiansPerUnit">$infoXml</CS_AngularUnit>';
  }

  /// Checks whether the values of this instance are equal to the values of another instance.
  /// Only parameters used for the coordinate system are used for comparison.
  /// Name, abbreviation, authority, alias, and remarks are ignored in the comparison.
  @override
  bool equal(Object? obj) {
    if (obj is AngularUnit) {
      return (obj.radiansPerUnit - radiansPerUnit).abs() < equalityTolerance;
    }
    return false;
  }
}
