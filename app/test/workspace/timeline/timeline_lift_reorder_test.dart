// Tests for AbsentMotion-style depth-lift vertical layer reordering on the timeline.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/timeline/slip_edit.dart';
import 'package:motolii/workspace/timeline/timeline_labels.dart';
import 'package:motolii/workspace/timeline/timeline_media_cache.dart';
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';
import 'package:motolii/workspace/timeline/timeline_rows.dart';
import 'package:motolii/workspace/timeline/timeline_tracks_paint.dart';
import 'package:motolii/workspace/timeline/timeline_viewport.dart';
import 'package:motolii/workspace/timeline/track_drag.dart';

const _savePreview = bool.fromEnvironment('SAVE_PREVIEW');

List<double> _sampleWave(int frames, {int seed = 1}) {
  final rng = math.Random(seed);
  return [
    for (var i = 0; i < frames; i++)
      () {
        final beatPos = i % 15;
        final kick = beatPos == 0 ? 0.0 : -math.min(34.0, beatPos * 4.5);
        final snare = (i % 30) == 15 ? -2.0 : -46.0;
        final hat = (i % 4 == 0) ? -14.0 - rng.nextDouble() * 8.0 : -44.0;
        final bed = -26.0 + rng.nextDouble() * 11.0;
        return math
            .max(math.max(kick, snare), math.max(hat, bed))
            .clamp(-54.0, -1.0);
      }(),
  ];
}

