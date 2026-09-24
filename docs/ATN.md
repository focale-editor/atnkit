# ATN format support

AtnKit supports the version 16 action-set container used by Photoshop. An ATN
file stores one named set, an ordered list of actions, and an ordered list of
events for each action.

All scalar values are big-endian. Set and action names are counted UTF-16BE
strings whose count includes a trailing null code unit. Event identifiers are
either a length-prefixed Latin-1 string after `TEXT`, or a four-character code
after `long`. An event may end with one unversioned Photoshop Action Descriptor;
AtnKit uses `PsDescriptorCodec` from `package:pscore` for that payload.

ATN does not provide a length around each descriptor or event. A descriptor
type unknown to `PsCore` therefore makes the boundary of later events
unknowable, and decoding fails explicitly instead of scanning for a guessed
boundary. Command identifiers unknown to an application are still fully
decoded and can be retained or displayed as unsupported operations.

The decoder applies configurable limits before allocating collections or
strings. Trailing bytes can be retained for forensic round trips or rejected
with `AtnDecodeOptions(preserveTrailingData: false)`.
