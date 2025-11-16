part of 'coordinate_reference_systems.dart';

/// A class that provides methods to calculate UTM (Universal Transverse Mercator) zones and related information.
class UTMZones {
  static const Map<String, int> _degreesMap = {
    'A': -90,
    'C': -84,
    'D': -72,
    'E': -64,
    'F': -56,
    'G': -48,
    'H': -40,
    'J': -32,
    'K': -24,
    'L': -16,
    'M': -8,
    'N': 0,
    'P': 8,
    'Q': 16,
    'R': 24,
    'S': 32,
    'T': 40,
    'U': 48,
    'V': 56,
    'W': 64,
    'X': 72,
    'Z': 84,
  };

  static const List<String> _positiveLetters = [
    'N',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Z'
  ];
  static const List<String> _negativeLetters = [
    'A',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'J',
    'K',
    'L',
    'M'
  ];

  /// Get the UTM zone identifier based on the given latitude and longitude.
  ///
  /// [latitude]: The latitude value in decimal degrees.
  /// [longitude]: The longitude value in decimal degrees.
  /// Returns the UTM zone identifier as a string.
  String getZone({required double latitude, required double longitude}) {
    final int longZone = longitude < 0.0
        ? ((180 + longitude) ~/ 6.0) + 1
        : (longitude ~/ 6) + 31;
    return '$longZone${getHemisphere(getLatZone(latitude))}';
  }

  /// Get the central meridian value for the UTM zone based on the given longitude.
  ///
  /// [longitude]: The longitude value in decimal degrees.
  /// Returns the central meridian value for the UTM zone.
  int getCentralMeridian(double longitude) {
    final int longZone = longitude < 0.0
        ? ((180 + longitude) ~/ 6.0) + 1
        : (longitude ~/ 6) + 31;
    return (6 * longZone) - 183;
  }

  /// Get the Zone Number from the Longitude
  ///
  /// [longitude]: The longitude value in decimal degrees.
  /// Returns the Zone Number for the LatLon point.
  int getLongZone(double longitude) {
    final int longZone = longitude < 0.0
        ? ((180 + longitude) ~/ 6.0) + 1
        : (longitude ~/ 6) + 31;
    return longZone;
  }

  /// Get the latitude zone letter based on the given latitude.
  ///
  /// [latitude]: The latitude value in decimal degrees.
  /// Returns the latitude zone letter as a string.
  String getLatZone(double latitude) {
    final String letter = latitude >= 0
        ? _positiveLetters.firstWhere((ltr) => latitude < _degreesMap[ltr]!)
        : _negativeLetters.lastWhere((ltr) => latitude >= _degreesMap[ltr]!);
    return letter;
  }

  /// Get the hemisphere (N or S) based on the latitude zone.
  ///
  /// [latZone]: The latitude zone.
  /// Returns the hemisphere letter "N" for northern hemisphere and "S" for southern hemisphere.
  String getHemisphere(String latZone) {
    String hemisphere = "N";
    if (_negativeLetters.contains(latZone)) {
      hemisphere = "S";
    }
    return hemisphere;
  }
}
