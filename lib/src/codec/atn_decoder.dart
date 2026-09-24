import 'dart:convert';
import 'dart:typed_data';

import 'package:atnkit/src/codec/atn_binary.dart';
import 'package:atnkit/src/codec/atn_legacy_descriptor.dart';
import 'package:atnkit/src/model/atn_action.dart';
import 'package:atnkit/src/model/atn_event.dart';
import 'package:atnkit/src/model/atn_file.dart';
import 'package:atnkit/src/model/atn_options.dart';
import 'package:pscore/pscore.dart';

/// Decodes Photoshop ATN version 12 and 16 action-set files.
final class AtnDecoder extends Converter<List<int>, AtnFile> {
  /// Resource limits used for every conversion.
  final AtnDecodeOptions options;

  /// Creates a reusable decoder.
  const AtnDecoder({this.options = const AtnDecodeOptions()});

  /// Decodes one complete ATN byte sequence.
  static AtnFile decode(
    List<int> input, {
    AtnDecodeOptions options = const AtnDecodeOptions(),
  }) => AtnDecoder(options: options).convert(input);

  @override
  AtnFile convert(List<int> input) {
    if (input.length > options.maxFileBytes) {
      throw AtnFormatException(
        message:
            'ATN input contains ${input.length} bytes, over the configured '
            '${options.maxFileBytes} limit.',
        source: input,
      );
    }
    final Uint8List bytes = Uint8List.fromList(input);
    final PsBinaryReader reader = PsBinaryReader(bytes: bytes);
    try {
      final int version = reader.readInt32();
      if (!AtnFile.isSupportedVersion(version)) {
        throw AtnFormatException(
          message: 'Unsupported ATN version $version.',
          source: bytes,
          offset: 0,
        );
      }
      final AtnActionSet actionSet = _readActionSet(reader, version: version);
      final Uint8List trailingData = reader.isAtEnd ? Uint8List(0) : reader.readBytes(reader.remaining);
      if (trailingData.isNotEmpty && !options.preserveTrailingData) {
        throw AtnFormatException(
          message: 'Unexpected data follows the ATN action set.',
          source: bytes,
          offset: bytes.length - trailingData.length,
        );
      }
      return AtnFile(
        version: version,
        actionSet: actionSet,
        trailingData: trailingData,
      );
    } on AtnFormatException {
      rethrow;
    } on PsFormatException catch (error) {
      throw AtnFormatException(
        message: error.message,
        source: bytes,
        offset: error.offset,
      );
    }
  }

  /// Decodes the one action set following the version field.
  AtnActionSet _readActionSet(PsBinaryReader reader, {required int version}) {
    final String name = readAtnUnicodeString(
      reader,
      maximumCodeUnits: options.maxNameCodeUnits,
      label: 'Action-set name',
    );
    final bool expanded = reader.readUint8() != 0;
    final int count = readAtnCount(
      reader,
      maximum: options.maxActions,
      label: 'Action',
    );
    int eventCount = 0;
    final List<AtnAction> actions = [];
    for (int index = 0; index < count; index++) {
      final AtnAction action = _readAction(
        reader,
        index: index,
        maximumEvents: options.maxEvents - eventCount,
        version: version,
      );
      eventCount += action.events.length;
      actions.add(action);
    }
    return AtnActionSet(name: name, expanded: expanded, actions: actions);
  }

  /// Decodes one action and its declared events.
  AtnAction _readAction(
    PsBinaryReader reader, {
    required int index,
    required int maximumEvents,
    required int version,
  }) {
    final int storedIndex = reader.readInt16();
    final bool shiftKey = reader.readUint8() != 0;
    final int commandKey = reader.readUint8();
    final int colorIndex = reader.readInt16();
    final String name = readAtnUnicodeString(
      reader,
      maximumCodeUnits: options.maxNameCodeUnits,
      label: 'Action name',
    );
    final bool expanded = reader.readUint8() != 0;
    final int count = readAtnCount(
      reader,
      maximum: maximumEvents,
      label: 'Event in action ${index + 1}',
    );
    return AtnAction(
      index: storedIndex,
      shiftKey: shiftKey,
      commandKey: commandKey,
      colorIndex: colorIndex,
      name: name,
      expanded: expanded,
      events: [
        for (int eventIndex = 0; eventIndex < count; eventIndex++) readEvent(reader, eventIndex: eventIndex, version: version),
      ],
    );
  }

  /// Decodes one action event from the current reader position.
  AtnActionEvent readEvent(
    PsBinaryReader reader, {
    int? eventIndex,
    int version = AtnFile.supportedVersion,
  }) {
    if (!AtnFile.isSupportedVersion(version)) {
      throw AtnFormatException(
        message: 'Unsupported ATN version $version.',
        source: reader.bytes,
        offset: reader.baseOffset + reader.offset,
      );
    }
    final bool expanded = reader.readUint8() != 0;
    final bool enabled = reader.readUint8() != 0;
    final bool withDialog = reader.readUint8() != 0;
    final int dialogOptions = reader.readUint8();
    final String kind = reader.readString(4);
    final AtnEventIdentifier identifier = switch (kind) {
      'TEXT' => AtnEventIdentifier.string(
        readAtnByteString(
          reader,
          maximumBytes: options.maxEventTextBytes,
          label: 'Event identifier',
        ),
      ),
      'long' => AtnEventIdentifier.fourCharacter(reader.readString(4)),
      _ => throw AtnFormatException(
        message: 'Unsupported ATN event identifier kind "$kind".',
        source: reader.bytes,
        offset: reader.baseOffset + reader.offset - 4,
      ),
    };
    final String displayName = readAtnByteString(
      reader,
      maximumBytes: options.maxEventTextBytes,
      label: 'Event display name',
    );
    final int hasDescriptor = reader.readInt32();
    if (hasDescriptor != 0 && hasDescriptor != -1) {
      throw AtnFormatException(
        message:
            'Event${eventIndex == null ? '' : ' ${eventIndex + 1}'} has an '
            'invalid descriptor marker of $hasDescriptor.',
        source: reader.bytes,
        offset: reader.baseOffset + reader.offset - 4,
      );
    }
    final PsDescriptor? descriptor = hasDescriptor == -1
        ? version == AtnFile.legacyVersion
              ? AtnLegacyDescriptorCodec.decodeReader(
                  reader,
                  options: options.descriptorOptions,
                )
              : PsDescriptorCodec.decodeReader(
                  reader,
                  options: options.descriptorOptions,
                )
        : null;
    return AtnActionEvent(
      expanded: expanded,
      enabled: enabled,
      withDialog: withDialog,
      dialogOptions: dialogOptions,
      identifier: identifier,
      displayName: displayName,
      descriptor: descriptor,
    );
  }
}
