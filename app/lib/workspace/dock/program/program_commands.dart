// What the Program shelf asks the engine to do: make a layer from a program, and take its code after an edit.
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/dock/program/program.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';

/// What the Program shelf asks the engine to do. Every call to the engine the shelf makes is a method here.
class ProgramCommands {
  /// [c] is the shelf as it is built now.
  ProgramCommands(this.c);

  /// The shelf's context: the project, the shelf's memory and a way to rebuild the shelf.
  final ShelfContext c;

  void _told(Program p, bool done, String why) => c.set(
    () => done ? c.mem.trouble.remove(p.file) : c.mem.trouble[p.file] = why,
  );

  /// Makes a layer from the program [p] and selects it. A pack is created by its name, as Create's tile does it;
  /// any other program goes through the adapter of what it was written for.
  void put(Program p) {
    final m = c.ws.inside!;
    if (p.recipe case final r?) {
      return c.ws.after(
        m.later('create', word: r),
        (done, why) => _told(p, done, why),
        (made) => c.ws.select('$made'),
        // Created as Create's tile does it (see CreateCommands.make).
      );
    }
    c.ws.after(
      m.later(
        'adapter',
        layer: int.tryParse(c.ws.selected ?? '') ?? 0,
        word: p.file,
      ),
      (done, why) => _told(p, done, why),
      (made) {
        if (made <= 0) return;
        if (p.name != p.plain) {
          c.ws.after(m.later('say', layer: made, name: 'name', word: p.name));
        }
        c.ws.select('$made');
      },
    );
  }

  /// Applies the saved code: the layer made from it follows, and so do its parameters in the inspector.
  ///
  /// If the code does not run, the reason is shown under the code.
  void saved(Program p) {
    final m = c.ws.inside;
    if (m == null) return;
    c.ws.after(m.later('code', word: p.file), (done, why) {
      _told(p, done, why);
      c.ws.reread();
    });
  }
}
