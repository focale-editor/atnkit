import 'dart:typed_data';

import 'package:atnkit/src/codec/atn_binary.dart';
import 'package:atnkit/src/model/atn_options.dart';
import 'package:pscore/pscore.dart';

/// Reads and writes the compact descriptors stored by ATN version 12.
///
/// Version 12 omits the descriptor name and uses four-byte identifiers instead
/// of the length-prefixed identifiers found in version 16.
abstract final class AtnLegacyDescriptorCodec {
  /// Decodes one descriptor and advances [reader] to the next action event.
  static PsDescriptor decodeReader(
    PsBinaryReader reader, {
    PsDescriptorDecodeOptions options = const PsDescriptorDecodeOptions(),
  }) => _readDescriptor(
    reader,
    _LegacyDecodeContext(options: options),
    depth: 0,
    classId: 'null',
  );

  /// Encodes a version 12 descriptor without its event marker.
  static Uint8List encode(PsDescriptor descriptor) {
    final PsBinaryWriter writer = PsBinaryWriter();
    _writeDescriptor(writer, descriptor, root: true);
    return writer.takeBytes();
  }
}

/// Tracks nested collections and the total number of decoded values.
final class _LegacyDecodeContext {
  /// Caller-selected descriptor limits.
  final PsDescriptorDecodeOptions options;

  /// Number of values consumed across nested collections.
  int valueCount = 0;

  /// Creates a bounded context for one event descriptor.
  _LegacyDecodeContext({required this.options});

  /// Rejects excessive recursion before descending into another collection.
  void checkDepth(PsBinaryReader reader, int depth) {
    if (depth > options.maxDepth) {
      throw AtnFormatException(
        message: 'ATN descriptor depth exceeds the configured ${options.maxDepth} limit.',
        source: reader.bytes,
        offset: reader.baseOffset + reader.offset,
      );
    }
  }

  /// Accounts for [count] values before allocating or reading them.
  void addValues(PsBinaryReader reader, int count) {
    if (count > options.maxValues - valueCount) {
      throw AtnFormatException(
        message: 'ATN descriptor value count exceeds the configured ${options.maxValues} limit.',
        source: reader.bytes,
        offset: reader.baseOffset + reader.offset - 4,
      );
    }
    valueCount += count;
  }
}

/// Reads a version 12 descriptor, whose root has no stored class identifier.
PsDescriptor _readDescriptor(
  PsBinaryReader reader,
  _LegacyDecodeContext context, {
  required int depth,
  required String classId,
}) {
  context.checkDepth(reader, depth);
  final int count = reader.readUint32();
  context.addValues(reader, count);
  final List<PsDescriptorItem> items = [
    for (int index = 0; index < count; index++)
      PsDescriptorItem(
        key: reader.readString(4),
        value: _readValue(reader, reader.readString(4), context, depth: depth),
      ),
  ];
  return PsDescriptor(name: '', classId: classId, items: items);
}

/// Reads one typed value using the version 12 fixed-width identifier layout.
PsDescriptorValue _readValue(
  PsBinaryReader reader,
  String type,
  _LegacyDecodeContext context, {
  required int depth,
}) => switch (type) {
  'bool' => PsBooleanValue(value: reader.readUint8() != 0),
  'long' => PsIntegerValue(value: reader.readInt32()),
  'comp' => PsLargeIntegerValue(value: reader.readInt64()),
  'doub' => PsDoubleValue(value: reader.readFloat64()),
  'UntF' => PsUnitFloatValue(unit: reader.readString(4), value: reader.readFloat64()),
  'TEXT' => PsStringValue(value: _readUnicode(reader)),
  'enum' => PsEnumeratedValue(typeId: reader.readString(4), value: reader.readString(4)),
  'Objc' || 'GlbO' => PsObjectValue(
    value: _readDescriptor(
      reader,
      context,
      depth: depth + 1,
      classId: reader.readString(4),
    ),
    global: type == 'GlbO',
  ),
  'VlLs' => PsListValue(values: _readValues(reader, context, depth: depth + 1)),
  'obj ' => PsReferenceValue(values: _readValues(reader, context, depth: depth + 1)),
  'prop' => PsPropertyValue(name: '', classId: reader.readString(4), keyId: reader.readString(4)),
  'Clss' => PsReferenceClassValue(name: '', classId: reader.readString(4)),
  'Enmr' => PsEnumeratedReferenceValue(
    name: '',
    classId: reader.readString(4),
    typeId: reader.readString(4),
    value: reader.readString(4),
  ),
  'rele' => PsOffsetValue(name: '', classId: reader.readString(4), value: reader.readUint32()),
  'Idnt' => PsIdentifierValue(value: reader.readInt32()),
  'indx' => PsIndexValue(value: reader.readInt32()),
  'name' => PsNameValue(name: '', classId: reader.readString(4), value: _readUnicode(reader)),
  'tdta' => PsRawValue(value: reader.readBytes(reader.readLength(wide: false, label: 'ATN raw data'))),
  'alis' => PsAliasValue(value: reader.readBytes(reader.readLength(wide: false, label: 'ATN alias'))),
  'type' || 'GlbC' => PsClassValue(name: '', classId: reader.readString(4), global: type == 'GlbC'),
  _ => throw AtnFormatException(
    message: 'Unsupported version 12 descriptor type "$type".',
    source: reader.bytes,
    offset: reader.baseOffset + reader.offset - 4,
  ),
};

