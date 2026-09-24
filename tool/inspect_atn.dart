import 'dart:io';

import 'package:atnkit/atnkit.dart';

/// Inspects one or more ATN files without changing them.
Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run tool/inspect_atn.dart FILE.atn [...]');
    exitCode = 64;
    return;
  }
  for (final String path in arguments) {
    try {
      final AtnFile file = AtnDecoder.decode(await File(path).readAsBytes());
      stdout.writeln('$path: ${file.actionSet.name}');
      for (final AtnAction action in file.actionSet.actions) {
        stdout.writeln('  ${action.name}: ${action.events.length} events');
        for (final AtnActionEvent event in action.events) {
          stdout.writeln(
            '    ${event.identifier.kind.name}:${event.identifier.value} '
            '(${event.displayName}, descriptor: ${event.descriptor != null})',
          );
          final PsDescriptor? descriptor = event.descriptor;
          if (descriptor != null) {
            stdout.writeln(
              '      ${descriptor.classId}: '
              '${descriptor.items.map((item) => '${item.key}/${_valueSummary(item.value)}').join(', ')}',
            );
          }
        }
      }
    } on Object catch (error) {
      stderr.writeln('$path: $error');
      exitCode = 1;
    }
  }
}

/// Returns a compact diagnostic representation for a descriptor value.
String _valueSummary(PsDescriptorValue value) => switch (value) {
  PsBooleanValue(:final value) => 'bool:$value',
  PsIntegerValue(:final value) => 'long:$value',
  PsDoubleValue(:final value) => 'doub:$value',
  PsStringValue(:final value) => 'TEXT:$value',
  PsEnumeratedValue(:final typeId, :final value) => 'enum:$typeId/$value',
  _ => value.type,
};
