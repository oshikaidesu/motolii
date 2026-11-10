// The app's top bar: wordmark, project name, selected layer, size, light or dark mode, and the Render button.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/skin/skin_parts.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge, Chip, ChipLook, Hov, IconPress;
import 'package:motolii/widgets/media.dart' show Draw, glyph;
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/state/art_scene.dart' show WsArt;
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/top_bar/size_chip.dart';
import 'package:motolii/workspace/top_bar/timings.dart';
import 'package:motolii/workspace/top_bar/zoom_readout.dart';

class WsTopBar extends StatelessWidget {
  const WsTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.animating, WsAspect.document, WsAspect.picked});
    return Container(
      color: WsT.body,
      padding: EdgeInsets.symmetric(horizontal: Shape.s(10)),
      child: Row(
        children: [
          const _Wordmark(),
          SizedBox(width: Shape.s(14)),
          const _UndoRedo(),
          SizedBox(width: Shape.s(14)),
          Flexible(
            child: Text(
              ws.document ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.name(Grey.g95).copyWith(fontWeight: FontWeight.w600),
            ),
          ), // A long name is cut off with an ellipsis so the bar keeps its layout.
          SizedBox(width: Shape.s(6)),
          Text('/', style: T.name(Grey.g44)),
          SizedBox(width: Shape.s(6)),
          Text(ws.layer?.name ?? 'Stage', style: T.name(Grey.g76)),
          SizedBox(width: Shape.s(10)),
          const SizeChip(),
          SizedBox(width: Shape.s(4)),
          Chip(
            label: '${Ws.fps} fps',
            look: ChipLook.readout(ink: Grey.g76),
          ),
          SizedBox(width: Shape.s(4)),
          Chip(
            label: ws.timecode(Ws.duration),
            look: ChipLook.readout(ink: Grey.g76),
          ),
          const Spacer(),
          const WsZoomReadout(),
          const _ShadeSwitch(),
          SizedBox(width: Shape.s(10)),
          const Waited(),
          const _Saved(),
          SizedBox(width: Shape.s(12)),
          const _Render(),
        ],
      ),
    );
  }
}

/// A square lime block with the wordmark in it: the poster's own manner, used once.
class _Wordmark extends StatelessWidget {
  const _Wordmark();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Badge(
        WsT.accent,
        size: Shape.z(22),
        radius: Radius.zero,
        child: Text(
          'M',
          style: T.title(WsT.onAccent).copyWith(fontSize: T.px(14), fontWeight: FontWeight.w900, height: 1),
        ),
      ),
      SizedBox(width: Shape.s(8)),
      Text(
        'Motolii',
        style: T.title(Grey.g95).copyWith(fontSize: T.px(14), fontWeight: FontWeight.w800, letterSpacing: -.2),
      ),
    ],
  );
}

/// Describes in plain words what an undo or redo changed, as the Edit menu of After Effects and Premiere Pro names
/// the step, for example "Undo Change Warmth".
///
/// It reads the layers and values that the reloaded project reports as changed.
String wsStepSaid(Ws ws, String done) {
  final c = ws.lastChange, m = ws.inside;
  if (c == null || m == null) return done;
  if (c.layers) return '$done: things added or taken away';
  final byThing = <int, Set<String>>{};
  for (final (t, n) in c.values) {
    (byThing[t] ??= {}).add(m.shown(n)?.label ?? n);
  }
  String nameOf(int t) => t == 0 ? 'Stage' : ws.layers.where((l) => l.id == '$t').firstOrNull?.name ?? 'a thing';
  final said = [for (final e in byThing.entries.take(3)) '${nameOf(e.key)} ${e.value.take(3).join(', ')}${e.value.length > 3 ? '…' : ''}'];
  return said.isEmpty ? done : '$done: ${said.join(' · ')}${byThing.length > 3 ? ' …' : ''}';
}

