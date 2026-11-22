// Hosts one `.js` custom panel inside ToolPanel: delegates QuickJS evaluation
// and document ops to custom_panel_service.dart.
// 詳細: docs/design/custom_panels.md
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
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
  String? _actionError;
  int _reloadTick = 0;

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
    final ctxJson = customPanelCtxJson(ws, _stateOf(ws));
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
    if (res.ops.isNotEmpty) {
      applyCustomPanelOps(ws, [
        for (final o in res.ops)
          (
            op: o.op,
            layer: o.layer,
            name: o.name,
            word: o.word,
            kind: o.kind,
            file: o.file,
            value: o.value,
            at: o.at,
            layers: o.layers,
          ),
      ]);
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
        customPanelCtxJson(ws, _stateOf(ws)),
      ),
    );
    final err = _actionError ?? renderRes.error;

    return ListView(
      padding: EdgeInsets.all(WindowTokens.gap),
      children: [
        if (err != null) ...[
          Container(
            padding: EdgeInsets.all(Shape.s(7)),
            decoration: BoxDecoration(
              color: InspectorSkin.well,
              borderRadius: Shape.round(5),
              border: Border.all(color: InspectorSkin.tonePlace),
            ),
            child: Text(err, style: TextStyles.micro(InspectorSkin.tonePlace)),
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
