import 'dart:typed_data';

import 'package:atnkit/atnkit.dart';
import 'package:checks/checks.dart';
import 'package:test/test.dart';

void main() {
  group('AtnCodec', () {
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
