// Every effect on the shelf has a tile that shows what it does, as Alight Motion's do (docs/design/alight_motion_ui.md).
// AbsentMotion shows each effect from a table written beforehand (tools/effect_showcase.json). Here the effect file itself tells the tile what to
// show, so a file the user puts in needs no table line and no developer. What is read from the file (engine/document/scripts/recipes.h, isf_tags):
// - A transition's progress goes from 0 to 1. An effect that runs by the clock, or keeps its previous frame, is left to run.
// - Otherwise the sample stands still, so the parameter that stands for the effect goes between two values (see [tellingKnob]).
// - If nothing shows on the whole photo, the effect goes on a card moving across AbsentMotion's grid (its "move" layout).
// - With no parameter to turn, a line between before and after sweeps across the tile.
// Only a tile that shows nothing stays still. AbsentMotion's own effects use their line of the table.
// A tile is sixteen pictures a twelfth of a second apart, played forwards and back at 24 fps so nothing jumps where it loops. The sample is the
// balloon photo that shelves/effects/sources/fx_tiles.sh draws on (fx_sample.jpg beside it). Tiles are drawn in a project of their own in another
// isolate, as create_preview.dart does for presets, and the engine says where each goes (~/Library/Caches/Motolii/tiles: doc_tile in
// engine/document/scripts/recipes.h). The effect is applied as fx_tiles.sh and engine/edit.sh do: a screen effect (.fs, .wgsl) on the whole picture,
// anything else on the photo layer. Pictures are shrunk with sips (192 px); moving ones are JPEG from ffmpeg. They are compared with the sample's
// own pictures using ffmpeg's psnr. If the effect changes nothing (over 40 dB: helpers of other scripts, PSD ones, scripts that stop on a call
// not supported yet), the tile is marked `home.same` and the shelf says so.
//
// The user's own folder is watched while the app is open (dart:io watch, FSEvents on a Mac). When a file is put in or taken out there, the
// shelves are read again (docs/app/BRIDGE.md rule 8) and its tile is drawn ahead of the rest.
import 'dart:async';

import 'package:flutter/foundation.dart' show ValueNotifier;

import 'package:motolii/bridge/engine_paths.dart'
    show motoliiDir, motoliiOwn, motoliiShelves;
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/folder_entries.dart' show folderThere;
import 'package:motolii/storage/shelf_disk.dart';
import 'package:motolii/workspace/state/tiles/tile_frames.dart';
import 'package:motolii/workspace/state/tiles/tile_queue.dart';
import 'package:motolii/workspace/state/tiles/tile_review.dart';
import 'package:motolii/workspace/state/tiles/tile_studio.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

abstract final class EffectTiles {
  static void Function()? _told;

  /// How many of the queued tiles are drawn, out of how many, while any are queued. The shelf's reload mark shows it.
  static final progress = ValueNotifier<(int, int)?>(null);
  static final _tiles = TileQueue<(String, String)>(
    draw,
    moving: true,
    batch: 12,
    progress: progress,
  );

  /// Draws [file]'s tile again ahead of the queue or, without [file], every tile on the shelf (the reload mark).
  static void again(WorkspaceController ws, {String? file}) =>
      _again(ws.inside!, file: file);

  static void _again(Motolii m, {String? file}) {
    _tiles.drop((q) => file == null || q.$1 == file);
    for (final (_, f) in m.effects) {
      final home = m.tileHome(f);
      if (home.isEmpty || (file != null && f != file)) continue;
      _tiles.forget(home);
      try {
        deleteFile('$home.tells');
      } catch (_) {}
      if (file != null) _tiles.ask(home, (f, home), at: 0);
    }
    if (_told case final changed?) _ask(m, changed);
  }

  /// How wide a tile's pictures are read. A picture drawn again under its own name is evicted at this width, or Flutter's image cache shows the old one.
  static const readWide = tileReadWide;

