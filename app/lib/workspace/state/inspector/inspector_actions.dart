// What the inspector asks of the engine when the user acts on a card or a keyframe mark: moving, removing, saving and
// copying effects, keyframe marks, and the names and texts the engine keeps for them. Each change is one undo step.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/inspector/inspector_state.dart'
    show KeyframeState, propOf;
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/workspace/state/inspector/inspector_reads.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The titles of the effect cards of layer [t], in effect order.
List<String> effectTitles(WorkspaceController ws, int t) =>
    ws.inside!.fxTitles(t);

/// The titles of the cards layer [t] can have but is not showing (the More shelf).
List<String> moreCardTitles(WorkspaceController ws, int t) =>
    ws.inside!.moreCards(t);

/// The effects of layer [t] that are switched off.
List<String> effectsOff(WorkspaceController ws, int t) => [
  for (final e in ws.inside!.word(t, 'fx_off').split(';'))
    if (e.isNotEmpty) e,
];

/// What an effect does, in its maker's words. Empty if none.
String aboutEffect(WorkspaceController ws, String title) =>
    ws.inside!.about(title);

/// Evaluates a number typed into a number field (see Motolii.workOut), or null when it is not a valid expression.
double? workOutSum(WorkspaceController ws, String sum) =>
    ws.inside!.workOut(sum);

/// The SVG path of layer [t]'s outline, for the Paths preview (see Motolii.shapeSvg).
String shapeSvgOf(WorkspaceController ws, int t) => ws.inside!.shapeSvg(t);

/// Moves the effect card [title] of layer [t] by [by] places in its stack, as one undo step.
void moveEffect(WorkspaceController ws, int t, String title, int by) =>
    ws.after(
      ws.inside!.later('fx_move', layer: t, word: title, number: by.toDouble()),
    );

/// Puts the More card [title] of layer [t] on, and rebuilds the inspector.
void askMoreCard(WorkspaceController ws, int t, String title) {
  ws.inside!.asked.putIfAbsent(t, () => {}).add(title);
  ws.reread();
}

/// Removes the card [title] of layer [t], whose parameters are [names]. A Stroke card's ids name the stroke they belong to,
/// which the bin takes out; a Script card's script is cleared.
void removeCard(
  WorkspaceController ws,
  int t,
  String title,
  List<String> names,
) {
  final m = ws.inside!;
  // A Stroke card's parameter ids read as "<6-hex>:stroke" and
  // "<6-hex>:stroke_width"; the id in front of the colon is the
  // instance's handle. The bin takes that one slot out.
  if (title == 'Stroke' && names.isNotEmpty) {
    final head = names.first.split(':');
    if (head.length == 2 && head[0].length == 6) {
      ws.after(
        m.later('stroke_out', layer: t, word: head[0]),
        (_, _) => ws.reread(),
      );
      return;
    }
  }
  ws.after(
    title == 'Script'
        ? m.later('say', layer: t, name: 'script', word: '')
        : m.later('fx_out', layer: t, word: title),
    (_, _) => ws.reread(),
  );
}

/// Adds a stroke to layer [t] (a text, a shape or an image).
void addStroke(WorkspaceController ws, int t) =>
    ws.after(ws.inside!.later('stroke_add', layer: t), (_, _) => ws.reread());

/// Switches the effect card [title] of layer [t] on or off, which the document keeps as bypass.
void toggleEffect(WorkspaceController ws, int t, String title) => ws.after(
  ws.inside!.later('fx_visible', layer: t, word: title),
  (_, _) => ws.reread(),
);

/// Puts the effect [title] of layer [t] on again after itself, with its values (Alight Motion's Duplicate).
void duplicateEffect(WorkspaceController ws, int t, String title) => ws.after(
  ws.inside!.later('fx_duplicate', layer: t, word: title),
  (done, why) => done ? ws.reread() : ws.notice = why,
);

/// Keeps the values and keys of card [title] of layer [t], whose parameters are [names], as a look on the Effects shelf.
void keepCardPreset(
  WorkspaceController ws,
  int t,
  String title,
  List<String> names,
) {
  final m = ws.inside!;
  ws.after(
    m.later('keep_preset', layer: t, name: names.join(' '), word: title),
    (done, why) {
      // (that effect's values and keys a look on the Effects shelf, by its name and a number the inside gives it)
      m.forgetFolders();
      ws.notice = done ? 'Preset kept: $title' : 'Not kept: $why';
      ws.reread();
    },
  );
}

/// Sets the values of the cards [names] of layer [t] back to their defaults.
void resetCardValues(WorkspaceController ws, int t, List<String> names) =>
    ws.after(
      ws.inside!.later('reset', layer: t, word: names.join(' ')),
      (_, _) => ws.reread(),
    );

/// Copies the values of the cards [names] of layer [t] to the clipboard file [file]. Returns the ticket.
int copyCardValues(
  WorkspaceController ws,
  int t,
  List<String> names,
  String file,
) =>
    ws.inside!.later('copy_style', layer: t, name: names.join(' '), word: file);

/// Pastes the card values in the clipboard file [file] onto layer [t], when that file is there.
void pasteCardValues(WorkspaceController ws, int t, String file) {
  if (!existsFile(file)) return;
  ws.after(
    ws.inside!.later('paste_style', layer: t, word: file),
    (_, _) => ws.reread(),
  );
}

/// Puts down a value the user has dragged, unchanged, without waiting for the engine.
void putDownValue(WorkspaceController ws) =>
    ws.after(ws.inside!.later('drag_end'));

/// Applies a keyframe mark chosen in the inspector: a keyframe at the playhead, that keyframe removed, or no keyframes at all.
void applyKeyframeMark(
  WorkspaceController ws,
  String? id,
  String prop,
  KeyframeState mark,
) {
  final m = ws.inside!, t = id == null ? 0 : int.tryParse(id);
  if (t == null) return;
  final at = ws.frame / WorkspaceController.fps, has = m.values(t).toSet();
  // Only values the layer has are keyed. A flat layer has no scale_z, and asking for a key on it was refused,
  // which rolled back the whole undo step including the number just released.
  // With Animate on, that lost the first scale of a flat layer.
  // The calls form one undo step and do not wait for the result.
  m.later('together', number: 1);
  for (final n in [
    for (final MapEntry(:key, :value) in keyableValuesOf(ws, t).entries)
      if (key == prop || propOf(key) == prop) value,
  ].where(has.contains)) {
    m.later(
      switch (mark) {
        KeyframeState.at => 'key_here',
        KeyframeState.anim => 'unkey',
        KeyframeState.off => 'stay',
      },
      layer: t,
      name: n,
      number: at,
    );
  }
  ws.after(m.later('together'));
}
