import 'package:geoengine/geoengine.dart';

Future<void> main(List<String> args) async {
  // Read file
  final geoData = await GeoDataFrame.readFile(
    'example/GH.txt',
    delimiter: '\t',
    hasHeader: false,
    coordinatesColumns: {
      'latitude': 4,
      'longitude': 5
    }, // Specify column names and indices
  );

  // Get row count
  print(geoData.rows.length);

  print(geoData.head(5));

  // Rename Columns
  geoData.rename({"Column 4": "latitude", "Column 5": "longitude"});

  print(geoData.head(5));

  // Delete a row
  geoData.deleteRow(0);

  // Add a new column
  geoData.addColumn('newColumn', defaultValue: 'defaultValue');

  // Delete a column
  geoData.drop('newColumn');

  // Update a cell
  geoData.updateCell( 'latitude',1, 23.45);

  // Get a specific row
  var row = geoData.getFeature(1);
  print(row);

  // Find rows based on a query
  var foundRows = geoData
      .findFeatures((feature) => num.parse(feature.properties!['latitude'].toString()) > 6.5 && num.parse(feature.properties!['longitude'].toString()) < 0.5);
  print(foundRows.length);

  // // Export data to CSV
  // await geoData.toFile('example/output.csv');
}
