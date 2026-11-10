// The home screen: a grid of the projects in a folder.
//
// The layout follows CapCut's desktop home: a wide "New Project" button, then "Projects" with a search field and a grid
// of square thumbnails, each with its name and "size | length" below.
// The facts shown (aspect ratio, resolution, frame rate) and the grouping follow AbsentMotion (Apache-2.0,
// ui/home/HomeScreen.kt, ProjectFacts.kt aspectName, ExportOptions.kt formatBytes):
// projects are grouped under the day they were last changed, newest first, or listed by name.
// Clicking a card opens it. Its menu can select, export, duplicate, or move it to the Trash after a confirmation.
// The thumbnail, size and length come from what the project last saved (Motolii.poster), read without opening it.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../../bridge/motolii.dart' show docFactsOf;
import '../../skin/tokens.dart';
import '../../widgets/controls.dart' show Chip, ChipLook;
import '../state/state.dart';
import 'settings_file.dart' show firstFree;
import '../../widgets/text_gestures.dart';

/// One project listed: its file, and the facts saved in it. [facts] and [picture] are null until read, or if the project saved none.
class HomeDoc {
  HomeDoc(this.path, this.changed, this.bytes);
  final String path;
  final DateTime changed;
  final int bytes;
  ({int wide, int high, double seconds, double rate})? facts;
  String? picture;
  String get name => path.split('/').last.replaceFirst(RegExp(r'\.motolii$'), '');
}

class WsHome extends StatefulWidget {
  const WsHome({
    super.key,
    required this.folder,
    required this.lib,
    required this.open,
    required this.onOpen,
    required this.onExport,
    required this.onNew,
    required this.onClose,
  });

  /// The folder whose projects are listed.
  final String folder;

  /// The engine library, used to read each project's facts on another isolate.
  final String lib;

  /// The path of the project that is open now.
  final String open;
  final void Function(String doc) onOpen;
  final void Function(List<String> docs) onExport;
  final VoidCallback onNew, onClose;
  @override
  State<WsHome> createState() => _WsHomeState();
}

class _WsHomeState extends State<WsHome> {
  // The last sort order chosen, kept like AbsentMotion's sortBy.
  static var byName = false;
  List<HomeDoc> _docs = const [];
  // The card whose menu is open.
  String? _menu;
  // The card waiting for the user to confirm moving it to the Trash.
  String? _asking;
  // The search text, matched against project names.
  String _find = '';
  // Selected projects, as in Alight Motion's menu "Select" or Cmd-click in the Finder.
  // While any is selected, a click toggles selection instead of opening.
  final _picked = <String>{};
  late final Directory _pictures = Directory.systemTemp.createTempSync('motolii_home');

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void dispose() {
    _findText.dispose();
    _findFocus.dispose();
    try {
      _pictures.deleteSync(recursive: true);
    } catch (_) {}
    super.dispose();
  }

  // Counts reads so each read writes thumbnails under new names and never overwrites one that is on screen.
  var _reads = 0;
  void _read() {
    final docs = <HomeDoc>[], read = _reads++;
    for (final f in Directory(widget.folder).listSync().whereType<File>()) {
      if (!f.path.endsWith('.motolii')) continue;
      final s = f.statSync();
      docs.add(HomeDoc(f.path, s.modified, s.size));
    }
    setState(() => _docs = docs);
    for (final (i, d) in docs.indexed) {
      final png = '${_pictures.path}/$read-$i.png';
      docFactsOf(widget.lib, d.path, png).then((facts) {
        if (!mounted) return;
        setState(
          () => d
            ..facts = facts
            ..picture = facts != null && File(png).existsSync() ? png : null,
        );
      });
    }
  }

  /// Copies the project next to it, named "Name Copy" (AbsentMotion's naming), with a number added if that name is taken.
  void _duplicate(HomeDoc d) {
    final to = firstFree('${widget.folder}/${d.name} Copy.motolii', (f) => File(f).existsSync(), (n) => '${widget.folder}/${d.name} Copy $n.motolii');
    File(d.path).copySync(to);
    _menu = null;
    _read();
  }

