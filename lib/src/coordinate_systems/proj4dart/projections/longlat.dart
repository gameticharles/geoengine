import '../../points/points.dart';
import '../classes/projection.dart';

class LongLat extends Projection {
  static final List<String> names = ['longlat', 'identity'];

  final String? datumCode;
  final String? datumName;

  LongLat.init(super.params)
      : datumCode = params.datumCode,
        datumName = params.datumName,
        super.init();

  @override
  Point forward(Point p) {
    return p;
  }

  @override
  Point inverse(Point p) {
    return p;
  }
}
