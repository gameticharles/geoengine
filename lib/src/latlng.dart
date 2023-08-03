part of geoengine;

class LatLng extends PointX {
  final double latitude;
  final double longitude;
  final double? height;

  /// Default constructor
  LatLng(this.latitude, this.longitude, [this.height])
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180),
        super(
            y: latitude,
            x: longitude,
            z: height,
            type: CoordinateType.geodetic);

  /// Named constructor that creates a LatLng from a Map
  LatLng.fromMap(Map<String, double> map)
      : latitude = map['latitude']!,
        longitude = map['longitude']!,
        height = map['height']!,
        super(
            y: map['latitude']!,
            x: map['longitude']!,
            z: map['height']!,
            type: CoordinateType.geodetic);

  /// Named constructor that creates a LatLng from a List
  LatLng.fromList(List<double> list)
      : assert(list.length >= 2),
        latitude = list[0],
        longitude = list[1],
        height = list.length == 3 ? list[2] : null,
        super(
            y: list[0],
            x: list[1],
            z: list.length == 3 ? list[2] : null,
            type: CoordinateType.geodetic);

  /// Named constructor that creates a LatLng from a string (e.g., "40.7128,-74.0060")
  LatLng.fromString(String latLngAsString)
      : assert(latLngAsString.split(',').length >= 2),
        latitude = double.parse(latLngAsString.split(',')[0]),
        longitude = double.parse(latLngAsString.split(',')[1]),
        height = latLngAsString.split(',').length == 3
            ? double.parse(latLngAsString.split(',')[2])
            : null,
        super(
            y: double.parse(latLngAsString.split(',')[0]),
            x: double.parse(latLngAsString.split(',')[1]),
            z: latLngAsString.split(',').length == 3
                ? double.parse(latLngAsString.split(',')[2])
                : null,
            type: CoordinateType.geodetic);

  /// Converts sexagesimal string into a lat/long value
  ///
  ///     final LatLng p1 = new LatLng.fromSexagesimal('''51° 31' 10.11" N, 19° 22' 32.00" W''');
  ///     print("${p1.latitude}, ${p1.longitude}");
  ///     // Shows:
  ///     51.519475, -19.37555556
  ///
  factory LatLng.fromSexagesimal(String sexagesimal) {
    double latitude = 0.0;
    double longitude = 0.0;

    // try format '''47° 09' 53.57" N, 8° 32' 09.04" E'''
    var splits = sexagesimal.split(',');
    if (splits.length != 2) {
      // try format '''N 47°08'52.57" E 8°32'09.04"'''
      splits = sexagesimal.split('E');
      if (splits.length != 2) {
        // try format '''N 47°08'52.57" W 8°32'09.04"'''
        splits = sexagesimal.split('W');
        if (splits.length != 2) {
          throw 'Unsupported sexagesimal format: $sexagesimal';
        }
      }
    }

    latitude = _sexagesimalToDecimal(splits[0]);
    longitude = _sexagesimalToDecimal(splits[1]);

    return LatLng(latitude, longitude);
  }

  // Converts latitude and longitude to sexagesimal
  ///
  ///     final LatLng p1 = new LatLng(51.519475, -19.37555556);
  ///
  ///     // Shows: 51° 31' 10.11" N, 19° 22' 32.00" W
  ///     print(p1..toSexagesimal());
  ///
  String toSexagesimal({int decPlaces = 3}) {
    return '${degree2DMSString(
      latitude,
      isLat: true,
      isLatLon: true,
      decPlace: 3,
    )}, ${degree2DMSString(
      longitude,
      isLat: false,
      isLatLon: true,
      decPlace: 3,
    )}';
  }

  /// Convert LatLong to timezone
  ///
  /// Example:
  /// ```
  /// final LatLng pp = LatLng(6.65412, -1.54651);
  /// var timeZone = pp.toTimeZone() // [0, 6, 11.162400000000012] HH,MM,SS
  /// ```
  List<num> toTimeZone() {
    // Converting this all to seconds of longitude gives:

    // Now we find the time zone difference in seconds of time:
    var longInSec =
        degrees2Seconds(longitude) / 15; // seconds before/behind GMT

    // Convert to HH:MM:SS.
    var newTime = degree2DMS(longInSec / 3600);
//'${newTime[0] > 0 ? '+' : '-'}${newTime[0].abs().toString().padLeft(2, '0')}:${newTime[1].toString().padLeft(2, '0')}';
    return newTime;
  }

  @override
  int get hashCode => latitude.hashCode + longitude.hashCode;

  @override
  bool operator ==(final Object other) =>
      other is LatLng &&
      latitude == other.latitude &&
      longitude == other.longitude;

  // Helper function to convert sexagesimal to decimal
  static double _sexagesimalToDecimal(String sexagesimal) {
    final parts = sexagesimal
        .trim()
        .split(RegExp('[°\'"]'))
        .where((part) => part.isNotEmpty)
        .toList();
    double decimal = double.parse(parts[0].trim()) +
        double.parse(parts[1].trim()) / 60 +
        double.parse(parts[2].trim()) / 3600;
    if (sexagesimal.toUpperCase().contains('S') ||
        sexagesimal.toUpperCase().contains('W')) {
      decimal = -decimal;
    }

    return decimal;
  }
}
