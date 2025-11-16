import '../classes/nadgrid.dart';
import '../constants/values.dart' as consts;

class Datum {
  late int datumType;
  late List<double> datumParams;
  final double a;
  final double b;
  final double es;
  final double ep2;
  final List<NadgridParam>? grids;

  Datum(
    String? datumCode,
    List<double>? datumParams,
    this.a,
    this.b,
    this.es,
    this.ep2,
    this.grids,
  ) {
    if (datumCode == null || datumCode == 'none') {
      datumType = consts.PJD_NODATUM;
    } else {
      datumType = consts.PJD_WGS84;
    }
    if (datumParams != null && datumParams.isNotEmpty) {
      this.datumParams = datumParams;
      if (this.datumParams[0] != 0 ||
          this.datumParams[1] != 0 ||
          this.datumParams[2] != 0) {
        datumType = consts.PJD_3PARAM;
      }
      if (this.datumParams.length > 3) {
        if (this.datumParams[3] != 0 ||
            this.datumParams[4] != 0 ||
            this.datumParams[5] != 0 ||
            this.datumParams[6] != 0) {
          datumType = consts.PJD_7PARAM;
          this.datumParams[3] *= consts.SEC_TO_RAD;
          this.datumParams[4] *= consts.SEC_TO_RAD;
          this.datumParams[5] *= consts.SEC_TO_RAD;
          this.datumParams[6] = (this.datumParams[6] / 1000000.0) + 1.0;
        }
      }
    }

    if (grids != null) {
      datumType = consts.PJD_GRIDSHIFT;
    }
  }
}
