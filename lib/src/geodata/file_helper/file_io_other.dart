import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'file_io.dart';

class FileIO implements FileIOBase {
  void _saveToFileDesktop(String path, String data) async {
    var file = File(path);
    await file.writeAsString(data);
  }

  Future<String> _readFromFileDesktop(String path) async {
    var file = File(path);
    if (await file.exists()) {
      var contents = await file.readAsString();
      return contents;
    } else {
      throw Exception('File does not exist');
    }
  }

  Stream<String> _readFromFileDesktopAsStream(String path) async* {
    var file = File(path);
    if (await file.exists()) {
      var lines =
          file.openRead().transform(utf8.decoder).transform(LineSplitter());
      await for (var line in lines) {
        yield line;
      }
    } else {
      throw Exception('File does not exist');
    }
  }

  IOSink _writeToFileDesktopAsStream(String path) {
    var file = File(path);
    var sink = file.openWrite();
    return sink;
  }

  @override
  IOSink writeFileAsStream(dynamic path) {
    return _writeToFileDesktopAsStream(path);
  }

  @override
  Stream<String> readFileAsStream(String path) {
    return _readFromFileDesktopAsStream(path);
  }

  @override
  void saveToFile(String path, String data) {
    _saveToFileDesktop(path, data);
  }

  @override
  Future<String> readFromFile(dynamic path) async {
    return await _readFromFileDesktop(path);
  }
}
