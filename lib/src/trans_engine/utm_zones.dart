class UTMZones {
  final List<String> _letters = [
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
    'M',
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

  final List<int> _degrees = [
    -90,
    -84,
    -72,
    -64,
    -56,
    -48,
    -40,
    -32,
    -24,
    -16,
    -8,
    0,
    8,
    16,
    24,
    32,
    40,
    48,
    56,
    64,
    72,
    84
  ];

  final List<String> _negLetters = [
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

  final List<int> _negDegrees = [
    -90,
    -84,
    -72,
    -64,
    -56,
    -48,
    -40,
    -32,
    -24,
    -16,
    -8
  ];

  final List<String> _posLetters = [
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

  final List<int> _posDegrees = [0, 8, 16, 24, 32, 40, 48, 56, 64, 72, 84];

  int arrayLength = 22;

  UTMZones();

  int getLatZoneDegree(String letter) {
    String ltr = letter[0];
    for (int i = 0; i < arrayLength; i++) {
      if (_letters[i] == ltr) {
        return _degrees[i];
      }
    }
    return -100;
  }

  String getHemisphere(String latZone) {
    String hemisphere = "N";
    if (_negLetters.contains(latZone)) {
      hemisphere = "S";
    }
    return hemisphere;
  }

  ///Get the UTMZones from the given longitude and latitude
  String getZone({required double latitude, required double longitude}) {
    String zone = (longitude < 0.0
                ? ((180 + longitude) ~/ 6.0) + 1
                : (longitude ~/ 6) + 31)
            .toString() +
        getLatZone(latitude);
    return zone;
  }

  ///Get the Central Meridian from the given longitude
  int getLongZone(double longitude) {
    int longZone = longitude < 0.0
        ? ((180 + longitude) ~/ 6.0) + 1
        : (longitude ~/ 6) + 31;

    return (6 * longZone) - 183;
  }

  String getLatZone(double latitude) {
    int latIndex = -2;
    int lat = latitude.toInt();

    if (lat >= 0) {
      int len = _posLetters.length;
      for (int i = 0; i < len; i++) {
        if (lat == _posDegrees[i]) {
          latIndex = i;
          break;
        }

        if (lat > _posDegrees[i]) {
          continue;
        } else {
          latIndex = i - 1;
          break;
        }
      }
    } else {
      int len = _negLetters.length;
      for (int i = 0; i < len; i++) {
        if (lat == _negDegrees[i]) {
          latIndex = i;
          break;
        }

        if (lat < _negDegrees[i]) {
          latIndex = i - 1;
          break;
        } else {
          continue;
        }
      }
    }

    if (latIndex == -1) {
      latIndex = 0;
    }
    if (lat >= 0) {
      if (latIndex == -2) {
        latIndex = _posLetters.length - 1;
      }
      return _posLetters[latIndex].toString();
    } else {
      if (latIndex == -2) {
        latIndex = _negLetters.length - 1;
      }
      return _negLetters[latIndex].toString();
    }
  }
}
