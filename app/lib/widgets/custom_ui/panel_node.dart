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

/// Maps a semantic tone keyword (`accent`, `layout`, `blend`, `place`, `time`, `layer`,
/// `muted`, `border`, `text`, `surface`) or `#RRGGBB` hex string to a [Color].
Color? resolveCanvasColor(String token) {
  if (token.isEmpty) return null;
  return switch (token) {
    'accent' => Accent.fill,
    'layout' => InspectorSkin.toneLayout,
    'blend' => InspectorSkin.toneBlend,
    'place' => InspectorSkin.tonePlace,
    'time' => InspectorSkin.toneTime,
    'layer' => InspectorSkin.toneLayer,
    'muted' => Grey.g56,
    'border' => Grey.g26,
    'text' => Grey.g91,
    'surface' => Grey.g15,
    'well' => InspectorSkin.well,
    _ => parseHexColor(token),
  };
}

String _hexRgb(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Current Motolii skin tokens as `#rrggbb` strings for `ctx.theme` and SVG `var(--token)`.
Map<String, String> panelThemeHexMap() => {
  'accent': _hexRgb(Accent.fill),
  'layout': _hexRgb(InspectorSkin.toneLayout),
  'blend': _hexRgb(InspectorSkin.toneBlend),
  'place': _hexRgb(InspectorSkin.tonePlace),
  'time': _hexRgb(InspectorSkin.toneTime),
  'layer': _hexRgb(InspectorSkin.toneLayer),
  'muted': _hexRgb(Grey.g56),
  'border': _hexRgb(Grey.g26),
  'text': _hexRgb(Grey.g91),
  'surface': _hexRgb(Grey.g15),
  'well': _hexRgb(InspectorSkin.well),
};

final _svgVarPattern = RegExp(r'var\(--([a-zA-Z0-9_-]+)\)');

/// Replaces CSS custom properties like `var(--accent)` in inline SVG markup with the
/// active Motolii skin hex color so standard SVG stays skin-adaptive.
String resolveSvgThemeVars(String svg) {
  if (!svg.contains('var(--')) return svg;
  final map = panelThemeHexMap();
  return svg.replaceAllMapped(_svgVarPattern, (m) {
    final key = m.group(1) ?? '';
    return map[key] ?? m.group(0)!;
  });
}

/// One vector draw command inside a `ui.canvas(height, drawOps)` node.
/// Coordinates are normalized `0..1` relative to the canvas box.
class CanvasDrawOp {
  const CanvasDrawOp({
    required this.op,
    this.x = 0,
    this.y = 0,
    this.x2 = 0,
    this.y2 = 0,
    this.w = 0,
    this.h = 0,
    this.r = 0,
    this.cx1 = 0,
    this.cy1 = 0,
    this.cx2 = 0,
    this.cy2 = 0,
    this.start = 0,
    this.sweep = 0,
    this.strokeWidth = 1.2,
    this.alpha = 1.0,
    this.radius = 0,
    this.fill = '',
    this.stroke = '',
    this.text = '',
    this.align = 'left',
    this.points = const [],
  });

  final String op;
  final double x, y, x2, y2, w, h, r, cx1, cy1, cx2, cy2, start, sweep;
  final double strokeWidth, alpha, radius;
  final String fill, stroke, text, align;
  final List<(double, double)> points;

  static CanvasDrawOp? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final op = raw['op']?.toString() ?? '';
    if (op.isEmpty) return null;
    double numOr(String k, double fallback) =>
        raw[k] is num ? (raw[k] as num).toDouble() : fallback;
    final pts = <(double, double)>[];
    if (raw['points'] is List) {
      for (final p in raw['points'] as List) {
        if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
          pts.add(((p[0] as num).toDouble(), (p[1] as num).toDouble()));
        } else if (p is Map && p['x'] is num && p['y'] is num) {
          pts.add(((p['x'] as num).toDouble(), (p['y'] as num).toDouble()));
        }
      }
    }
    return CanvasDrawOp(
      op: op,
      x: numOr('x', 0),
      y: numOr('y', 0),
      x2: numOr('x2', 0),
      y2: numOr('y2', 0),
      w: numOr('w', 0),
      h: numOr('h', 0),
      r: numOr('r', 0),
      cx1: numOr('cx1', 0),
      cy1: numOr('cy1', 0),
      cx2: numOr('cx2', 0),
      cy2: numOr('cy2', 0),
      start: numOr('start', 0),
      sweep: numOr('sweep', 0),
      strokeWidth: numOr('width', 1.2),
      alpha: numOr('alpha', 1.0).clamp(0.0, 1.0),
      radius: numOr('radius', 0),
      fill: raw['fill']?.toString() ?? '',
      stroke: raw['stroke']?.toString() ?? '',
      text: raw['text']?.toString() ?? '',
      align: raw['align']?.toString() ?? 'left',
      points: pts,
    );
  }
}

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
    this.height,
    this.cols = 3,
    this.accent = false,
    this.disabled = false,
    this.muted = false,
    this.bold = false,
    this.active = false,
    this.open = true,
    this.snap9 = false,
    this.options = const [],
    this.draw = const [],
    this.svg = '',
    this.fit = 'contain',
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
  final double? height;
  final int cols;
  final bool accent;
  final bool disabled;
  final bool muted;
  final bool bold;
  final bool active;
  final bool open;
  final bool snap9;
  final List<String> options;
  final List<CanvasDrawOp> draw;
  final String svg;
  final String fit;
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
      height: raw['height'] is num ? (raw['height'] as num).toDouble() : null,
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
      draw: [
        if (raw['draw'] is List)
          for (final d in raw['draw'] as List) ?CanvasDrawOp.fromJson(d),
      ],
      svg: raw['svg']?.toString() ?? '',
      fit: raw['fit']?.toString() ?? 'contain',
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
    this.ease = '',
    this.mode = '',
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
  final String ease;
  final String mode;
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
      ease: raw['ease']?.toString() ?? '',
      mode: raw['mode']?.toString() ?? '',
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

