import 'package:pscore/pscore.dart';

/// Resource limits applied while decoding an ATN file.
final class AtnDecodeOptions {
  /// Maximum accepted input size.
  final int maxFileBytes;

  /// Maximum number of actions in one set.
  final int maxActions;

  /// Maximum aggregate number of events in one set.
  final int maxEvents;

  /// Maximum number of UTF-16 code units in one set or action name.
  final int maxNameCodeUnits;

  /// Maximum byte length of one string event identifier or display name.
  final int maxEventTextBytes;

  /// Resource limits applied to Action Descriptors.
  final PsDescriptorDecodeOptions descriptorOptions;

  /// Whether bytes after the declared set are retained instead of rejected.
  final bool preserveTrailingData;

  /// Creates bounded options suitable for untrusted action files.
  const AtnDecodeOptions({
    this.maxFileBytes = 64 * 1024 * 1024,
    this.maxActions = 4096,
    this.maxEvents = 65536,
    this.maxNameCodeUnits = 1024 * 1024,
    this.maxEventTextBytes = 1024 * 1024,
    this.descriptorOptions = const PsDescriptorDecodeOptions(),
    this.preserveTrailingData = true,
  });
}

/// Validation and preservation choices applied while encoding an ATN file.
final class AtnEncodeOptions {
  /// Whether retained bytes after the action set are appended.
  final bool includeTrailingData;

  /// Creates encoding options for an interoperable file.
  const AtnEncodeOptions({this.includeTrailingData = true});
}

/// Reports malformed, truncated, unsupported, or unsafe ATN input.
final class AtnFormatException implements FormatException {
  /// Human-readable explanation of the malformed data.
  @override
  final String message;

  /// Input object associated with the failure, when available.
  @override
  final Object? source;

  /// Absolute byte offset associated with the failure, when available.
  @override
  final int? offset;

  /// Creates an error at an optional byte [offset].
  const AtnFormatException({required this.message, this.source, this.offset});

  @override
  String toString() {
    final String location = offset == null ? '' : ' at byte $offset';
    return 'AtnFormatException$location: $message';
  }
}

/// Reports a model value that cannot be represented by the selected ATN version.
final class AtnWriteException implements Exception {
  /// Human-readable explanation of the invalid value.
  final String message;

  /// Creates an encoding error.
  const AtnWriteException({required this.message});

  @override
  String toString() => 'AtnWriteException: $message';
}
