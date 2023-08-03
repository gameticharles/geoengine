part of geoengine;

abstract class GeoFile {
  late File _file;

  // Constructor
  GeoFile(String filePath) {
    _file = File(filePath);
  }

  // Method to read from the file
  Future<String> read() async {
    try {
      return _file.readAsStringSync();
    } catch (e) {
      throw FileSystemException('Could not read file: ${_file.path}');
    }
  }

  // Method to write to the file
  Future<void> write(String data) async {
    try {
      _file.writeAsStringSync(data);
    } catch (e) {
      throw FileSystemException('Could not write to file: ${_file.path}');
    }
  }

  // Method to parse the data from the file
  // This would typically be implemented in the subclasses
  Map<String, dynamic> parse();

  // Method to validate file
  // Placeholder for now, actual implementation depends on file type and would be in subclasses
  bool isValid() {
    return true;
  }
}
