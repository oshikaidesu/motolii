// Shared declarative JSON model for both Custom Tabs (shelves/panels/*.js) and
// Effect Custom Inspector Cards (<effect>.ui.js / TSL renderCard).
// 詳細: docs/design/custom_panels.md
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/hex_color.dart' show colorOfHex;
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';

/// Metadata for one `.js` custom tab discovered under `shelves/panels/` or user `panels/`.
typedef PanelDescriptor = ({
  String name,
  String path,
  String about,
  String acts,
  String tone,
});

/// Parses `motolii_panels()` output (`name\tpath\tabout\tacts\ttone` per line).
List<PanelDescriptor> parsePanelList(String raw) {
  if (raw.trim().isEmpty) return const [];
  final out = <PanelDescriptor>[];
  for (final line in raw.split('\n')) {
    if (line.trim().isEmpty) continue;
    final p = line.split('\t');
    if (p.length < 2 || p[0].isEmpty || p[1].isEmpty) continue;
    out.add((
      name: p[0],
      path: p[1],
      about: p.length > 2 ? p[2] : '',
      acts: p.length > 3 && p[3].isNotEmpty ? p[3] : 'Panel',
      tone: p.length > 4 && p[4].isNotEmpty ? p[4] : 'accent',
    ));
  }
  return out;
}

/// Maps a semantic tone keyword (`accent`, `layout`, `blend`, `place`, `time`, `layer`)
/// to Motolii's skin tokens.
Color panelToneColor(String tone) => switch (tone) {
  'layout' => InspectorSkin.toneLayout,
  'blend' => InspectorSkin.toneBlend,
  'place' => InspectorSkin.tonePlace,
  'time' => InspectorSkin.toneTime,
  'layer' => InspectorSkin.toneLayer,
  'muted' => Grey.g56,
  _ => Accent.fill,
};

/// Parses a `#RGB` or `#RRGGBB` user-supplied hex color string, or null when invalid.
Color? parseHexColor(String hex) => colorOfHex(hex.trim());

/// One node in the declarative UI tree returned by `render(ctx)` or `renderCard(ctx)`.
class PanelNode {
  const PanelNode({
    required this.type,
    this.id = '',
    this.label = '',
    this.title = '',
    this.text = '',
    this.tone = '',
    this.unit = '',
    this.placeholder = '',
    this.tip = '',
    this.color = '',
    this.stringValue = '',
    this.numValue,
    this.boolValue,
    this.x = 0,
    this.y = 0,
    this.min,
    this.max,
    this.step,
    this.dec,
    this.size,
    this.cols = 3,
    this.accent = false,
    this.disabled = false,
    this.muted = false,
    this.bold = false,
    this.active = false,
    this.open = true,
    this.snap9 = false,
    this.options = const [],
    this.children = const [],
  });

  final String type;
  final String id;
  final String label;
  final String title;
  final String text;
  final String tone;
  final String unit;
  final String placeholder;
  final String tip;
  final String color;
  final String stringValue;
  final double? numValue;
  final bool? boolValue;
  final double x;
  final double y;
  final double? min;
  final double? max;
  final double? step;
  final int? dec;
  final double? size;
  final int cols;
  final bool accent;
  final bool disabled;
  final bool muted;
  final bool bold;
  final bool active;
  final bool open;
  final bool snap9;
  final List<String> options;
  final List<PanelNode> children;

  static PanelNode? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final type = raw['type']?.toString() ?? '';
    if (type.isEmpty) return null;
    final val = raw['value'];
    return PanelNode(
      type: type,
      id: raw['id']?.toString() ?? '',
      label: raw['label']?.toString() ?? '',
      title: raw['title']?.toString() ?? '',
      text: raw['text']?.toString() ?? '',
      tone: raw['tone']?.toString() ?? '',
      unit: raw['unit']?.toString() ?? '',
      placeholder: raw['placeholder']?.toString() ?? '',
      tip: raw['tip']?.toString() ?? '',
      color: raw['color']?.toString() ?? (val is String ? val : ''),
      stringValue: val is String ? val : '',
      numValue: val is num ? val.toDouble() : null,
      boolValue: val is bool ? val : null,
      x: raw['x'] is num ? (raw['x'] as num).toDouble() : 0.0,
      y: raw['y'] is num ? (raw['y'] as num).toDouble() : 0.0,
      min: raw['min'] is num ? (raw['min'] as num).toDouble() : null,
      max: raw['max'] is num ? (raw['max'] as num).toDouble() : null,
      step: raw['step'] is num ? (raw['step'] as num).toDouble() : null,
      dec: raw['dec'] is num ? (raw['dec'] as num).toInt() : null,
      size: raw['size'] is num ? (raw['size'] as num).toDouble() : null,
      cols: raw['cols'] is num ? (raw['cols'] as num).toInt().clamp(1, 12) : 3,
      accent: raw['accent'] == true,
      disabled: raw['disabled'] == true,
      muted: raw['muted'] == true,
      bold: raw['bold'] == true,
      active: raw['active'] == true,
      open: raw['open'] != false,
      snap9: raw['snap9'] == true,
      options: [
        if (raw['options'] is List)
          for (final o in raw['options'] as List) o.toString(),
      ],
      children: [
        if (raw['children'] is List)
          for (final c in raw['children'] as List) ?PanelNode.fromJson(c),
      ],
    );
  }
}

/// One document mutation returned by a custom tab's `onAction(action, ctx)`.
class PanelOp {
  const PanelOp({
    required this.op,
    this.layer = 0,
    this.name = '',
    this.word = '',
    this.kind = '',
    this.file = '',
    this.value,
    this.at,
    this.layers = const [],
  });

