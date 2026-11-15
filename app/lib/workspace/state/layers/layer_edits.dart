// Engine calls on one layer, for the panels: what a layer says or is set to, and the undo steps that group changes.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// What layer [layer] has for [name] (its fill, kind or text), or '' when no project is open.
String wordOf(WorkspaceController ws, int layer, String name) =>
    ws.inside?.word(layer, name) ?? '';

/// The value of [name] on layer [layer] at [at], or null when it has none there.
double? valueOf(WorkspaceController ws, int layer, String name, double at) =>
    ws.inside?.value(layer, name, at);

/// Whether layer [layer] is a sound: a video with no image, which has nothing to color.
bool soundLayer(WorkspaceController ws, int layer) =>
    isSoundLayer(ws.inside!, layer);

/// Gives layer [layer] the word [word] for [name], queued. Returns its ticket.
int sayWord(WorkspaceController ws, int layer, String name, String word) =>
    ws.inside!.later('say', layer: layer, name: name, word: word);

/// Gives layer [layer] the number [number] for [name], queued. Returns its ticket.
int setNumber(WorkspaceController ws, int layer, String name, double number) =>
    ws.inside!.later('set', layer: layer, name: name, number: number);

/// Starts an undo step: every change queued until [groupEnd] is one step. Returns its ticket.
int groupBegin(WorkspaceController ws) =>
    ws.inside!.later('together', number: 1);

/// Ends the undo step that [groupBegin] started. Returns its ticket.
int groupEnd(WorkspaceController ws) => ws.inside!.later('together');
