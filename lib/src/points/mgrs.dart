part of geoengine;

/// Military Grid Reference System (MGRS/NATO) grid references provides with methods to parse references, and
/// to convert to UTM coordinates and latitude/longitude.
///
/// MGRS references comprise a grid zone designator, a 100km square identification, and an easting
/// and northing (in metres); e.g. ‘31U DQ 48251 11932’.
///
/// Depending on requirements, some parts of the reference may be omitted (implied), and
/// eastings/northings may be given to varying resolution.
class MGRS {
  final int zone;
  final String band;
  final String e100k;
  final String n100k;
  final int easting;
  final int northing;

  final String _latBands = 'CDEFGHJKLMNPQRSTUVWXX';

  final List<String> _e100kLetters = ['ABCDEFGH', 'JKLMNPQR', 'STUVWXYZ'];

  final List<String> _n100kLetters = [
    'ABCDEFGHJKLMNPQRSTUV',
    'FGHJKLMNPQRSTUVABCDE'
  ];

  /// Creates an Mgrs grid reference object.
  ///
  /// - [zone] - 6° longitudinal zone (1..60 covering 180°W..180°E).
  /// - [band] - 8° latitudinal band (C..X covering 80°S..84°N).
  /// - [e100k] - First letter (E) of 100km grid square.
  /// - [n100k] - Second letter (N) of 100km grid square.
  /// - [easting] - Easting in metres within 100km grid square.
  /// - [northing] - Northing in metres within 100km grid square.
  ///
  /// Error - Invalid MGRS grid reference.
  ///
  /// Example:
  /// ```dart
  ///   var mgrsRef = new MGRS(31, 'U', 'D', 'Q', 48251, 11932);
  ///  // 31U DQ 48251 11932
  /// ```
  MGRS(this.zone, this.band, this.e100k, this.n100k, this.easting,
      this.northing) {
    if (zone < 1 || zone > 60) {
      throw ArgumentError('Invalid MGRS zone');
    }

    if (!_latBands.contains(band) || band.length != 1) {
      throw ArgumentError('Invalid MGRS band');
    }

    if (!_e100kLetters[(zone - 1) % 3].contains(e100k) || e100k.length != 1) {
      throw ArgumentError('Invalid MGRS 100km grid square column');
    }

    if (!_n100kLetters[(zone - 1) % 2].contains(n100k) || n100k.length != 1) {
      throw ArgumentError('Invalid MGRS 100km grid square row');
    }
  }

  // Assume Utm class exists, otherwise implement it
  /// Converts MGRS grid reference to UTM coordinate.
  ///
  /// Grid references refer to squares rather than points (with the size of the square indicated
  /// by the precision of the reference); this conversion will return the UTM coordinate of the SW
  /// corner of the grid reference square.
  ///
  /// Example:
  /// ```dart
  ///   var mgrsRef = MGRS.parse('31U DQ 48251 11932');
  ///   var utmCoord = mgrsRef.toUtm(); // 31 N 448251 5411932
  /// ```
  UTM toUTM() {
    // Determine the hemisphere
    String hemisphere = band.compareTo('N') >= 0 ? 'N' : 'S';

    // Get easting specified by e100k
    int col = _e100kLetters[(zone - 1) % 3].indexOf(e100k) + 1;
    int e100kNum = col * 100000; // e100k in meters

    // Get northing specified by n100k
    int row = _n100kLetters[(zone - 1) % 2].indexOf(n100k);
    int n100kNum = row * 100000; // n100k in meters

    // Get latitude of the bottom of the band
    int latBand = (_latBands.indexOf(band) - 10) * 8;

    // Get northing of the bottom of the band (this part might require extra implementation)
    int nBand =
        (LatLng(latBand.toDouble(), 3).toUTM().northing / 100000).floor() *
            100000;

    // 100km grid square row letters repeat every 2,000,000 meters north
    int n2M = 0;
    while (n2M + n100kNum + northing < nBand) {
      n2M += 2000000;
    }

    return UTM(
      zoneNumber: zone,
      zoneLetter: hemisphere,
      easting: (e100kNum + easting).toDouble(),
      northing: (n2M + n100kNum + northing.toDouble()),
    );

    // return UTM(zone, hemisphere, (e100kNum + easting).toDouble(),
    //     (n2M + n100kNum + northing.toDouble()));
  }

  /// Converts UTM zone/easting/northing coordinate to latitude/longitude.
  ///
  /// Implements Karney’s method, using Krüger series to order n⁶, giving results accurate to 5nm
  /// for distances up to 3900km from the central meridian.
  ///
  /// Returns {LatLon} Latitude/longitude of supplied grid reference.
  ///
  /// Example
  /// ```dart
  ///   var grid = new UTM(31, 'N', 448251.795, 5411932.678);
  ///   var latlong = grid.toLatLon(); // 48°51′29.52″N, 002°17′40.20″E
  /// ```
  LatLng toLatLng() {
    return toUTM().toLatLng();
  }

