import 'file_io.dart';

class FileIO implements FileIOBase {
  @override
  void saveToFile(String path, String data) {
    throw UnsupportedError('Cannot save a file without dart:io or dart:html.');
  }

  @override
  Future<String> readFromFile(dynamic pathOrUploadInput) {
    throw UnsupportedError('Cannot read a file without dart:io or dart:html.');
  }

  @override
  Stream<String> readFileAsStream(String pathOrUploadInput) {
    throw UnsupportedError('Cannot read a file without dart:io or dart:html.');
  }

  @override
  writeFileAsStream(pathOrData) {
    throw UnsupportedError('Cannot save a file without dart:io or dart:html.');
  }
}
