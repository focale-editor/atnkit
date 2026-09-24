import 'package:pscore/pscore.dart';

/// Binary representation used to identify one Photoshop action event.
enum AtnEventIdentifierKind {
  /// A length-prefixed string ID introduced by the `TEXT` marker.
  string,

  /// A compact four-character ID introduced by the `long` marker.
  fourCharacter,
}

/// Identifies the Photoshop command represented by an action event.
final class AtnEventIdentifier {
  /// Representation used by the ATN container.
  final AtnEventIdentifierKind kind;

  /// String ID or four-character code stored in the file.
  final String value;

  /// Creates an event identifier while retaining its on-disk representation.
  const AtnEventIdentifier({required this.kind, required this.value});

  /// Creates a length-prefixed Photoshop string identifier.
  const AtnEventIdentifier.string(String value) : this(kind: AtnEventIdentifierKind.string, value: value);

  /// Creates a compact Photoshop four-character identifier.
  const AtnEventIdentifier.fourCharacter(String value) : this(kind: AtnEventIdentifierKind.fourCharacter, value: value);
}

/// One executable or disabled command inside a Photoshop action.
final class AtnActionEvent {
  /// Whether Photoshop presents this event expanded in the Actions panel.
  final bool expanded;

  /// Whether playback executes this event.
  final bool enabled;

  /// Whether playback opens the command dialog.
  final bool withDialog;

  /// Raw dialog-options byte retained for interoperability.
  final int dialogOptions;

  /// Photoshop command identifier.
  final AtnEventIdentifier identifier;

  /// Human-readable command name stored by Photoshop.
  final String displayName;

  /// Optional Action Descriptor containing command parameters.
  final PsDescriptor? descriptor;

  /// Creates one immutable action event.
  const AtnActionEvent({
    required this.identifier,
    required this.displayName,
    this.expanded = false,
    this.enabled = true,
    this.withDialog = false,
    this.dialogOptions = 0,
    this.descriptor,
  });
}
