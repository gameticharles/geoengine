import 'dart:async';
import 'dart:html';

import 'file_io.dart';

class FileIO implements FileIOBase {
  void _saveToFileWeb(String path, String data) {
    var blob = Blob([data]);
    var url = Url.createObjectUrlFromBlob(blob);
    var anchor = document.createElement('a') as AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = path;
    document.body!.children.add(anchor);

    // download the file
    anchor.click();

    // cleanup the DOM
    document.body!.children.remove(anchor);
    Url.revokeObjectUrl(url);
  }

  Future<String> _readFromFileWeb(InputElement uploadInput) async {
    var file = uploadInput.files!.first;
    var reader = FileReader();

    var completer = Completer<String>();
    reader.onLoadEnd.listen((e) {
      completer.complete(reader.result as String);
    });
    reader.onError.listen((fileError) {
      completer.completeError(fileError);
    });
    reader.readAsText(file);

    return completer.future;
  }

  @override
  void saveToFile(String path, String data) {
    _saveToFileWeb(data, path);
  }

  @override
  Future<String> readFromFile(dynamic uploadInput) async {
    return await _readFromFileWeb(uploadInput);
  }

  @override
  Stream<String> readFileAsStream(String path) {
    // Stream-based reading is not directly supported in web environments.
    // You may need to implement custom logic depending on the use case.
    // Typically, file reading in web is event-driven, as shown in _readFromFileWeb.
    throw UnimplementedError(
        'Stream reading is not supported in web environments.');
  }

  @override
  StreamSink<String> writeFileAsStream(dynamic path) {
    // Stream-based writing is not directly supported in web environments.
    // Implementing this would require a custom approach, maybe accumulating data in memory
    // and then triggering a download when the stream is closed.
    throw UnimplementedError(
        'Stream writing is not supported in web environments.');
  }
}
