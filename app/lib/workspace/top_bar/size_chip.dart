// The top bar's size chip: shows the project size, lets the user scrub or type it, and offers common shapes and resolutions.
import 'package:motolii/widgets/modal_card.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/state/art_scene.dart' show ArtGeometry;
import 'package:motolii/workspace/state/document/document_reads.dart';
import 'package:motolii/workspace/state/document/document_writes.dart';
import 'package:motolii/workspace/state/layers/layer_reads.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Shows the project size.
///
/// A click opens the project box. A double-click turns the chip into a text field: a width alone keeps the aspect
/// ratio, and "1080x1920" sets both. Dragging sideways changes the width by 1% per 3 px with the aspect ratio kept,
/// and the project is reopened at the new size when the drag ends.
class SizeChip extends StatefulWidget {
  const SizeChip({super.key});
  @override
  State<SizeChip> createState() => _SizeChipState();
}

/// The shapes and resolutions of Alight Motion's new-project box.
///
/// A resolution is the length of the shorter side, as in its 2160p to 270p. Choosing a shape and a resolution sets
/// the project size and reopens the project at it.
const sizeShapes = [
  ('16:9', 16, 9),
  ('9:16', 9, 16),
  ('4:5', 4, 5),
  ('1:1', 1, 1),
  ('4:3', 4, 3),
];

const sizeResolutions = [2160, 1440, 1080, 720, 540, 360, 270];

(int, int) sizeOf((String, int, int) shape, int p) {
  final (_, a, b) = shape;
  // H.264 needs an even number of pixels.
  int even(double v) => (v / 2).round() * 2;
  return a >= b ? (even(p * a / b), p) : (p, even(p * b / a));
}

class _SizeChipState extends State<SizeChip> {
  final _box = OverlayPortalController();
  bool _editing = false;
  // The width the user is dragging to, or null when not dragging.
  double? _scrub;
  double _dx = 0;

  @override
  void initState() {
    super.initState();
    sizeBoxRequested.addListener(_asked);
    // The request may have been made while the window was still opening the new project.
    WidgetsBinding.instance.addPostFrameCallback((_) => _asked());
  }

  void _asked() {
    if (!mounted ||
        !sizeBoxRequested.value ||
        WorkspaceScope.read(context).onSize == null) {
      return;
    }
    sizeBoxRequested.value = false;
    _box.show();
  }

  @override
  void dispose() {
    sizeBoxRequested.removeListener(_asked);
    super.dispose();
  }

