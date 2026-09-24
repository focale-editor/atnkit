import 'package:atnkit/src/model/atn_event.dart';

/// One named Photoshop action and its ordered events.
final class AtnAction {
  /// Position retained from the action record.
  final int index;

  /// Whether Shift accompanies the function-key shortcut.
  final bool shiftKey;

  /// Raw function-key byte, where zero means no shortcut.
  final int commandKey;

  /// Raw Photoshop Actions-panel colour index.
  final int colorIndex;

  /// Human-readable action name.
  final String name;

  /// Whether Photoshop presents this action expanded in the panel.
  final bool expanded;

  /// Ordered events executed by this action.
  final List<AtnActionEvent> events;

  /// Creates one immutable action.
  AtnAction({
    required this.index,
    required this.name,
    List<AtnActionEvent> events = const [],
    this.shiftKey = false,
    this.commandKey = 0,
    this.colorIndex = 0,
    this.expanded = true,
  }) : events = List<AtnActionEvent>.unmodifiable(events);
}

/// One named set stored by an ATN file.
final class AtnActionSet {
  /// Human-readable set name.
  final String name;

  /// Whether Photoshop presents this set expanded in the panel.
  final bool expanded;

  /// Ordered actions contained by the set.
  final List<AtnAction> actions;

  /// Creates one immutable action set.
  AtnActionSet({
    required this.name,
    List<AtnAction> actions = const [],
    this.expanded = true,
  }) : actions = List<AtnAction>.unmodifiable(actions);
}
