part of "../../geoengine.dart";

/// The `GeoData` class for handling geospatial data in various formats.
///
/// This class provides methods to read from and write to different geospatial
/// data formats like CSV, TXT, ESRI Shapefile, and GeoJSON. It also includes
/// functionalities to manipulate the data such as adding, deleting, and updating rows and columns.
///
/// Example:
/// ```dart
///   // Future<void> main(List<String> args) async {
///   // Read file
///   final geoData = await GeoData.readFile(
///     'example/GH.txt',
///     delimiter: '\t',
///     hasHeader: false,
///     coordinatesColumns: {
///       'latitude': 4,
///       'longitude': 5
///     }, // Specify column names and indices
///   );
///
///   // Get row count
///   print(geoData.rows.length);
///
///   // Delete a row
///   geoData.deleteRow(0);
///
///   // Add a new column
///   geoData.addColumn('newColumn', defaultValue: 'defaultValue');
///
///   // Delete a column
///   geoData.deleteColumn('newColumn');
///
///   // Update a cell
///   geoData.updateCell(1, 'latitude', 23.45);
///
///   // Get a specific row
///   var row = geoData.getRow(1);
///   print(row);
///
///   // Find rows based on a query
///   var foundRows = geoData
///       .findRows((row) => row['latitude'] > 6.5 && row['longitude'] < 0.5);
///   print(foundRows.length);
///
///   // // Export data to CSV
///   // await geoData.toFile('example/output.csv');
/// }
///```
class GeoData {
  /// A list of maps where each map represents a row in the geospatial data.
  final List<Map<String, dynamic>> rows;

  /// The headers for the data columns.
  List<String> headers;

  // Private constructor for internal use.
  GeoData._(this.rows, this.headers);

  /// Gets the number of rows in the data.
  int get rowCount => rows.length;

  /// Gets the number of columns in the data.
  int get columnCount => headers.length;

  /// A constant map linking file extensions to their respective drivers.
  static const Map<String, String> _extensionToDriver = {
    ".csv": "CSV",
    ".txt": "TXT",
    ".json": "GeoJSON",
    // Not implemented yet
    ".geojson": "GeoJSON",
    ".geojsonl": "GeoJSONSeq",
    ".geojsons": "GeoJSONSeq",
    ".bna": "BNA",
    ".dxf": "DXF",
    ".shp": "ESRI Shapefile",
    ".dbf": "ESRI Shapefile",
    ".gpkg": "GPKG",
    ".gml": "GML",
    ".xml": "GML",
    ".kml": "KML",
    ".gpx": "GPX",
    ".gtm": "GPSTrackMaker",
    ".gtz": "GPSTrackMaker",
    ".tab": "MapInfo File",
    ".mif": "MapInfo File",
    ".mid": "MapInfo File",
    ".dgn": "DGN",
    ".fgb": "FlatGeobuf",
  };

  /// Determines the appropriate driver for a given file extension.
  ///
  /// Returns the driver as a string. If no matching driver is found, returns 'Unknown'.
  static String _getDriverForExtension(String filePath) {
    String extension = filePath.split('.').last.toLowerCase();
    return _extensionToDriver[".$extension"] ?? 'Unknown';
  }

