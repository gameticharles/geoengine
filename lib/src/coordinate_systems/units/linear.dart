part of '../../../geoengine.dart';

class LinearUnit extends Info {
  /// Number of meters per unit.
  double metersPerUnit;

  LinearUnit({
    required this.metersPerUnit,
    required super.name,
    required super.authorityCode,
    super.authority = "EPSG",
    super.alias,
    super.abbreviation,
    super.remarks,
  });

  /// Meter
  static final LinearUnit meter = LinearUnit(
    name: 'Meter',
    alias: 'm',
    metersPerUnit: 1,
    authorityCode: 9001,
    abbreviation: null,
    remarks: 'Also known as International metre. SI standard unit.',
  );

  static final LinearUnit foot = LinearUnit(
    name: 'Foot',
    alias: 'ft',
    metersPerUnit: 0.3048,
    authorityCode: 9002,
    abbreviation: null,
    remarks: null,
  );

  static final LinearUnit usFoot = LinearUnit(
    name: 'US survey foot',
    alias: 'ft',
    metersPerUnit: 0.304800609601219,
    authorityCode: 9003,
    abbreviation: 'ftUS',
    remarks: 'Used in USA.',
  );

  static final LinearUnit ghFoot = LinearUnit(
    name: 'Gold Coast foot',
    alias: 'ft',
    metersPerUnit: 0.304799710181509,
    authorityCode: 9004,
    abbreviation: 'Ghana foot',
    remarks: 'Used in Ghana.',
  );

  static final LinearUnit clarkFoot = LinearUnit(
    name: "Clarke's foot",
    alias: "Clarke's foot",
    metersPerUnit: 0.3047972654,
    authorityCode: 9005,
    abbreviation: null,
    remarks:
        "Assumes Clarke's 1865 ratio of 1 British foot = 0.3047972654 French legal metres applies to the international metre. Used in older Australian, southern African & British West Indian mapping.",
  );

  static final LinearUnit nauticalMile = LinearUnit(
    name: "Nautical mile",
    alias: "NM",
    metersPerUnit: 1852,
    authorityCode: 9030,
    abbreviation: null,
    remarks: null,
  );

  /// Checks whether the values of this instance are equal to the values of another instance.
  /// Only parameters used for the coordinate system are used for comparison.
  /// Name, abbreviation, authority, alias, and remarks are ignored in the comparison.
  @override
  bool equal(Object obj) {
    if (obj is! LinearUnit) return false;
    return (obj).metersPerUnit == metersPerUnit;
  }

  @override
  String get wkt =>
      'UNIT["$name", $metersPerUnit${authority.isNotEmpty && authorityCode > 0 ? ', AUTHORITY["$authority", "$authorityCode"]' : ''}]';

  @override
  String get xml =>
      '<CS_LinearUnit MetersPerUnit="$metersPerUnit">$infoXml</CS_LinearUnit>';
}
