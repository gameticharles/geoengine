part of '../coordinate_reference_systems.dart';

class Ellipsoid extends Info {
  /// semi-major axis
  final double a;

  /// flattening
  final double f;

  /// inverse flattening
  final double invF;

  /// semi-minor axis
  final double b;

  /// Eccentricity of the ellipsoid.
  double eSq;

  /// First eccentricity
  double get e => sqrt(eSq);

  /// Second eccentricity
  double get ePrime => e / sqrt(1 - eSq);

  /// Polar Radius of Curvature
  double get rho => a * (1 - eSq);

  /// Inverse flattening aliase
  double? get rf => invF;

  /// Tells if the Inverse Flattening is definitive for this ellipsoid.
  bool isIvfDefinitive;
  final LinearUnit linearUnit; // unit of the ellipsoid

  Ellipsoid({
    required this.a,
    required this.invF,
    required super.name,
    super.authority,
    super.authorityCode,
    super.alias,
    super.abbreviation,
    super.remarks,
    LinearUnit? linearUnit,
    this.isIvfDefinitive = true,
  })  : linearUnit = linearUnit ?? LinearUnit.meter,
        f = 1 / invF,
        b = a * (1 - (1 / invF)),
        eSq = (2 * (1 / invF)) - ((1 / invF) * (1 / invF));

  Ellipsoid.withB({
    required this.a,
    required this.b,
    required super.name,
    super.authority,
    super.authorityCode,
    super.alias,
    super.abbreviation,
    super.remarks,
    LinearUnit? linearUnit,
    this.isIvfDefinitive = false,
  })  : linearUnit = linearUnit ?? LinearUnit.meter,
        f = (a - b) / a,
        invF = a / (a - b),
        eSq = (a * a - b * b) / (a * a);

  /// Surface Area Calculation
  double surfaceArea() {
    return 4 * pi * a * b;
  }

  /// Volume Calculation
  double volume() {
    return (4 / 3) * pi * a * a * b;
  }

  // Similarity Check
  bool isSimilar(Ellipsoid other, {double tolerance = 0.1}) {
    return (a - other.a).abs() <= tolerance &&
        (f - other.f).abs() <= tolerance &&
        (b - other.b).abs() <= tolerance;
  }

  // Validation
  bool isValid() {
    // Check for positive, non-zero values
    if (a <= 0 || b <= 0 || f <= 0 || invF <= 0) {
      return false;
    }

    // Check consistency between parameters
    if ((1 / invF) != f) {
      return false;
    }

    if (a * (1 - f) != b) {
      return false;
    }

    return true;
  }

  /// WGS 84 (World Geodetic System 1984)
  ///
  /// The most widely used ellipsoid for GPS and modern mapping applications.
  /// Semi-major axis: 6378137.0 m
  /// Inverse flattening: 298.257223563
  /// Authority: EPSG:7030
  static final Ellipsoid wgs84 = Ellipsoid(
    a: 6378137,
    invF: 298.257223563,
    isIvfDefinitive: true,
    name: 'WGS 84',
    authority: 'EPSG',
    authorityCode: 7030,
    abbreviation: 'wgs84',
  );

  /// WGS 72 (World Geodetic System 1972)
  ///
  /// Predecessor to WGS 84, used in early GPS systems.
  /// Semi-major axis: 6378135.0 m
  /// Inverse flattening: 298.26
  /// Authority: EPSG:7043
  static final Ellipsoid wgs72 = Ellipsoid(
    a: 6378135,
    invF: 298.26,
    isIvfDefinitive: true,
    name: 'WGS 72',
    authority: 'EPSG',
    authorityCode: 7043,
    abbreviation: 'wgs72',
  );

  /// WGS 66 (World Geodetic System 1966)
  ///
  /// Earlier version of the World Geodetic System.
  /// Semi-major axis: 6378145.0 m
  /// Inverse flattening: 298.25
  static final Ellipsoid wgs66 = Ellipsoid(
    a: 6378145.0,
    invF: 298.25,
    name: 'WGS 66',
    abbreviation: 'wgs66',
  );

