<p align="center">
  <img src="screenshots/overview.png" alt="AtnKit package illustration" width="180">
</p>

# AtnKit

AtnKit is a pure Dart codec for Adobe Photoshop Actions (`.atn`) files. It reads and writes version 16 action sets, exposes immutable actions and events, and delegates Photoshop Action Descriptor values to `package:pscore`.

The package is intended for editors such as Focale that need editable automation data rather than opaque action files: stable command identifiers, playback flags, keyboard shortcuts, typed descriptors, and bounded decoding of untrusted input.

## Supported data

- Version 16 files containing one named action set and its ordered actions.
- Action indices, names, expanded state, function-key shortcuts, Shift modifiers, and color labels.
- Ordered action events with enabled, dialog, and expansion flags.
- Both `TEXT` string identifiers and compact `long` four-character identifiers.
- Optional version 16 Photoshop Action Descriptors decoded and encoded through PsCore.
- Unknown Photoshop commands retained through their identifiers, display names, flags, and typed descriptors.
- Configurable limits for file size, names, actions, events, text fields, and descriptor collections.
- Optional preservation of trailing bytes for forensic round trips.
- Canonical ATN writing and reusable `dart:convert` codec support.

ATN does not provide a length around each event descriptor. When an unknown descriptor type makes the next event boundary unknowable, AtnKit fails explicitly instead of scanning for a guessed boundary.

## Usage

```dart
import 'dart:io';

import 'package:atnkit/atnkit.dart';

final AtnFile file = AtnDecoder.decode(
  await File('Retouching.atn').readAsBytes(),
);

for (final AtnAction action in file.actionSet.actions) {
  print('${action.name}: ${action.events.length} events');
}

await File('Copy.atn').writeAsBytes(AtnEncoder.encode(file));
```

See [docs/ATN.md](docs/ATN.md) for the supported binary layout, boundary rules, and integration policy.

AtnKit is an independent implementation and is not affiliated with or endorsed by Adobe.

---

Built for **[Focale](https://focale-editor.app)**, an advanced local image editor. Discover what these packages make possible in a real creative workflow.