  final String op;
  final int layer;
  final String name;
  final String word;
  final String kind;
  final String file;
  final double? value;
  final double? at;
  final List<int> layers;

  static PanelOp? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final op = raw['op']?.toString() ?? '';
    if (op.isEmpty) return null;
    return PanelOp(
      op: op,
      layer: raw['layer'] is num ? (raw['layer'] as num).toInt() : 0,
      name: raw['name']?.toString() ?? '',
      word: raw['word']?.toString() ?? '',
      kind: raw['kind']?.toString() ?? '',
      file: raw['file']?.toString() ?? '',
      value: raw['value'] is num ? (raw['value'] as num).toDouble() : null,
      at: raw['at'] is num ? (raw['at'] as num).toDouble() : null,
      layers: [
        if (raw['layers'] is List)
          for (final l in raw['layers'] as List)
            if (l is num) l.toInt(),
      ],
    );
  }
}

/// Parsed result of `motolii_panel_render`.
typedef PanelRenderResult = ({PanelNode? root, String? error});

PanelRenderResult parsePanelRenderResponse(String rawJson) {
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) return (root: null, error: 'Invalid panel response');
    if (decoded['ok'] != true) {
      return (
        root: null,
        error: decoded['error']?.toString() ?? 'Panel render failed',
      );
    }
    final root = PanelNode.fromJson(decoded['ui']);
    if (root == null) {
      return (root: null, error: 'render(ctx) must return a UI node object');
    }
    return (root: root, error: null);
  } catch (e) {
    return (root: null, error: 'Panel JSON parse error: $e');
  }
}

/// Parsed result of `motolii_panel_action`.
typedef PanelActionResult = ({
  Map<String, Object?>? state,
  List<PanelOp> ops,
  String? notice,
  String? error,
});

PanelActionResult parsePanelActionResponse(String rawJson) {
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      return (
        state: null,
        ops: const [],
        notice: null,
        error: 'Invalid panel action response',
      );
    }
    if (decoded['ok'] != true) {
      return (
        state: null,
        ops: const [],
        notice: null,
        error: decoded['error']?.toString() ?? 'Panel action failed',
      );
    }
    final res = decoded['result'];
    if (res is! Map) {
      return (state: null, ops: const [], notice: null, error: null);
    }
    final stRaw = res['state'];
    final Map<String, Object?>? st = stRaw is Map
        ? {for (final e in stRaw.entries) e.key.toString(): e.value}
        : null;
    final ops = <PanelOp>[
      if (res['ops'] is List)
        for (final item in res['ops'] as List) ?PanelOp.fromJson(item),
    ];
    return (
      state: st,
      ops: ops,
      notice: res['notice']?.toString(),
      error: null,
    );
  } catch (e) {
    return (
      state: null,
      ops: const [],
      notice: null,
      error: 'Panel action JSON parse error: $e',
    );
  }
}

/// Parsed result of `motolii_card_ui_render`: supports either `{ hide: [...], ui: {...} }`
/// or a bare `PanelNode` directly.
typedef CardUiRenderResult = ({
  PanelNode? root,
  Set<String> hide,
  String? error,
});

CardUiRenderResult parseCardUiRenderResponse(String rawJson) {
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      return (root: null, hide: const {}, error: 'Invalid card UI response');
    }
    if (decoded['ok'] != true) {
      return (
        root: null,
        hide: const {},
        error: decoded['error']?.toString() ?? 'Card UI render failed',
      );
    }
    final payload = decoded['ui'];
    if (payload is Map && payload.containsKey('ui')) {
      final hide = <String>{
        if (payload['hide'] is List)
          for (final h in payload['hide'] as List) h.toString(),
      };
      final root = PanelNode.fromJson(payload['ui']);
      return (
        root: root,
        hide: hide,
        error: root == null ? 'Card UI `ui` field must be a UI node' : null,
      );
    }
    final root = PanelNode.fromJson(payload);
    return (
      root: root,
      hide: const {},
      error: root == null ? 'renderCard(ctx) must return a UI node' : null,
    );
  } catch (e) {
    return (root: null, hide: const {}, error: 'Card UI JSON error: $e');
  }
}

/// Parsed result of `motolii_card_ui_action`: `{ set?: { param: num }, say?: { param: word } }`.
typedef CardUiActionResult = ({
  Map<String, double> set,
  Map<String, String> say,
  String? error,
});

CardUiActionResult parseCardUiActionResponse(String rawJson) {
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      return (set: const {}, say: const {}, error: 'Invalid card action');
    }
    if (decoded['ok'] != true) {
      return (
        set: const {},
        say: const {},
        error: decoded['error']?.toString() ?? 'Card action failed',
      );
    }
    final res = decoded['result'];
    if (res is! Map) return (set: const {}, say: const {}, error: null);
    final setMap = <String, double>{};
    if (res['set'] is Map) {
      for (final e in (res['set'] as Map).entries) {
        if (e.value is num) {
          setMap[e.key.toString()] = (e.value as num).toDouble();
        }
      }
    }
    final sayMap = <String, String>{};
    if (res['say'] is Map) {
      for (final e in (res['say'] as Map).entries) {
        sayMap[e.key.toString()] = e.value?.toString() ?? '';
      }
    }
    return (set: setMap, say: sayMap, error: null);
  } catch (e) {
    return (set: const {}, say: const {}, error: 'Card action JSON error: $e');
  }
}
