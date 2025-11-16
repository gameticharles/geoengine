import '../../points/points.dart';
import '../classes/projection.dart';
import '../common/datum_utils.dart' as datum_utils;

class GeocentricProjection extends Projection {
  static final List<String> names = [
    'Geocentric',
    'geocentric',
    'geocent',
    'Geocent'
  ];

  String name;

  GeocentricProjection.init(super.params)
      : name = 'geocent',
        super.init();

  @override
  Point forward(Point p) {
    var point = datum_utils.geodeticToGeocentric(p, es, a);
    return point;
  }

  @override
  Point inverse(Point p) {
    var point = datum_utils.geocentricToGeodetic(p, es, a, b);
    return point;
  }
}
