// Verifies the improved Effects & Fonts 2D map: cluster island labels, zoom/fit bar,
// hover loupe preview, and optional golden visual capture (`MOTOLII_MAP_SHOWCASE_PNG`).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/dock/map/shelf_map.dart';
import 'package:motolii/workspace/dock/map/shelf_map_view.dart';

void main() {
  testWidgets(
    'ShelfMapView renders cluster island labels, zoom bar, and hover loupe',
    (tester) async {
      const w = 1120.0;
      const h = 640.0;
      tester.view.physicalSize = const Size(w * 2, h * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final fxMap = ShelfMap('effects_preview');
      final clusters = [
        ('Blur', const Offset(360, 290), const Color(0xFF38BDF8)),
        ('Glitch', const Offset(1360, 270), const Color(0xFFFF4DCA)),
        ('Stylize', const Offset(860, 520), const Color(0xFFA855F7)),
        ('Color', const Offset(420, 790), const Color(0xFFFFB547)),
        ('Distortion', const Offset(1320, 780), const Color(0xFF10B981)),
      ];
      final positions = <String, Offset>{};
      final names = <String, String>{};
      final groups = <String, String>{};
      final tiles = <(String, Widget)>[];
      final rng = math.Random(42);
      for (final (label, center, col) in clusters) {
        for (var i = 0; i < 24; i++) {
          final angle = i * 2.39996;
          final rad = 22 + math.sqrt(i) * 34;
          final id = '${label.toLowerCase()}_$i';
          positions[id] = Offset(
            center.dx + math.cos(angle) * rad + (rng.nextDouble() - 0.5) * 10,
            center.dy +
                math.sin(angle) * rad * 0.8 +
                (rng.nextDouble() - 0.5) * 10,
          );
          names[id] = '$label FX ${i + 1}';
          groups[id] = label;
          tiles.add((
            id,
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    col.withValues(alpha: 0.78),
                    Color.lerp(col, Grey.g10, 0.7)!,
                  ],
                ),
              ),
            ),
          ));
        }
      }
      fxMap.places.value = positions;

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        WidgetsApp(
          color: Grey.g07,
          debugShowCheckedModeBanner: false,
          pageRouteBuilder: <T>(settings, builder) =>
              PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
          home: RepaintBoundary(
            key: repaintKey,
            child: Container(
              color: WindowTokens.body,
              child: ShelfMapView(
                fxMap,
                tiles,
                picked: 'glitch_0',
                names: names,
                groups: groups,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cluster island labels and zoom controls must be visible.
      for (final label in const [
        'Blur',
        'Glitch',
        'Stylize',
        'Color',
        'Distortion',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('ws-map-effects_preview-zoom-in')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ws-map-effects_preview-zoom-fit')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ws-map-effects_preview-labels')),
        findsOneWidget,
      );

      // Zoom in updates the zoom indicator from Fit to a percentage, Fit resets it.
      await tester.tap(
        find.byKey(const ValueKey('ws-map-effects_preview-zoom-in')),
      );
      await tester.pumpAndSettle();
      expect(find.text('140%'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('ws-map-effects_preview-zoom-fit')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fit'), findsOneWidget);

      final outPath = Platform.environment['MOTOLII_MAP_SHOWCASE_PNG'];
      if (outPath != null && outPath.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary =
              repaintKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final img = await boundary.toImage(pixelRatio: 2.0);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          if (data != null) {
            final f = File(outPath);
            f.parent.createSync(recursive: true);
            f.writeAsBytesSync(data.buffer.asUint8List());
          }
        });
      }
    },
  );
}
