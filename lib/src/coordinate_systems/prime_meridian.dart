part of '../../geoengine.dart';

/// A meridian used to take longitude measurements from.
class PrimeMeridian extends Info {
  /// Longitude of the prime meridian (relative to the Greenwich prime meridian).
  double longitude;

  /// Angular unit.
  AngularUnit angularUnit;

  /// Initializes a new instance of a prime meridian.
  PrimeMeridian(
    this.longitude,
    this.angularUnit,
    String name,
    String authority,
    int authorityCode,
    String? alias,
    String? abbreviation,
    String? remarks,
  ) : super(
          name: name,
          authority: authority,
          authorityCode: authorityCode,
          alias: alias,
          abbreviation: abbreviation,
          remarks: remarks,
        );

  /// Greenwich prime meridian.
  static PrimeMeridian get greenwich {
    return PrimeMeridian(
      0.0,
      AngularUnit.degrees,
      'Greenwich',
      'EPSG',
      8901,
      '',
      '',
      '',
    );
  }

  /// Lisbon prime meridian.
  static PrimeMeridian get lisbon {
    return PrimeMeridian(
      -9.0754862,
      AngularUnit.degrees,
      'Lisbon',
      'EPSG',
      8902,
      '',
      '',
      '',
    );
  }

  /// Paris prime meridian.
  ///
  /// Value adopted by IGN (Paris) in 1936.
  /// Equivalent to 2 deg 20 min 14.025 sec.
  /// Preferred by EPSG to earlier value of 2 deg 20 min 13.95 sec (2.596898 grads) used by RGS London.
  static PrimeMeridian get paris {
    return PrimeMeridian(
      2.5969213,
      AngularUnit.degrees,
      'Paris',
      'EPSG',
      8903,
      '',
      '',
      'Value adopted by IGN (Paris) in 1936. Equivalent to 2 deg 20 min 14.025 sec. Preferred by EPSG to earlier value of 2 deg 20 min 13.95 sec (2.596898 grads) used by RGS London.',
    );
  }

  /// Bogota prime meridian.
  static PrimeMeridian get bogota {
    return PrimeMeridian(
      -74.04513,
      AngularUnit.degrees,
      'Bogota',
      'EPSG',
      8904,
      '',
      '',
      '',
    );
  }

  /// Madrid prime meridian.
  static PrimeMeridian get madrid {
    return PrimeMeridian(
      -3.411658,
      AngularUnit.degrees,
      'Madrid',
      'EPSG',
      8905,
      '',
      '',
      '',
    );
  }

  /// Rome prime meridian.
  static PrimeMeridian get rome {
    return PrimeMeridian(
      12.27084,
      AngularUnit.degrees,
      'Rome',
      'EPSG',
      8906,
      '',
      '',
      '',
    );
  }

  /// Bern prime meridian.
  ///
  /// 1895 value. Newer value of 7 deg 26 min 22.335 sec E determined in 1938.
  static PrimeMeridian get bern {
    return PrimeMeridian(
      7.26225,
      AngularUnit.degrees,
      'Bern',
      'EPSG',
      8907,
      '',
      '',
      '1895 value. Newer value of 7 deg 26 min 22.335 sec E determined in 1938.',
    );
  }

  /// Jakarta prime meridian.
  static PrimeMeridian get jakarta {
    return PrimeMeridian(
      106.482779,
      AngularUnit.degrees,
      'Jakarta',
      'EPSG',
      8908,
      '',
      '',
      '',
    );
  }

  /// Ferro prime meridian.
  ///
  /// Used in Austria and former Czechoslovakia.
  static PrimeMeridian get ferro {
    return PrimeMeridian(
      -17.66666666666667,
      AngularUnit.degrees,
      'Ferro',
      'EPSG',
      8909,
      '',
      '',
      'Used in Austria and former Czechoslovakia.',
    );
  }

  /// Brussels prime meridian.
  static PrimeMeridian get brussels {
    return PrimeMeridian(
      4.220471,
      AngularUnit.degrees,
      'Brussels',
      'EPSG',
      8910,
      '',
      '',
      '',
    );
  }

  /// Stockholm prime meridian.
  static PrimeMeridian get stockholm {
    return PrimeMeridian(
      18.03298,
      AngularUnit.degrees,
      'Stockholm',
      'EPSG',
      8911,
      '',
      '',
      '',
    );
  }

  /// Athens prime meridian.
  ///
  /// Used in Greece for older mapping based on Hatt projection.
  static PrimeMeridian get athens {
    return PrimeMeridian(
      23.4258815,
      AngularUnit.degrees,
      'Athens',
      'EPSG',
      8912,
      '',
      '',
      'Used in Greece for older mapping based on Hatt projection.',
    );
  }

  /// Oslo prime meridian.
  ///
  /// Formerly known as Kristiania or Christiania.
  static PrimeMeridian get oslo {
    return PrimeMeridian(
      10.43225,
      AngularUnit.degrees,
      'Oslo',
      'EPSG',
      8913,
      '',
      '',
      'Formerly known as Kristiania or Christiania.',
    );
  }

  @override
  bool equal(Object obj) {
    if (obj is! PrimeMeridian) return false;
    final prime = obj;
    return prime.angularUnit.equal(angularUnit) && prime.longitude == longitude;
  }

  @override
  String get wkt {
    final sb = StringBuffer();
    sb.write('PRIMEM["$name", $longitude');
    if (authority.isNotEmpty && authorityCode > 0) {
      sb.write(', AUTHORITY["$authority", "$authorityCode"]');
    }
    sb.write(']');
    return sb.toString();
  }

  @override
  String get xml =>
      '<CS_PrimeMeridian Longitude="$longitude">$infoXml${angularUnit.xml}</CS_PrimeMeridian>';
}
