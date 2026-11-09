// dock_files_sheet.dart: a timesheet put on the stage, each of its columns a level timed by its keys.
part of 'dock_files.dart';

/// A timesheet's columns (XDTS, CELSYS's open exchange sheet: its first line, then JSON), read as OpenToonz reads one
/// (xdtsio.cpp loadXdtsScene and getCellFrameIdTrack): its first time table's cells (fieldId 0), a track a column, named
/// by the header's names at its trackNo, the bottom first; each item a change at its frame, held to the next, the last
/// to the sheet's end. A drawing's number, or -1 for × (SYMBOL_NULL_CELL, or no value, and before the first item); a
/// hyphen and the in-between marks ○ ● (SYMBOL_HYPHEN, SYMBOL_TICK_1, _2) keep what was before; an item below frame 0
/// is what shows from the start (CLIP STUDIO writes some). A number with a letter (3a) is not read yet: told. Null: not one.
({int frames, List<(String, List<(int, int)>)> columns, Set<String> unread})? _sheetOf(String text) {
  const first = 'exchangeDigitalTimeSheet Save Data';
  if (!text.startsWith(first)) return null;
  try {
    final table = (jsonDecode(text.substring(first.length)) as Map)['timeTables'][0] as Map, unread = <String>{};
    final names = (table['timeTableHeaders'] as List).firstWhere((h) => h['fieldId'] == 0)['names'] as List;
    final tracks = ((table['fields'] as List).firstWhere((f) => f['fieldId'] == 0)['tracks'] as List).cast<Map>().toList()..sort((a, b) => (a['trackNo'] as int).compareTo(b['trackNo'] as int));
    List<(int, int)> keysOf(Map track) {
      final keys = <int, int>{0: -1};
      for (final item in (track['frames'] as List).cast<Map>().toList()..sort((a, b) => (a['frame'] as int).compareTo(b['frame'] as int))) {
        final values = [for (final d in item['data'] as List) ...d['values'] as List];
        final said = values.isEmpty ? 'SYMBOL_NULL_CELL' : '${values.first}', n = said == 'SYMBOL_NULL_CELL' ? -1 : int.tryParse(said);
        if (n != null) keys[math.max(0, item['frame'] as int)] = n;
        if (n == null && !said.startsWith('SYMBOL_')) unread.add(said);
      }
      return [for (final e in keys.entries) (e.key, e.value)];
    }

    return (frames: table['duration'] as int, columns: [for (final t in tracks) ('${names[t['trackNo'] as int]}'.trim(), keysOf(t))], unread: unread);
  } catch (_) {
    return null;
  }
}

/// The drawings of the level [name] for the timesheet [sheet]: a level's name is what is before the '.' or '_' and its
/// number (OpenToonz's tfilepath.cpp getLevelNameW: A.0001.png, A_0001.png), looked for in the sheet's folder, then
/// in a folder of that name in it, as CLIP STUDIO writes foo/A/ (OpenToonz's xdtsimportpopup.cpp updateSuggestions).
List<(int, String)>? _levelNamed(String sheet, String name) {
  final here = File(sheet).parent.path, named = RegExp('^${RegExp.escape(name)}[._]\\d+\\.[^./]+\$');
  for (final folder in [here, '$here/$name']) {
    if (!Directory(folder).existsSync()) continue;
    if (_level([for (final e in Directory(folder).listSync()) if (e is File && named.hasMatch(_base(e.path))) e.path], least: 1) case final drawings?) return drawings;
  }
  return null;
}

/// A timesheet put on the stage from the present moment: each column a level, as [_placeLevel] makes one, named as the
/// column (OpenToonz names its column so), as long as the sheet, a held key of its Drawing at each change, 24 frames a
/// second (DiTiS reads a sheet so); the bottom column first, all in one step, all picked. What is not found or read,
/// the top bar says.
Future<void> _placeSheet(DockCtx c, String file) async {
  final sheet = _sheetOf(await File(file).readAsString().catchError((_) => ''));
  if (sheet == null) {
    c.ws.notice = 'Not a timesheet: ${_base(file)}';
    return;
  }
  final m = c.ws.inside!, from = c.ws.frame / Ws.fps, missing = <String>[], made = <Future<int>>[];
  m.later('together', number: 1);
  for (final (name, keys) in sheet.columns) {
    if (_levelNamed(file, name) case final drawings?) {
      final asked = Completer<int>();
      c.ws.after(m.later('add', word: drawings.first.$2), (done, why) {
        if (!done) asked.complete(0);
      }, asked.complete);
      m.later('fit', thing: -1, word: 'fit');
      m.later('say', thing: -1, name: 'name', word: name);
      m.later('set', thing: -1, name: 'duration', number: sheet.frames / 24);
      for (final (f, n) in keys) {
        final at = '${from + f / 24}';
        m.later('key', thing: -1, name: 'cel', word: at, number: n.toDouble());
        m.later('way', thing: -1, name: 'cel', number: double.parse(at), word: 'hold');
      }
      made.add(asked.future);
    } else {
      missing.add(name);
    }
  }
  c.ws.after(m.later('together'), (_, _) => c.ws.reread());
  final ids = [for (final i in await Future.wait(made)) if (i > 0) '$i'];
  c.ws.pickMany(ids);
  final told = [if (missing.isNotEmpty) 'no drawings named ${missing.join(', ')} beside it', if (sheet.unread.isNotEmpty) 'not read: ${sheet.unread.join(', ')}'];
  c.ws.notice = 'Placed ${ids.length} of ${sheet.columns.length} columns of ${_base(file)}${told.isEmpty ? '' : ': ${told.join('; ')}'}';
}