/// Reads a bounded list of independently typed descriptor values.
List<PsDescriptorValue> _readValues(
  PsBinaryReader reader,
  _LegacyDecodeContext context, {
  required int depth,
}) {
  context.checkDepth(reader, depth);
  final int count = reader.readUint32();
  context.addValues(reader, count);
  return [
    for (int index = 0; index < count; index++) _readValue(reader, reader.readString(4), context, depth: depth),
  ];
}

/// Reads a counted, null-terminated UTF-16BE descriptor string.
String _readUnicode(PsBinaryReader reader) => readAtnUnicodeString(
  reader,
  maximumCodeUnits: reader.remaining ~/ 2,
  label: 'Version 12 descriptor string',
);

/// Writes a descriptor after rejecting fields absent from version 12.
void _writeDescriptor(PsBinaryWriter writer, PsDescriptor descriptor, {required bool root}) {
  if (descriptor.name.isNotEmpty || (root && descriptor.classId != 'null')) {
    throw const AtnWriteException(
      message: 'Version 12 descriptors cannot store a name or a root class identifier.',
    );
  }
  if (!root) {
    _writeCode(writer, descriptor.classId, 'Descriptor class identifier');
  }
  writer.writeUint32(descriptor.items.length);
  for (final PsDescriptorItem item in descriptor.items) {
    _writeCode(writer, item.key, 'Descriptor key');
    writer.writeString(item.value.type);
    _writeValue(writer, item.value);
  }
}

/// Writes one typed descriptor value using version 12 field widths.
void _writeValue(PsBinaryWriter writer, PsDescriptorValue value) {
  switch (value) {
    case PsBooleanValue():
      writer.writeUint8(value.value ? 1 : 0);
    case PsIntegerValue():
      writer.writeInt32(value.value);
    case PsLargeIntegerValue():
      writer.writeInt64(value.value);
    case PsDoubleValue():
      writer.writeFloat64(value.value);
    case PsUnitFloatValue():
      _writeCode(writer, value.unit, 'Descriptor unit');
      writer.writeFloat64(value.value);
    case PsStringValue():
      writeAtnUnicodeString(writer, value.value, label: 'Version 12 descriptor string');
    case PsEnumeratedValue():
      _writeCode(writer, value.typeId, 'Enumeration type');
      _writeCode(writer, value.value, 'Enumeration value');
    case PsObjectValue():
      _writeDescriptor(writer, value.value, root: false);
    case PsListValue():
      _writeValues(writer, value.values);
    case PsReferenceValue():
      _writeValues(writer, value.values);
    case PsPropertyValue():
      _requireEmptyName(value.name);
      _writeCode(writer, value.classId, 'Reference class');
      _writeCode(writer, value.keyId, 'Property identifier');
    case PsReferenceClassValue():
      _requireEmptyName(value.name);
      _writeCode(writer, value.classId, 'Reference class');
    case PsEnumeratedReferenceValue():
      _requireEmptyName(value.name);
      _writeCode(writer, value.classId, 'Reference class');
      _writeCode(writer, value.typeId, 'Reference type');
      _writeCode(writer, value.value, 'Reference value');
    case PsOffsetValue():
      _requireEmptyName(value.name);
      _writeCode(writer, value.classId, 'Reference class');
      writer.writeUint32(value.value);
    case PsIdentifierValue():
      writer.writeInt32(value.value);
    case PsIndexValue():
      writer.writeInt32(value.value);
    case PsNameValue():
      _requireEmptyName(value.name);
      _writeCode(writer, value.classId, 'Reference class');
      writeAtnUnicodeString(writer, value.value, label: 'Reference name');
    case PsRawValue():
      writer
        ..writeUint32(value.value.length)
        ..writeBytes(value.value);
    case PsAliasValue():
      writer
        ..writeUint32(value.value.length)
        ..writeBytes(value.value);
    case PsClassValue():
      _requireEmptyName(value.name);
      _writeCode(writer, value.classId, 'Descriptor class');
    case PsUnitFloatsValue() || PsObjectArrayValue() || PsPathValue():
      throw AtnWriteException(message: 'Version 12 cannot encode descriptor type "${value.type}".');
  }
}

/// Writes a list whose members each carry their own type code.
void _writeValues(PsBinaryWriter writer, List<PsDescriptorValue> values) {
  writer.writeUint32(values.length);
  for (final PsDescriptorValue value in values) {
    writer.writeString(value.type);
    _writeValue(writer, value);
  }
}

/// Rejects a human-readable name that version 12 cannot store.
void _requireEmptyName(String name) {
  if (name.isNotEmpty) {
    throw const AtnWriteException(message: 'Version 12 descriptor names must be empty.');
  }
}

/// Writes one fixed-width Latin-1 identifier.
void _writeCode(PsBinaryWriter writer, String value, String label) {
  if (value.length != 4 || value.codeUnits.any((unit) => unit > 0xff)) {
    throw AtnWriteException(message: '$label must contain four Latin-1 characters in version 12.');
  }
  writer.writeString(value);
}
