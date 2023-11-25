import 'dart:convert';

import 'package:http/http.dart' as http;

mixin GeocoderRequestMixin {
  /// Performs an HTTP GET request to the specified URL with a retry mechanism.
  ///
  /// This method attempts to send an HTTP GET request to the provided URL.
  /// If the request fails, it retries a specified number of times before
  /// throwing an exception.
  ///
  /// [url]: The URL to which the HTTP GET request is sent. This should be
  ///        a fully qualified URL string.
  ///
  /// [requestTimeout]: The duration to wait before the request times out.
  ///
  /// [retries]: (Optional) The number of times to retry the request in case
  ///            of a failure. Defaults to 3 retries.
  ///
  /// [service]: (Optional) The name of the geocoding service being used.
  ///            This is included in the error message for better context.
  ///
  /// Returns a `Future` that resolves to the `GeocoderRequestResponse` from the API
  ///
  /// Throws a `GeocodingException` if the request fails after the specified
  /// number of retries or if the server returns a non-200 status code.
  Future<GeocoderRequestResponse> performRequest(
      String url, Duration requestTimeout,
      {int retries = 3, String? service}) async {
    int attempts = 0;
    while (attempts < retries) {
      try {
        final uri = Uri.parse(url);
        final response = await http.get(uri).timeout(requestTimeout);
        if (response.statusCode == 200) {
          return GeocoderRequestResponse(
            success: true,
            result: json.decode(response.body),
          );
        } else {
          return GeocoderRequestResponse(
            success: false,
            error:
                'Failed to fetch data${service != null ? ' from $service' : ''}',
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        attempts++;
        if (attempts >= retries) {
          return GeocoderRequestResponse(
            success: false,
            error: 'Error occurred while fetching data: $e',
          );
        }
      }
    }
    // Return a generic failure response if the loop exits without a return.
    return GeocoderRequestResponse(
      success: false,
      error: 'Failed to complete the request',
    );
  }
}

/// Represents the response from a geocoding request.
class GeocoderRequestResponse {
  final bool success;
  final dynamic result;
  final String? error;
  final int? statusCode;

  GeocoderRequestResponse({
    required this.success,
    this.result,
    this.error,
    this.statusCode,
  });

  @override
  String toString() {
    if (success) {
      return 'GeocoderRequestResponse: Success: $success\nBody: $result';
    } else {
      // Error reporting with status code and error message
      String errorDetails = 'Error';
      if (statusCode != null) {
        errorDetails += ' (Status code: $statusCode)';
      }
      if (error != null) {
        errorDetails += ': $error';
      }
      return 'GeocoderRequestResponse:(Success: $success, $errorDetails)';
    }
  }
}
