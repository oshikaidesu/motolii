// What an agent is told of the selected layer's values, read from the engine now.
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
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

String _number(double v) => v == v.roundToDouble()
    ? '${v.toInt()}'
    : '${double.parse(v.toStringAsFixed(4))}';
