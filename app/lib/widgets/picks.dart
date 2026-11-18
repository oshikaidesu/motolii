// What a click does to a selection, the same everywhere: the rule of Finder and Explorer, which Figma, After Effects and Premiere Pro follow.
// (Apple Human Interface Guidelines, Selecting: a click replaces the selection; Command-click adds or removes one; Shift-click takes a range.)
// Every place that picks things by clicking (layers, keys, files, projects, fields) calls [pickOnClick] with the keys from [clickKeys].
import 'package:flutter/services.dart' show HardwareKeyboard;

/// The selection after a click on [id].
/// [now] is what is picked, in the order it was picked. [lead] is the item the last plain or added click was on; a range starts from it.
/// [order] is every item in reading order, for ranges; leave it empty where there is no row order (the stage), and a range is then an addition.
/// - A plain click (neither key): only [id] is picked, and it becomes the lead.
/// - [add] (Command, or Ctrl on Windows and Linux): [id] is added, or removed if it was picked. An added [id] becomes the lead.
///   A removed one leaves the lead where it was, unless it was the lead: then the lead is the last item still picked, or null.
/// - [span] (Shift): everything from [lead] to [id] in [order], both ends included, replaces the selection. It is listed starting at
///   the lead and going toward [id], whichever way that is. The lead stays, so a second Shift-click extends from the same item.
///   With no lead, or with the lead or [id] not in [order], it is an addition, as [add] is.
/// - [add] and [span] together: that range is added to [now]; what was picked stays.
/// The result is a new set in pick order; [now] is not changed.
({Set<T> picked, T? lead}) pickOnClick<T>({
  required Set<T> now,
  required T? lead,
  required T id,
  List<T> order = const [],
  bool add = false,
  bool span = false,
}) {
  final picked = <T>{...now};
  final a = lead == null ? -1 : order.indexOf(lead), b = order.indexOf(id);
  if (span && a >= 0 && b >= 0) {
    final range = a <= b
        ? order.sublist(a, b + 1)
        : order.sublist(b, a + 1).reversed;
    if (!add) picked.clear();
    picked.addAll(range);
    return (picked: picked, lead: lead);
  }
  if (add || span) {
    if (picked.remove(id)) {
      return (picked: picked, lead: lead == id ? picked.lastOrNull : lead);
    }
    return (picked: picked..add(id), lead: id);
  }
  return (picked: {id}, lead: id);
}

/// Whether the keys of a click add ([add]: Command on a Mac, Ctrl elsewhere) or span ([span]: Shift) right now.
({bool add, bool span}) clickKeys() {
  final k = HardwareKeyboard.instance;
  return (add: k.isMetaPressed || k.isControlPressed, span: k.isShiftPressed);
}
