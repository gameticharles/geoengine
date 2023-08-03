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

List<String> getCoordinateHeaderLabels(CoordinateType coordinateType) {
  return coordinateType == CoordinateType.geodetic
      ? ['Longitude', 'Latitude', 'Altitude']
      : coordinateType == CoordinateType.geocentric
          ? ['Cartesian-X', 'Cartesian-Y', 'Cartesian-Z']
          : ['Eastings', 'Northings', 'Height'];
}