  /// WGS 60 (World Geodetic System 1960)
  ///
  /// Original World Geodetic System ellipsoid.
  /// Semi-major axis: 6378165.0 m
  /// Inverse flattening: 298.3
  static final Ellipsoid wgs60 = Ellipsoid(
    a: 6378165.0,
    invF: 298.3,
    name: 'WGS 60',
    abbreviation: 'wgs60',
  );

  /// GRS 1980 (Geodetic Reference System 1980)
  ///
  /// Adopted by IUGG in 1980, very similar to WGS 84.
  /// Used in NAD83 and many modern geodetic systems.
  /// Semi-major axis: 6378137.0 m
  /// Inverse flattening: 298.257222101
  /// Authority: EPSG:7019
  static final Ellipsoid grs80 = Ellipsoid(
    a: 6378137,
    invF: 298.257222101,
    isIvfDefinitive: true,
    name: 'GRS 1980',
    authority: 'EPSG',
    authorityCode: 7019,
    abbreviation: 'grs80',
  );

  /// GRS 1967 (Geodetic Reference System 1967)
  ///
  /// Adopted by IUGG in 1967.
  /// Semi-major axis: 6378160.0 m
  /// Inverse flattening: 298.247167427
  static final Ellipsoid grs67 = Ellipsoid(
    a: 6378160.0,
    invF: 298.2471674270,
    name: 'GRS 67(IUGG 1967)',
    abbreviation: 'grs67',
  );

  /// Clarke 1866
  ///
  /// Used in North American Datum 1927 (NAD27).
  /// Semi-major axis: 6378206.4 m
  /// Semi-minor axis: 6356583.8 m
  /// Authority: EPSG:7008
  static final Ellipsoid clarke1866 = Ellipsoid.withB(
    a: 6378206.4,
    b: 6356583.8,
    name: 'Clarke 1866',
    authority: 'EPSG',
    authorityCode: 7008,
    abbreviation: 'clrk66',
    alias: 'North American 1927',
    remarks: 'Used in North American Datum 1927 (NAD27)',
  );

  /// Clarke 1880 (IGN)
  ///
  /// Modified Clarke 1880 ellipsoid used by IGN (Institut Géographique National).
  /// Semi-major axis: 6378249.145 m
  /// Inverse flattening: 293.465
  /// Authority: EPSG:7011
  static final Ellipsoid clarke1880 = Ellipsoid(
    a: 6378249.145,
    invF: 293.465,
    isIvfDefinitive: true,
    name: 'Clarke 1880 (IGN)',
    authority: 'EPSG',
    authorityCode: 7011,
    abbreviation: 'clrk80',
  );

  /// Clarke 1878
  ///
  /// Clarke 1878 ellipsoid.
  /// Semi-major axis: 6378190.0 m
  /// Inverse flattening: 293.465998
  static final Ellipsoid clarke1878 = Ellipsoid(
    a: 6378190.0,
    invF: 293.465998,
    name: 'Clarke 1878',
    abbreviation: 'clrk78',
    remarks: 'Clarke 1878 ellipsoid',
  );

  /// Clarke 1858
  ///
  /// Early Clarke ellipsoid.
  /// Semi-major axis: 6378293.645208759 m
  /// Inverse flattening: 294.2606763692654
  static final Ellipsoid clarke1858 = Ellipsoid(
    a: 6378293.645208759,
    invF: 294.2606763692654,
    name: 'Clarke 1858',
    abbreviation: 'clrk58',
  );

  /// International 1924 (Hayford 1909)
  ///
  /// Also known as International 1924 or Hayford 1909 ellipsoid.
  /// Widely used in Europe and other regions.
  /// Semi-major axis: 6378388.0 m
  /// Inverse flattening: 297.0
  /// Authority: EPSG:7022
  static final Ellipsoid international1924 = Ellipsoid(
    a: 6378388,
    invF: 297,
    isIvfDefinitive: true,
    name: 'International 1909 (Hayford)',
    authority: 'EPSG',
    authorityCode: 7022,
    abbreviation: 'intl',
    alias: 'International 1924, Hayford 1909',
    remarks: 'Also known as International 1924 ellipsoid',
  );

