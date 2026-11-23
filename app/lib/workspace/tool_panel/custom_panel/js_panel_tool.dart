// Hosts one `.js` custom panel inside ToolPanel: delegates QuickJS evaluation
// and document ops to custom_panel_service.dart.
// 詳細: docs/design/custom_panels.md
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/panel_presets_file.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/custom_ui/script_watch.dart';
import 'package:motolii/workspace/state/custom_panel_service.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/tool_panel/custom_panel/panel_node.dart';
import 'package:motolii/workspace/tool_panel/custom_panel/panel_renderer.dart';

/// Discovers JS custom panels from the open engine, or returns empty in headless tests.
List<PanelDescriptor> discoverJsPanels(WorkspaceController ws) =>
    parsePanelList(customPanelListRaw(ws));

/// Interactive ToolPanel body backed by a `.js` file evaluated in QuickJS.
class JsPanelTool extends StatefulWidget {
  const JsPanelTool(this.panel, {super.key});
  final PanelDescriptor panel;

  @override
  State<JsPanelTool> createState() => _JsPanelToolState();
}

class _JsPanelToolState extends State<JsPanelTool> {
  final _watcher = ScriptFileWatcher();
  String? _actionError;
  int _reloadTick = 0;

  @override
  void initState() {
    super.initState();
    _watchScript();
  }

  @override
  void didUpdateWidget(JsPanelTool oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.panel.path != widget.panel.path) {
      _actionError = null;
      _watchScript();
    }
  }

  @override
  void dispose() {
    _watcher.dispose();
    super.dispose();
  }

  void _watchScript() {
    _watcher.watch(widget.panel.path, () {
      if (!mounted) return;
      setState(() {
        _actionError = null;
        _reloadTick++;
      });
    });
  }

  String get _stateKey => 'panel.state:${widget.panel.path}';

  Map<String, Object?> _stateOf(WorkspaceController ws) {
    final raw = ws.view[_stateKey];
    return raw is Map<String, Object?> ? raw : const {};
  }

  void _onAction(
    WorkspaceController ws,
    String id,
    Object? value, {
    bool live = false,
  }) {
    if (!customPanelsReady(ws)) return;
    final presets = readPanelPresets(widget.panel.name);
    final ctxJson = customPanelCtxJson(ws, _stateOf(ws), presets: presets);
    final actionJson = jsonEncode({'id': id, 'value': value, 'live': live});
    final res = parsePanelActionResponse(
      customPanelAction(ws, widget.panel.path, actionJson, ctxJson),
    );
    if (res.error != null) {
      setState(() => _actionError = res.error);
      return;
    }
    if (_actionError != null) setState(() => _actionError = null);
    if (res.state != null) {
      ws.setView(_stateKey, Map<String, Object?>.of(res.state!));
    }
    if (res.notice != null && res.notice!.isNotEmpty) {
      ws.notice = res.notice;
    }
    var presetsChanged = false;
    final nextPresets = Map<String, Object?>.of(presets);
    for (final o in res.ops) {
      if (o.op == 'preset_save' && o.name.isNotEmpty) {
        try {
          nextPresets[o.name] = jsonDecode(o.word);
        } catch (_) {
          nextPresets[o.name] = o.word;
        }
        presetsChanged = true;
      } else if (o.op == 'preset_delete' && o.name.isNotEmpty) {
        nextPresets.remove(o.name);
        presetsChanged = true;
      }
    }
    if (presetsChanged) {
      writePanelPresets(widget.panel.name, nextPresets);
      setState(() {});
    }
    if (res.ops.isNotEmpty) {
      applyCustomPanelOps(ws, [for (final o in res.ops) panelDocOpOf(o)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {
      WorkspaceAspect.document,
      WorkspaceAspect.picked,
      WorkspaceAspect.view,
    });
    if (!customPanelsReady(ws)) {
      return Center(
        child: Text(
          'Open a project to run panels',
          style: TextStyles.micro(Grey.g56),
        ),
      );
    }

    // Read _reloadTick so manual Reload forces a fresh disk read & QuickJS eval.
    final _ = _reloadTick;
    final renderRes = parsePanelRenderResponse(
      customPanelRender(
        ws,
        widget.panel.path,
        customPanelCtxJson(
          ws,
          _stateOf(ws),
          presets: readPanelPresets(widget.panel.name),
        ),
      ),
    );
    final err = _actionError ?? renderRes.error;

    return ListView(
      padding: EdgeInsets.all(WindowTokens.gap),
      children: [
        if (err != null) ...[
          CustomUiErrorBanner(
            error: err,
            fileLabel: widget.panel.name,
            onReload: () => setState(() {
              _actionError = null;
              _reloadTick++;
            }),
          ),
          SizedBox(height: Shape.s(6)),
        ],
        if (renderRes.root case final root?)
          PanelTreeView(
            node: root,
            onAction: (id, value, {live = false}) =>
                _onAction(ws, id, value, live: live),
          ),
        SizedBox(height: Shape.s(8)),
        Row(
          children: [
            if (widget.panel.about.isNotEmpty)
              Expanded(
                child: Text(
                  widget.panel.about,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.micro(Grey.g44),
                ),
              )
            else
              const Spacer(),
            SizedBox(width: Shape.s(6)),
            Pressable(
              key: ValueKey('panel:reload:${widget.panel.name}'),
              onTap: () => setState(() {
                _actionError = null;
                _reloadTick++;
              }),
              builder: (_, hot) => Text(
                'Reload',
                style: TextStyles.micro(hot ? Grey.g95 : Grey.g56),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
