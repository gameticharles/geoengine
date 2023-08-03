import 'package:geoengine/geoengine.dart';

//https://www.movable-type.co.uk/scripts/latlong.html

void main() {
  // var p1 = Point(1223, 1186.5);
  // var p2 = Point(1400, 1186.5);

  // print(p1.distanceTo(p2));
  // var bear = p1.bearingTo(p2);
  // print(bear);

  // var delta_e = p2.x - p1.x;
  // var delta_n = p2.y - p1.y;
  // print('$delta_e  $delta_n');
  // var angle = toDegrees(atan2(delta_e, delta_n));
  // var bearing = angle >= 0 ? angle : 360 + angle;
  // print(bearing);

  //  var wcb = (Angle(deg: 240) + Angle.fromDegMinSec(240, 1, 0)) as Angle;

  // // print(wcb);
  // print(Angle(deg: wcb.normalize()));

  //----------------------------------------------------------------

  final LatLng pp = LatLng(6.65412, -1.54651);
  CoordinateConversion transCoordinate = CoordinateConversion();
  CoordinateType sourceCoordinateType = CoordinateType.geodetic;
  CoordinateType targetCoordinateType = CoordinateType.projected;

  Projection sourceProjection = Projection.get('EPSG:4326')!;
  Projection targetProjection = Projection.get('EPSG:4326')!;
  Projection targetProjectionUTM =
      transCoordinate.getUTMProjection(pp.longitude);

  var res = CoordinateConversion().convert(
    point: pp,
    projSrc: sourceProjection,
    projDst: targetProjectionUTM,
    conversion: transCoordinate.getConversionType(
        sourceCoordinateType, targetCoordinateType),
  );

  print(res);
  print(pp.toTimeZone());

  // Shows: 51° 31' 10.11" N, 19° 22' 32.00" W
  print(pp.toSexagesimal(decPlaces: 3));
}
