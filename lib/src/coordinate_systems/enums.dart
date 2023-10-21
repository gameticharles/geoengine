part of geoengine;

///Enum for the types of datum-to-datum conversions
enum ConversionType {
  geocentricToGeodetic,
  geocentricToProjected,
  geocentricToGeocentric,

  geodeticToGeodetic,
  geodeticToProjected,
  geodeticToGeocentric,

  projectedToGeodetic,
  projectedToProjected,
  projectedToGeocentric,
}

///Enum for the different types of
///coordinates supported by the the software
enum CoordinateType {
  geocentric,
  geodetic,
  projected,
}

/// Get the conversion type from the source coordinate type to the target coordinate type.
///
/// [sourceCoordinateType]: The source coordinate type.
/// [targetCoordinateType]: The target coordinate type.
/// Returns the `ConversionType` enum representing the conversion type.
ConversionType getConversionType(
    CoordinateType sourceCoordinateType, CoordinateType targetCoordinateType) {
  var conversionType = ConversionType.geodeticToGeodetic;

  String conv =
      '${sourceCoordinateType.toString().split('.')[1].toLowerCase()}To${targetCoordinateType.toString().split('.')[1].capitalize()}';

  conversionType = ConversionType.values
      .firstWhere((e) => e.toString().split('.')[1] == conv);

  return conversionType;
}

List<String> getCoordinateHeaderLabels(CoordinateType coordinateType) {
  return coordinateType == CoordinateType.geodetic
      ? ['Longitude', 'Latitude', 'Altitude']
      : coordinateType == CoordinateType.geocentric
          ? ['Cartesian-X', 'Cartesian-Y', 'Cartesian-Z']
          : ['Eastings', 'Northings', 'Height'];
}
