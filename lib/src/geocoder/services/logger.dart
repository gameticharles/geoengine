/// Defines log levels used for controlling logging output.
///
/// This enum provides levels for logging, allowing messages to be categorized
/// by their importance. The log levels are, in order of increasing importance:
/// [debug], [info], [warning], [error].
enum LogLevel { debug, info, warning, error }

/// A simple logger for managing logging across the application.
///
/// This logger supports different levels of logging and is capable of
/// filtering log messages based on the specified log level.
class Logger {
  /// The minimum level of messages that will be logged.
  ///
  /// Messages with a level lower than [level] will not be logged.
  final LogLevel level;

  /// Constructs a Logger instance with the given minimum log level.
  ///
  /// [level]: The minimum [LogLevel] to log. Messages with a lower
  /// level than this will not be logged.
  Logger(this.level);

  /// Logs a message if its level is greater than or equal to the logger's level.
  ///
  /// This method checks the level of the message against the logger's
  /// minimum level. If the message level is greater than or equal to
  /// the minimum level, it is printed to the console.
  ///
  /// [message]: The message to log.
  /// [messageLevel]: The level of the message.
  void log(String message, LogLevel messageLevel) {
    if (messageLevel.index >= level.index) {
      print('[$messageLevel] $message');
    }
  }
}
