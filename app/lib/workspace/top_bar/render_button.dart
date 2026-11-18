// The top bar's Render button and the dialog it opens: file, folder, format, size, resolution, rate, quality, options.
// The dialog is read top to bottom: a thin outline shows the composition's own shape and size (the only visual anchor,
// so a glance says what is being rendered); under it the file name, chosen format tabs and the destination folder;
// then two ChipGroups for the picture (resolution, rate, quality) and options (motion blur, background); a summary
// line (work area, frame count, rough size) and the Cancel / Render buttons. See [RenderButton] class comment.
import 'package:motolii/widgets/modal_card.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/free_space.dart';
import 'package:motolii/widgets/controls.dart' show Chip, Pressable;
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/state/art_scene.dart' show ArtGeometry;
import 'package:motolii/workspace/state/document/document_reads.dart';
import 'package:motolii/workspace/state/document/document_writes.dart';
import 'package:motolii/workspace/state/layers/layer_reads.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/top_bar/size_chip.dart';

/// The one loud action: a flat lime pill with dark ink.
/// Pressing it opens the render dialog. The dialog follows the Mac export panel pattern used by Final Cut Pro and iMovie:
/// an outline of what will be rendered on top, the file name and destination grouped together, then the picture settings
/// and options. The whole dialog is about 430 px wide, so the labels do not need their own column.
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
      final kb = freeKilobytesOn(folder ?? '.');
      return '${(kb / (1024 * 1024)).toStringAsFixed(1)} GB free';
    } catch (_) {
      return '';
    }
  }

  void _ask() {
    if (!mounted || _open.isShowing) return;
    final ws = WorkspaceScope.read(context),
        doc = ws.document ?? 'film.motolii';
    _free = _room(ws.documentFolder);
    final ext = ws.viewOf<String>('render.ext', '.mp4');
    _name.text = '${doc.replaceFirst(RegExp(r'\.motolii$'), '')}$ext';
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
    ws.view['render.ext'] = _ending;
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
      overlayChildBuilder: (_) => _dialog(ws),
      child: Forms.worn.action(context, ActionSpec('Render', _ask)),
    );
  }

  Widget _dialog(WorkspaceController ws) {
    final (from, to) = ws.work;
    final frames = ((to - from) * WorkspaceController.fps).round();
    final w = ArtGeometry.comp.width, h = ArtGeometry.comp.height;
    return ModalCard(
      title: 'Render',
      onClose: _open.hide,
      across: CrossAxisAlignment.stretch,
      children: [
        _header(w, h, from, to, frames),
        SizedBox(height: Shape.s(14)),
        _formatTabs(),
        SizedBox(height: Shape.s(14)),
        _fileBlock(),
        SizedBox(height: Shape.s(14)),
        _imageGroup(ws, w, h, from, to),
        SizedBox(height: Shape.s(10)),
        _optionsGroup(ws),
        SizedBox(height: Shape.s(16)),
        _actions(ws),
      ],
    );
  }

  /// A thin outline at the composition's own aspect ratio, labelled with its size and the chosen range. The user sees
  /// at a glance what shape and length they are about to render. The outline is bounded so a very wide or very tall
  /// composition still fits in the header's 56 px band.
  Widget _header(double w, double h, double from, double to, int frames) =>
      RenderHeader(w: w, h: h, from: from, to: to, frames: frames);

  /// Format tabs: the chosen format (which is what the file name ends with) is highlighted. Clicking a tab rewrites the
  /// extension of the file name, and the description line under the tabs updates. Tabs rather than chips because a
  /// format is a bigger choice than a resolution or a quality setting.
  Widget _formatTabs() {
    return StatefulBuilder(
      builder: (context, again) {
        final chosen = _formats.firstWhere((f) => f.$2 == _ending);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final (i, (label, ending, _)) in _formats.indexed) ...[
                  if (i > 0) SizedBox(width: Shape.s(4)),
                  _FormatTab(
                    label: label,
                    on: _ending == ending,
                    onTap: () => again(() => _as(ending)),
                  ),
                ],
              ],
            ),
            SizedBox(height: Shape.s(6)),
            Text(
              chosen.$3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.label(Grey.g76),
            ),
          ],
        );
      },
    );
  }

  /// The file name input is the big input on the dialog (it is what the user changes most often). The destination
  /// folder, and how much room is on its disk, sit under it as a muted subtitle.
  Widget _fileBlock() {
    final ws = WorkspaceScope.read(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: Shape.s(10),
            vertical: Shape.s(8),
          ),
          decoration: BoxDecoration(
            color: WindowTokens.well,
            borderRadius: Shape.round(5),
            border: Border.all(color: WindowTokens.line),
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
        SizedBox(height: Shape.s(4)),
        Padding(
          padding: EdgeInsets.only(left: Shape.s(2)),
          child: Text(
            '${ws.documentFolder ?? ''}${_free.isEmpty ? '' : '  ·  $_free'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.label(Grey.g56),
          ),
        ),
      ],
    );
  }

  /// Resolution, Rate and Quality: the three picture knobs. One ChipGroup each. For Quality the estimated file size is
  /// added as a trailing label when the bitrate is set.
  Widget _imageGroup(
    WorkspaceController ws,
    double w,
    double h,
    double from,
    double to,
  ) {
    final resolutions = [
      (0, 'Full'),
      for (final p in sizeResolutions)
        if (p < math.min(w, h)) (p, '${p}p'),
    ];
    final rates = [
      (0, '${WorkspaceController.fps}'),
      for (final r in const [30, 24, 15])
        if (r < WorkspaceController.fps) (r, '$r'),
    ];
    final qualities = [
      (0, 'Auto'),
      for (final b in const [4, 8, 16, 32]) (b, '$b Mbps'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chipRow(ws, 'Resolution', 'render_height', resolutions),
        SizedBox(height: Shape.s(10)),
        _chipRow(ws, 'Rate', 'render_rate', rates),
        SizedBox(height: Shape.s(10)),
        _chipRow(
          ws,
          'Quality',
          'render_mbps',
          qualities,
          trailing: (now) => now > 0
              ? 'about ${(now * (to - from) / 8).toStringAsFixed(1)} MB'
              : null,
        ),
      ],
    );
  }

  /// Motion blur and background: the two on/off options.
  Widget _optionsGroup(WorkspaceController ws) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chipRow(ws, 'Motion blur', 'render_blur', const [
          (0, 'Off'),
          (8, 'On'),
        ]), // Eight samples per frame, like After Effects' 180° shutter.
        SizedBox(height: Shape.s(10)),
        // Clear leaves empty areas transparent. PNG, GIF and HEVC in .mov keep it (see render_draw.h).
        _chipRow(ws, 'Background', 'render_alpha', const [
          (0, 'Solid'),
          (1, 'Clear'),
        ]),
      ],
    );
  }

  /// One label with a wrap of chips to its right. The chips are kept in the engine's project store under [name].
  Widget _chipRow(
    WorkspaceController ws,
    String label,
    String name,
    List<(int, String)> choices, {
    String? Function(int now)? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: Shape.z(76),
          child: Padding(
            padding: EdgeInsets.only(top: Shape.s(4)),
            child: Text(label, style: TextStyles.label(Grey.g56)),
          ),
        ),
        Expanded(
          child: StatefulBuilder(
            builder: (context, again) {
              final now = (layerValue(ws, 0, name, 0) ?? 0).round(),
                  tail = trailing?.call(now);
              return Wrap(
                spacing: Shape.s(6),
                runSpacing: Shape.s(6),
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final (v, said) in choices)
                    Chip(
                      key: ValueKey('render-$name-$v'),
                      label: said,
                      on: now == v,
                      onTap: !isConnected(ws)
                          ? null
                          : () => setDocumentNumber(
                              ws,
                              name,
                              v.toDouble(),
                              (_, _) => mounted ? again(() {}) : null,
                            ),
                    ),
                  if (tail != null)
                    Padding(
                      padding: EdgeInsets.only(left: Shape.s(4)),
                      child: Text(
                        tail,
                        key: const ValueKey('render-estimate'),
                        style: TextStyles.label(Grey.g76),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actions(WorkspaceController ws) => Row(
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
          child: Text('Cancel', style: TextStyles.name(Grey.g76)),
        ),
      ),
      SizedBox(width: Shape.s(6)),
      Forms.worn.action(context, ActionSpec('Render', () => _go(ws))),
    ],
  );
}

/// The outline thumbnail + size label at the top of the render dialog.
/// Extracted so the golden test can pump it without a WorkspaceController.
class RenderHeader extends StatelessWidget {
  const RenderHeader({
    super.key,
    required this.w,
    required this.h,
    required this.from,
    required this.to,
    required this.frames,
  });

  final double w, h, from, to;
  final int frames;

  @override
  Widget build(BuildContext context) {
    const bandHigh = 56.0, bandWide = 120.0;
    final box = w >= h
        ? (bandWide, bandWide * h / w).clamp(min: 12.0, max: bandHigh)
        : (bandHigh * w / h, bandHigh).clamp(min: 12.0, max: bandWide);
    final (boxW, boxH) = box;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: Shape.z(boxW),
          height: Shape.z(boxH),
          decoration: BoxDecoration(
            borderRadius: Shape.round(3),
            border: Border.all(color: WindowTokens.line),
            color: WindowTokens.well,
          ),
        ),
        SizedBox(width: Shape.s(14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${w.round()} × ${h.round()}',
                style: TextStyles.value(Grey.g95).bold,
              ),
              SizedBox(height: Shape.s(2)),
              Text(
                'Work area ${_fmtSeconds(from)} – ${_fmtSeconds(to)} · $frames frames',
                style: TextStyles.label(Grey.g76),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A format tab. On / Off are drawn flat; the on tab fills with the window's selected tint, the off tab is a plain
/// row. Tabs are wider than chips so the format reads as a top-level choice.
class _FormatTab extends StatelessWidget {
  const _FormatTab({
    required this.label,
    required this.on,
    required this.onTap,
  });
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    cursor: MouseCursor.defer,
    onTap: onTap,
    builder: (_, hover) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: Shape.s(14),
        vertical: Shape.s(7),
      ),
      decoration: BoxDecoration(
        color: on
            ? WindowTokens.accent
            : (hover ? WindowTokens.raised : WindowTokens.well),
        borderRadius: Shape.round(5),
        border: Border.all(color: on ? WindowTokens.accent : WindowTokens.line),
      ),
      child: Text(
        label,
        style: (on ? TextStyles.value(Accent.on) : TextStyles.value(Grey.g91))
            .bold,
      ),
    ),
  );
}

/// Formats [s] seconds as a short "0.00 s" label for the header.
String _fmtSeconds(double s) => '${s.toStringAsFixed(2)} s';

extension on (double, double) {
  /// Clamps each side of the tuple so neither is below [min] nor above [max]. Keeps the rendered thumbnail readable
  /// for extreme aspect ratios.
  (double, double) clamp({required double min, required double max}) =>
      ($1.clamp(min, max), $2.clamp(min, max));
}
