// dock_files_used.dart: which files the document uses (and by which thing), and a file put on the stage.
part of 'dock_files.dart';

var _usedNow = <String, String>{};

int? _usedRev;

/// The files the document's things are made of, by whole path: the thing that uses each (the last one, the one in front).
Map<String, String> _used(Ws ws) {
  if (_usedRev == ws.rev) return _usedNow;
  final m = ws.inside!;
  _usedRev = ws.rev;
  return _usedNow = {
    for (final l in ws.layers.reversed) // (the nearest thing is the first row: it is told last, so it is the one kept)
      if (m.word(int.parse(l.id), 'file') case final f when f.isNotEmpty && !const {'behaviour', 'camera', 'light'}.contains(m.word(int.parse(l.id), 'kind'))) m.whole(f): l.id,   // (theirs is their kind's name, no file)
  };
}

/// The thing of the document a file is on.
String? _layerOf(FileNode n, DockCtx c) => _used(c.ws)[n.id];

bool _inUse(FileNode n, DockCtx c) => _layerOf(n, c) != null;

/// Every thing that shows [file] (whole path), by the word that says so: its own file, or a shape filled with it.
List<(int, String)> _showing(Motolii m, String file) => [
  for (final t in m.things)
    for (final w in const ['file', 'fill_media'])
      if (m.word(t, w) case final f when f.isNotEmpty && m.whole(f) == file) (t, w),
];

/// [file] put in place of what [all] show, in one step, as Alight Motion's Media Info replaces a file in the whole scene
/// (AbsentMotion's replaceMedia, model/Media.kt: the file's uri and every fill of it), After Effects' and Premiere Pro's
/// Replace Footage.
void _replaceAll(DockCtx c, List<(int, String)> all, String file) {
  final m = c.ws.inside!;
  m.later('together', number: 1);
  for (final (t, w) in all) {
    c.ws.after(m.later('say', thing: t, name: w, word: file), (done, why) {
      if (!done) c.ws.notice = 'Not replaced: $why';
    });
  }
  c.ws.after(m.later('together'), (_, _) => c.ws.reread());
}

/// The files picked together (⌘ and a press, as Finder adds to what is picked): placed together, one after another.
final _filesPicked = <String>{};

/// The files picked together put on the stage, each a new thing from the present moment, each film as long as it plays
/// (the discoverer's length: a film said no length lasts to the document's end), then, all of them films, laid one after
/// another in the order picked (the inside's Stagger: Alight Motion adds several so); all of them picked. A still lasts
/// as long as chosen under it (End: stills are laid together).
Future<void> _placeAll(DockCtx c, List<String> files) async {
  if (_level(files) case final drawings?) return _placeLevel(c, drawings);
  final m = c.ws.inside!;
  final lengths = [for (final (i, s) in (await Future.wait([for (final f in files) mediaSecondsOf(m.libPath, f)])).indexed) _kindOfFile(files[i]) == 'picture' ? _stillSeconds : s];   // (a still: as long as chosen)
  m.later('together', number: 1);
  final made = <Future<int>>[];
  for (final (i, f) in files.indexed) {
    final asked = Completer<int>();
    c.ws.after(m.later('add', word: f), (done, why) {
      if (done) return;
      c.set(() => c.mem.trouble[f] = why);
      asked.complete(0);
    }, asked.complete);
    if (_fitted(f)) m.later('fit', thing: -1, word: 'fit');
    if (lengths[i] > 0) m.later('set', thing: -1, name: 'duration', number: lengths[i]);   // (the one just added)
    made.add(asked.future);
  }
  c.ws.after(m.later('together'));
  Future.wait(made).then((ids) {
    final all = [for (final i in ids) if (i > 0) i];
    if (all.length > 1 && lengths.every((s) => s > 0)) c.ws.after(m.later('time_align', word: 'stagger ${all.join(' ')}'), (_, _) => c.ws.reread());
    c.ws.pickMany([for (final i in all) '$i']);
    _filesPicked.clear();
  });
}

