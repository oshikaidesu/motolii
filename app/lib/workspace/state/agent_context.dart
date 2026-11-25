// What an agent is told of the scene and selected layer's values, read from the engine now.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/workspace/state/layer.dart' show LayerKind;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Every card of the Inspector on layer [t] as a line: its title, then each value as `Label (name)=value`, now.
List<String> cardValueLines(WorkspaceController ws, int t) {
  final m = ws.inside;
  if (m == null) return const [];
  String value(String n) =>
      m.words(t, n).isNotEmpty || m.value(t, n, m.now) == null
      ? m.word(t, n)
      : _number(m.value(t, n, m.now)!);
  return [
    for (final (title, names) in m.cards(t))
      '$title: ${[for (final n in names) '${m.shown(n)?.label ?? n} ($n)=${value(n)}'].join(', ')}',
  ];
}

/// True when the open composition has any audio or sound-carrying video layer.
bool sceneHasAudio(WorkspaceController ws) {
  final m = ws.inside;
  if (m == null) return false;
  return ws.layers.any(
    (l) => l.kind == LayerKind.audio || isSoundLayer(m, l.id),
  );
}

/// Compact inline scene outline so agents understand the layer tree immediately
/// without shelling out to python/jq on scene.json.
List<String> sceneOutlineLines(WorkspaceController ws, {int maxLayers = 40}) {
  final m = ws.inside;
  if (m == null || ws.layers.isEmpty) return const [];
  final fps = WorkspaceController.fps > 0 ? WorkspaceController.fps : 60;
  final at = ws.frame / fps;
  final sel = ws.many.isNotEmpty ? ws.many : {?ws.selected};
  final lines = <String>[];
  for (final l in ws.layers.take(maxLayers)) {
    final parent = m.parentOf(l.id);
    final rawKind = m.word(l.id, 'kind');
    final kind = rawKind.isNotEmpty ? rawKind : l.kind.name;
    final shape = (kind == 'shape' || kind == 'solid')
        ? m.word(l.id, 'shape')
        : '';
    final kindTag = shape.isNotEmpty ? '$kind:$shape' : kind;
    final x = _shortNum(m.value(l.id, 'x', at) ?? 0);
    final y = _shortNum(m.value(l.id, 'y', at) ?? 0);
    final z = m.value(l.id, 'z', at) ?? 0;
    final fx = m.word(l.id, 'fx').trim();
    final script = m.word(l.id, 'script').trim();
    final txt = kind == 'text'
        ? m.word(l.id, 'text').replaceAll('\n', ' ').trim()
        : '';
    String keyInfo = '';
    if (l.keys.isNotEmpty) {
      final lo = l.keys.reduce((a, b) => a < b ? a : b) / fps;
      final hi = l.keys.reduce((a, b) => a > b ? a : b) / fps;
      final props = [for (final lane in l.lanes) lane.name].take(4).join(',');
      final span = lo == hi
          ? '${lo.toStringAsFixed(2)}s'
          : '${lo.toStringAsFixed(2)}–${hi.toStringAsFixed(2)}s';
      keyInfo = props.isNotEmpty
          ? 'keys=${l.keys.length}@$span($props)'
          : 'keys=${l.keys.length}@$span';
    }
    final bits = <String>[
      if (sel.contains(l.id)) '*',
      '[${l.id}]',
      '"${l.name}"',
      '($kindTag)',
      if (parent > 0) 'parent=$parent',
      z == 0 ? 'pos=($x,$y)' : 'pos=($x,$y,${_shortNum(z)})',
      if (txt.isNotEmpty)
        'text="${txt.length > 24 ? '${txt.substring(0, 24)}…' : txt}"',
      if (keyInfo.isNotEmpty) keyInfo,
      if (script.isNotEmpty) 'script=${script.split('/').last}',
      if (fx.isNotEmpty)
        'fx=${fx.split(' ').map((p) => p.split('/').last).join(',')}',
    ];
    lines.add('- ${bits.join(' ')}');
  }
  if (ws.layers.length > maxLayers) {
    lines.add(
      '- …and ${ws.layers.length - maxLayers} more layers in scene.json',
    );
  }
  return lines;
}

String _number(double v) => v == v.roundToDouble()
    ? '${v.toInt()}'
    : '${double.parse(v.toStringAsFixed(4))}';

String _shortNum(double v) =>
    v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);
