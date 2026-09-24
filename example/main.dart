import 'dart:io';

import 'package:atnkit/atnkit.dart';

/// Prints the action hierarchy from the first command-line path.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw const FormatException('Usage: dart run example/main.dart FILE.atn');
  }
  final AtnFile file = AtnDecoder.decode(
    await File(arguments.single).readAsBytes(),
  );
  stdout.writeln(file.actionSet.name);
  for (final AtnAction action in file.actionSet.actions) {
    stdout.writeln('  ${action.name} (${action.events.length} events)');
  }
}
