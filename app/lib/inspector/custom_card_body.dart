// Evaluates and renders an effect's custom JS Inspector card UI (`<effect>.ui.js`
// sidecar or co-located `renderCard(ctx)` in a `.js`/TSL effect).
// 詳細: docs/design/custom_panels.md
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/custom_ui/panel_node.dart';
import 'package:motolii/widgets/custom_ui/panel_renderer.dart';

/// Maps short parameter names (`width`, `angle`) to the card's actual prefixed
/// parameter IDs (`js_diagonal_blur_width` or `a1b2c3:js_diagonal_blur_width`).
class CardParamNames {
  CardParamNames(CardDeclaration card) {
    final ids = [for (final p in card.params) p.id];
    final prefix = _commonJsPrefix(ids);
    final jsHead = RegExp(r'^([0-9a-f]{6}:)?js_');
    for (final id in ids) {
      final rawName = id.replaceFirst(jsHead, '');
      final short = prefix.isNotEmpty && id.startsWith(prefix)
          ? id.substring(prefix.length)
          : rawName;
      shortToFull[rawName] = id;
      shortToFull[short] = id;
      fullToShort[id] = short;
      fullToAliases[id] = {rawName, short};
    }
  }

  final Map<String, String> shortToFull = {};
  final Map<String, String> fullToShort = {};
  final Map<String, Set<String>> fullToAliases = {};

  String? resolve(String key) =>
      shortToFull[key] ?? (fullToShort.containsKey(key) ? key : null);

  static String _commonJsPrefix(List<String> ids) {
    final jsIds = [
      for (final id in ids)
        if (RegExp(r'^([0-9a-f]{6}:)?js_').hasMatch(id)) id,
    ];
    if (jsIds.isEmpty) return '';
    // Find longest shared `_`-terminated prefix (e.g. `js_diagonal_blur_`).
    var prefix = jsIds.first;
    for (final id in jsIds.skip(1)) {
      var i = 0;
      while (i < prefix.length && i < id.length && prefix[i] == id[i]) {
        i++;
      }
      prefix = prefix.substring(0, i);
    }
    final lastUnderscore = prefix.lastIndexOf('_');
    if (lastUnderscore < 0) return '';
    return prefix.substring(0, lastUnderscore + 1);
  }
}

/// Evaluates an effect card's custom UI for the current [doc] snapshot.
({
  CardUiRenderResult result,
  Set<String> hiddenFullIds,
  String ctxJson,
  CardParamNames names,
})
evaluateCardCustomUi(
  InspectorValues doc,
  CardDeclaration card,
  CardCustomUi ui,
) {
  final names = CardParamNames(card);
  final params = <String, Object?>{};
  final ranges = <String, Object?>{};
  for (final p in card.params) {
    final vid = 'v_${p.id}';
    final Object? val = doc.numbers.containsKey(vid)
        ? doc.numbers[vid]
        : (doc.strings.containsKey(vid) ? doc.strings[vid] : p.def);
    final range = {
      'min': p.min,
      'max': p.max,
      'unit': p.unit,
      'label': p.label,
    };
    for (final alias in names.fullToAliases[p.id] ?? {p.id}) {
      params[alias] = val;
      ranges[alias] = range;
    }
  }
  final ctxJson = jsonEncode({
    'card': card.name,
    'params': params,
    'ranges': ranges,
  });
  final res = parseCardUiRenderResponse(ui.render(ctxJson));
  final hiddenFull = <String>{for (final h in res.hide) ?names.resolve(h)};
  return (
    result: res,
    hiddenFullIds: hiddenFull,
    ctxJson: ctxJson,
    names: names,
  );
}

/// Renders the custom JS UI body inside a [ValuesCard] and routes interactions
/// directly back to the card's document parameters (single source of truth).
class CustomCardBody extends StatefulWidget {
  const CustomCardBody({
    required this.doc,
    required this.card,
    required this.ui,
    required this.result,
    required this.ctxJson,
    required this.names,
    super.key,
  });

  final InspectorValues doc;
  final CardDeclaration card;
  final CardCustomUi ui;
  final CardUiRenderResult result;
  final String ctxJson;
  final CardParamNames names;

  @override
  State<CustomCardBody> createState() => _CustomCardBodyState();
}

class _CustomCardBodyState extends State<CustomCardBody> {
  String? _actionError;

  void _onAction(String id, Object? value, {bool live = false}) {
    final doc = widget.doc;
    final actionJson = jsonEncode({'id': id, 'value': value, 'live': live});
    final act = parseCardUiActionResponse(
      widget.ui.action(actionJson, widget.ctxJson),
    );
    if (act.error != null) {
      setState(() => _actionError = act.error);
      return;
    }
    if (_actionError != null) setState(() => _actionError = null);

    final numWrites = <String, double>{};
    final strWrites = <String, String>{};
    for (final e in act.set.entries) {
      final full = widget.names.resolve(e.key);
      if (full != null) numWrites['v_$full'] = e.value;
    }
    for (final e in act.say.entries) {
      final full = widget.names.resolve(e.key);
      if (full != null) strWrites['v_$full'] = e.value;
    }

    // Zero-boilerplate direct binding: if onCardAction returned nothing, bind
    // directly when control `id` matches a param (or "xParam,yParam" for xy).
    if (numWrites.isEmpty && strWrites.isEmpty) {
      if (value is num) {
        final full = widget.names.resolve(id);
        if (full != null) numWrites['v_$full'] = value.toDouble();
      } else if (value is bool) {
        final full = widget.names.resolve(id);
        if (full != null) numWrites['v_$full'] = value ? 1.0 : 0.0;
      } else if (value is String) {
        final full = widget.names.resolve(id);
        if (full != null) strWrites['v_$full'] = value;
      } else if (value is Map && id.contains(',')) {
        final parts = id.split(',').map((s) => s.trim()).toList();
        if (parts.length == 2) {
          final fx = widget.names.resolve(parts[0]);
          final fy = widget.names.resolve(parts[1]);
          if (fx != null && value['x'] is num) {
            numWrites['v_$fx'] = (value['x'] as num).toDouble();
          }
          if (fy != null && value['y'] is num) {
            numWrites['v_$fy'] = (value['y'] as num).toDouble();
          }
        }
      }
    }

    if (numWrites.isNotEmpty) {
      if (live) {
        doc.beginGesture();
        doc.setMany(numWrites);
      } else {
        if (doc.inGesture) {
          doc.setMany(numWrites);
          doc.endGesture();
        } else {
          doc.setMany(numWrites);
        }
      }
    }
    for (final e in strWrites.entries) {
      doc.str(e.key, e.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final err = _actionError ?? widget.result.error;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        InspectorSkin.inset,
        0,
        InspectorSkin.inset,
        InspectorSkin.tileGap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (err != null) ...[
            Container(
              padding: EdgeInsets.all(Shape.s(6)),
              decoration: BoxDecoration(
                color: InspectorSkin.well,
                borderRadius: Shape.round(5),
                border: Border.all(color: InspectorSkin.tonePlace),
              ),
              child: Text(
                err,
                style: TextStyles.micro(InspectorSkin.tonePlace),
              ),
            ),
            SizedBox(height: Shape.s(5)),
          ],
          if (widget.result.root case final root?)
            PanelTreeView(node: root, onAction: _onAction),
        ],
      ),
    );
  }
}