  /// Airy 1830
  ///
  /// Used in Great Britain and Ireland (OSGB36).
  /// Semi-major axis: 6377563.396 m
  /// Semi-minor axis: 6356256.910 m
  static final Ellipsoid airy = Ellipsoid.withB(
    a: 6377563.396,
    b: 6356256.910,
    name: 'Airy 1830',
    abbreviation: 'airy',
  );

  /// Modified Airy
  ///
  /// Modified version of Airy 1830 ellipsoid.
  /// Semi-major axis: 6377340.189 m
  /// Semi-minor axis: 6356034.446 m
  static final Ellipsoid modifiedAiry = Ellipsoid.withB(
    a: 6377340.189,
    b: 6356034.446,
    name: 'Modified Airy',
    abbreviation: 'mod_airy',
  );

  /// Bessel 1841
  ///
  /// Used in Central Europe, Japan, Indonesia, and other regions.
  /// Semi-major axis: 6377397.155 m
  /// Inverse flattening: 299.1528128
  static final Ellipsoid bessel = Ellipsoid(
    a: 6377397.155,
    invF: 299.1528128,
    name: 'Bessel 1841',
    abbreviation: 'bessel',
  );

  /// Bessel 1841 (Namibia)
  ///
  /// Modified Bessel ellipsoid used in Namibia.
  /// Semi-major axis: 6377483.865 m
  /// Inverse flattening: 299.1528128
  static final Ellipsoid besselNamibia = Ellipsoid(
    a: 6377483.865,
    invF: 299.1528128,
    name: 'Bessel 1841 (Namibia)',
    abbreviation: 'bess_nam',
  );

  /// Everest 1830
  ///
  /// Used in India and surrounding regions.
  /// Semi-major axis: 6377276.345 m
  /// Inverse flattening: 300.8017
  static final Ellipsoid everest1830 = Ellipsoid(
    a: 6377276.345,
    invF: 300.8017,
    name: 'Everest 1830',
    abbreviation: 'evrst30',
  );

  /// Everest 1948 (Modified Everest 1830)
  ///
  /// Modified version of Everest 1830 ellipsoid.
  /// Semi-major axis: 6377304.063 m
  /// Inverse flattening: 300.8017
  static final Ellipsoid everest1948 = Ellipsoid(
    a: 6377304.063,
    invF: 300.8017,
    name: 'Everest 1948',
    abbreviation: 'evrst48',
    alias: 'Modified Everest 1830',
    remarks: 'Modified version of Everest 1830 ellipsoid',
  );

  /// Everest 1956
  ///
  /// Everest ellipsoid variant from 1956.
  /// Semi-major axis: 6377301.243 m
  /// Inverse flattening: 300.8017
  static final Ellipsoid everest1956 = Ellipsoid(
    a: 6377301.243,
    invF: 300.8017,
    name: 'Everest 1956',
    abbreviation: 'evrst56',
  );

  /// Everest 1969
  ///
  /// Everest ellipsoid variant from 1969.
  /// Semi-major axis: 6377295.664 m
  /// Inverse flattening: 300.8017
  static final Ellipsoid everest1969 = Ellipsoid(
    a: 6377295.664,
    invF: 300.8017,
    name: 'Everest 1969',
    abbreviation: 'evrst69',
  );

  /// Everest (Sabah & Sarawak)
  ///
  /// Everest ellipsoid used in Sabah and Sarawak regions.
  /// Semi-major axis: 6377298.556 m
  /// Inverse flattening: 300.8017
  static final Ellipsoid everestSabahSarawak = Ellipsoid(
    a: 6377298.556,
    invF: 300.8017,
    name: 'Everest (Sabah & Sarawak)',
    abbreviation: 'evrstSS',
  );

  /// Krassovsky 1940
  ///
  /// Used in Soviet Union and Eastern European countries.
  /// Semi-major axis: 6378245.0 m
  /// Inverse flattening: 298.3
  static final Ellipsoid krassovsky = Ellipsoid(
    a: 6378245.0,
    invF: 298.3,
    name: 'Krassovsky, 1942',
    abbreviation: 'krass',
    alias: 'Krasovsky 1940',
    remarks: 'Used in Soviet Union and Eastern European countries',
  );

