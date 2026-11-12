// The app's top bar: wordmark, project name, selected layer, size, light or dark mode, and the Render button.
import 'package:motolii/workspace/top_bar/render_button.dart';

import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/skin_parts.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart'
    show Badge, Chip, ChipLook, Pressable, IconPress;
import 'package:motolii/widgets/media.dart' show Draw, glyph;
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/top_bar/size_chip.dart';
import 'package:motolii/workspace/top_bar/timings.dart';
import 'package:motolii/workspace/top_bar/workspace_switch.dart';
import 'package:motolii/workspace/top_bar/zoom_readout.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {
      WorkspaceAspect.animating,
      WorkspaceAspect.document,
      WorkspaceAspect.picked,
    });
    return Container(
      color: WindowTokens.body,
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
              style: TextStyles.name(Grey.g95)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ), // A long name is cut off with an ellipsis so the bar keeps its layout.
          SizedBox(width: Shape.s(6)),
          Text('/', style: TextStyles.name(Grey.g44)),
          SizedBox(width: Shape.s(6)),
          Text(ws.layer?.name ?? 'Stage', style: TextStyles.name(Grey.g76)),
          SizedBox(width: Shape.s(10)),
          const SizeChip(),
          SizedBox(width: Shape.s(4)),
          Chip(
            label: '${WorkspaceController.fps} fps',
            look: ChipLook.readout(ink: Grey.g76),
          ),
          SizedBox(width: Shape.s(4)),
          Chip(
            label: ws.timecode(WorkspaceController.duration),
            look: ChipLook.readout(ink: Grey.g76),
          ),
          const Spacer(),
          const WorkspaceSwitch(),
          SizedBox(width: Shape.s(10)),
          const ZoomReadout(),
          const _ShadeSwitch(),
          SizedBox(width: Shape.s(10)),
          const Waited(),
          const _Saved(),
          SizedBox(width: Shape.s(12)),
          const RenderButton(),
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
        WindowTokens.accent,
        size: Shape.z(22),
        radius: Radius.zero,
        child: Text(
          'M',
          style: TextStyles.title(WindowTokens.onAccent).copyWith(
            fontSize: TextStyles.px(14),
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
      SizedBox(width: Shape.s(8)),
      Text(
        'Motolii',
        style: TextStyles.title(Grey.g95).copyWith(
          fontSize: TextStyles.px(14),
          fontWeight: FontWeight.w800,
          letterSpacing: -.2,
        ),
      ),
    ],
  );
}

/// Describes in plain words what an undo or redo changed, as the Edit menu of After Effects and Premiere Pro names
/// the step, for example "Undo Change Warmth".
///
/// It reads the layers and values that the reloaded project reports as changed.
String undoStepName(WorkspaceController ws, String done) {
  final c = ws.lastChange, m = ws.inside;
  if (c == null || m == null) return done;
  if (c.layers) return '$done: things added or taken away';
  final byThing = <int, Set<String>>{};
  for (final (t, n) in c.values) {
    (byThing[t] ??= {}).add(m.shown(n)?.label ?? n);
  }
  String nameOf(int t) => t == 0
      ? 'Stage'
      : ws.layers.where((l) => l.id == '$t').firstOrNull?.name ?? 'a thing';
  final said = [
    for (final e in byThing.entries.take(3))
      '${nameOf(e.key)} ${e.value.take(3).join(', ')}${e.value.length > 3 ? '…' : ''}',
  ];
  return said.isEmpty
      ? done
      : '$done: ${said.join(' · ')}${byThing.length > 3 ? ' …' : ''}';
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
            child: CustomPaint(
              size: const Size(12, 10),
              painter: Draw((cv, s) => _drawUndo(cv, s, c), c),
            ),
          ),
          key: ValueKey(flip ? 'ws-redo' : 'ws-undo'),
          size: Shape.z(24),
          rest: const Color(0x00000000),
          ink: Grey.g63,
          onTap: () {
            final ws = WorkspaceScope.read(context), m = ws.inside;
            if (m == null) return;
            ws.after(
              m.later(flip ? 'redo' : 'undo'),
              (done, why) => ws.notice = done
                  ? undoStepName(ws, flip ? 'Redone' : 'Undone')
                  : why,
            ); // The app does not wait for the step to finish.
          },
        ),
    ],
  );
}

void _drawUndo(Canvas canvas, Size s, Color c) {
  if (SkinParts.draw(canvas, s, 'undo', c)) {
    return; // The skin's own icon, if any.
  }
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
  if (SkinParts.draw(canvas, s, 'shade', c)) {
    return; // The skin's own icon, if any.
  }
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
String _savedAt(WorkspaceController ws) {
  final f = File('${ws.documentFolder}/${ws.document}');
  if (ws.document == null || !f.existsSync()) return 'Saved';
  final t = f.lastModifiedSync();
  return 'Saved ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _Saved extends StatelessWidget {
  const _Saved();
  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {
          WorkspaceAspect.document,
          WorkspaceAspect.notice,
        }),
        go = ws.noticeGo;
    final said = Text(
      ws.notice ?? _savedAt(ws),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: go == null
          ? TextStyles.label(Grey.g63)
          : TextStyles.label(Grey.g63)
                .copyWith(decoration: TextDecoration.underline),
    ); // The underline marks the notice as a link when it has a target.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Badge(
          WindowTokens.accent,
          size: Shape.z(6),
          radius: Radius.circular(Shape.z(3)),
        ),
        SizedBox(width: Shape.s(6)),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Shape.z(260)),
          child: go == null
              ? said
              : Pressable(onTap: go, builder: (_, _) => said),
        ),
      ],
    );
  }
}