  /// The times its pictures are drawn at (AbsentMotion's 16 at 12 per second), and the index of the still: well into the motion.
  static final moments = tileMoments;
  static const still = tileStill;

  /// The saved .tells of [home]. Null when it was drawn before tiles were told anything.
  static String? _toldOf(String home) => readTextIfThere('$home.tells');

  /// Its moving pictures: home_0.jpg … home_15.jpg beside its still (none for a tile not drawn here).
  static String frame(String home, int k) => tileFrame(home, k);
  static String drawnFrame(String home, int k) => tileDrawnFrame(home, k);

  static String get own => motoliiOwn;

  /// The library's folders beside the user's own (the engine's doc_folders: the folder above its out/).
  static List<String> get library => [
    for (final f in const [
      'effects',
      'aviutl_scripts',
      'create',
      'expressions',
      'relations',
    ])
      '$motoliiShelves/$f',
  ];

  /// Watches until the subscription is cancelled. [changed] is called after the folders are read again and after tiles are drawn.
  static StreamSubscription<String>? watch(
    WorkspaceController ws,
    void Function() changed, {
    void Function(String file)? codeFile,
  }) {
    final m = ws.inside!;
    _ask(m, changed);
    try {
      makeFolder(
        '$own/effects',
      ); // There is somewhere to put files, as the README says.
    } catch (_) {
      return null;
    }
    Timer? soon;
    void again() {
      m.forgetFolders();
      changed();
      _ask(m, changed);
    }

    final inner = <StreamSubscription<String>>[];
    final merged = StreamController<String>(
      onCancel: () => Future.wait([for (final w in inner) w.cancel()]),
    );
    inner.addAll([
      for (final p in [own, ...library.where((p) => folderThere(p))])
        watchFolder(p).listen(merged.add),
    ]);
    final told = <String, Timer>{};
    return merged.stream.listen((e) {
      if (codeFile != null && e.startsWith('$own/programs/')) {
        // A code file: what is made from it follows, and no shelf is read again.
        told[e]?.cancel();
        told[e] = Timer(const Duration(milliseconds: 300), () => codeFile(e));
        return;
      }
      soon?.cancel();
      soon = Timer(
        const Duration(milliseconds: 300),
        again,
      ); // A copy is several events, so read once it has settled.
    });
  }

  /// Draws the tiles of effects on the shelf that are not drawn yet. One drawn before (in this run or another) is shown at once. The rest are queued,
  /// the user's own at the head (they were just put in), drawn a few at a time and shown as each batch finishes.
  static void ask(WorkspaceController ws, void Function() changed) =>
      _ask(ws.inside!, changed);

  static void _ask(Motolii m, void Function() changed) {
    var shown = false, head = 0;
    _told = changed;
    _tiles.onDrawn = (homes) {
      for (final h in homes) {
        m.tileRendered(h, same: existsFile('$h.same'));
      }
      changed();
    };
    for (final (_, f) in [
      ...m.effects,
    ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()))) {
      final home = m.tileHome(f);
      // Stale if drawn before tiles showed what the effect does, or with other weights. It is drawn again.
      final stale =
          home.isNotEmpty && _toldOf(home) != TileReview.tells(motoliiDir, f);
      if (home.isEmpty || (!stale && m.tileImage(f) == home)) continue;
      if (!stale && existsFile(home)) {
        m.tileRendered(home, same: existsFile('$home.same'));
        shown = true;
      } else {
        // The user's own effects go at the head (just put in). None are drawn under flutter test: seven hundred pictures would slow its timing.
        final own1 = f.startsWith(own);
        if (_tiles.ask(home, (f, home), at: own1 ? head : null) && own1) head++;
      }
    }
    if (shown) changed();
    _tiles.start();
  }

  static List<String> draw(String dir, List<(String, String)> files) {
    final studio = TileStudio.open(dir), drawn = <String>[];
    if (studio == null) return drawn;
    for (final (f, home) in files) {
      if (studio.tile(f, home)) drawn.add(home);
    }
    studio.close();
    return drawn;
  }
}