  /// Australian National & South American 1969
  ///
  /// Used in Australian and South American geodetic systems.
  /// Also known as Australian 1965 and South American 1969.
  /// Semi-major axis: 6378160.0 m
  /// Inverse flattening: 298.25
  static final Ellipsoid australian = Ellipsoid(
    a: 6378160.0,
    invF: 298.25,
    name: 'Australian Natl & S. Amer. 1969',
    abbreviation: 'aust_SA',
    alias: 'Australian 1965, South American 1969',
    remarks: 'Used in Australian and South American geodetic systems',
  );

  /// Fischer 1960 (Mercury Datum)
  ///
  /// Fischer ellipsoid used in Mercury Datum.
  /// Semi-major axis: 6378166.0 m
  /// Inverse flattening: 298.3
  static final Ellipsoid fischer1960 = Ellipsoid(
    a: 6378166.0,
    invF: 298.3,
    name: 'Fischer (Mercury Datum) 1960',
    abbreviation: 'fschr60',
  );

  /// Modified Fischer 1960
  ///
  /// Modified version of Fischer 1960 ellipsoid.
  /// Semi-major axis: 6378155.0 m
  /// Inverse flattening: 298.3
  static final Ellipsoid modifiedFischer1960 = Ellipsoid(
    a: 6378155.0,
    invF: 298.3,
    name: 'Fischer 1960',
    abbreviation: 'fschr60m',
    alias: 'Modified Fischer 1960',
    remarks: 'Modified version of Fischer 1960 ellipsoid',
  );

  /// Fischer 1968
  ///
  /// Fischer 1968 ellipsoid.
  /// Semi-major axis: 6378150.0 m
  /// Inverse flattening: 298.3
  static final Ellipsoid fischer1968 = Ellipsoid(
    a: 6378150.0,
    invF: 298.3,
    name: 'Fischer 1968',
    abbreviation: 'fschr68',
  );

  /// Helmert 1906
  ///
  /// Helmert 1906 ellipsoid.
  /// Semi-major axis: 6378200.0 m
  /// Inverse flattening: 298.3
  static final Ellipsoid helmert = Ellipsoid(
    a: 6378200.0,
    invF: 298.3,
    name: 'Helmert 1906',
    abbreviation: 'helmert',
  );

  /// Hough
  ///
  /// Hough ellipsoid.
  /// Semi-major axis: 6378270.0 m
  /// Inverse flattening: 297.0
  static final Ellipsoid hough = Ellipsoid(
    a: 6378270.0,
    invF: 297.0,
    name: 'Hough',
    abbreviation: 'hough',
  );

  /// MERIT 1983
  ///
  /// MERIT (Monitoring Earth Rotation and Intercomparison of Techniques) 1983.
  /// Semi-major axis: 6378137.0 m
  /// Inverse flattening: 298.257
  static final Ellipsoid merit = Ellipsoid(
    a: 6378137.0,
    invF: 298.257,
    name: 'MERIT 1983',
    abbreviation: 'MERIT',
  );

  /// Soviet Geodetic System 1985
  ///
  /// Soviet Geodetic System 85.
  /// Semi-major axis: 6378136.0 m
  /// Inverse flattening: 298.257
  static final Ellipsoid sgs85 = Ellipsoid(
    a: 6378136.0,
    invF: 298.257,
    name: 'Soviet Geodetic System 85',
    abbreviation: 'SGS85',
  );

  /// IAU 1976
  ///
  /// International Astronomical Union 1976 ellipsoid.
  /// Semi-major axis: 6378140.0 m
  /// Inverse flattening: 298.257
  static final Ellipsoid iau76 = Ellipsoid(
    a: 6378140.0,
    invF: 298.257,
    name: 'IAU 1976',
    abbreviation: 'IAU76',
  );

  /// Applied Physics 1965
  ///
  /// Applied Physics Laboratory 1965 ellipsoid.
  /// Semi-major axis: 6378137.0 m
  /// Inverse flattening: 298.25
  static final Ellipsoid apl4 = Ellipsoid(
    a: 6378137,
    invF: 298.25,
    name: 'Appl. Physics. 1965',
    abbreviation: 'APL4',
  );

