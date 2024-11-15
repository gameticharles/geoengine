import 'package:advance_math/advance_math.dart';
import 'package:geoengine/geoengine.dart';

void main(List<String> args) async {
// Search Point
  var point2 = LatLng(6, -1.5);

  var googleGeocoder = Geocoder(
      strategyFactory: GoogleStrategy.create('YOUR_GOOGLE_API_KEY'),
      config: {
        // Common Configurations
        'language': 'en',
        'requestTimeout': const Duration(seconds: 10),

        // Google-Specific Configurations
        'regionBias': 'US',
        'resultType': 'address',
        'locationType': 'ROOFTOP',
        'components': 'country:US',
        'rateLimit': 10, // Requests per second
      });

  GeocoderRequestResponse googleSearch = await googleGeocoder.search('KNUST');
  print(googleSearch);

  var openStreetMapGeocoder =
      Geocoder(strategyFactory: OpenStreetMapStrategy.create(), config: {
    // Common Configurations
    'language': 'en',
    'requestTimeout': const Duration(seconds: 10),

    // OpenStreetMap-Specific Configurations
    'email': 'contact@example.com', // For Nominatim usage policy
    'countryCodes': 'us,uk',
    'viewBox': 'left,bottom,right,top',
    'boundedViewBox': '1', //bounded to viewBox
    'limit': 5,
    'addressDetails': 1,
  });

  GeocoderRequestResponse search = await openStreetMapGeocoder.search('KNUST');
  print(search);
  print('');

  GeocoderRequestResponse rev = await openStreetMapGeocoder.reverse(point2);
  print(rev);
  print('');

  // List<Map<String, double>> points = [
  //   {'latitude': 5.80736, 'longitude': 0.41074},
  //   {'latitude': 6.13373, 'longitude': 0.81585},
  //   {'latitude': 11.01667, 'longitude': -0.5},
  //   {'latitude': 10.08587, 'longitude': -0.13587},
  //   {'latitude': 9.35, 'longitude': -0.88333},
  //   {'latitude': 10.73255, 'longitude': -1.05917},
  // ];

  final geoData = await GeoData.readFile(
    'example/GH.txt',
    delimiter: '\t',
    hasHeader: false,
    coordinatesColumns: {
      'latitude': 4,
      'longitude': 5
    }, // Specify column names and indices
  );
  print(geoData.rows.length);

  var localGeocoder = Geocoder(
      strategyFactory: LocalStrategy.create(
        entries: geoData.rows,
        coordinatesColumnNames: (y: 'latitude', x: 'longitude'),
      ),
      config: {
        // Common Configurations
        'language': 'en',
        'requestTimeout': const Duration(seconds: 10),

        // Local-Specific Configurations
        'isGeodetic': true,
        'searchRadius': 2000, // in meters
        'limit': 5, // Number of results to return
        'dataPreprocessing': (data) => {/* preprocessing logic */},
        'cacheSize': 100,
        'indexingStrategy': 'KDTree', // or 'RTree'
      });

  GeocoderRequestResponse u = await localGeocoder.search('Kotei');
  print(u);
  print('');

  GeocoderRequestResponse rex = await localGeocoder.reverse(point2);
  print(rex);
  print('');

  rex.result.forEach((x) {
    // print(x);
    var point1 = LatLng((x[0]['latitude']), x[0]['longitude']);

    print('Initial Bearing: ${point1.initialBearingTo(point2)}');
    print('Final Bearing: ${point1.finalBearingTo(point2)}');
    print(
        'Distance (Haversine): ${point1.distanceTo(point2, method: DistanceMethod.haversine)!.valueInUnits(LengthUnits.kilometers)} km');
    print(
        'Distance (Great Circle): ${point1.distanceTo(point2, method: DistanceMethod.greatCircle)!.valueInUnits(LengthUnits.kilometers)} km');
    print(
        'Distance (Vincenty): ${point1.distanceTo(point2, method: DistanceMethod.vincenty)!.valueInUnits(LengthUnits.kilometers)} km');
    print('');
  });
}
