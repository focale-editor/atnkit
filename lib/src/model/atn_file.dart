import 'dart:typed_data';

import 'package:atnkit/src/model/atn_action.dart';

/// One complete Photoshop ATN action-set file.
final class AtnFile {
  /// ATN container version written by currently supported Photoshop files.
  static const int supportedVersion = 16;

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
