// ignore_for_file: overridden_fields

import '../common/utils.dart' as utils;
import '../constants/values.dart' as consts;
import '../projections/etmerc.dart';

class UniversalTransverseMercatorProjection
    extends ExtendedTransverseMercatorProjection {
  static final List<String> names = [
    'Universal Transverse Mercator System',
    'utm'
  ];

  int zone;
  bool utmSouth;
  @override
  double lat0;
  @override
  double long0;
  @override
  double x0;
  @override
  double y0;
  @override
  double k0;

  UniversalTransverseMercatorProjection.init(super.params)
      : zone = utils.adjust_zone(params.zone, params.long0),
        utmSouth = params.utmSouth == true,
        lat0 = 0,
        long0 = ((6 * params.zone!.abs()) - 183) * consts.D2R,
        x0 = 500000,
        y0 = params.utmSouth == true ? 10000000 : 0,
        k0 = 0.9996,
        super.init();
}
