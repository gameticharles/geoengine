import 'package:geoengine/geoengine.dart';

Future<void> main(List<String> args) async {
  // Read file
  final geoData = await GeoData.readFile(
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

  // Delete a row
  geoData.deleteRow(0);

  // Add a new column
  geoData.addColumn('newColumn', defaultValue: 'defaultValue');

  // Delete a column
  geoData.deleteColumn('newColumn');

  // Update a cell
  geoData.updateCell(1, 'latitude', 23.45);

  // Get a specific row
  var row = geoData.getRow(1);
  print(row);

  // Find rows based on a query
  var foundRows = geoData
      .findRows((row) => row['latitude'] > 6.5 && row['longitude'] < 0.5);
  print(foundRows.length);

  // // Export data to CSV
  // await geoData.toFile('example/output.csv');
}
