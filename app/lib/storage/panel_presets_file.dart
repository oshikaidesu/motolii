// Persists user JSON presets for JS custom panels under ~/.motolii/panel_presets/.
import 'dart:convert';
import 'dart:io';

import 'package:motolii/storage/host_platform.dart' show homeFolder;

File _presetFile(String panelName) {
  final safe = panelName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return File('$homeFolder/.motolii/panel_presets/$safe.json');
}

/// Reads saved presets for [panelName] as a map of preset name -> JSON value.
Map<String, Object?> readPanelPresets(String panelName) {
  try {
    final f = _presetFile(panelName);
    if (!f.existsSync()) return const {};
    final decoded = jsonDecode(f.readAsStringSync());
    if (decoded is Map) {
      return {for (final e in decoded.entries) e.key.toString(): e.value};
    }
  } catch (_) {}
  return const {};
}

/// Writes [presets] for [panelName] atomically to ~/.motolii/panel_presets/.
void writePanelPresets(String panelName, Map<String, Object?> presets) {
  try {
    final f = _presetFile(panelName);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(presets));
  } catch (_) {}
}
