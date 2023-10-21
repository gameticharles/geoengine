import 'package:geoengine/geoengine.dart';

void main() {
  var utm = UTM(
    zoneNumber: 35,
    zoneLetter: 'J',
    easting: 527924.23,
    northing: 6537662.80,
    height: 1312,
  );

  print(utm.toLatLng());
  LatLng p = LatLng(-31.295043, 27.293409, 1312);
  print(p.toUTM());

  print('\n---Express Ellipsoid in different formats---');
  // Print WKT2 of the Ellipsoid
  print(Ellipsoid.wgs84.toEsriWKT());
  print(Ellipsoid.wgs84.toWKT());
  print(Ellipsoid.wgs84.toWKT2());
  print(Ellipsoid.wgs84.toGeoServer());
  print(Ellipsoid.wgs84.toJSON());

  // Create a random point
  final LatLng pp = LatLng(6.65412, -1.54651, 200);

  // Set up converter
  CoordinateConversion transCoordinate = CoordinateConversion();

  Projection sourceProjection = Projection.WGS84; // Geodetic
  //Projection sourceProjection = Projection.get('EPSG:4326')!; // Geodetic
  Projection targetProjection = Projection.parse(
      'PROJCS["Accra / Ghana National Grid",GEOGCS["Accra",DATUM["Accra",SPHEROID["War Office",6378300,296,AUTHORITY["EPSG","7029"]],TOWGS84[-199,32,322,0,0,0,0],AUTHORITY["EPSG","6168"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4168"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",4.666666666666667],PARAMETER["central_meridian",-1],PARAMETER["scale_factor",0.99975],PARAMETER["false_easting",900000],PARAMETER["false_northing",0],UNIT["Gold Coast foot",0.3047997101815088,AUTHORITY["EPSG","9094"]],AXIS["Easting",EAST],AXIS["Northing",NORTH],AUTHORITY["EPSG","2136"]]');

  print('\n---Convert Projected To Geodetic (GH -> WGS 84)---');
  var gp = PointX(x: 665000, y: 544000);
  var np = transCoordinate.convert(
    point: gp,
    projSrc: targetProjection,
    projDst: sourceProjection,
    conversion: ConversionType.projectedToGeodetic,
  );

  var ut = np.asLatLng().toUTM();
  print('GH Pt=> ${gp.x}, ${gp.y}');
  print('WGS 84 Geodetic Pt=> ${np.asLatLng()}');
  print('WGS 84 UTM Pt=> $ut');

  print('\n---Convert Geodetic To Geodetic (WGS 84 -> GH)---');
  var res = transCoordinate.convert(
    point: pp,
    projSrc: sourceProjection,
    projDst: targetProjection,
    conversion: ConversionType.geodeticToGeodetic,
  );
  print('WGS 84 Pt=> $pp');
  print('GH Pt=> ${res.asLatLng()}');

  print('\n---Convert LatLng To TimeZone---');
  var tz = pp.toTimeZone();
  print(
      'Time Zone at location (${pp.latitude}, ${pp.longitude}) [HH:MM:SS] = (${tz[0].toString().padLeft(2, '0')}:${tz[1].toString().padLeft(2, '0')}:${tz[2].round().toString().padLeft(2, '0')})');

  print('\n---Compute Distances---');
  var point1 = LatLng(dms2Degree(50, 03, 59), dms2Degree(-5, 42, 53));
  var point2 = LatLng(dms2Degree(58, 38, 38), dms2Degree(-3, 04, 12));

  print(
      'Distance (Haversine): ${point1.distanceTo(point2, method: DistanceMethod.haversine)!.valueInUnits(LengthUnits.kilometers)} km');
  print(
      'Distance (Great Circle): ${point1.distanceTo(point2, method: DistanceMethod.greatCircle)!.valueInUnits(LengthUnits.kilometers)} km');
  print(
      'Distance (Vincenty): ${point1.distanceTo(point2, method: DistanceMethod.vincenty)!.valueInUnits(LengthUnits.kilometers)} km');

  print('\n---Compute Cross and Along Track Distances---');
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
