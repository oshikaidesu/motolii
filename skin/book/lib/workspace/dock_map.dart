// A shelf's map, as XLN Audio's XO's Space: each item where what is alike lies near (laid out by the inside's t-SNE,
// motolii_map, as XO's are), the shelf's chips and words narrowing which are shown, as XO's filters narrow its Space;
// moved and zoomed by Flutter's own InteractiveViewer. Laid out again when what the shelf holds changes (XO's Scan &
// Refresh, done by itself), kept between openings beside the tiles (~/Library/Caches/Motolii).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../motolii.dart' show Motolii, MotoliiQuestions;
import '../tokens.dart';

/// Where one shelf's items lie on its map, by id, 0 to 1 each way; [laying] while that is being worked out.
class DockMapPlaces {
  DockMapPlaces(this.name);
  final String name;
  final places = ValueNotifier<Map<String, Offset>>(const {});
  final laying = ValueNotifier<bool>(false);
  String? _for;

  File get _kept => File('${Platform.environment['HOME']}/Library/Caches/Motolii/map_$name.json');

  /// Laid out for these items (each its id and what it is read from), each read as numbers by [read] (null: left off the
  /// map); only when they are not the ones laid out last, nor the ones kept from before ([also]: what else they were
  /// laid out by, the same items read again when it changes).
  void need(Motolii m, List<(String, String)> items, Future<List<Float32List?>> Function(List<String> from) read, {String also = ''}) {
    final key = jsonEncode([also, for (final (id, from) in items) '$id\t$from']);
    if (key == _for) return;
    _for = key;
    Zone.root.run(() async {   // (on the program's own clock, as fontsRead: a test may wait for it)
      try {
        final kept = jsonDecode(await _kept.readAsString()) as Map<String, dynamic>;
        if (kept['for'] == key) {
          places.value = {for (final MapEntry(key: id, value: at) in (kept['places'] as Map<String, dynamic>).entries) id: Offset(((at as List)[0] as num).toDouble(), (at[1] as num).toDouble())};
          return;
        }
      } catch (_) {}   // (none kept, or for others: laid out now)
      laying.value = true;
      final numbers = await read([for (final (_, from) in items) from]);
      final ids = [for (final (i, (id, _)) in items.indexed) if (numbers[i] != null) id];
      final laid = await m.map([for (final v in numbers) ?v]);
      if (key != _for) return;   // (asked for others meanwhile: theirs comes)
      laying.value = false;
      places.value = laid == null ? const {} : {for (final (i, id) in ids.indexed) id: Offset(laid[i].$1, laid[i].$2)};
      try {
        _kept.parent.createSync(recursive: true);
        await _kept.writeAsString(jsonEncode({'for': key, 'places': {for (final MapEntry(key: id, value: at) in places.value.entries) id: [at.dx, at.dy]}}));
      } catch (_) {}   // (not kept: laid out again next time)
    });
  }
}

/// A picture's numbers: its colours made 16 points square, as Torralba, Fergus and Freeman's tiny images ("80 million
/// tiny images", 2008) tell pictures apart by their colours made small; several pictures one after another. null:
/// one of them cannot be read (yet: asked again next time). Read once while the window is open.
final _tiny = <String, Float32List>{};
Future<Float32List?> dockTiny(List<String> files) async {
  final key = files.join('\n');
  if (_tiny[key] case final v?) return v;
  final v = await _read(files);
  if (v != null) _tiny[key] = v;
  return v;
}
Future<Float32List?> _read(List<String> files) async {
  const side = 16;
  final out = Float32List(files.length * side * side * 3);
  for (final (k, f) in files.indexed) {
    try {
      final codec = await ui.instantiateImageCodec(await File(f).readAsBytes(), targetWidth: side, targetHeight: side);
      final image = (await codec.getNextFrame()).image, px = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
      image.dispose();
      codec.dispose();
      for (var i = 0; i < side * side; i++) {
        for (var ch = 0; ch < 3; ch++) {
          out[(k * side * side + i) * 3 + ch] = px[i * 4 + ch] / 255;
        }
      }
    } catch (_) {
      return null;
    }
  }
  return out;
}

/// The map: each shown item's tile ([cell] wide, [aspect] its width to its height) where it lies, the rest left off;
/// what is said while it is being laid out.
class DockMap extends StatelessWidget {
  const DockMap(this.places, this.shown, {super.key, this.cell = 26, this.aspect = 1});
  final DockMapPlaces places;
  final List<(String, Widget)> shown;
  final double cell, aspect;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([places.places, places.laying]),
    builder: (context, _) {
      final at = places.places.value;
      if (at.isEmpty) {
        return Center(child: Text(places.laying.value ? 'Laying out the map…' : 'Nothing on the map yet', style: T.label(Grey.g63)));
      }
      return LayoutBuilder(
        builder: (context, box) {
          final w = Shape.z(cell), h = w / aspect, room = Size(box.maxWidth, box.maxHeight);
          return ClipRect(
            child: InteractiveViewer(
              key: ValueKey('ws-map-${places.name}'),
              maxScale: 12,
              boundaryMargin: EdgeInsets.all(w),
              child: SizedBox.fromSize(
                size: room,
                child: Stack(
                  children: [
                    for (final (id, tile) in shown)
                      if (at[id] case final p?) Positioned(key: ValueKey('ws-map-${places.name}-$id'), left: p.dx * (room.width - w), top: p.dy * (room.height - h), width: w, height: h, child: tile),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Each shelf's map, while the window is open (not the document's).
final _maps = <String, DockMapPlaces>{};
DockMapPlaces dockMap(String shelf) => _maps[shelf] ??= DockMapPlaces(shelf);