  /// Naval Weapons Lab 1965
  ///
  /// Naval Weapons Laboratory 1965 ellipsoid.
  /// Semi-major axis: 6378145.0 m
  /// Inverse flattening: 298.25
  static final Ellipsoid nwl9d = Ellipsoid(
    a: 6378145.0,
    invF: 298.25,
    name: 'Naval Weapons Lab., 1965',
    abbreviation: 'NWL9D',
  );

  /// Andrae 1876
  ///
  /// Andrae 1876 ellipsoid used in Denmark and Iceland.
  /// Semi-major axis: 6377104.43 m
  /// Inverse flattening: 300.0
  static final Ellipsoid andrae = Ellipsoid(
    a: 6377104.43,
    invF: 300.0,
    name: 'Andrae 1876 (Den., Iclnd.)',
    abbreviation: 'andrae',
  );

  /// Comm. des Poids et Mesures 1799
  ///
  /// Commission des Poids et Mesures 1799 ellipsoid.
  /// Semi-major axis: 6375738.7 m
  /// Inverse flattening: 334.29
  static final Ellipsoid cpm = Ellipsoid(
    a: 6375738.7,
    invF: 334.29,
    name: 'Comm. des Poids et Mesures 1799',
    abbreviation: 'CPM',
  );

  /// Delambre 1810
  ///
  /// Delambre 1810 ellipsoid used in Belgium.
  /// Semi-major axis: 6376428.0 m
  /// Inverse flattening: 311.5
  static final Ellipsoid delambre = Ellipsoid(
    a: 6376428.0,
    invF: 311.5,
    name: 'Delambre 1810 (Belgium)',
    abbreviation: 'delmbr',
  );

  /// Engelis 1985
  ///
  /// Engelis 1985 ellipsoid.
  /// Semi-major axis: 6378136.05 m
  /// Inverse flattening: 298.2566
  static final Ellipsoid engelis = Ellipsoid(
    a: 6378136.05,
    invF: 298.2566,
    name: 'Engelis 1985',
    abbreviation: 'engelis',
  );

  /// Kaula 1961
  ///
  /// Kaula 1961 ellipsoid.
  /// Semi-major axis: 6378163.0 m
  /// Inverse flattening: 298.24
  static final Ellipsoid kaula = Ellipsoid(
    a: 6378163.0,
    invF: 298.24,
    name: 'Kaula 1961',
    abbreviation: 'kaula',
  );

  /// Lerch 1979
  ///
  /// Lerch 1979 ellipsoid.
  /// Semi-major axis: 6378139.0 m
  /// Inverse flattening: 298.257
  static final Ellipsoid lerch = Ellipsoid(
    a: 6378139.0,
    invF: 298.257,
    name: 'Lerch 1979',
    abbreviation: 'lerch',
  );

  /// Maupertuis 1738
  ///
  /// Maupertuis 1738 ellipsoid.
  /// Semi-major axis: 6397300.0 m
  /// Inverse flattening: 191.0
  static final Ellipsoid maupertuis = Ellipsoid(
    a: 6397300.0,
    invF: 191.0,
    name: 'Maupertius 1738',
    abbreviation: 'mprts',
  );

  /// New International 1967
  ///
  /// New International 1967 ellipsoid.
  /// Semi-major axis: 6378157.5 m
  /// Semi-minor axis: 6356772.2 m
  static final Ellipsoid newInternational = Ellipsoid.withB(
    a: 6378157.5,
    b: 6356772.2,
    name: 'New International 1967',
    abbreviation: 'new_intl',
  );

  /// Plessis 1817
  ///
  /// Plessis 1817 ellipsoid used in France.
  /// Semi-major axis: 6376523.0 m
  /// Inverse flattening: 6355863.0
  static final Ellipsoid plessis = Ellipsoid(
    a: 6376523.0,
    invF: 6355863.0,
    name: 'Plessis 1817 (France)',
    abbreviation: 'plessis',
  );

