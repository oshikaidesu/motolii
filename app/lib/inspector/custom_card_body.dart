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
import 'package:motolii/storage/panel_presets_file.dart'
    show readPanelPresets, writePanelPresets;
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/custom_ui/panel_node.dart';
import 'package:motolii/widgets/custom_ui/panel_renderer.dart';
import 'package:motolii/widgets/custom_ui/script_watch.dart';

/// Maps short parameter names (`width`, `angle`) to the card's actual prefixed
/// parameter IDs (`js_diagonal_blur_width` or `a1b2c3:js_diagonal_blur_width`).
class CardParamNames {
  CardParamNames(CardDeclaration card) {
    final ids = [for (final p in card.params) p.id];
    final prefix = _commonJsPrefix(ids);
    final jsHead = RegExp(r'^([0-9a-f]{6}:)?js_');
    final rawById = <String, String>{};
    for (final id in ids) {
      final rawName = id.replaceFirst(jsHead, '');
      rawById[id] = rawName;
      final short = prefix.isNotEmpty && id.startsWith(prefix)
          ? id.substring(prefix.length)
          : rawName;
      shortToFull[rawName] = id;
      shortToFull[short] = id;
      fullToShort[id] = short;
      fullToAliases[id] = {rawName, short};
    }
    // Multi-step Vism packs mix `js_<param>` (expression) and `id:js_<stem>_<param>`
    // (shader). Expose the trailing leaf alias (`amount` for `glow_amount`) when it
    // does not collide across steps; colliding names keep their step-prefixed form.
    final leafCounts = <String, int>{};
    final leafById = <String, String>{};
    for (final entry in rawById.entries) {
      final raw = entry.value;
      final cut = raw.lastIndexOf('_');
      if (cut > 0 && cut + 1 < raw.length) {
        final leaf = raw.substring(cut + 1);
        leafById[entry.key] = leaf;
        leafCounts[leaf] = (leafCounts[leaf] ?? 0) + 1;
      }
    }
    for (final entry in leafById.entries) {
      final leaf = entry.value;
      if (leafCounts[leaf] == 1 && !shortToFull.containsKey(leaf)) {
        shortToFull[leaf] = entry.key;
        fullToAliases[entry.key]!.add(leaf);
      }
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

/// Builds the JSON context passed to `renderCard(ctx)` and `onCardAction(action, ctx)`.
String buildCardCustomUiContext(
  InspectorValues doc,
  CardDeclaration card,
  CardCustomUi ui,
  CardParamNames names, {
  Map<String, Object?> state = const {},
}) {
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
  final sig = ui.liveSignal?.call();
  final extra = ui.contextExtra?.call();
  return jsonEncode({
    ...?extra,
    'card': card.name,
    'params': params,
    'ranges': ranges,
    'theme': panelThemeHexMap(),
    'state': state,
    'time': sig?.time ?? 0.0,
    'fps': sig?.fps ?? 60.0,
    'audio': sig?.audio ?? const <double>[],
    'waveform': sig?.waveform ?? const <double>[],
    'strikes': sig?.strikes ?? const <double>[],
  });
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
  CardCustomUi ui, {
  Map<String, Object?> state = const {},
}) {
  final names = CardParamNames(card);
  final ctxJson = buildCardCustomUiContext(doc, card, ui, names, state: state);
  final res = parseCardUiRenderResponse(ui.render(ctxJson));
  final hiddenFull = <String>{for (final h in res.hide) ?names.resolve(h)};
  return (
    result: res,
    hiddenFullIds: hiddenFull,
    ctxJson: ctxJson,
    names: names,
  );
}

/// Notifies open Vism cards when a card preset is saved or deleted.
final ValueNotifier<int> vismPresetsTick = ValueNotifier<int>(0);

/// Saves the current parameter values of [card] as a new Vism preset and returns its label.
String saveVismCardPreset(
  InspectorValues doc,
  CardDeclaration card,
  CardParamNames names,
) {
  final current = Map<String, Object?>.of(readPanelPresets(card.name));
  final snapshot = <String, Object?>{};
  for (final p in card.params) {
    final short = names.fullToShort[p.id] ?? p.id;
    final vid = 'v_${p.id}';
    if (doc.numbers.containsKey(vid)) {
      snapshot[short] = doc.numbers[vid];
    } else if (doc.strings.containsKey(vid)) {
      snapshot[short] = doc.strings[vid];
    }
  }
  var n = current.length + 1;
  var label = 'Preset $n';
  while (current.containsKey(label)) {
    n++;
    label = 'Preset $n';
  }
  current[label] = snapshot;
  writePanelPresets(card.name, current);
  vismPresetsTick.value++;
  return label;
}

/// Renders the custom JS UI body inside a [ValuesCard] and routes interactions
/// directly back to the card's document parameters (single source of truth).
/// Keeps ephemeral UI [state] for multi-handle drags and hot-reloads `.ui.js` on save.
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
  final _watcher = ScriptFileWatcher();
  final Map<String, Object?> _uiState = {};
  String? _actionError;
  CardUiRenderResult? _overrideResult;

  @override
  void initState() {
    super.initState();
    widget.doc.addListener(_onDocChanged);
    vismPresetsTick.addListener(_onPresetsChanged);
    _watchScript();
  }

  @override
  void didUpdateWidget(CustomCardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc != widget.doc) {
      oldWidget.doc.removeListener(_onDocChanged);
      widget.doc.addListener(_onDocChanged);
    }
    if (oldWidget.ui.uiFile != widget.ui.uiFile) {
      _uiState.clear();
      _actionError = null;
      _overrideResult = null;
      _watchScript();
    } else if (_uiState.isNotEmpty) {
      // Re-evaluate with the latest doc values while preserving ephemeral drag state.
      _reRenderNow(notify: false);
    } else {
      _overrideResult = null;
    }
  }

  @override
  void dispose() {
    widget.doc.removeListener(_onDocChanged);
    vismPresetsTick.removeListener(_onPresetsChanged);
    _watcher.dispose();
    super.dispose();
  }

  void _onPresetsChanged() {
    if (mounted) setState(() {});
  }

  void _onDocChanged() {
    if (!mounted) return;
    _reRenderNow(notify: true);
  }

  void _watchScript() {
    _watcher.watch(widget.ui.uiFile, () {
      if (!mounted) return;
      _actionError = null;
      _reRenderNow(notify: true);
    });
  }

  void _reRenderNow({required bool notify}) {
    final ctxJson = buildCardCustomUiContext(
      widget.doc,
      widget.card,
      widget.ui,
      widget.names,
      state: _uiState,
    );
    final res = parseCardUiRenderResponse(widget.ui.render(ctxJson));
    _overrideResult = res;
    if (notify && mounted) setState(() {});
  }

  String _fileLabel() {
    final f = widget.ui.uiFile;
    if (f.isEmpty) return widget.card.name;
    final slash = f.lastIndexOf('/');
    return slash >= 0 ? f.substring(slash + 1) : f;
  }

  void _onAction(String id, Object? value, {bool live = false}) {
    final doc = widget.doc;
    final ctxJson = buildCardCustomUiContext(
      doc,
      widget.card,
      widget.ui,
      widget.names,
      state: _uiState,
    );
    final actionJson = jsonEncode({'id': id, 'value': value, 'live': live});
    final act = parseCardUiActionResponse(
      widget.ui.action(actionJson, ctxJson),
    );
    if (act.error != null) {
      setState(() => _actionError = act.error);
      return;
    }
    if (_actionError != null) setState(() => _actionError = null);

    var stateChanged = false;
    if (act.state != null) {
      for (final e in act.state!.entries) {
        if (e.value == null) {
          stateChanged = _uiState.remove(e.key) != null || stateChanged;
        } else if (_uiState[e.key] != e.value) {
          _uiState[e.key] = e.value;
          stateChanged = true;
        }
      }
    }

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
    if (numWrites.isEmpty &&
        strWrites.isEmpty &&
        act.state == null &&
        act.ops.isEmpty) {
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
    if (act.ops.isNotEmpty || (act.notice != null && act.notice!.isNotEmpty)) {
      widget.ui.applyOps?.call(act.ops, act.notice);
      _reRenderNow(notify: true);
      return;
    }

    if (stateChanged) {
      _reRenderNow(notify: true);
    }
  }

  void _savePreset() {
    saveVismCardPreset(widget.doc, widget.card, widget.names);
  }

  void _applyPreset(Object? payload) {
    if (payload is! Map) return;
    final doc = widget.doc;
    final numWrites = <String, double>{};
    final strWrites = <String, String>{};
    for (final e in payload.entries) {
      final full = widget.names.resolve(e.key.toString());
      if (full == null) continue;
      if (e.value is num) {
        numWrites['v_$full'] = (e.value as num).toDouble();
      } else if (e.value is String) {
        strWrites['v_$full'] = e.value as String;
      }
    }
    if (numWrites.isNotEmpty) doc.setMany(numWrites);
    for (final e in strWrites.entries) {
      doc.str(e.key, e.value);
    }
    _reRenderNow(notify: true);
  }

  void _deletePreset(String label) {
    final current = Map<String, Object?>.of(readPanelPresets(widget.card.name));
    if (current.remove(label) != null) {
      writePanelPresets(widget.card.name, current);
      vismPresetsTick.value++;
    }
  }

  Widget? _presetStrip() {
    final presets = readPanelPresets(widget.card.name);
    if (presets.isEmpty) return null;
    return Padding(
      padding: EdgeInsets.only(top: Shape.s(6)),
      child: Wrap(
        spacing: Shape.s(4),
        runSpacing: Shape.s(4),
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final e in presets.entries)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Shape.s(6),
                vertical: Shape.s(2),
              ),
              decoration: BoxDecoration(
                color: InspectorSkin.well,
                borderRadius: Shape.round(4),
                border: Border.all(color: Grey.g26),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Pressable(
                    key: ValueKey('vism-preset:${widget.card.name}:${e.key}'),
                    onTap: () => _applyPreset(e.value),
                    builder: (_, hot) => Text(
                      e.key,
                      style: TextStyles.micro(hot ? Grey.g95 : Grey.g76),
                    ),
                  ),
                  SizedBox(width: Shape.s(4)),
                  Pressable(
                    key: ValueKey(
                      'vism-preset-del:${widget.card.name}:${e.key}',
                    ),
                    onTap: () => _deletePreset(e.key),
                    builder: (_, hot) => Text(
                      '×',
                      style: TextStyles.micro(hot ? Grey.g95 : Grey.g44),
                    ),
                  ),
                ],
              ),
            ),
          Pressable(
            key: ValueKey('vism-preset-save:${widget.card.name}'),
            onTap: _savePreset,
            builder: (_, hot) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: Shape.s(6),
                vertical: Shape.s(2),
              ),
              decoration: BoxDecoration(
                color: hot ? Grey.g20 : InspectorSkin.well,
                borderRadius: Shape.round(4),
                border: Border.all(color: Grey.g26),
              ),
              child: Text(
                '+',
                style: TextStyles.micro(hot ? Grey.g95 : Grey.g56),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _overrideResult ?? widget.result;
    final err = _actionError ?? active.error;
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
            CustomUiErrorBanner(
              error: err,
              fileLabel: _fileLabel(),
              onReload: () {
                _actionError = null;
                _reRenderNow(notify: true);
              },
            ),
            SizedBox(height: Shape.s(5)),
          ],
          if (active.root case final root?)
            PanelTreeView(
              node: root,
              baseFile: widget.ui.uiFile,
              onAction: _onAction,
            ),
          if (widget.card.params.isNotEmpty) ?_presetStrip(),
        ],
      ),
    );
  }
}