/// Parsed result of `motolii_card_ui_action`:
/// `{ set?: { param: num }, say?: { param: word }, state?: { key: val }, ops?: PanelOp[], notice?: string }`.
typedef CardUiActionResult = ({
  Map<String, double> set,
  Map<String, String> say,
  Map<String, Object?>? state,
  List<PanelOp> ops,
  String? notice,
  String? error,
});

CardUiActionResult parseCardUiActionResponse(String rawJson) {
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      return (
        set: const {},
        say: const {},
        state: null,
        ops: const [],
        notice: null,
        error: 'Invalid card action',
      );
    }
    if (decoded['ok'] != true) {
      return (
        set: const {},
        say: const {},
        state: null,
        ops: const [],
        notice: null,
        error: decoded['error']?.toString() ?? 'Card action failed',
      );
    }
    final res = decoded['result'];
    if (res is! Map) {
      return (
        set: const {},
        say: const {},
        state: null,
        ops: const [],
        notice: null,
        error: null,
      );
    }
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
    Map<String, Object?>? st;
    if (res['state'] is Map) {
      st = {
        for (final e in (res['state'] as Map).entries)
          e.key.toString(): e.value,
      };
    }
    final ops = <PanelOp>[
      if (res['ops'] is List)
        for (final item in res['ops'] as List) ?PanelOp.fromJson(item),
    ];
    return (
      set: setMap,
      say: sayMap,
      state: st,
      ops: ops,
      notice: res['notice']?.toString(),
      error: null,
    );
  } catch (e) {
    return (
      set: const {},
      say: const {},
      state: null,
      ops: const [],
      notice: null,
      error: 'Card action JSON error: $e',
    );
  }
}