  /// Southeast Asia
  ///
  /// Southeast Asia ellipsoid.
  /// Semi-major axis: 6378155.0 m
  /// Semi-minor axis: 6356773.3205 m
  static final Ellipsoid southeastAsia = Ellipsoid.withB(
    a: 6378155.0,
    b: 6356773.3205,
    name: 'Southeast Asia',
    abbreviation: 'SEasia',
  );

  /// Walbeck
  ///
  /// Walbeck ellipsoid.
  /// Semi-major axis: 6376896.0 m
  /// Semi-minor axis: 6355834.8467 m
  static final Ellipsoid walbeck = Ellipsoid.withB(
    a: 6376896.0,
    b: 6355834.8467,
    name: 'Walbeck',
    abbreviation: 'walbeck',
  );

  /// Ghana War Office
  ///
  /// Ghana War Office ellipsoid used in Ghana geodetic surveys.
  /// Semi-major axis: 6378299.996 m
  /// Inverse flattening: 296.0
  static final Ellipsoid ghanaWarOffice = Ellipsoid(
    a: 6378299.996,
    invF: 296.0,
    name: 'Ghana War Office',
    abbreviation: 'ghanaWarOffice',
    remarks: 'Used in Ghana geodetic surveys',
  );

  /// IERS 1989
  ///
  /// International Earth Rotation Service 1989 ellipsoid.
  /// Semi-major axis: 6378136.0 m
  /// Inverse flattening: 298.257
  static final Ellipsoid iers1989 = Ellipsoid(
    a: 6378136.0,
    invF: 298.257,
    name: 'IERS 1989',
    abbreviation: 'IERS1989',
    remarks: 'International Earth Rotation Service 1989',
  );

  /// IERS 2003
  ///
  /// International Earth Rotation and Reference Systems Service 2003 ellipsoid.
  /// Semi-major axis: 6378136.6 m
  /// Inverse flattening: 298.25642
  static final Ellipsoid iers2003 = Ellipsoid(
    a: 6378136.6,
    invF: 298.25642,
    name: 'IERS 2003',
    abbreviation: 'IERS2003',
    remarks: 'International Earth Rotation and Reference Systems Service 2003',
  );

  /// Normal Sphere
  ///
  /// Spherical Earth model with radius of 6370997 m.
  /// Semi-major axis: 6370997.0 m
  /// Semi-minor axis: 6370997.0 m
  static final Ellipsoid sphere = Ellipsoid.withB(
    a: 6370997.0,
    b: 6370997.0,
    name: 'Normal Sphere (r=6370997)',
    abbreviation: 'sphere',
  );

  /// Get all available ellipsoids
  static List<Ellipsoid> get all => [
        wgs84,
        wgs72,
        wgs66,
        wgs60,
        grs80,
        grs67,
        clarke1866,
        clarke1880,
        clarke1878,
        clarke1858,
        international1924,
        airy,
        modifiedAiry,
        bessel,
        besselNamibia,
        everest1830,
        everest1948,
        everest1956,
        everest1969,
        everestSabahSarawak,
        krassovsky,
        australian,
        fischer1960,
        modifiedFischer1960,
        fischer1968,
        helmert,
        hough,
        merit,
        sgs85,
        iau76,
        apl4,
        nwl9d,
        andrae,
        cpm,
        delambre,
        engelis,
        kaula,
        lerch,
        maupertuis,
        newInternational,
        plessis,
        southeastAsia,
        walbeck,
        ghanaWarOffice,
        iers1989,
        iers2003,
        sphere,
      ];

  /// Find an ellipsoid by name or abbreviation
  static Ellipsoid? findByName(String name) {
    final lowerName = name.toLowerCase();
    try {
      return all.firstWhere(
        (e) =>
            e.name.toLowerCase() == lowerName ||
            e.abbreviation?.toLowerCase() == lowerName ||
            e.alias?.toLowerCase().contains(lowerName) == true,
      );
    } catch (e) {
      return null;
    }
  }

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
    return '<CS_Ellipsoid SemiMajorAxis="$a" SemiMinorAxis="$b" InverseFlattening="$invF" IvfDefinitive="${isIvfDefinitive ? 1 : 0}">$infoXml${linearUnit.xml}</CS_Ellipsoid>';
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