class _UndoRedo extends StatelessWidget {
  const _UndoRedo();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final flip in [false, true])
        IconPress(
          (c) => Transform.flip(
            flipX: flip,
            child: CustomPaint(size: const Size(12, 10), painter: Draw((cv, s) => _drawUndo(cv, s, c), c)),
          ),
          key: ValueKey(flip ? 'ws-redo' : 'ws-undo'),
          size: Shape.z(24),
          rest: const Color(0x00000000),
          ink: Grey.g63,
          onTap: () {
            final ws = WsScope.read(context), m = ws.inside;
            if (m == null) return;
            ws.after(
              m.later(flip ? 'redo' : 'undo'),
              (done, why) => ws.notice = done ? wsStepSaid(ws, flip ? 'Redone' : 'Undone') : why,
            ); // The app does not wait for the step to finish.
          },
        ),
    ],
  );
}

void _drawUndo(Canvas canvas, Size s, Color c) {
  if (SkinParts.draw(canvas, s, 'undo', c)) return; // The skin's own icon, if any.
  final p = Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas
    ..drawPath(
      Path()
        ..moveTo(1, 4)
        ..lineTo(8, 4)
        ..arcToPoint(Offset(8, s.height - 1), radius: Shape.r(3.2))
        ..lineTo(4, s.height - 1),
      p,
    )
    ..drawPath(
      Path()
        ..moveTo(4, 1)
        ..lineTo(1, 4)
        ..lineTo(4, 7),
      p,
    );
}

/// Switches between dark and light by flipping [Grey.shade] and rebuilding the whole app in place, keeping every State.
class _ShadeSwitch extends StatelessWidget {
  const _ShadeSwitch();
  static void flip() {
    Grey.shade.value = Grey.light ? Shade.dark : Shade.light;
    WidgetsBinding.instance.reassembleApplication();
  }

  @override
  Widget build(BuildContext context) => IconPress(
    (c) => glyph(12, (cv, s) => _drawShade(cv, s, c), c),
    key: const ValueKey('ws-shade'),
    onTap: flip,
    size: Shape.z(24),
    rest: const Color(0x00000000),
    ink: Grey.g63,
  );
}

/// A ring with its left half filled: the usual sign for "light or dark".
void _drawShade(Canvas canvas, Size s, Color c) {
  if (SkinParts.draw(canvas, s, 'shade', c)) return; // The skin's own icon, if any.
  final r = Rect.fromLTWH(.7, .7, s.width - 1.4, s.height - 1.4);
  canvas
    ..drawOval(
      r,
      Paint()
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    )
    ..drawArc(r, 1.5708, 3.14159, true, Paint()..color = c);
}

/// When the project file was last written. Every change is written as it is made.
String _savedAt(Ws ws) {
  final f = File('${ws.documentFolder}/${ws.document}');
  if (ws.document == null || !f.existsSync()) return 'Saved';
  final t = f.lastModifiedSync();
  return 'Saved ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _Saved extends StatelessWidget {
  const _Saved();
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.document, WsAspect.notice}), go = ws.noticeGo;
    final said = Text(
      ws.notice ?? _savedAt(ws),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: go == null ? T.label(Grey.g63) : T.label(Grey.g63).copyWith(decoration: TextDecoration.underline),
    ); // The underline marks the notice as a link when it has a target.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Badge(WsT.accent, size: Shape.z(6), radius: Radius.circular(Shape.z(3))),
        SizedBox(width: Shape.s(6)),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Shape.z(260)),
          child: go == null ? said : Hov(onTap: go, builder: (_, _) => said),
        ),
      ],
    );
  }
}

/// The one loud action: a flat lime pill with dark ink.
class _Render extends StatefulWidget {
  const _Render();
  @override
  State<_Render> createState() => _RenderState();
}

