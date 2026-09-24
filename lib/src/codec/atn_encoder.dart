import 'dart:convert';
import 'dart:typed_data';

import 'package:atnkit/src/codec/atn_binary.dart';
import 'package:atnkit/src/model/atn_action.dart';
import 'package:atnkit/src/model/atn_event.dart';
import 'package:atnkit/src/model/atn_file.dart';
import 'package:atnkit/src/model/atn_options.dart';
import 'package:pscore/pscore.dart';

/// Encodes Photoshop ATN version 16 action-set files.
final class AtnEncoder extends Converter<AtnFile, List<int>> {
  /// Validation and preservation choices used for every conversion.
  final AtnEncodeOptions options;

  /// Creates a reusable encoder.
  const AtnEncoder({this.options = const AtnEncodeOptions()});

  /// Encodes one complete ATN model.
  static Uint8List encode(
    AtnFile input, {
    AtnEncodeOptions options = const AtnEncodeOptions(),
  }) => AtnEncoder(options: options).convert(input);

  @override
  Uint8List convert(AtnFile input) {
    if (input.version != AtnFile.supportedVersion) {
      throw const AtnWriteException(
        message: 'Only ATN version ${AtnFile.supportedVersion} can be written.',
      );
    }
    final PsBinaryWriter writer = PsBinaryWriter();
    writer.writeInt32(input.version);
    _writeActionSet(writer, input.actionSet);
    if (options.includeTrailingData) {
      writer.writeBytes(input.trailingData);
    }
    return writer.takeBytes();
  }

  /// Encodes the file's single action set.
  void _writeActionSet(PsBinaryWriter writer, AtnActionSet set) {
    writeAtnUnicodeString(writer, set.name, label: 'Action-set name');
    writer
      ..writeUint8(set.expanded ? 1 : 0)
      ..writeInt32(set.actions.length);
    for (final AtnAction action in set.actions) {
      _writeAction(writer, action);
    }
  }

  /// Encodes one action and its ordered events.
  void _writeAction(PsBinaryWriter writer, AtnAction action) {
    _requireSigned16(action.index, 'Action index');
    _requireByte(action.commandKey, 'Function-key byte');
    _requireSigned16(action.colorIndex, 'Colour index');
    writer
      ..writeInt16(action.index)
      ..writeUint8(action.shiftKey ? 1 : 0)
      ..writeUint8(action.commandKey)
      ..writeInt16(action.colorIndex);
    writeAtnUnicodeString(writer, action.name, label: 'Action name');
    writer
      ..writeUint8(action.expanded ? 1 : 0)
      ..writeInt32(action.events.length);
    for (final AtnActionEvent event in action.events) {
      writeEvent(writer, event);
    }
  }

  /// Encodes one action event at the current writer position.
  void writeEvent(PsBinaryWriter writer, AtnActionEvent event) {
    _requireByte(event.dialogOptions, 'Dialog-options byte');
    writer
      ..writeUint8(event.expanded ? 1 : 0)
      ..writeUint8(event.enabled ? 1 : 0)
      ..writeUint8(event.withDialog ? 1 : 0)
      ..writeUint8(event.dialogOptions);
    switch (event.identifier.kind) {
      case AtnEventIdentifierKind.string:
        writer.writeString('TEXT');
        writeAtnByteString(
          writer,
          event.identifier.value,
          label: 'Event identifier',
        );
      case AtnEventIdentifierKind.fourCharacter:
        if (event.identifier.value.length != 4 || event.identifier.value.codeUnits.any((unit) => unit > 0xff)) {
          throw const AtnWriteException(
            message: 'A compact event identifier must contain four Latin-1 characters.',
          );
        }
        writer
          ..writeString('long')
          ..writeString(event.identifier.value);
    }
    writeAtnByteString(writer, event.displayName, label: 'Event display name');
    final PsDescriptor? descriptor = event.descriptor;
    if (descriptor == null) {
      writer.writeInt32(0);
    } else {
      writer
        ..writeInt32(-1)
        ..writeBytes(PsDescriptorCodec.encode(descriptor));
    }
  }

  /// Rejects a value outside one unsigned byte.
  void _requireByte(int value, String label) {
    if (value < 0 || value > 0xff) {
      throw AtnWriteException(message: '$label must be between 0 and 255.');
    }
  }

  /// Rejects a value outside one signed 16-bit field.
  void _requireSigned16(int value, String label) {
    if (value < -0x8000 || value > 0x7fff) {
      throw AtnWriteException(
        message: '$label must fit a signed 16-bit integer.',
      );
    }
  }
}
