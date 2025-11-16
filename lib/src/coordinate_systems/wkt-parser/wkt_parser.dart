/// wkt_parser library
library;

import 'src/clean_wkt.dart' as clean_wkt;
import 'src/parser.dart';
import 'src/process.dart' as process;
import 'src/proj_wkt.dart';

export 'src/proj_wkt.dart';

ProjWKT parseWKT(String wkt) {
  var lisp = Parser.parseString(wkt);
  var type = lisp.removeAt(0).toString();
  var name = lisp.removeAt(0).toString();
  lisp.insert(0, <dynamic>['name', name]);
  lisp.insert(0, <dynamic>['type', type]);
  var obj = <String, dynamic>{};
  process.sExpr(lisp, obj);
  clean_wkt.cleanWKT(obj);
  var wktObj = ProjWKT(obj);
  return wktObj;
}
