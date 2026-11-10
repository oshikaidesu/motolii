import 'package:flutter/widgets.dart';

import 'package:motolii/skin/theme.dart';

/// The colours the user chose on the Note card, by layer id. Each value is an index into Ableton Live's 16 colours.
/// Read together with the document.
final chosenLabelColors = <String, int>{};

/// A layer's label colour, as Ableton gives each clip its own.
///
/// Without a chosen colour it is one of sixteen, five apart from the previous layer so that neighbours differ.
/// It is the same every time the document is opened. The layer's row, its dot on the Relations map, its frame in the
/// preview and its name in lists all use it. A skin can override each colour (Label1 to Label16).
Color layerLabelColor(String id) => labelColor(
  chosenLabelColors[id] ?? ((int.tryParse(id) ?? 0) * 5) % _live.length,
);

/// The label colour [k], from 0 to 15. Marks use these colours too.
Color labelColor(int k) => ColorTheme.of('Label${k + 1}', Color(_live[k]));
const _live = [
  0xFFFF94A6,
  0xFFFFA529,
  0xFFF7F47C,
  0xFFBFFB00,
  0xFF1AFF2F,
  0xFF25FFA8,
  0xFF5CFFE8,
  0xFF8BC5FF,
  0xFF5480E4,
  0xFF92A7FF,
  0xFFD86CE4,
  0xFFE553A0,
  0xFFFF3636,
  0xFFF66C03,
  0xFF10A4EE,
  0xFF00BFAF,
]; // Ableton Live's clip colours.