void main() {
  test(
    'TimelineRows drives AbsentMotion lift, slide, and drop-settle motion',
    () {
      final ws = WorkspaceController();
      addTearDown(ws.dispose);
      ws.layers
        ..clear()
        ..addAll([
          Layer(1, 'Title', LayerKind.text, 0, 120, const []),
          Layer(2, 'BGM.wav', LayerKind.audio, 0, 180, const [], hidden: true),
          Layer(3, 'Clip.mp4', LayerKind.image, 15, 200, const []),
          Layer(4, 'Pad.mp3', LayerKind.audio, 0, 240, const [], hidden: true),
        ]);

      final viewport = TimelineViewport(() => 240)
        ..layout(trackWidth: 600, rowsHeight: 200, rows: 4);
      final media = TimelineMediaCache();
      final slip = SlipEdit(media: media);
      final rows = TimelineRows(
        workspaceOf: () => ws,
        viewport: viewport,
        media: media,
        slip: slip,
      );
      addTearDown(() {
        rows.dispose();
        slip.dispose();
        media.dispose();
        viewport.dispose();
      });

      final drawn = rows.layOut();
      expect(drawn[1].dim, isFalse);

      var lifted = 0;
      var shifted = 0;
      VoidCallback? pendingDrop;
      rows.onLiftStart = () => lifted++;
      rows.onShiftChanged = () => shifted++;
      rows.onDropSettle = (done) => pendingDrop = done;

      // Pick up row 2 (Clip.mp4): starts 100ms lift transition.
      rows.reorderStart(ws.layers[2], 2);
      expect(rows.isReordering, isTrue);
      expect(lifted, 1);
      expect(rows.liftAmount, 0);
      rows.setLiftProgress(1.0);
      expect(rows.liftAmount, 1.0);

      // Drag up past row 1: sibling slides smoothly over 120ms.
      rows.reorderBy(-TimelineMetrics.row * 0.8);
      expect(rows.dragDeltaLayers, -1);
      expect(shifted, 1);
      rows.setShiftProgress(0.5);
      expect(
        rows.animatedRowOffset(1),
        closeTo(TimelineMetrics.row * 0.5, 1e-6),
      );
      rows.setShiftProgress(1.0);
      expect(rows.animatedRowOffset(1), closeTo(TimelineMetrics.row, 1e-6));

      // Release: enters 150ms drop-settle easing into slot 1 while lowering lift back to 0.
      rows.reorderEnd(ws.layers[2]);
      expect(rows.isSettling, isTrue);
      expect(pendingDrop, isNotNull);
      rows.setDropProgress(0.5);
      expect(rows.liftAmount, closeTo(0.5, 1e-6));
      expect(rows.dragOffsetY, closeTo(-TimelineMetrics.row * 0.9, 1e-6));
      rows.setDropProgress(1.0);
      expect(rows.liftAmount, 0.0);
      expect(rows.dragOffsetY, closeTo(-TimelineMetrics.row, 1e-6));

      pendingDrop!();
      expect(rows.isReordering, isFalse);
      expect(rows.isSettling, isFalse);
    },
  );

  testWidgets(
    'Timeline renders clean rest state and AbsentMotion depth-lift state',
    (tester) async {
      tester.view.physicalSize = const Size(980, 340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final ws = WorkspaceController();
      addTearDown(ws.dispose);
      ws.layers
        ..clear()
        ..addAll([
          Layer(1, 'Title Card', LayerKind.text, 10, 140, const [10, 60, 120]),
          Layer(
            2,
            'Main Beat.wav',
            LayerKind.audio,
            0,
            220,
            const [],
            hidden: true,
          ),
          Layer(3, 'Camera Clip.mp4', LayerKind.image, 20, 200, const []),
          Layer(
            4,
            'Ambient Pad.mp3',
            LayerKind.audio,
            40,
            230,
            const [],
            hidden: true,
          ),
        ]);

      final viewport = TimelineViewport(() => 240)
        ..layout(trackWidth: 700, rowsHeight: 160, rows: 4);
      final media = TimelineMediaCache();
      final slip = SlipEdit(media: media);
      final restRows = TimelineRows(
        workspaceOf: () => ws,
        viewport: viewport,
        media: media,
        slip: slip,
      );
      final liftedRows = TimelineRows(
        workspaceOf: () => ws,
        viewport: viewport,
        media: media,
        slip: slip,
      );
      final drag = TrackDrag(
        workspaceOf: () => ws,
        viewport: viewport,
        rows: restRows,
        slip: slip,
        snapTo: (_) => null,
      );
      addTearDown(() {
        drag.dispose();
        liftedRows.dispose();
        restRows.dispose();
        slip.dispose();
        media.dispose();
        viewport.dispose();
      });

      restRows.layOut();
      liftedRows.layOut();
      liftedRows.reorderStart(ws.layers[2], 2);
      liftedRows.reorderBy(-TimelineMetrics.row * 0.85);

      final thumb = (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final tc = Canvas(recorder);
        tc.drawRect(
          const Rect.fromLTWH(0, 0, 32, 18),
          Paint()
            ..shader = ui.Gradient.linear(Offset.zero, const Offset(32, 18), [
              const Color(0xFF4E708A),
              const Color(0xFFC29064),
            ]),
        );
        return recorder.endRecording().toImage(32, 18);
      }))!;
      addTearDown(thumb.dispose);

      final drawn = <TimelineRow>[
        const TimelineRow(
          id: 1,
          name: 'Title Card',
          kind: LayerKind.text,
          inF: 10,
          outF: 140,
          keys: [10, 60, 120],
          picked: {60},
        ),
        TimelineRow(
          id: 2,
          name: 'Main Beat.wav',
          kind: LayerKind.audio,
          inF: 0,
          outF: 220,
          keys: const [],
          picked: const {},
          selected: true,
          hasAudio: true,
          fadeInF: 20,
          fadeOutF: 30,
          wave: _sampleWave(220, seed: 2),
        ),
        TimelineRow(
          id: 3,
          name: 'Camera Clip.mp4',
          kind: LayerKind.image,
          inF: 20,
          outF: 200,
          keys: const [],
          picked: const {},
          hasAudio: true,
          frames: [thumb, thumb, thumb, thumb, thumb, thumb],
          wave: _sampleWave(180, seed: 3),
        ),
        TimelineRow(
          id: 4,
          name: 'Ambient Pad.mp3',
          kind: LayerKind.audio,
          inF: 40,
          outF: 230,
          keys: const [],
          picked: const {},
          hasAudio: true,
          wave: _sampleWave(190, seed: 4),
        ),
      ];

      Widget panel(TimelineRows rs) {
        final dragRow = rs.draggingRowIndex;
        final lift = rs.liftAmount;
        Widget buildLabel(int i) {
          Widget child = TimelineLabelRow(
            index: i,
            depth: 0,
            row: drawn[i],
            hidden: false,
            solo: false,
            lanes: null,
            onLanes: () {},
            onSelect: () {},
            onEye: () {},
            onSolo: () {},
            onLock: () {},
            clip: false,
            onClip: () {},
          );
          if (i == dragRow && lift > 0) {
            child = Transform.scale(
              scale: 1.0 + 0.015 * lift,
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Grey.g00.withValues(alpha: 0.55 * lift),
                      blurRadius: 14 * lift,
                      offset: Offset(0, 5 * lift),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          }
          return Positioned(
            left: 0,
            right: 0,
            top: i * TimelineMetrics.row + rs.rowVisualOffset(i),
            height: TimelineMetrics.row,
            child: child,
          );
        }

        return ColoredBox(
          color: WindowTokens.body,
          child: Row(
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  children: [
                    const TimelineLabelHeader(count: 4, solo: false),
                    Expanded(
                      child: Stack(
                        children: [
                          for (var i = 0; i < drawn.length; i++)
                            if (i != dragRow) buildLabel(i),
                          if (rs.isReordering && lift > 0)
                            Positioned.fill(
                              child: ColoredBox(
                                color: WindowTokens.body.withValues(
                                  alpha: 0.42 * lift,
                                ),
                              ),
                            ),
                          if (dragRow != null) buildLabel(dragRow),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: TimelineMetrics.divider,
                child: ColoredBox(color: WindowTokens.ground),
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: TimelineMetrics.ruler,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _PreviewRulerPainter(viewport, 30),
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: TimelineTracksPainter(
                          rows: drawn,
                          viewport: viewport,
                          fps: 30,
                          drag: drag,
                          rowsState: rs,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: WindowTokens.ground,
              child: Column(
                children: [
                  Expanded(child: panel(restRows)),
                  SizedBox(
                    height: 6,
                    child: ColoredBox(color: WindowTokens.ground),
                  ),
                  Expanded(child: panel(liftedRows)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main Beat.wav'), findsNWidgets(2));

      if (_savePreview) {
        await tester.runAsync(() async {
          final ro =
              boundaryKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
          final image = await ro.toImage(pixelRatio: 2.0);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final out = File('build/timeline_absentmotion_lift_preview.png');
          out.parent.createSync(recursive: true);
          out.writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    },
  );
}

class _PreviewRulerPainter extends CustomPainter {
  const _PreviewRulerPainter(this.viewport, this.fps);
  final TimelineViewport viewport;
  final int fps;

  @override
  void paint(Canvas c, Size s) {
    final v = viewport.view;
    c.drawRect(Offset.zero & s, Paint()..color = Grey.g10);
    final tick = Paint()..color = Grey.g38;
    for (var f = 0; f <= 240; f += fps) {
      final x = v.x(f).roundToDouble();
      if (x < 0 || x > s.width) continue;
      c.drawRect(Rect.fromLTWH(x, s.height - 9, 1, 9), tick);
      final tp = lineText('${f ~/ fps}s', TextStyles.micro(Grey.g63));
      tp.paint(c, Offset(x + 4, s.height - 15));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_PreviewRulerPainter old) => false;
}