  /// Reads spatial data from a file, automatically determining the driver.
  ///
  /// [filePath]: The path of the file to read.
  /// [driver]: The type of driver to use. Defaults to 'Auto', which automatically determines the driver.
  /// Other parameters as per your existing implementation.
  ///
  /// Returns a `Future<GeoData>` representing the read data.
  static Future<GeoData> readFile(
    String filePath, {
    String driver = 'Auto',
    String delimiter = ',',
    bool hasHeader = true,
    String eol = '\r\n',
    String textDelimiter = '"',
    bool delimitAllFields = false,
    Map<String, int>? coordinatesColumns,
  }) async {
    if (driver == 'Auto') {
      driver = _getDriverForExtension(filePath);
    }

    switch (driver) {
      case 'TXT':
      case 'CSV':
        FileIO fileIO = FileIO();
        Stream<String> lines;

        if (filePath.isNotEmpty) {
          // Read file
          lines = fileIO.readFileAsStream(filePath);
        } else {
          throw ArgumentError('Either inputFilePath must be provided.');
        }

        List<String> headers = [];
        final List<Map<String, dynamic>> data = [];

        await for (String line in lines) {
          if (headers.isEmpty && hasHeader) {
            headers = line.split(delimiter).map((e) => e.trim()).toList();
            continue;
          }

          final values = line.split(delimiter).map((e) => e.trim()).toList();
          final entryData = <String, dynamic>{};

          for (var column in coordinatesColumns!.entries) {
            final columnIndex = column.value;
            final columnValue = double.tryParse(values[columnIndex]);
            if (columnValue == null) {
              continue; // Skip if coordinate value is invalid
            }
            entryData[column.key] = columnValue;
          }

          if (headers.isEmpty) {
            headers = List.generate(values.length, (i) => i.toString());
          }

          for (var i = 0; i < values.length; i++) {
            entryData[headers[i]] = values[i];
          }

          data.add(entryData);
        }

        return GeoData._(data, headers);

      case 'ESRI Shapefile':
        // Read Shapefile

        break;
      case 'GeoJSON':
        // Read GeoJSON
        //GeoJSON.fromMap(map);
        break;
      // Add more cases for other drivers
      default:
        // Handle unknown or unsupported driver
        break;
    }

    return GeoData._([], []); // Placeholder return
  }

  /// Exports the data to different file formats, automatically determining the driver.
  ///
  /// [filePath]: The path of the file to write to.
  /// Other parameters as per your existing implementation.
  ///
  /// Returns a `Future<void>` indicating the completion of the file writing process.
  Future<void> toFile(
    String filePath, {
    String driver = 'Auto',
    String delimiter = ',',
    bool hasHeader = true,
    String defaultEol = '\r\n',
    String defaultTextDelimiter = '"',
    bool defaultDelimitAllFields = false,
  }) async {
    if (driver == 'Auto') {
      driver = _getDriverForExtension(filePath);
    }

    switch (driver) {
      case 'TXT':
      case 'CSV':
        // Export to CSV TXT
        FileIO fileIO = FileIO();
        final buffer = StringBuffer();
        buffer.writeln(headers.join(delimiter));

        for (var row in rows) {
          final rowValues =
              headers.map((h) => row[h]?.toString() ?? '').toList();
          buffer.writeln(rowValues.join(delimiter));
        }

        fileIO.saveToFile(filePath, buffer.toString());
        break;
      case 'ESRI Shapefile':
        // Export to Shapefile
        break;
      case 'GeoJSON':
        // Export to GeoJSON

        break;
      // Add more cases for other drivers
      default:
        // Handle unknown or unsupported driver
        break;
    }
  }

  /// Adds a new row to the data.
  ///
  /// [row]: The map representing the row to add.
  /// Each key in the map should correspond to a header.
  void addRow(Map<String, dynamic> row) {
    // Ensure the row contains all headers.
    for (var header in headers) {
      row.putIfAbsent(header, () => null);
    }
    rows.add(row);
  }

  /// Deletes a row by index.
  void deleteRow(int index) {
    if (index >= 0 && index < rows.length) {
      rows.removeAt(index);
    }
  }

  /// Adds a new column to the data.
  void addColumn(String columnName, {dynamic defaultValue}) {
    headers.add(columnName);
    for (var row in rows) {
      row[columnName] = defaultValue;
    }
  }

  /// Deletes a column from the data.
  void deleteColumn(String columnName) {
    headers.remove(columnName);
    for (var row in rows) {
      row.remove(columnName);
    }
  }

  /// Updates a specific cell in the table.
  void updateCell(int rowIndex, String columnName, dynamic value) {
    if (rowIndex >= 0 &&
        rowIndex < rows.length &&
        headers.contains(columnName)) {
      rows[rowIndex][columnName] = value;
    }
  }

  /// Gets a specific row by index.
  Map<String, dynamic>? getRow(int index) {
    return (index >= 0 && index < rows.length) ? rows[index] : null;
  }

  /// Finds rows based on a query function.
  List<Map<String, dynamic>> findRows(
      bool Function(Map<String, dynamic>) query) {
    return rows.where(query).toList();
  }
}