  /// Parses string representation of MGRS grid reference.
  ///
  ///  An MGRS grid reference comprises (space-separated)
  ///   - grid zone designator (GZD)
  ///   - 100km grid square letter-pair
  ///   - easting
  ///   - northing.
  ///
  ///  [mgrsGridRef] - String representation of MGRS grid reference.
  ///  Returns MGRS grid reference object.
  ///  Invalid MGRS grid reference.
  ///
  ///  Example
  ///  ```dart
  ///    var mgrsRef = MGRS.parse('31U DQ 48251 11932');
  ///    var mgrsRef = MGRS.parse('31UDQ4825111932');
  ///    //  mgrsRef: { zone:31, band:'U', e100k:'D', n100k:'Q', easting:48251, northing:11932 }
  /// ```
  static MGRS parse(String mgrsGridRef) {
    if (mgrsGridRef.isEmpty) {
      throw ArgumentError("Invalid MGRS grid reference '\$mgrsGridRef'");
    }

    // Check for military-style grid reference with no separators
    if (!mgrsGridRef.trim().contains(" ")) {
      if (int.tryParse(mgrsGridRef.substring(0, 2)) == null) {
        throw ArgumentError("Invalid MGRS grid reference '\$mgrsGridRef'");
      }
      String en = mgrsGridRef
          .trim()
          .substring(5); // Get easting/northing following zone/band/100ksq
      en =
          "${en.substring(0, en.length ~/ 2)} ${en.substring(en.length ~/ 2)}"; // Separate easting/northing
      mgrsGridRef =
          "${mgrsGridRef.substring(0, 3)} ${mgrsGridRef.substring(3, 5)} $en"; // Insert spaces
    }

    // Match separate elements (separated by whitespace)
    final ref = mgrsGridRef.split(" ");
    if (ref.length != 4) {
      throw ArgumentError("Invalid MGRS grid reference '\$mgrsGridRef'");
    }

    // Split gzd into zone/band
    final gzd = ref[0];
    final zone = int.tryParse(gzd.substring(0, 2));
    final band = gzd.substring(2, 3);

    // Split 100km letter-pair into e/n
    final en100k = ref[1];
    final e100k = en100k.substring(0, 1);
    final n100k = en100k.substring(1, 2);

    var e = ref[2];
    var n = ref[3];

    // Standardize to 10-digit refs - i.e., meters (but only if < 10-digit refs, to allow decimals)
    e = e.length >= 5 ? e : ("${e}00000").substring(0, 5);
    n = n.length >= 5 ? n : ("${n}00000").substring(0, 5);

    return MGRS(zone!, band, e100k, n100k, int.parse(e), int.parse(n));
  }

  /// Returns a string representation of an MGRS grid reference.
  ///
  /// To distinguish from civilian UTM coordinate representations, no space is included within the
  /// zone/band grid zone designator.
  ///
  /// Components are separated by spaces: for a milit31U DQ 48251 11932ary-style unseparated string, use
  /// ```dart
  /// MGRS.toString().replace(/ /g, '');
  /// ```
  ///
  /// Note that MGRS grid references get truncated, not rounded (unlike UTM coordinates); grid
  /// references indicate a bounding square, rather than a point, with the size of the square
  /// indicated by the precision - a precision of 10 indicates a 1-metre square, a precision of 4
  /// indicates a 1,000-metre square (hence 31U DQ 48 11 indicates a 1km square with SW corner at
  /// `31 N 448000 5411000`, which would include the 1m square ``).
  ///
  /// [digits]: Precision of returned grid reference (eg 4 = km, 10 = m). The values should
  /// be between these numbers [2, 4, 6, 8, 10]. Default value is 10.
  ///
  /// Returns a string representation of the grid reference in standard format.
  ///
  /// Example:
  /// ```
  /// var mgrsStr = MGRS(31, 'U', 'D', 'Q', 48251, 11932).toString()
  /// // 31U DQ 48251 11932
  /// ```
  @override
  String toString({int digits = 10}) {
    if (![2, 4, 6, 8, 10].contains(digits)) {
      throw ArgumentError('Invalid MGRS precision $digits');
    }

    // truncate to required precision
    var eRounded = (easting / pow(10, 5 - digits / 2)).floor();
    var nRounded = (northing / pow(10, 5 - digits / 2)).floor();

    // ensure leading zeros
    var zPadded = zone.toString().padLeft(2, '0');
    var ePadded = eRounded.toString().padLeft(digits ~/ 2, '0');
    var nPadded = nRounded.toString().padLeft(digits ~/ 2, '0');

    return '$zPadded$band $e100k$n100k $ePadded $nPadded';
  }
}
