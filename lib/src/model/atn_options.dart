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
final class AtnFormatException extends PsFormatException {
  /// Creates an error at an optional absolute byte [offset].
  const AtnFormatException({
    required super.message,
    super.source,
    super.offset,
  });

  @override
  String get typeName => 'AtnFormatException';
}

/// Reports a model value that cannot be represented by the selected ATN version.
final class AtnWriteException extends PsWriteException {
  /// Creates an encoding error with a user-facing [message].
  const AtnWriteException({
    required super.message,
  });

  @override
  String get typeName => 'AtnWriteException';
}