  void _commit(WorkspaceController ws, String? said) {
    final nums = RegExp(r'\d+')
        .allMatches(said ?? '')
        .map((m) => int.parse(m.group(0)!))
        .toList();
    setState(() => _editing = false);
    if (nums.isEmpty || ws.onSize == null) return;
    final w0 = ArtGeometry.comp.width, h0 = ArtGeometry.comp.height;
    // engine/document/marks.cpp の doc_size_words が 16〜8192、偶数のみを受け付ける。
    // H.264 も偶数を要る。上限を合わせないと打った値が黙って捨てられる。
    int even(int v) => (v ~/ 2) * 2;
    int fit(int v) => even(v.clamp(16, 8192));
    final w = fit(nums[0]),
        h = fit(nums.length > 1 ? nums[1] : (nums[0] * h0 / w0).round());
    if (w != w0.round() || h != h0.round()) ws.onSize!(w, h);
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.structure}),
        w0 = ArtGeometry.comp.width,
        h0 = ArtGeometry.comp.height;
    final shownW = (_scrub ?? w0).round(), shownH = (shownW * h0 / w0).round();
    if (_editing) {
      return Container(
        height: Shape.z(20),
        width: Shape.z(92),
        padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: WindowTokens.well,
          borderRadius: Shape.round(WindowTokens.chipRadius),
          border: WindowTokens.chosen,
        ),
        child: TypedField(
          text: '${w0.round()}x${h0.round()}',
          take: true,
          style: TextStyles.value(Grey.g95)
              .copyWith(fontSize: TextStyles.px(10)),
          cursor: WindowTokens.accent,
          onDone: (said) => _commit(ws, said),
        ),
      );
    }
    // The box offers shapes and resolutions. The current one is highlighted, or a chip of its own if the size matches no shape.
    final short = math.min(w0, h0).round(),
        now = sizeShapes
            .where((s) => sizeOf(s, short) == (w0.round(), h0.round()))
            .firstOrNull;
    Widget box(BuildContext _) {
      return ModalCard(
        title: 'Document',
        onClose: _box.hide,
        cardKey: const ValueKey('ws-size-box'),
        children: [
          ChipGroup('Shape', [
            for (final s in sizeShapes)
              Chip(
                key: ValueKey('size-${s.$1}'),
                label: s.$1,
                on: s == now,
                onTap: () => _to(ws, sizeOf(s, short)),
              ),
            if (now == null)
              Chip(
                label: '$shownW:$shownH',
                on: true,
                onTap: () {},
              ), // A size the user typed.
          ]),
          SizedBox(height: Shape.s(12)),
          ChipGroup('Resolution', [
            for (final p in sizeResolutions)
              Chip(
                key: ValueKey('size-${p}p'),
                label: '${p}p',
                on: p == short,
                onTap: () => _to(
                  ws,
                  now == null
                      ? ((p * w0 / short).round(), (p * h0 / short).round())
                      : sizeOf(now, p),
                ),
              ),
          ]),
          SizedBox(height: Shape.s(12)),
          // The frame rates of Alight Motion's new-project sheet, as a dropdown since the list is long.
          MenuRow<int>(
            menuKey: const ValueKey('size-fps'),
            label: 'Frame rate',
            value: WorkspaceController.fps,
            options: [
              for (final r in const [12, 15, 18, 20, 24, 25, 30, 48, 50, 60])
                (r, '$r fps'),
            ],
            onChanged: !isConnected(ws)
                ? null
                : (r) => setDocumentNumber(
                    ws,
                    'frame_rate',
                    r == documentRate(ws) ? 0 : r.toDouble(),
                    (_, _) => ws.reread(),
                  ),
          ),
          SizedBox(height: Shape.s(12)),
          // The six backgrounds of Alight Motion's new-project sheet. Transparent has no colour and is exported clear.
          ChipGroup('Background', [
            for (final (label, hex) in const [
              ('Black', '000000'),
              ('White', 'ffffff'),
              ('Light Gray', 'd8d8d8'),
              ('Green', '00b140'),
              ('Blue', '0047bb'),
              ('Transparent', ''),
            ])
              Chip(
                key: ValueKey('size-bg-$label'),
                label: label,
                on: layerWord(ws, 0, 'background') == hex,
                onTap: !isConnected(ws) ? null : () => setBackground(ws, hex),
              ),
          ]),
          SizedBox(height: Shape.s(12)),
          // How long a new layer lasts (Alight Motion's New Layer Length). End runs to the end of the project.
          MenuRow<int>(
            menuKey: const ValueKey('size-len'),
            label: 'New layer length',
            value: (layerValue(ws, 0, 'layer_length', 0) ?? 0).round(),
            options: [
              (0, 'End'),
              for (final n in const [
                1,
                2,
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                15,
                20,
                25,
                30,
                45,
                60,
              ])
                (n, '${n}s'),
            ],
            onChanged: !isConnected(ws)
                ? null
                : (n) => setDocumentNumber(
                    ws,
                    'layer_length',
                    n.toDouble(),
                    (_, _) => ws.reread(),
                  ),
          ),
          SizedBox(height: Shape.s(12)),
          Text(
            '$shownW × $shownH  ·  ${WorkspaceController.fps} frames a second',
            style: TextStyles.value(Grey.g76),
          ),
          if (documentEdited(ws) case final edited?) ...[
            // Alight Motion's Total Edit Time: how long the project has been worked on.
            SizedBox(height: Shape.s(6)),
            Text(
              'Total Edit Time  ${edited ~/ 3600}h ${(edited % 3600) ~/ 60}m',
              key: const ValueKey('size-edited'),
              style: TextStyles.value(Grey.g63),
            ),
          ],
        ],
      );
    }

    return OverlayPortal(
      controller: _box,
      overlayChildBuilder: box,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          supportedDevices: pressingDevices,
          key: const ValueKey('ws-top-size'),
          behavior: HitTestBehavior.opaque,
          onTap: ws.onSize == null ? null : _box.show,
          onDoubleTap: ws.onSize == null
              ? null
              : () => setState(() => _editing = true),
          onHorizontalDragStart: (_) => _dx = 0,
          onHorizontalDragUpdate: (e) => setState(
            () => _scrub = math.max(
              16,
              w0 + w0 * ((_dx += e.delta.dx) / 3).round() / 100,
            ),
          ),
          onHorizontalDragEnd: (_) {
            final w = _scrub?.round();
            setState(() => _scrub = null);
            if (w != null && w != w0.round() && ws.onSize != null) {
              ws.onSize!(w, (w * h0 / w0).round());
            }
          },
          child: Chip(
            label: '$shownW × $shownH',
            look: ChipLook.readout(ink: Grey.g76),
          ),
        ),
      ),
    );
  }

  void _to(WorkspaceController ws, (int, int) size) {
    _box.hide();
    if (size !=
        (ArtGeometry.comp.width.round(), ArtGeometry.comp.height.round())) {
      ws.onSize?.call(size.$1, size.$2);
    }
  }
}
