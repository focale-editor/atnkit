import 'dart:typed_data';

import 'package:atnkit/atnkit.dart';
import 'package:checks/checks.dart';
import 'package:test/test.dart';

void main() {
  group('AtnCodec', () {
    test('decodes and reconstructs a version 12 descriptor', () {
      final Uint8List source = _legacyFixture();

      final AtnFile decoded = AtnDecoder.decode(source);

      check(decoded.version).equals(AtnFile.legacyVersion);
      check(decoded.actionSet.name).equals('Old');
      final AtnActionEvent event = decoded.actionSet.actions.single.events.single;
      check(event.identifier.value).equals('Stop');
      final PsDescriptor descriptor = event.descriptor!;
      check((descriptor.value('Msge')! as PsStringValue).value).equals('Hi');
      final PsDescriptor nested = (descriptor.value('Usng')! as PsObjectValue).value;
      check(nested.classId).equals('Lyr ');
      check((nested.value('Nm  ')! as PsStringValue).value).equals('Layer');
      final PsReferenceValue reference = descriptor.value('null')! as PsReferenceValue;
      check((reference.values.single as PsEnumeratedReferenceValue).value).equals('Trgt');
      check(AtnEncoder.encode(decoded)).deepEquals(source);
    });

    test('rejects unverified file versions and truncated legacy descriptors', () {
      final Uint8List unsupported = _legacyFixture()..[3] = 13;
      final Uint8List truncated = Uint8List.fromList(_legacyFixture().sublist(0, _legacyFixture().length - 2));

      check(() => AtnDecoder.decode(unsupported)).throws<AtnFormatException>();
      check(() => AtnDecoder.decode(truncated)).throws<AtnFormatException>();
      check(
        () => AtnDecoder.decode(
          _legacyFixture(),
          options: const AtnDecodeOptions(
            descriptorOptions: PsDescriptorDecodeOptions(maxValues: 0),
          ),
        ),
      ).throws<AtnFormatException>();
      check(
        () => AtnDecoder.decode(
          _legacyFixture(),
          options: const AtnDecodeOptions(
            descriptorOptions: PsDescriptorDecodeOptions(maxDepth: 0),
          ),
        ),
      ).throws<AtnFormatException>();
      check(
        () => AtnEncoder.encode(
          AtnFile(version: 13, actionSet: AtnActionSet(name: 'Unsupported')),
        ),
      ).throws<AtnWriteException>();
    });

    test('round-trips actions, identifiers, and descriptors', () {
      final AtnFile source = AtnFile(
        actionSet: AtnActionSet(
          name: 'Retouche',
          actions: [
            AtnAction(
              index: 7,
              name: 'Contraste',
              commandKey: 3,
              shiftKey: true,
              colorIndex: 4,
              events: [
                const AtnActionEvent(
                  identifier: AtnEventIdentifier.string('inverse'),
                  displayName: 'Invert',
                ),
                const AtnActionEvent(
                  identifier: AtnEventIdentifier.fourCharacter('setd'),
                  displayName: 'Set',
                  descriptor: PsDescriptor(
                    name: '',
                    classId: 'null',
                    compactClassId: true,
                    items: [
                      PsDescriptorItem(
                        key: 'enab',
                        compactKey: true,
                        value: PsBooleanValue(value: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final Uint8List encoded = const AtnCodec().encode(source);
      final AtnFile decoded = const AtnCodec().decode(encoded);

      check(decoded.version).equals(16);
      check(decoded.actionSet.name).equals('Retouche');
      check(decoded.actionSet.actions).length.equals(1);
      final AtnAction action = decoded.actionSet.actions.single;
      check(action.name).equals('Contraste');
      check(action.commandKey).equals(3);
      check(action.shiftKey).isTrue();
      check(action.events).length.equals(2);
      check(action.events.first.identifier.value).equals('inverse');
      check(action.events.last.identifier.value).equals('setd');
      final PsDescriptor descriptor = action.events.last.descriptor!;
      check(descriptor.items).length.equals(1);
      check(const AtnCodec().encode(decoded)).deepEquals(encoded);
    });

    test('rejects counts beyond the configured limit before allocation', () {
      final PsBinaryWriter writer = PsBinaryWriter()
        ..writeInt32(AtnFile.supportedVersion)
        ..writeUint32(1)
        ..writeUint16(0)
        ..writeUint8(1)
        ..writeInt32(2);

      check(
        () => AtnDecoder.decode(
          writer.takeBytes(),
          options: const AtnDecodeOptions(maxActions: 1),
        ),
      ).throws<AtnFormatException>();
    });

    test('applies the event limit across the complete action set', () {
      final Uint8List encoded = AtnEncoder.encode(
        AtnFile(
          actionSet: AtnActionSet(
            name: 'Bounded',
            actions: [
              for (int index = 0; index < 2; index++)
                AtnAction(
                  index: index,
                  name: 'Action ${index + 1}',
                  events: const [
                    AtnActionEvent(
                      identifier: AtnEventIdentifier.string('inverse'),
                      displayName: 'Inverse',
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

      check(
        () => AtnDecoder.decode(
          encoded,
          options: const AtnDecodeOptions(maxEvents: 1),
        ),
      ).throws<AtnFormatException>();
    });

    test('retains trailing data when requested', () {
      final AtnFile source = AtnFile(
        actionSet: AtnActionSet(name: 'Set'),
        trailingData: const [1, 2, 3],
      );

      final AtnFile decoded = AtnDecoder.decode(AtnEncoder.encode(source));

      check(decoded.trailingData).deepEquals([1, 2, 3]);
    });
  });
}

/// Returns an independently written version 12 action with nested values.
Uint8List _legacyFixture() {
  const String hex =
      '0000000c'
      '00000004004f006c00640000'
      '0100000001'
      '000000000000'
      '00000004004f006e00650000'
      '0100000001'
      '00010000'
      '6c6f6e6753746f70'
      '0000000453746f70'
      'ffffffff'
      '00000003'
      '4d73676554455854'
      '00000003004800690000'
      '55736e674f626a63'
      '4c79722000000001'
      '4e6d202054455854'
      '00000006004c00610079006500720000'
      '6e756c6c6f626a20'
      '00000001456e6d72'
      '4c7972204f72646e54726774';
  return Uint8List.fromList([
    for (int index = 0; index < hex.length; index += 2) int.parse(hex.substring(index, index + 2), radix: 16),
  ]);
}
