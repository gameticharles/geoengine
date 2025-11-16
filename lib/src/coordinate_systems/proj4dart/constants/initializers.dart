import '../classes/proj_params.dart';
import '../classes/projection.dart';
import '../projections/aea.dart';
import '../projections/aeqd.dart';
import '../projections/cass.dart';
import '../projections/cea.dart';
import '../projections/eqc.dart';
import '../projections/eqdc.dart';
import '../projections/etmerc.dart';
import '../projections/gauss.dart';
import '../projections/geocent.dart';
import '../projections/gnom.dart';
import '../projections/gstmerc.dart';
import '../projections/krovak.dart';
import '../projections/laea.dart';
import '../projections/lcc.dart';
import '../projections/longlat.dart';
import '../projections/merc.dart';
import '../projections/mill.dart';
import '../projections/moll.dart';
import '../projections/nzmg.dart';
import '../projections/omerc.dart';
import '../projections/ortho.dart';
import '../projections/poly.dart';
import '../projections/qsc.dart';
import '../projections/robin.dart';
import '../projections/sinu.dart';
import '../projections/somerc.dart';
import '../projections/stere.dart';
import '../projections/sterea.dart';
import '../projections/tmerc.dart';
import '../projections/utm.dart';
import '../projections/vandg.dart';

/// Defines a function structure which returns a projection based on ProjParams
typedef ProjectionInitializer = Projection Function(ProjParams params);

/// Explicit closure initializers
final initializers = <String, ProjectionInitializer>{
  ...{
    for (var name in PseudoMercatorProjection.names)
      name: (params) => PseudoMercatorProjection.init(params)
  },
  ...{for (var name in LongLat.names) name: (params) => LongLat.init(params)},
  ...{
    for (var name in SwissObliqueMercatorProjection.names)
      name: (params) => SwissObliqueMercatorProjection.init(params)
  },
  ...{
    for (var name in AlbersProjection.names)
      name: (params) => AlbersProjection.init(params)
  },
  ...{
    for (var name in AzimuthalEquidistantProjection.names)
      name: (params) => AzimuthalEquidistantProjection.init(params)
  },
  ...{
    for (var name in CassiniProjection.names)
      name: (params) => CassiniProjection.init(params)
  },
  ...{
    for (var name in CentralCylindricalProjection.names)
      name: (params) => CentralCylindricalProjection.init(params)
  },
  ...{
    for (var name in EquidistantCylindricalProjection.names)
      name: (params) => EquidistantCylindricalProjection.init(params)
  },
  ...{
    for (var name in EquidistantConicProjection.names)
      name: (params) => EquidistantConicProjection.init(params)
  },
  ...{
    for (var name in ExtendedTransverseMercatorProjection.names)
      name: (params) => ExtendedTransverseMercatorProjection.init(params)
  },
  ...{
    for (var name in UniversalTransverseMercatorProjection.names)
      name: (params) => UniversalTransverseMercatorProjection.init(params)
  },
  ...{
    for (var name in VanDerGrintenProjection.names)
      name: (params) => VanDerGrintenProjection.init(params)
  },
  ...{
    for (var name in GaussProjection.names)
      name: (params) => GaussProjection.init(params)
  },
  ...{
    for (var name in StereographicNorthProjection.names)
      name: (params) => StereographicNorthProjection.init(params)
  },
  ...{
    for (var name in StereographicSouthProjection.names)
      name: (params) => StereographicSouthProjection.init(params)
  },
  ...{
    for (var name in SinusoidalProjection.names)
      name: (params) => SinusoidalProjection.init(params)
  },
  ...{
    for (var name in RobinsonProjection.names)
      name: (params) => RobinsonProjection.init(params)
  },
  ...{
    for (var name in GeocentricProjection.names)
      name: (params) => GeocentricProjection.init(params)
  },
  ...{
    for (var name in GnomicProjection.names)
      name: (params) => GnomicProjection.init(params)
  },
  ...{
    for (var name in GaussSchreiberTransverseMercatorProjection.names)
      name: (params) => GaussSchreiberTransverseMercatorProjection.init(params)
  },
  ...{
    for (var name in KrovakProjection.names)
      name: (params) => KrovakProjection.init(params)
  },
  ...{
    for (var name in LambertAzimuthalEqualAreaProjection.names)
      name: (params) => LambertAzimuthalEqualAreaProjection.init(params)
  },
  ...{
    for (var name in LambertConformalConicProjection.names)
      name: (params) => LambertConformalConicProjection.init(params)
  },
  ...{
    for (var name in MillerCylindricalProjection.names)
      name: (params) => MillerCylindricalProjection.init(params)
  },
  ...{
    for (var name in MollweideProjection.names)
      name: (params) => MollweideProjection.init(params)
  },
  ...{
    for (var name in NewZealandMapGridProjection.names)
      name: (params) => NewZealandMapGridProjection.init(params)
  },
  ...{
    for (var name in HotineObliqueMercatorProjection.names)
      name: (params) => HotineObliqueMercatorProjection.init(params)
  },
  ...{
    for (var name in OrthographicProjection.names)
      name: (params) => OrthographicProjection.init(params)
  },
  ...{
    for (var name in PolyconicProjection.names)
      name: (params) => PolyconicProjection.init(params)
  },
  ...{
    for (var name in QuadrilateralizedSphericalCubeProjection.names)
      name: (params) => QuadrilateralizedSphericalCubeProjection.init(params)
  },
  ...{
    for (var name in TransverseMercatorProjection.names)
      name: (params) => TransverseMercatorProjection.init(params)
  },
};
