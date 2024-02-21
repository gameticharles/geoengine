import '../file_helper/file_io.dart';

/// CSV provides functionality to read and write CSV files.
///
/// The CSV class can read a CSV file into memory and provides access to the
/// headers and rows of data. It also allows exporting the in-memory
/// representation back to a CSV file.
///
/// The static readCSVorTXT() method does the work of parsing a file into
/// headers and rows. The exportToCSV() method writes the headers and rows
/// back to a CSV file.
class CSV {
  List<String> headers;
  List<Map<String, dynamic>> rows;

  CSV._(this.rows, this.headers);

  // Getters for various properties
  int get rowCount => rows.length;
  int get columnCount => headers.length;

  static Future<CSV> readCSVorTXT(
    String filePath, {
    String delimiter = ',',
    bool hasHeader = true,
    String eol = '\r\n',
    String textDelimiter = '"',
    bool delimitAllFields = false,
    required Map<String, int> coordinatesColumns, // Column names and indexes
  }) async {
    FileIO fileIO = FileIO();
    List<String> lines = [];

    if (filePath.isNotEmpty) {
      // Read file
      lines = (await fileIO.readFromFile(filePath)).split('\n');
    } else {
      throw ArgumentError('Either inputFilePath must be provided.');
    }

    List<String> headers = hasHeader
        ? lines.first.split(delimiter).map((e) => e.trim()).toList()
        : [];
    final List<Map<String, dynamic>> data = [];

    for (final line in lines.skip(hasHeader ? 1 : 0)) {
      final values = line.split(delimiter).map((e) => e.trim()).toList();
      final entryData = <String, dynamic>{};

      for (var column in coordinatesColumns.entries) {
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

    return CSV._(data, headers);
  }

  /// Exports the data to a CSV format with headers.
  ///
  /// [outputFile]: The file where the CSV data will be written.
  /// [delimiter]: The delimiter used to separate values in the CSV. Defaults to ','.
  Future<void> exportToCSV({
    required String outputFilePath,
    String delimiter = ',',
  }) async {
    FileIO fileIO = FileIO();
    final buffer = StringBuffer();
    buffer.writeln(headers.join(delimiter));

    for (var row in rows) {
      final rowValues = headers.map((h) => row[h]?.toString() ?? '').toList();
      buffer.writeln(rowValues.join(delimiter));
    }

    fileIO.saveToFile(outputFilePath, buffer.toString());
  }
}
