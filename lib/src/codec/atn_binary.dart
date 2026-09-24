import 'package:atnkit/src/model/atn_options.dart';
import 'package:pscore/pscore.dart';

/// Reads one ATN UTF-16BE string whose count includes a null terminator.
String readAtnUnicodeString(
  PsBinaryReader reader, {
  required int maximumCodeUnits,
  required String label,
}) {
  final int count = reader.readUint32();
  if (count == 0 || count > maximumCodeUnits + 1) {
    throw AtnFormatException(
      message: '$label has an invalid UTF-16 length of $count.',
      source: reader.bytes,
      offset: reader.baseOffset + reader.offset - 4,
    );
  }
  if (count > reader.remaining ~/ 2) {
    throw AtnFormatException(
      message: '$label exceeds the remaining file data.',
      source: reader.bytes,
      offset: reader.baseOffset + reader.offset,
    );
  }
  final List<int> codeUnits = [
    for (int index = 0; index < count - 1; index++) reader.readUint16(),
  ];
  final int terminator = reader.readUint16();
  if (terminator != 0) {
    throw AtnFormatException(
      message: '$label is not null terminated.',
      source: reader.bytes,
      offset: reader.baseOffset + reader.offset - 2,
    );
  }
  return String.fromCharCodes(codeUnits);
}

/// Writes one ATN UTF-16BE string with its counted null terminator.
void writeAtnUnicodeString(
  PsBinaryWriter writer,
  String value, {
  required String label,
}) {
  final List<int> codeUnits = value.codeUnits;
  if (codeUnits.length == 0xffffffff) {
    throw AtnWriteException(message: '$label is too long for ATN.');
  }
  writer
    ..writeUint32(codeUnits.length + 1)
    ..writeUint16List(codeUnits)
    ..writeUint16(0);
}

/// Reads one unsigned-length-prefixed Latin-1 ATN string.
String readAtnByteString(
  PsBinaryReader reader, {
  required int maximumBytes,
  required String label,
}) {
  final int length = reader.readUint32();
  if (length > maximumBytes || length > reader.remaining) {
    throw AtnFormatException(
      message: '$label has an invalid byte length of $length.',
      source: reader.bytes,
      offset: reader.baseOffset + reader.offset - 4,
    );
  }
  return reader.readString(length);
}

/// Writes one unsigned-length-prefixed Latin-1 ATN string.
void writeAtnByteString(
  PsBinaryWriter writer,
  String value, {
  required String label,
}) {
  if (value.codeUnits.any((unit) => unit > 0xff)) {
    throw AtnWriteException(
      message: '$label must contain only Latin-1 characters.',
    );
  }
  writer
    ..writeUint32(value.length)
    ..writeString(value);
}

/// Validates one nonnegative bounded signed count before allocation.
int readAtnCount(
  PsBinaryReader reader, {
  required int maximum,
  required String label,
}) {
  final int count = reader.readInt32();
  if (count < 0 || count > maximum) {
    throw AtnFormatException(
      message: '$label count $count exceeds the supported range.',
      source: reader.bytes,
      offset: reader.baseOffset + reader.offset - 4,
    );
  }
  return count;
}
