import 'dart:typed_data';

import 'package:atnkit/src/model/atn_action.dart';

/// One complete Photoshop ATN action-set file.
final class AtnFile {
  /// ATN container version used for newly created files.
  static const int supportedVersion = 16;

  /// Legacy ATN container version found in Photoshop 5 action files.
  static const int legacyVersion = 12;

  /// Whether [version] has a supported action and descriptor layout.
  static bool isSupportedVersion(int version) => version == legacyVersion || version == supportedVersion;

  /// Version stored in the file header.
  final int version;

  /// Single action set stored by the ATN container.
  final AtnActionSet actionSet;

  /// Uninterpreted bytes following the declared action set.
  final Uint8List trailingData;

  /// Creates one immutable ATN document.
  AtnFile({
    required this.actionSet,
    this.version = supportedVersion,
    List<int> trailingData = const [],
  }) : trailingData = Uint8List.fromList(trailingData);
}