class _RenderState extends State<_Render> {
  final _open = OverlayPortalController(), _name = TextEditingController(), _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    wsAskRender.addListener(_ask);
  }

  @override
  void dispose() {
    wsAskRender.removeListener(_ask);
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Free space of the folder's disk, read when the dialog opens.
  String _free = '';

  /// Free space on the folder's disk, as the Mac's df reports it (the Available column, in 1024-byte blocks).
  static String _room(String? folder) {
    try {
      final cols = (Process.runSync('df', ['-k', folder ?? '.']).stdout as String).trim().split('\n').last.split(RegExp(r'\s+'));
      return '${(int.parse(cols[3]) / (1024 * 1024)).toStringAsFixed(1)} GB free';
    } catch (_) {
      return '';
    }
  }

  void _ask() {
    if (!mounted || _open.isShowing) return;
    final ws = WsScope.read(context), doc = ws.document ?? 'film.motolii';
    _free = _room(ws.documentFolder);
    _name.text = '${doc.replaceFirst(RegExp(r'\.motolii$'), '')}.mp4';
    _open.show();
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);
  }

  // The export formats the engine writes, chosen by file extension (see render_draw.h). Alight Motion offers the same four.
  static const _formats = [
    ('MP4', '.mp4', "H.264, with the films' sound"),
    ('HEVC', '.mov', "HEVC by the Mac's own encoder, with the films' sound"),
    ('GIF', '.gif', '15 frames a second, no sound'),
    ('PNG', '.png', 'a picture each, name_0001.png on'),
    ('JPEG', '.jpg', 'a JPEG each, name_0001.jpg on'),
  ];
  String get _ending => _formats.map((f) => f.$2).firstWhere((e) => _name.text.trim().toLowerCase().endsWith(e), orElse: () => '.mp4');
  void _as(String ending) =>
      setState(() => _name.text = '${_name.text.trim().replaceFirst(RegExp(r'\.(mp4|mov|gif|png|jpg)$', caseSensitive: false), '')}$ending');

  void _go(Ws ws) {
    var name = _name.text.trim();
    if (name.isEmpty) return;
    if (!_formats.any((f) => name.toLowerCase().endsWith(f.$2))) name = '$name.mp4';
    ws.renderTo = name.startsWith('/') ? name : '${ws.documentFolder ?? '.'}/$name';
    _open.hide();
    ws.onRender?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.document});
    return OverlayPortal(
      controller: _open,
      overlayChildBuilder: (_) {
        final (from, to) = ws.work;
        final frames = ((to - from) * Ws.fps).round();
        String t(double s) => '${s.toStringAsFixed(2)} s';
        Widget row(String k, Widget v) => Padding(
          padding: EdgeInsets.only(bottom: Shape.s(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: Shape.z(70),
                child: Text(k, style: T.label(Grey.g56)),
              ),
              Expanded(child: v),
            ],
          ),
        );
        Text fact(String v) => Text(v, style: T.value(Grey.g91));
        // Esc and Cmd+. cancel, as a Mac dialog's Cancel does. The keys arrive from the name field, which holds focus.
        return CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): _open.hide, const SingleActivator(LogicalKeyboardKey.period, meta: true): _open.hide},
          child: Stack(
            children: [
              Positioned.fill(
                child: Hov(
                  cursor: MouseCursor.defer,
                  onTap: _open.hide,
                  builder: (_, _) => const ColoredBox(color: Color(0x88000000)),
                ),
              ),
              Center(
                child: Container(
                  width: Shape.z(380),
                  padding: EdgeInsets.all(Shape.s(16)),
                  decoration: BoxDecoration(
                    color: WsT.card,
                    borderRadius: BorderRadius.all(Shape.r(8)),
                    border: Border.all(color: WsT.line),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: Shape.s(12)),
                        child: Text('Render', style: T.title(Grey.g95).copyWith(fontWeight: FontWeight.w700)),
                      ),
                      row(
                        'File',
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: Shape.s(8), vertical: Shape.s(5)),
                          decoration: BoxDecoration(color: WsT.well, borderRadius: BorderRadius.all(Shape.r(4))),
                          child: TextGestures(
                            field: (k) => EditableText(
                              key: k,
                              rendererIgnoresPointer: true,
                              controller: _name,
                              focusNode: _focus,
                              style: T.value(Grey.g95),
                              cursorColor: WsT.accent,
                              backgroundCursorColor: Grey.g38,
                              maxLines: 1,
                              onSubmitted: (_) => _go(ws),
                            ),
                          ),
                        ),
                      ),
                      row(
                        'Folder',
                        Text(
                          '${ws.documentFolder ?? ''}${_free.isEmpty ? '' : '  ·  $_free'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.label(Grey.g76),
                        ),
                      ),
                      row('Range', fact('Work area  ${t(from)} – ${t(to)}  ·  $frames frames')),
                      row('Size', fact('${WsArt.comp.width.round()} × ${WsArt.comp.height.round()}')),
                      // Export settings, stored in the project as in Alight Motion. A value of 0 matches the preview.
                      for (final (label, name, choices) in [
                        (
                          'Resolution',
                          'render_height',
                          [
                            (0, 'Full'),
                            for (final p in sizeResolutions)
                              if (p < math.min(WsArt.comp.width, WsArt.comp.height)) (p, '${p}p'),
                          ],
                        ),
                        (
                          'Rate',
                          'render_rate',
                          [
                            (0, '${Ws.fps}'),
                            for (final r in const [30, 24, 15])
                              if (r < Ws.fps) (r, '$r'),
                          ],
                        ),
                        (
                          'Quality',
                          'render_mbps',
                          [
                            (0, 'Auto'),
                            for (final b in const [4, 8, 16, 32]) (b, '$b Mbps'),
                          ],
                        ),
                        ('Motion blur', 'render_blur', const [(0, 'Off'), (8, 'On')]), // Eight samples per frame, like After Effects' 180° shutter.
                        // Clear leaves empty areas transparent. PNG, GIF and HEVC in .mov keep it (see render_draw.h).
                        ('Background', 'render_alpha', const [(0, 'Solid'), (1, 'Clear')]),
                      ])
                        row(
                          label,
                          StatefulBuilder(
                            builder: (context, again) {
                              final m = ws.inside, now = (m?.value(0, name, 0) ?? 0).round();
                              return Wrap(
                                spacing: Shape.s(6),
                                runSpacing: Shape.s(4),
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  for (final (v, said) in choices)
                                    Chip(
                                      key: ValueKey('render-$name-$v'),
                                      label: said,
                                      on: now == v,
                                      onTap: m == null
                                          ? null
                                          : () => ws.after(m.later('set', layer: 0, name: name, number: v.toDouble()), (_, _) => mounted ? again(() {}) : null),
                                    ),
                                  if (name == 'render_mbps' && now > 0)
                                    Text(
                                      'about ${(now * (to - from) / 8).toStringAsFixed(1)} MB',
                                      key: const ValueKey('render-estimate'),
                                      style: T.label(Grey.g76),
                                    ), // Megabits per second times the duration, as Alight Motion estimates it.
                                ],
                              );
                            },
                          ),
                        ),
                      row(
                        'Format',
                        StatefulBuilder(
                          builder: (context, again) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: Shape.s(6),
                                runSpacing: Shape.s(4),
                                children: [
                                  for (final (label, ending, _) in _formats)
                                    Chip(key: ValueKey('render-$label'), label: label, on: _ending == ending, onTap: () => again(() => _as(ending))),
                                ],
                              ),
                              SizedBox(height: Shape.s(4)),
                              Text(
                                _formats.firstWhere((f) => f.$2 == _ending).$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: T.label(Grey.g76),
                              ), // On its own line under the chips, because five chips leave no room beside it.
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: Shape.s(4)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Hov(
                            cursor: MouseCursor.defer,
                            onTap: _open.hide,
                            builder: (_, _) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: Shape.s(12), vertical: Shape.s(6)),
                              child: Text('Cancel', style: T.name(Grey.g76)),
                            ),
                          ),
                          SizedBox(width: Shape.s(6)),
                          Forms.worn.action(context, ActionSpec('Render', () => _go(ws))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Forms.worn.action(context, ActionSpec('Render', _ask)), // Drawn by the skin's forms.
    );
  }
}
