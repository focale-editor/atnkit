# ATN format support

AtnKit supports version 12 and 16 action-set containers used by Photoshop. An ATN
file stores one named set, an ordered list of actions, and an ordered list of
events for each action.

All scalar values are big-endian. Set and action names are counted UTF-16BE
strings whose count includes a trailing null code unit. Event identifiers are
either a length-prefixed Latin-1 string after `TEXT`, or a four-character code
after `long`. An event may end with one unversioned Photoshop Action Descriptor.
Version 16 uses `PsDescriptorCodec` from `package:pscore`. Version 12 stores a
more compact descriptor: its root omits the name and class identifier, nested
objects store a four-character class identifier, and item keys and enumeration
identifiers are four-character codes. Version 12 strings include a counted null
terminator. A newly constructed `AtnFile` defaults to version 16; decoded files
retain their version when re-encoded.

The version in the ATN header is a file-format version, not the Photoshop
application version. Adobe's [file-format specification](https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/)
documents version 16. A [Photoshop 5 action file](https://community.adobe.com/questions-712/i-need-help-with-an-edit-1129751)
has a version 12 header and was used to verify the legacy layout. Other version
numbers remain unsupported until their layouts can be checked against real files.

ATN does not provide a length around each descriptor or event. A descriptor
type unknown to its codec therefore makes the boundary of later events
unknowable, and decoding fails explicitly instead of scanning for a guessed
boundary. Command identifiers unknown to an application are still fully
decoded and can be retained or displayed as unsupported operations.

The decoder applies configurable limits before allocating collections or
strings. Trailing bytes can be retained for forensic round trips or rejected
with `AtnDecodeOptions(preserveTrailingData: false)`.

Locally downloaded `.atn` files can be kept in `ATN_EXAMPLES/`. The directory is
excluded from Git and pub.dev. `dart test test/atn_photoshop_corpus_test.dart`
checks byte-for-byte decode/encode reconstruction when the directory is present.
