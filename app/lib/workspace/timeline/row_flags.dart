// Each row's switches as the project stores them: hidden, solo and locked.
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The hidden, solo and locked switches of the layers of a workspace, and the commands that turn them.
///
/// Solo and lock are stored in the project, as in After Effects. Reading a switch reads the last snapshot of the
/// project, so no engine call is made while a row is built.
class RowFlags {
  /// The switches of the layers of [workspace].
  const RowFlags(this.workspace);

  /// The workspace whose layers are read and whose engine takes the commands.
  final WorkspaceController workspace;

  /// Whether the layer [id] is hidden.
  ///
  /// Hiding sets the layer's visible property to 0 in the project, so the layer is not on the canvas.
  bool isHidden(String id) =>
      workspace.layers.any((l) => l.id == id && l.hidden);

  /// Hides the layer [id], or shows it again. It is one undo step.
  void toggleHidden(String id) {
    workspace.after(
      workspace.inside!.later(
        'set',
        layer: int.parse(id),
        name: 'visible',
        number: isHidden(id) ? 1 : 0,
      ),
    );
  }

  /// Whether the layer [id] is solo. While any layer is solo, only the solo layers are shown.
  bool isSolo(String id) => workspace.layers.any((l) => l.id == id && l.solo);

  /// Whether the layer [id] is locked. The engine refuses to change a locked layer and reports an error.
  bool isLocked(String id) =>
      workspace.layers.any((l) => l.id == id && l.locked);

  /// Whether any layer is solo.
  bool get anySolo => workspace.layers.any((l) => isSolo(l.id));

  /// Turns the switch [name] of the layer [id] on or off. [name] is `solo` or `lock`, as the project spells it.
  void toggle(String name, String id) {
    final m = workspace.inside!;
    workspace.after(
      m.later(
        'set',
        layer: int.parse(id),
        name: name,
        number: (name == 'solo' ? isSolo(id) : isLocked(id)) ? 0 : 1,
      ),
    );
  }
}
