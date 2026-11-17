// A headless render harness, not a test: it paints real widgets to PNG files
// so an LLM can review them. Run it explicitly, outside the normal suite:
//   flutter test tool/gallery/gallery.dart
// PNGs land in tool/gallery/out/. Motion is captured as a filmstrip — the same
// widget pumped across its 120 ms, each frame tiled left to right.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/switch_track.dart';
import 'package:motolii/widgets/disclosure_triangle.dart';

const _bg = DarkGrey.g15;
const _pad = 10.0;
const _gap = 8.0;
const _ratio = 3.0;

void main() {
  testWidgets('render gallery', (tester) async {
    Directory('tool/gallery/out').createSync(recursive: true);
    tester.view.physicalSize = const Size(1200, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // A static contact sheet: a handful of primitives in their rest states.
    await _sheet(tester, 'contact.png', const [
      PopSwitch(on: false),
      PopSwitch(on: true),
      DisclosureTriangle(open: false, hot: false),
      DisclosureTriangle(open: true, hot: true),
    ]);

    // Motion filmstrips: toggle the widget, pump across the animation, tile frames.
    await _strip(tester, 'popswitch_toggle.png', (on) => PopSwitch(on: on));
    await _strip(
      tester,
      'disclosure_open.png',
      (open) => DisclosureTriangle(open: open, hot: true),
    );
  });
}

final _key = GlobalKey();

Widget _frame(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: _bg,
    child: Center(
      child: Padding(padding: const EdgeInsets.all(_pad), child: child),
    ),
  ),
);

Future<ui.Image> _grab(WidgetTester tester) async {
  final rb = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  late ui.Image img;
  await tester.runAsync(() async {
    img = await rb.toImage(pixelRatio: _ratio);
  });
  return img;
}

Future<void> _sheet(
  WidgetTester tester,
  String name,
  List<Widget> parts,
) async {
  await tester.pumpWidget(
    _frame(
      RepaintBoundary(
        key: _key,
        child: ColoredBox(
          color: _bg,
          child: Padding(
            padding: const EdgeInsets.all(_pad),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in parts)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _gap),
                    child: p,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final img = await _grab(tester);
  await _write(tester, [img], 'tool/gallery/out/$name');
}

// Build the widget at `off`, hold it, then flip to `on` and pump across the
// animation, grabbing one frame per step. Tiled, the frames read as motion.
Future<void> _strip(
  WidgetTester tester,
  String name,
  Widget Function(bool on) build,
) async {
  const steps = [0, 20, 40, 60, 90, 120];
  bool on = false;
  late StateSetter set;
  await tester.pumpWidget(
    _frame(
      RepaintBoundary(
        key: _key,
        child: StatefulBuilder(
          builder: (_, s) {
            set = s;
            return build(on);
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final frames = <ui.Image>[await _grab(tester)];
  set(() => on = true);
  var last = 0;
  for (final ms in steps) {
    await tester.pump(Duration(milliseconds: ms - last));
    last = ms;
    frames.add(await _grab(tester));
  }
  await _write(tester, frames, 'tool/gallery/out/$name');
}

Future<void> _write(
  WidgetTester tester,
  List<ui.Image> frames,
  String path,
) async {
  final h = frames.map((f) => f.height).reduce((a, b) => a > b ? a : b);
  final totalW =
      frames.fold<int>(0, (a, f) => a + f.width) +
      (_gap * _ratio).round() * (frames.length + 1);
  final totalH = h + (_gap * _ratio).round() * 2;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, totalW.toDouble(), totalH.toDouble()),
    Paint()..color = _bg,
  );
  var x = (_gap * _ratio);
  for (final f in frames) {
    final y = (totalH - f.height) / 2;
    canvas.drawImage(f, Offset(x, y), Paint());
    x += f.width + _gap * _ratio;
  }
  final pic = rec.endRecording();
  late ByteData? bytes;
  await tester.runAsync(() async {
    final out = await pic.toImage(totalW, totalH);
    bytes = await out.toByteData(format: ui.ImageByteFormat.png);
  });
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}
