// What a shelf body is given by the dock for one build: DockMem (what each shelf remembers) and DockCtx (the memory,
// the search text, the project and a way to change local state), and the file that stores which items are starred.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/storage/kept_file.dart' show fileKeep, fileList;
import 'package:motolii/workspace/shelf/tile_hover.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

/// What the dock remembers per shelf while the user switches between shelves (selection, chip, folds).
/// It lives in the dock's state, never in [Ws].
class DockMem {
  final sel = <String, String>{'Media': 'coda_intro', 'Effects': 'Glow', 'Fonts': 'Avenir Next', 'Colors': 'pop-2', 'Create': 'Shape'};
  final chip = <String, String>{};
  final folded = <String>{'Time'};
  final open = <String>{'Project'};

  /// The ids the user has starred, stored in ~/.motolii/effect_stars.json like the Ease tool panel's stars.
  final starred = _starsRead();

  /// Why the last request to the engine for an entry failed, by the entry's id.
  final trouble = <String, String>{};

  /// Whether the shelf's footer is open (see [DockCtx.foot]).
  bool footOpen = false;
  bool mediaList = false;

  /// The shelves shown as a map with similar items close together (dock_map.dart), instead of as rows of tiles.
  final mapped = <String>{};

  /// Program: show the selected item's code instead of the list.
  bool programCode = false;

  /// Media: list the folders below the open one together with it, and where the tree sits.
  /// [treeSide] is 0 for automatic by the available room, 1 for left, 2 for above.
  bool mediaDeep = false;

  /// Create: the sections the user has folded. None at first, so the moving tiles of every recipe can be looked over.
  final createFolded = <String>{};
  int treeSide = 0;

  /// Media: the open folder (a [FileNode] id) and the height of the tree band when the shelf is narrow.
  String folder = 'Footage';
  double treeHeight = 132;

  /// Effects: which row of the list is chosen (All, Recent, ★, In video, /pack, @deck) and the list's height
  /// when the shelf is narrow.
  String fxPlace = 'All';
  double fxListHeight = 176;

  /// Effects: whether the list is open. When closed in a narrow shelf, it shows only the chosen row.
  bool fxListOpen = false;
}

/// What a shelf body needs from the dock for one build: the memory, the search text, the project, and a way to change local state.
class DockCtx {
  DockCtx(this.shelf, this.mem, this.query, this.ws, this.set, this.clearSearch);
  final String shelf;
  final DockMem mem;
  final String query;
  final Ws ws;
  final void Function(VoidCallback) set;
  final VoidCallback clearSearch;

  String? get sel => mem.sel[shelf];
  void pick(String id) => set(() => mem.sel[shelf] = id);

  /// Returns [picked] if the footer should show it, otherwise null.
  ///
  /// Opening the footer shortens the tiles, so a tile low on the shelf could move away before the second click of a
  /// double-click. A closed footer therefore opens only once a second click can no longer come, following Microsoft's
  /// "How to distinguish between single and double clicks". The selection itself does not wait,
  /// and neither does a footer that is already open.
  P? foot<P>(P? picked) {
    mem.footOpen = picked != null && (mem.footOpen || !DockHover.secondMayCome.value);
    return mem.footOpen ? picked : null;
  }

  String get chip => mem.chip[shelf] ?? 'All';
  void pickChip(String c) => set(() => mem.chip[shelf] = c);
  bool hit(String name) => query.isEmpty || name.toLowerCase().contains(query.toLowerCase());

  /// The ids of the five closest [items], best first, for when the search text finds nothing.
  ///
  /// Each item is its id, name and description. The engine does the matching, as it does for the effects shelf:
  /// RapidFuzz for a misspelled or partial word and Japanese WordNet for a Japanese word. Every shelf uses it.
  /// Empty while nothing is typed. [least] is the score below which an item is left out (see Motolii.find).
  List<String> near(Iterable<(String, String, String)> items, {double least = 0}) =>
      query.trim().isEmpty ? const [] : ws.inside?.find(query, items, least: least) ?? const [];
  Set<String> get _stars => mem.starred;
  bool starred(String id) => _stars.contains(id);
  void star(String id) => set(() {
    _stars.contains(id) ? _stars.remove(id) : _stars.add(id);
    _starsKeep(_stars);
  });
  void unstar(Iterable<String> ids) => set(() {
    _stars.removeAll(ids);
    _starsKeep(_stars);
  });
  void toggle(Set<String> s, String id) => set(() => s.contains(id) ? s.remove(id) : s.add(id));
}

/// Where the starred effects are stored, in the same way the Ease tool panel stores its stars (ease_stars.json).
/// A test can point it elsewhere with [dockStarsAt].
File _starsFile = File('${Platform.environment['HOME']}/.motolii/effect_stars.json');
void dockStarsAt(File f) => _starsFile = f;
Set<String> _starsRead() => {for (final s in fileList(_starsFile)) '$s'};

void _starsKeep(Set<String> all) => fileKeep(_starsFile, jsonEncode(all.toList()));
