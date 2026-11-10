// The top bar's Render button and the dialog it opens: the name, the ending, the room and the length of the film.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, Pressable;
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/state/art_scene.dart' show ArtGeometry;
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/top_bar/size_chip.dart';

/// The one loud action: a flat lime pill with dark ink.
class RenderButton extends StatefulWidget {
  const RenderButton({super.key});
  @override
  State<RenderButton> createState() => _RenderState();
}

class _RenderState extends State<RenderButton> {
  final _open = OverlayPortalController(),
      _name = TextEditingController(),
      _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    renderRequested.addListener(_ask);
  }

  @override
  void dispose() {
    renderRequested.removeListener(_ask);
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Free space of the folder's disk, read when the dialog opens.
  String _free = '';

  /// Free space on the folder's disk, as the Mac's df reports it (the Available column, in 1024-byte blocks).
  static String _room(String? folder) {
    try {
      final cols =
          (Process.runSync('df', ['-k', folder ?? '.']).stdout as String)
              .trim()
              .split('\n')
              .last
              .split(RegExp(r'\s+'));
      return '${(int.parse(cols[3]) / (1024 * 1024)).toStringAsFixed(1)} GB free';
    } catch (_) {
      return '';
    }
  }

  void _ask() {
    if (!mounted || _open.isShowing) return;
    final ws = WorkspaceScope.read(context),
        doc = ws.document ?? 'film.motolii';
    _free = _room(ws.documentFolder);
    _name.text = '${doc.replaceFirst(RegExp(r'\.motolii$'), '')}.mp4';
    _open.show();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => mounted ? _focus.requestFocus() : null,
    );
  }

  // The export formats the engine writes, chosen by file extension (see render_draw.h). Alight Motion offers the same four.
  static const _formats = [
    ('MP4', '.mp4', "H.264, with the films' sound"),
    ('HEVC', '.mov', "HEVC by the Mac's own encoder, with the films' sound"),
    ('GIF', '.gif', '15 frames a second, no sound'),
    ('PNG', '.png', 'a picture each, name_0001.png on'),
    ('JPEG', '.jpg', 'a JPEG each, name_0001.jpg on'),
  ];
  String get _ending => _formats
      .map((f) => f.$2)
      .firstWhere(
        (e) => _name.text.trim().toLowerCase().endsWith(e),
        orElse: () => '.mp4',
      );
  void _as(String ending) => setState(
    () => _name.text =
        '${_name.text.trim().replaceFirst(RegExp(r'\.(mp4|mov|gif|png|jpg)$', caseSensitive: false), '')}$ending',
  );

  void _go(WorkspaceController ws) {
    var name = _name.text.trim();
    if (name.isEmpty) return;
    if (!_formats.any((f) => name.toLowerCase().endsWith(f.$2))) {
      name = '$name.mp4';
    }
    ws.renderTo = name.startsWith('/')
        ? name
        : '${ws.documentFolder ?? '.'}/$name';
    _open.hide();
    ws.onRender?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.document});
    return OverlayPortal(
      controller: _open,
      overlayChildBuilder: (_) {
        final (from, to) = ws.work;
        final frames = ((to - from) * WorkspaceController.fps).round();
        String t(double s) => '${s.toStringAsFixed(2)} s';
        Widget row(String k, Widget v) => Padding(
          padding: EdgeInsets.only(bottom: Shape.s(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: Shape.z(70),
                child: Text(k, style: TextStyles.label(Grey.g56)),
              ),
              Expanded(child: v),
            ],
          ),
        );
        Text fact(String v) => Text(v, style: TextStyles.value(Grey.g91));
        // Esc and Cmd+. cancel, as a Mac dialog's Cancel does. The keys arrive from the name field, which holds focus.
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _open.hide,
            const SingleActivator(LogicalKeyboardKey.period, meta: true):
                _open.hide,
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Pressable(
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
                    color: WindowTokens.card,
                    borderRadius: BorderRadius.all(Shape.r(8)),
                    border: Border.all(color: WindowTokens.line),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: Shape.s(12)),
                        child: Text(
                          'Render',
                          style: TextStyles.title(Grey.g95)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      row(
                        'File',
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Shape.s(8),
                            vertical: Shape.s(5),
                          ),
                          decoration: BoxDecoration(
                            color: WindowTokens.well,
                            borderRadius: BorderRadius.all(Shape.r(4)),
                          ),
                          child: TextGestures(
                            field: (k) => EditableText(
                              key: k,
                              rendererIgnoresPointer: true,
                              controller: _name,
                              focusNode: _focus,
                              style: TextStyles.value(Grey.g95),
                              cursorColor: WindowTokens.accent,
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
                          style: TextStyles.label(Grey.g76),
                        ),
                      ),
                      row(
                        'Range',
                        fact(
                          'Work area  ${t(from)} – ${t(to)}  ·  $frames frames',
                        ),
                      ),
                      row(
                        'Size',
                        fact(
                          '${ArtGeometry.comp.width.round()} × ${ArtGeometry.comp.height.round()}',
                        ),
                      ),
                      // Export settings, stored in the project as in Alight Motion. A value of 0 matches the preview.
                      for (final (label, name, choices) in [
                        (
                          'Resolution',
                          'render_height',
                          [
                            (0, 'Full'),
                            for (final p in sizeResolutions)
                              if (p <
                                  math.min(
                                    ArtGeometry.comp.width,
                                    ArtGeometry.comp.height,
                                  ))
                                (p, '${p}p'),
                          ],
                        ),
                        (
                          'Rate',
                          'render_rate',
                          [
                            (0, '${WorkspaceController.fps}'),
                            for (final r in const [30, 24, 15])
                              if (r < WorkspaceController.fps) (r, '$r'),
                          ],
                        ),
                        (
                          'Quality',
                          'render_mbps',
                          [
                            (0, 'Auto'),
                            for (final b in const [4, 8, 16, 32])
                              (b, '$b Mbps'),
                          ],
                        ),
                        (
                          'Motion blur',
                          'render_blur',
                          const [(0, 'Off'), (8, 'On')],
                        ), // Eight samples per frame, like After Effects' 180° shutter.
                        // Clear leaves empty areas transparent. PNG, GIF and HEVC in .mov keep it (see render_draw.h).
                        (
                          'Background',
                          'render_alpha',
                          const [(0, 'Solid'), (1, 'Clear')],
                        ),
                      ])
                        row(
                          label,
                          StatefulBuilder(
                            builder: (context, again) {
                              final m = ws.inside,
                                  now = (m?.value(0, name, 0) ?? 0).round();
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
                                          : () => ws.after(
                                              m.later(
                                                'set',
                                                layer: 0,
                                                name: name,
                                                number: v.toDouble(),
                                              ),
                                              (_, _) =>
                                                  mounted ? again(() {}) : null,
                                            ),
                                    ),
                                  if (name == 'render_mbps' && now > 0)
                                    Text(
                                      'about ${(now * (to - from) / 8).toStringAsFixed(1)} MB',
                                      key: const ValueKey('render-estimate'),
                                      style: TextStyles.label(Grey.g76),
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
                                    Chip(
                                      key: ValueKey('render-$label'),
                                      label: label,
                                      on: _ending == ending,
                                      onTap: () => again(() => _as(ending)),
                                    ),
                                ],
                              ),
                              SizedBox(height: Shape.s(4)),
                              Text(
                                _formats.firstWhere((f) => f.$2 == _ending).$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.label(Grey.g76),
                              ), // On its own line under the chips, because five chips leave no room beside it.
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: Shape.s(4)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Pressable(
                            cursor: MouseCursor.defer,
                            onTap: _open.hide,
                            builder: (_, _) => Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: Shape.s(12),
                                vertical: Shape.s(6),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyles.name(Grey.g76),
                              ),
                            ),
                          ),
                          SizedBox(width: Shape.s(6)),
                          Forms.worn.action(
                            context,
                            ActionSpec('Render', () => _go(ws)),
                          ),
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
      child: Forms.worn.action(
        context,
        ActionSpec('Render', _ask),
      ), // Drawn by the skin's forms.
    );
  }
}
