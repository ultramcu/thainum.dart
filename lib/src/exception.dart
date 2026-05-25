/// Thrown when Thai number/date words or numeric input cannot be parsed.
///
/// It implements [FormatException] so callers that catch [FormatException]
/// (the idiomatic Dart parse-failure type) also catch this.
class ThaiNumException implements FormatException {
  /// Creates a [ThaiNumException] with a human-readable [message] and an
  /// optional [source] string and offset.
  const ThaiNumException(this.message, [this.source, this.offset]);

  @override
  final String message;

  @override
  final dynamic source;

  @override
  final int? offset;

  @override
  String toString() {
    final src = source;
    if (src is String) {
      return 'ThaiNumException: $message ("$src")';
    }
    return 'ThaiNumException: $message';
  }
}
