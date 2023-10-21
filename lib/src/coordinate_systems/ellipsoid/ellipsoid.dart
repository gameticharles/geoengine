part of geoengine;

class Ellipsoid extends Info {
  final double a; // semi-major axis
  final double f; // flattening
  final double invF; // inverse flattening
  final double b; // semi-minor axis
  /// Eccentricity of the ellipsoid.
  double eccentricitySq;

  /// Tells if the Inverse Flattening is definitive for this ellipsoid.
  bool isIvfDefinitive;
  final LinearUnit linearUnit; // unit of the ellipsoid

  Ellipsoid({
    required this.a,
    required this.invF,
    required this.linearUnit,
    required String name,
    required String authority,
    required int authorityCode,
    String? alias,
    String? abbreviation,
    String? remarks,
    this.isIvfDefinitive = true,
  })  : f = 1 / invF,
        b = a * (1 - (1 / invF)),
        eccentricitySq = (2 * (1 / invF)) - ((1 / invF) * (1 / invF)),
        super(
          name: name,
          authority: authority,
          authorityCode: authorityCode,
          alias: alias,
          abbreviation: abbreviation,
          remarks: remarks,
        );

  // Define a constant for WGS-84 outside the class
  static final Ellipsoid wgs84 = Ellipsoid(
    a: 6378137,
    invF: 298.257223563,
    isIvfDefinitive: true,
    name: 'WGS 84',
    authority: 'EPSG',
    linearUnit: LinearUnit.meter,
    authorityCode: 7030,
  );

  static final Ellipsoid wgs72 = Ellipsoid(
    a: 6378135,
    invF: 298.26,
    isIvfDefinitive: true,
    name: 'WGS 72',
    authority: 'EPSG',
    linearUnit: LinearUnit.meter,
    authorityCode: 7043,
  );

  static final Ellipsoid clarke1880 = Ellipsoid(
    a: 6378249.145,
    invF: 293.465,
    isIvfDefinitive: true,
    name: 'Clarke 1880 (IGN)',
    authority: 'EPSG',
    authorityCode: 7011,
    linearUnit: LinearUnit.meter,
  );

  /// OGC Well Known Text
  String toWKT() {
    return 'SPHEROID["$name",$a,$invF,AUTHORITY["$authority","$authorityCode"]]';
  }

  /// OGC Well Known Text 2 (2019)
  String toWKT2() {
    return 'ELLIPSOID["$name",$a,$invF,LENGTHUNIT["${linearUnit.name}",${linearUnit.metersPerUnit}],ID["$authority",$authorityCode]]';
  }

  /// ESRI Well Known Text
  String toEsriWKT() {
    return 'SPHEROID["$name",$a,$invF]';
  }

  /// GeoServer
  String toGeoServer() {
    return '$authorityCode-ellipsoid=SPHEROID["$name",$a,$invF,AUTHORITY["$authority","$authorityCode"]]';
  }

  @override
  String get wkt {
    return 'SPHEROID["$name", $a, $invF${authority.isNotEmpty && authorityCode > 0 ? ', AUTHORITY["$authority", "$authorityCode"]' : ''}]';
  }

  @override
  String get xml {
    return '<CS_Ellipsoid SemiMajorAxis="$a" SemiMinorAxis="$b" InverseFlattening="$invF" IvfDefinitive="${isIvfDefinitive ? 1 : 0}">${infoXml}${linearUnit.xml}</CS_Ellipsoid>';
  }

  /// Checks whether the values of this instance are equal to the values of another instance.
  /// Only parameters used for the coordinate system are used for comparison.
  /// Name, abbreviation, authority, alias, and remarks are ignored in the comparison.
  @override
  bool equal(Object obj) {
    if (obj is! Ellipsoid) return false;
    var e = obj;
    return (e.f == f && e.a == a && e.b == b && e.linearUnit.equal(linearUnit));
  }

  /// JSON
  // Factory constructor to create an Ellipsoid from a map/JSON
  factory Ellipsoid.fromMap(Map<String, dynamic> map) {
    return Ellipsoid(
      a: map['semi_major_axis'],
      invF: (map['semi_major_axis'] - map['semi_minor_axis']) /
          map['semi_major_axis'],
      isIvfDefinitive: true,
      name: map['name'],
      authority: map['id']['authority'],
      authorityCode: map['id']['code'],
      linearUnit:
          LinearUnit.meter, // You may need to adjust this based on your data
    );
  }

  // Convert an Ellipsoid to a map/JSON
  Map<String, dynamic> toJSON() {
    return {
      "schema":
          "https://proj.org/schemas/v0.5/projjson.schema.json", // "$schema":
      "type": "Ellipsoid",
      'name': name,
      'semi_major_axis': a,
      'semi_minor_axis': b,
      'inverse_flattening': invF,
      'id': {
        'authority': authority,
        'code': authorityCode,
      },
    };
  }
}