/// The pictures picked together, when they are the drawings of one level: one folder, one name, a number at its end
/// (OpenToonz's level, animation_0001.png, read by (\d+): tfilepath.cpp), each by its number, the lowest first.
List<(int, String)>? _level(List<String> files) {
  final named = RegExp(r'^(.*?)(\d+)(\.[^./]+)$'), drawings = <(int, String)>[];
  String? level;
  for (final f in files) {
    final m = named.firstMatch(f);
    if (_kindOfFile(f) != 'picture' || m == null || (level ??= '${m[1]}${m[3]}') != '${m[1]}${m[3]}') return null;
    drawings.add((int.parse(m[2]!), f));
  }
  return drawings.length < 2 ? null : (drawings..sort((a, b) => a.$1.compareTo(b.$1)));
}

/// A level put on the stage as one thing (OpenToonz's level, CLIP STUDIO's animation folder), its lowest drawing its
/// file, fitted; which drawing shows a key of its Drawing for each, the drawing's own number (not the how-manieth:
/// a drawing put in between, or a gap, moves no other), held to the next as a timesheet holds it (XDTS's frames, read
/// by OpenToonz's xdtsio.cpp: each to the next item). Each at its number's frame of 24 a second from the lowest (24: as
/// DiTiS reads a timesheet), so drawings numbered by their frames, 1, 3, 5, are held across the gaps, which the After
/// Effects forum asks for and After Effects lacks; the timing is then changed by moving the keys.
void _placeLevel(DockCtx c, List<(int, String)> drawings) {
  final m = c.ws.inside!, from = c.ws.frame / Ws.fps, first = drawings.first.$1;
  m.later('together', number: 1);
  c.ws.after(m.later('add', word: drawings.first.$2), (done, why) {
    if (!done) c.set(() => c.mem.trouble[drawings.first.$2] = why);
  }, (made) => c.ws.select('$made'));
  m.later('fit', thing: -1, word: 'fit');
  m.later('set', thing: -1, name: 'duration', number: (drawings.last.$1 - first + 1) / 24);
  for (final (n, _) in drawings) {
    final at = '${from + (n - first) / 24}';
    m.later('key', thing: -1, name: 'cel', word: at, number: n.toDouble());
    m.later('way', thing: -1, name: 'cel', number: double.parse(at), word: 'hold');
  }
  c.ws.after(m.later('together'), (_, _) => c.ws.reread());
  _filesPicked.clear();
}

/// A photo or a film comes fitted inside the picture, in its middle, as Alight Motion places one (AbsentMotion's
/// imageLayer and videoLayer, editor/EditorActions.kt and VideoActions.kt: golf ㊱); a drawing (Lottie, SVG, a roll) as it is.
bool _fitted(String file) => _kindOfFile(file) == 'film' || _kindOfFile(file) == 'picture' && RegExp(r'\.(jpe?g|png|webp|bmp|heic)$', caseSensitive: false).hasMatch(file);

final _placing = <String>{};

/// A file put on the stage as a new thing, picked. Not done: the foot of the shelf says why.
void _place(DockCtx c, FileNode n) {
  if (!_placing.add(n.id)) return;   // (a song takes the inside a moment to read: a press in that moment is the same press; golf_noise.md (119), no source, a rule of this window's)
  final m = c.ws.inside!, still = _kindOfFile(n.id) == 'picture' && _stillSeconds > 0, cut = const ['film', 'sound'].contains(_kindOfFile(n.id)) ? _filmRanges[n.id] : null, fit = _fitted(n.id); // (the inside makes of it what the file is; without waiting, picked once made)
  if (still || cut != null || fit) m.later('together', number: 1);   // (made, fitted and given its length: one step)
  c.ws.after(m.later('add', word: n.id), (done, why) {
    _placing.remove(n.id);
    c.set(() => done ? c.mem.trouble.remove(n.id) : c.mem.trouble[n.id] = why);
  }, (made) => c.ws.select('$made'));
  if (fit) m.later('fit', thing: -1, word: 'fit');
  if (still) m.later('set', thing: -1, name: 'duration', number: _stillSeconds);   // (the one just added: as long as chosen under it)
  if (cut case (final a, final b)) {
    mediaSecondsOf(m.libPath, n.id).then((len) {   // (known already: the band drew it)
      m.later('set', thing: -1, name: 'begin', number: a * len);   // (from where the band's left end is in the film)
      m.later('set', thing: -1, name: 'duration', number: (b - a) * len);
      c.ws.after(m.later('together'), (_, _) => c.ws.reread());
    });
  } else if (still || fit) {
    c.ws.after(m.later('together'), (_, _) => c.ws.reread());
  }
}
