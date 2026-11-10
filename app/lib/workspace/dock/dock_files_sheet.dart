// Places a timesheet on the canvas: each of its columns becomes a level timed by keyframes.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/dock/dock_files.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

/// Reads the columns of an XDTS timesheet, CELSYS's open exchange format: a header line followed by JSON.
///
/// It follows OpenToonz (xdtsio.cpp, loadXdtsScene and getCellFrameIdTrack). Each track of the first time table
/// (fieldId 0) is a column, named by the header name at its trackNo, with the bottom column first.
/// Each item is a change at its frame that holds until the next item, and the last one holds to the end of the sheet.
/// A value is a drawing number, or -1 for an empty cell (SYMBOL_NULL_CELL, no value, or before the first item).
/// The hyphen and in-between marks (SYMBOL_HYPHEN, SYMBOL_TICK_1, SYMBOL_TICK_2) keep the previous value.
/// An item before frame 0 shows from the start, which CLIP STUDIO writes sometimes.
/// A number with a letter, such as 3a, is not supported and is returned in `unread`.
/// Returns null if [text] is not a timesheet.
({int frames, List<(String, List<(int, int)>)> columns, Set<String> unread})? _sheetOf(String text) {
  const first = 'exchangeDigitalTimeSheet Save Data';
  if (!text.startsWith(first)) return null;
  try {
    final table = (jsonDecode(text.substring(first.length)) as Map)['timeTables'][0] as Map, unread = <String>{};
    final names = (table['timeTableHeaders'] as List).firstWhere((h) => h['fieldId'] == 0)['names'] as List;
    final tracks = ((table['fields'] as List).firstWhere((f) => f['fieldId'] == 0)['tracks'] as List).cast<Map>().toList()
      ..sort((a, b) => (a['trackNo'] as int).compareTo(b['trackNo'] as int));
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

/// Returns the drawings of one level, lowest number first, if [files] are all drawings of it, otherwise null.
///
/// The drawings are image files in one folder with the same name apart from a number at the end, such as
/// animation_0001.png, which OpenToonz reads in tfilepath.cpp. At least [least] drawings are needed.
List<(int, String)>? levelOf(List<String> files, {int least = 2}) {
  final named = RegExp(r'^(.*?)(\d+)(\.[^./]+)$'), drawings = <(int, String)>[];
  String? level;
  for (final f in files) {
    final m = named.firstMatch(f);
    if (kindOfFile(f) != 'picture' || m == null || (level ??= '${m[1]}${m[3]}') != '${m[1]}${m[3]}') return null;
    drawings.add((int.parse(m[2]!), f));
  }
  return drawings.length < least ? null : (drawings..sort((a, b) => a.$1.compareTo(b.$1)));
}

/// Finds the drawings of the level [name] for the timesheet file [sheet].
///
/// A level's name is the part before the '.' or '_' and the number, as in OpenToonz's tfilepath.cpp getLevelNameW
/// (A.0001.png, A_0001.png). It looks in the sheet's folder, then in a subfolder of that name, as CLIP STUDIO writes
/// foo/A/ (OpenToonz's xdtsimportpopup.cpp, updateSuggestions).
List<(int, String)>? _levelNamed(String sheet, String name) {
  final here = File(sheet).parent.path, named = RegExp('^${RegExp.escape(name)}[._]\\d+\\.[^./]+\$');
  for (final folder in [here, '$here/$name']) {
    if (!Directory(folder).existsSync()) continue;
    if (levelOf([
          for (final e in Directory(folder).listSync())
            if (e is File && named.hasMatch(basename(e.path))) e.path,
        ], least: 1)
        case final drawings?) {
      return drawings;
    }
  }
  return null;
}

/// Places the timesheet [file] on the canvas, starting at the current time.
///
/// Each column becomes a level as [_placeLevel] makes one, named after the column as OpenToonz does, and as long as
/// the sheet. Each change gets a hold keyframe on the level's Drawing property at 24 frames per second, as DiTiS reads
/// a sheet. The bottom column comes first, everything is one undo step, and the new layers are selected.
/// Missing drawings and unsupported values are reported in the notice.
Future<void> placeSheet(DockCtx c, String file) async {
  final sheet = _sheetOf(await File(file).readAsString().catchError((_) => ''));
  if (sheet == null) {
    c.ws.notice = 'Not a timesheet: ${basename(file)}';
    return;
  }
  final m = c.ws.inside!, from = c.ws.frame / WorkspaceController.fps, missing = <String>[], made = <Future<int>>[];
  m.later('together', number: 1);
  for (final (name, keys) in sheet.columns) {
    if (_levelNamed(file, name) case final drawings?) {
      final asked = Completer<int>();
      c.ws.after(m.later('add', word: drawings.first.$2), (done, why) {
        if (!done) asked.complete(0);
      }, asked.complete);
      m.later('fit', layer: -1, word: 'fit');
      m.later('say', layer: -1, name: 'name', word: name);
      m.later('set', layer: -1, name: 'duration', number: sheet.frames / 24);
      for (final (f, n) in keys) {
        final at = '${from + f / 24}';
        m.later('key', layer: -1, name: 'cel', word: at, number: n.toDouble());
        m.later('easing', layer: -1, name: 'cel', number: double.parse(at), word: 'hold');
      }
      made.add(asked.future);
    } else {
      missing.add(name);
    }
  }
  c.ws.after(m.later('together'), (_, _) => c.ws.reread());
  final ids = [
    for (final i in await Future.wait(made))
      if (i > 0) '$i',
  ];
  c.ws.pickMany(ids);
  final told = [
    if (missing.isNotEmpty) 'no drawings named ${missing.join(', ')} beside it',
    if (sheet.unread.isNotEmpty) 'not read: ${sheet.unread.join(', ')}',
  ];
  c.ws.notice = 'Placed ${ids.length} of ${sheet.columns.length} columns of ${basename(file)}${told.isEmpty ? '' : ': ${told.join('; ')}'}';
}
