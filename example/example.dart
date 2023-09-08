import 'package:geoengine/geoengine.dart';

void main() {
  final LatLng pp = LatLng(6.65412, -1.54651, 200);

  CoordinateConversion transCoordinate = CoordinateConversion();

  Projection sourceProjection = Projection.get('EPSG:4326')!; // Geodetic
  Projection targetProjection = Projection.parse(
      'PROJCS["Accra / Ghana National Grid",GEOGCS["Accra",DATUM["Accra",SPHEROID["War Office",6378300,296,AUTHORITY["EPSG","7029"]],TOWGS84[-199,32,322,0,0,0,0],AUTHORITY["EPSG","6168"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4168"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",4.666666666666667],PARAMETER["central_meridian",-1],PARAMETER["scale_factor",0.99975],PARAMETER["false_easting",900000],PARAMETER["false_northing",0],UNIT["Gold Coast foot",0.3047997101815088,AUTHORITY["EPSG","9094"]],AXIS["Easting",EAST],AXIS["Northing",NORTH],AUTHORITY["EPSG","2136"]]');

  var res = transCoordinate.convert(
    point: pp,
    projSrc: sourceProjection,
    projDst: targetProjection,
    conversion: ConversionType.geodeticToGeodetic,
  );

  print(res);
  print(pp.toTimeZone());

  var startPoint = LatLng(51.8853, 0.2545);
  var endPoint = LatLng(49.0034, 2.5735);
  var thirdPoint = LatLng(50.9640, 1.8523);

  var crossTrackDist = thirdPoint.crossTrackDistanceTo(startPoint, endPoint);
  var alongTrackDist = thirdPoint.alongTrackDistanceTo(startPoint, endPoint);

  print(
      'Cross-track distance: ${crossTrackDist.valueInUnits(LengthUnits.kilometers)} km');
  print(
      'Along-track distance: ${alongTrackDist.valueInUnits(LengthUnits.kilometers)} km');
}