  /// Moves the project to the user's ~/.Trash, as the Finder does, adding a number if the name is taken there.
  void _trash(HomeDoc d) {
    final trash = '${Platform.environment['HOME']}/.Trash';
    final to = firstFree('$trash/${d.name}.motolii', (f) => File(f).existsSync(), (n) => '$trash/${d.name} $n.motolii');
    try {
      File(d.path).renameSync(to);
    } catch (_) {
      return;
    }
    _menu = _asking = null;
    _read();
  }

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  // AbsentMotion's dateHeader in English: d MMMM yyyy.
  static String _day(DateTime t) => '${t.day} ${_months[t.month - 1]} ${t.year}';

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[],
        shown = [
          for (final d in _docs)
            if (d.name.toLowerCase().contains(_find.toLowerCase())) d,
        ];
    Widget grid(List<HomeDoc> docs) => Wrap(spacing: 20, runSpacing: 20, children: [for (final d in docs) _card(d)]);
    if (byName) {
      rows.add(grid(shown..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))));
    } else {
      final byDay = <String, List<HomeDoc>>{};
      for (final d in shown..sort((a, b) => b.changed.compareTo(a.changed))) {
        (byDay[_day(d.changed)] ??= []).add(d);
      }
      for (final MapEntry(key: day, value: docs) in byDay.entries) {
        rows
          ..add(
            Padding(
              padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 24, bottom: 12),
              child: Text(day, style: T.label(Grey.g76)),
            ),
          )
          ..add(grid(docs));
      }
    }
    return ColoredBox(
      key: const ValueKey('ws-home'),
      color: WsT.ground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [const Spacer(), _button('home-close', '×', false, widget.onClose)]),
            const SizedBox(height: 8),
            NakedButton(
              enableFeedback: false,
              // CapCut's "Create project": a button as wide as the page.
              key: const ValueKey('home-new'),
              onPressed: widget.onNew,
              child: Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WsT.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WsT.raised),
                ),
                child: Text('+  New Project', style: T.title(Grey.g91)),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Projects', style: T.title(Grey.g91)),
                const Spacer(),
                SizedBox(
                  width: 180,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: WsT.inset, vertical: 4),
                    decoration: BoxDecoration(color: WsT.card, borderRadius: BorderRadius.circular(6)),
                    child: TextGestures(
                      key: const ValueKey('home-find'),
                      field: (k) => EditableText(
                        key: k,
                        rendererIgnoresPointer: true,
                        controller: _findText,
                        focusNode: _findFocus,
                        style: T.label(Grey.g91),
                        cursorColor: WsT.accent,
                        backgroundCursorColor: Grey.g63,
                        onChanged: (v) => setState(() => _find = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_picked.isNotEmpty) ...[
                  _button('home-export', 'Export ${_picked.length}', true, () => widget.onExport([..._picked])),
                  _button('home-unpick', 'Cancel', false, () => setState(_picked.clear)),
                  const SizedBox(width: 8),
                ],
                _button('home-by-date', 'Date', !byName, () => setState(() => byName = false)),
                _button('home-by-name', 'Name', byName, () => setState(() => byName = true)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: ListView(children: rows)),
          ],
        ),
      ),
    );
  }

  final _findText = TextEditingController();
  final _findFocus = FocusNode();

  Widget _button(String key, String text, bool on, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Chip(
      key: ValueKey(key),
      label: text,
      on: on,
      onTap: tap,
      look: ChipLook(fill: WsT.card, onFill: WsT.accent, ink: Grey.g91, onInk: WsT.onAccent, padX: 8, padY: 4, radius: 6, text: (c) => T.label(c)),
    ),
  );
  // A square thumbnail above the name, as in CapCut's desktop grid.
  static const _tile = 150.0;

  Widget _card(HomeDoc d) {
    final f = d.facts, open = d.path == widget.open;
    return SizedBox(
      width: _tile,
      child: NakedButton(
        enableFeedback: false,
        key: ValueKey('home-doc:${d.path}'),
        onPressed: () => _picked.isNotEmpty || HardwareKeyboard.instance.isMetaPressed
            ? setState(() {
                if (!_picked.remove(d.path)) _picked.add(d.path);
              })
            : widget.onOpen(d.path),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: _tile,
              decoration: BoxDecoration(
                color: WsT.card,
                borderRadius: BorderRadius.circular(8),
                border: open ? Border.all(color: WsT.accent, width: 2) : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (d.picture != null) Image.file(File(d.picture!), fit: BoxFit.cover),
                  if (_picked.contains(d.path))
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        key: ValueKey('home-picked:${d.path}'),
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: WsT.accent, borderRadius: BorderRadius.circular(4)),
                        child: Text('✓', style: T.label(WsT.onAccent)),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: NakedButton(
                      enableFeedback: false,
                      key: ValueKey('home-more:${d.path}'),
                      onPressed: () => setState(() => _menu = _menu == d.path ? null : d.path),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: WsT.ground, borderRadius: BorderRadius.circular(4)),
                        child: Text('•••', style: T.label(Grey.g76)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              d.name,
              style: T.name(Grey.g91).copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // CapCut's "254.3M | 02:13".
            Text([_bytes(d.bytes), if (f != null) _length(f.seconds)].join(' | '), style: T.value(Grey.g63), maxLines: 1),
            Text(_facts(d).join(' · '), key: ValueKey('home-facts:${d.path}'), style: T.value(Grey.g56), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_menu == d.path)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: _asking == d.path
                      ? [
                          Text('Move to the Trash?', style: T.label(Grey.g91)),
                          _button('home-trash-yes:${d.path}', 'Move to Trash', true, () => _trash(d)),
                          _button('home-trash-no:${d.path}', 'Cancel', false, () => setState(() => _asking = null)),
                        ]
                      : [
                          _button('home-open:${d.path}', 'Open', false, () => widget.onOpen(d.path)),
                          _button(
                            'home-select:${d.path}',
                            'Select',
                            false,
                            () => setState(() {
                              _picked.add(d.path);
                              _menu = null;
                            }),
                          ),
                          _button('home-export:${d.path}', 'Export…', false, () => widget.onExport([d.path])),
                          _button('home-duplicate:${d.path}', 'Duplicate', false, () => _duplicate(d)),
                          if (!open) _button('home-trash:${d.path}', 'Move to Trash', false, () => setState(() => _asking = d.path)),
                        ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The aspect ratio and resolution, then the frame rate, as AbsentMotion shows them.
  /// A known ratio gives "9:16" and the shorter side as "1080p"; any other gives "1080x1350".
  static List<String> _facts(HomeDoc d) {
    final f = d.facts;
    if (f == null) return const [];
    String? ratio;
    for (final (a, b) in const [(16, 9), (9, 16), (4, 5), (1, 1), (4, 3)]) {
      if ((f.wide * b - f.high * a).abs() <= math.max(a, b)) {
        ratio = '$a:$b';
        break;
      }
    }
    return [
      if (ratio != null) ...[ratio, '${math.min(f.wide, f.high)}p'] else '${f.wide}x${f.high}',
      '${f.rate == f.rate.roundToDouble() ? f.rate.round() : f.rate}fps',
    ]; // The frame rate is the project's own frame_rate.
  }

  static String _bytes(int bytes) {
    // Follows ExportOptions.kt formatBytes.
    String f(double v, String unit) => (v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')) + unit;
    if (bytes < 1024) return '${math.max(bytes, 0)}B';
    if (bytes < 1024 * 1024 - 512) return f(bytes / 1024, 'KB');
    if (bytes < 1024 * 1024 * 1024 - 512 * 1024) return f(bytes / (1024 * 1024), 'MB');
    return f(bytes / (1024 * 1024 * 1024), 'GB');
  }

  static String _length(double seconds) {
    // CapCut's "02:13"; an hour or more gives AbsentMotion's "01:02:13".
    final s = seconds.round();
    String two(int n) => n.toString().padLeft(2, '0');
    return s >= 3600 ? '${two(s ~/ 3600)}:${two(s ~/ 60 % 60)}:${two(s % 60)}' : '${two(s ~/ 60)}:${two(s % 60)}';
  }
}
