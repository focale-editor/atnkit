import 'dart:io';
import 'dart:typed_data';

import 'package:atnkit/atnkit.dart';
import 'package:checks/checks.dart';
import 'package:test/test.dart';

/// Validates locally downloaded Photoshop action files when a corpus exists.
void main() {
  final List<File> examples = _examples();
  test(
    'decodes and losslessly reconstructs every local Photoshop example',
    () {
      for (final File example in examples) {
        final Uint8List source = example.readAsBytesSync();
        final AtnFile decoded = AtnDecoder.decode(source);
        final Uint8List reconstructed = AtnEncoder.encode(decoded);

        check(decoded.actionSet.actions, because: example.path).isNotEmpty();
        check(reconstructed, because: example.path).deepEquals(source);
      }
    },
    skip: examples.isEmpty ? 'No local ATN_EXAMPLES corpus is present.' : false,
  );
}

/// Discovers local `.atn` files recursively in a stable order.
List<File> _examples() {
  final Directory directory = Directory('ATN_EXAMPLES');
  if (!directory.existsSync()) {
    return [];
  }
  final List<File> files = directory.listSync(recursive: true).whereType<File>().where((file) => file.path.toLowerCase().endsWith('.atn')).toList()
    ..sort((left, right) => left.path.compareTo(right.path));
  return files;
}
