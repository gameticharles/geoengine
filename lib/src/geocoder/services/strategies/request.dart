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
    var startTime = DateTime.now();
    int attempts = 0;
    while (attempts < retries) {
      try {
        final uri = Uri.parse(url);
        final response = await http.get(uri).timeout(requestTimeout);
        if (response.statusCode == 200) {
          return GeocoderRequestResponse(
            success: true,
            duration: DateTime.now().difference(startTime),
            result: json.decode(response.body),
          );
        } else {
          return GeocoderRequestResponse(
            success: false,
            duration: DateTime.now().difference(startTime),
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
            duration: DateTime.now().difference(startTime),
            error: 'Error occurred while fetching data: $e',
          );
        }
      }
    }
    // Return a generic failure response if the loop exits without a return.
    return GeocoderRequestResponse(
      success: false,
      duration: DateTime.now().difference(startTime),
      error: 'Failed to complete the request',
    );
  }
}

/// Represents the response from a geocoding request.
///
/// This class encapsulates the results of a geocoding or reverse geocoding operation,
/// including information about the success or failure of the request, the results
/// of the request (if successful), and any error information (if failed).
///
/// [success]: Indicates whether the geocoding request was successful.
/// [result]: Holds the result of the request if it was successful. The type of this
///           field depends on the implementation of the geocoding strategy.
/// [error]: Contains error message details if the request failed.
/// [statusCode]: The HTTP status code returned by the server (if applicable).
/// [duration]: The time taken to complete the geocoding request.
class GeocoderRequestResponse {
  final bool success;
  final dynamic result;
  final String? error;
  final int? statusCode;
  final Duration? duration;

  /// Constructs a [GeocoderRequestResponse].
  ///
  /// [success]: A boolean indicating the success of the geocoding operation.
  /// [result]: The result of the geocoding operation, which varies based on the strategy.
  /// [error]: An optional string containing error details.
  /// [statusCode]: An optional integer representing the HTTP status code.
  /// [duration]: An optional [Duration] representing the time taken for the request.
  GeocoderRequestResponse({
    required this.success,
    this.result,
    this.error,
    this.statusCode,
    this.duration,
  });

  @override
  String toString() {
    if (success) {
      // Successful response
      return 'GeocoderRequestResponse:\nSuccess: $success\nDuration: ${duration!.inMilliseconds} ms\nResult: $result';
    } else {
      // Response with error
      String errorDetails = 'Error';
      if (statusCode != null) {
        errorDetails += ' (Status code: $statusCode)';
      }
      if (error != null) {
        errorDetails += ': $error';
      }
      return 'GeocoderRequestResponse:\nSuccess: $success\nDuration: ${duration?.inMilliseconds} ms\nError Details: $errorDetails';
    }
  }
}
