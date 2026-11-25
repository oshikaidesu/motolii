// The Agent pane: any agent of the ACP registry, chosen in a list like a shelf, writing the code a layer runs.
// Zed's agent panel is the model: every agent equal, one dense column of what was said and done.
// It is drawn with the app's own parts: PanelHeader, the shelf's search field (also the message field), DockHover
// rows, the skin's Forms for the agent's questions. A reply is Markdown, laid out by flutter_markdown_plus (BSD-3,
// the Flutter authors' flutter_markdown carried on) in the app's text styles.
import 'dart:convert' show base64Decode, jsonEncode;

import 'package:acpd/acpd.dart'
    show
        ContentBlock,
        PlanEntry,
        PlanEntryStatus,
        RequestPermissionRequest,
        ResourceLink;
import 'package:acpd_io/acpd_io.dart' show AcpAgentConfig;
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/disk.dart' show modifiedOf;
import 'package:motolii/storage/folder_files.dart';
import 'package:motolii/storage/open_in_host.dart' show pickFile;
import 'package:motolii/storage/script_files.dart' show textOf;
import 'package:motolii/storage/shelf_disk.dart' show writeText;
import 'package:motolii/widgets/custom_ui/panel_node.dart'
    show parsePanelOpsJson;
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/workspace/agent/acp_chat_session.dart';
import 'package:motolii/workspace/agent/agent_registry.dart';
import 'package:motolii/workspace/agent/agent_composer.dart';
import 'package:motolii/workspace/agent/agent_sign_in.dart' show signInCard;
import 'package:motolii/workspace/agent/layer_code.dart';
import 'package:motolii/workspace/agent/magpie.dart';
import 'package:motolii/workspace/dock/common/shelf_search_field.dart';
import 'package:motolii/workspace/shelf/empty_effect.dart' show putEffectFile;
import 'package:motolii/workspace/shelf/tile_hover.dart';
import 'package:motolii/workspace/state/custom_panel_service.dart'
    show
        applyCustomPanelOps,
        openVismPanelInDock,
        panelDocOpOf,
        reloadAgentShelves,
        writeAgentSceneSnapshot;
import 'package:motolii/workspace/state/motolii_mcp_bridge.dart';
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/document/expression_engine.dart';
import 'package:motolii/workspace/state/layer.dart' show LayerKind;
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// Multi-session conversations outlive the pane when docked tabs rebuild.
final _sessions = ValueNotifier<List<AcpChatSession>>([]);
final _activeIndex = ValueNotifier<int>(0);

AcpChatSession? _currentTalk() {
  final list = _sessions.value;
  if (list.isEmpty) return null;
  final idx = _activeIndex.value.clamp(0, list.length - 1);
  return list[idx];
}

class AgentPane extends StatefulWidget {
  const AgentPane({super.key});
  @override
  State<AgentPane> createState() => _AgentPaneState();
}

class _AgentPaneState extends State<AgentPane> {
  late final _agents = agentRegistry(ownFolder());
  final _find = TextEditingController(), _say = TextEditingController();
  final _attachments = <String>[];
  final _expandedThoughts = <int>{};
  var _choosing = false;
  var _addingThread = false;

  @override
  void dispose() {
    _find.dispose();
    _say.dispose();
    super.dispose();
  }

  Future<void> _choose(AgentEntry a) async {
    final ws = WorkspaceScope.read(context);
    final mcp = await MotoliiMcpBridge.instance.ensureServer(ws);
    if (!mounted) return;
    final c = a.config;
    final extraDirs = <String>[
      if (ws.documentFolder case final df? when df.isNotEmpty) df,
      shelvesFolder(),
    ];
    final session = AcpChatSession(
      a.name,
      AcpAgentConfig(
        command: c.command,
        args: c.args,
        env: c.env,
        workingDirectory: ownFolder(),
      ),
      ownFolder(),
      line: a.line,
      env: a.env,
      mcpServers: [?mcp],
      additionalDirectories: extraDirs,
    )..start();
    final list = [..._sessions.value];
    if (_addingThread || list.isEmpty) {
      list.add(session);
      _sessions.value = list;
      _activeIndex.value = list.length - 1;
    } else {
      final idx = _activeIndex.value.clamp(0, list.length - 1);
      list[idx].dispose();
      list[idx] = session;
      _sessions.value = list;
    }
    setState(() {
      _choosing = false;
      _addingThread = false;
    });
  }

  void _closeSession(int idx) {
    final list = [..._sessions.value];
    if (idx < 0 || idx >= list.length) return;
    list.removeAt(idx).dispose();
    _sessions.value = list;
    if (list.isEmpty) {
      _activeIndex.value = 0;
    } else if (_activeIndex.value >= list.length) {
      _activeIndex.value = list.length - 1;
    }
    setState(() {});
  }

  Future<void> _pickAttachment() async {
    final path = await pickFile(prompt: 'Attach file or reference image');
    if (path != null && mounted && !_attachments.contains(path)) {
      setState(() => _attachments.add(path));
    }
  }

  /// Sends [text] with the full scene snapshot (`scene.json` + `stage.png`),
  /// user-attached images/files, and the selected layer's cards/code.
  Future<void> _send(AcpChatSession talk, String text) async {
    if (!talk.ready || talk.sending || text.trim().isEmpty) return;
    _say.clear();
    final attachments = [..._attachments];
    if (_attachments.isNotEmpty) setState(() => _attachments.clear());
    final ws = WorkspaceScope.read(context), code = layerCode(ws);
    MotoliiMcpBridge.instance.attach(ws);
    final fresh = newFolder();
    final more = projectOpen(ws)
        ? await ownedFor(
            ws,
            code,
            fresh,
            supportsImage: talk.supportsImage,
            hasMcp: talk.mcpServers.isNotEmpty,
            attachments: attachments,
          )
        : const <ContentBlock>[];
    DateTime? time(String f) => modifiedOf(f);
    final opsFile = '$fresh/ops.json';
    final opsResultFile = '$fresh/ops_result.json';
    final sceneFile = '$fresh/scene.json';
    final stageFile = '$fresh/stage.png';
    DateTime? opsSeen = time(opsFile);
    String? opsAppliedRaw;
    final opsOwnedFiles = <String>{};
    final seen = <String, DateTime?>{
      for (final b in more)
        if (b is ResourceLink)
          Uri.parse(b.uri).toFilePath(): time(Uri.parse(b.uri).toFilePath()),
    };
    talk.settled = ({required bool turnEnded}) {
      // Apply ops.json only once at turn end (never mid-turn on incremental edits,
      // which previously duplicated `add` layers across repeated file writes).
      if (turnEnded && time(opsFile) != null && time(opsFile) != opsSeen) {
        opsSeen = time(opsFile);
        try {
          final raw = textOf(opsFile);
          if (raw != opsAppliedRaw) {
            opsAppliedRaw = raw;
            final parsed = parsePanelOpsJson(raw);
            if (parsed.error != null) {
              writeText(
                opsResultFile,
                jsonEncode({'ok': false, 'error': parsed.error}),
              );
              talk.tell('ops.json error: ${parsed.error}');
            } else if (parsed.ops.isNotEmpty) {
              for (final o in parsed.ops) {
                if (o.op == 'fx' && o.file.isNotEmpty) {
                  opsOwnedFiles.add(o.file);
                  seen[o.file] = time(o.file);
                }
              }
              applyCustomPanelOps(
                ws,
                [for (final o in parsed.ops) panelDocOpOf(o)],
                onDone: (done, why) {
                  final fps = WorkspaceController.fps > 0
                      ? WorkspaceController.fps
                      : 60;
                  writeText(
                    opsResultFile,
                    jsonEncode({
                      'ok': done,
                      'applied': done ? parsed.ops.length : 0,
                      if (!done)
                        'error': why.trim().isEmpty
                            ? 'Operation refused by engine (undo group rolled back).'
                            : why.trim(),
                      'layerCount': ws.layers.length,
                      'frame': ws.frame,
                      'time': ws.frame / fps,
                    }),
                  );
                  if (!done) {
                    talk.tell(
                      'ops.json refused (all ops rolled back): '
                      '${why.trim().isEmpty ? 'invalid property or value' : why.trim()}',
                    );
                    return;
                  }
                  if (parsed.notice != null && parsed.notice!.isNotEmpty) {
                    ws.notice = parsed.notice;
                  }
                  if (!mounted) return;
                  Future<void>.delayed(const Duration(milliseconds: 120), () {
                    if (!mounted) return;
                    writeAgentSceneSnapshot(ws, fresh);
                    seen[sceneFile] = time(sceneFile);
                    seen[stageFile] = time(stageFile);
                  });
                },
              );
            }
          }
        } catch (e) {
          talk.tell('ops.json could not be read: $e');
        }
      }
      for (final f in filesIn(fresh)) {
        if (f == opsFile ||
            f == opsResultFile ||
            f == sceneFile ||
            f == stageFile) {
          continue;
        }
        if (opsOwnedFiles.contains(f)) continue;
        if (!seen.containsKey(f)) {
          seen[f] = time(f);
          _handleNewFile(ws, talk, code != null, f);
        }
      }
      for (final f in seen.keys.toList()) {
        if (f == sceneFile ||
            f == stageFile ||
            f == opsFile ||
            f == opsResultFile) {
          continue;
        }
        if (time(f) case final t when t != seen[f]) {
          seen[f] = t;
          _read(ws, talk, f);
        }
      }
    };
    final noteParts = [
      situationSummary(ws),
      if (attachments.isNotEmpty)
        '+ ${attachments.map((p) => p.split('/').last).join(', ')}',
    ];
    talk.send(text, more: more, note: noteParts.join(' · '));
  }

  /// Handles a newly written file without mis-attaching `.ui.js` cards or Vism panels.
  void _handleNewFile(
    WorkspaceController ws,
    AcpChatSession talk,
    bool hasLayer,
    String file,
  ) {
    if (file.endsWith('.ui.js') || file.endsWith('.way')) {
      reloadAgentShelves(ws);
      return;
    }
    if (file.contains('/panels/') && file.endsWith('.js')) {
      openVismPanelInDock(ws, path: file);
      ws.reread();
      return;
    }
    if (hasLayer) _put(ws, talk, file);
  }

  /// Puts a new file the agent wrote on the selected layer, as the Effects shelf puts an empty one (empty_effect.dart).
  void _put(WorkspaceController ws, AcpChatSession talk, String file) {
    if (!RegExp(r'\.(wgsl|fs|js|css|am|mjs)$').hasMatch(file)) return;
    putEffectFile(
      ws,
      file,
      expression: file.endsWith('.js') || file.endsWith('.css'),
      told: (why) {
        if (why.isNotEmpty) {
          talk.tell(
            '${file.split('/').last} was not put on the layer: ${why.trim()}',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    MotoliiMcpBridge.instance.attach(WorkspaceScope.read(context));
    return ListenableBuilder(
      listenable: Listenable.merge([_sessions, _activeIndex]),
      builder: (context, _) {
        final sessions = _sessions.value;
        final talk = _currentTalk();
        return ListenableBuilder(
          listenable: Listenable.merge([?talk, _find]),
          builder: (context, _) {
            final listing = talk == null || _choosing;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PanelHeader(
                  talk?.agentName ?? 'Agent',
                  trailing: [
                    if (talk != null && !_choosing)
                      _link('+ New', () {
                        setState(() {
                          _addingThread = true;
                          _choosing = true;
                        });
                      }),
                    if (talk != null)
                      _link(_choosing ? 'Back' : 'Agents', () {
                        setState(() {
                          _addingThread = false;
                          _choosing = !_choosing;
                        });
                      }),
                  ],
                ),
                if (sessions.length > 1 && !listing) _sessionBar(sessions),
                if (listing) ...[
                  if (talk == null) _intro(choose: true),
                  ShelfSearchField(controller: _find, hint: 'Search agents'),
                  Expanded(child: _list()),
                ] else ...[
                  if (talk.needsSignIn)
                    signInCard(
                      context,
                      talk,
                      onSwitchAgent: () => setState(() => _choosing = true),
                    ),
                  if (talk.plan.isNotEmpty) _planBar(talk.plan),
                  Expanded(child: _conversation(talk)),
                  if (talk.asked case final r?) _question(context, talk, r),
                  _with(context, talk),
                  AgentComposer(
                    talk: talk,
                    controller: _say,
                    attachments: _attachments,
                    onAttach: _pickAttachment,
                    onRemoveAttachment: (p) =>
                        setState(() => _attachments.remove(p)),
                    onSend: (t) => _send(talk, t),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _sessionBar(List<AcpChatSession> sessions) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: WindowTokens.inset,
      vertical: Shape.s(3),
    ),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: WindowTokens.line)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, s) in sessions.indexed) ...[
            if (i > 0) SizedBox(width: Shape.s(4)),
            GestureDetector(
              onTap: () => _activeIndex.value = i,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Shape.s(6),
                  vertical: Shape.s(2),
                ),
                decoration: BoxDecoration(
                  color: i == _activeIndex.value
                      ? WindowTokens.card
                      : WindowTokens.well,
                  borderRadius: Shape.round(WindowTokens.chipRadius),
                  border: Border.all(
                    color: i == _activeIndex.value
                        ? Accent.fill
                        : WindowTokens.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${s.agentName} #${i + 1}',
                      style: TextStyles.micro(
                        i == _activeIndex.value ? Grey.g95 : Grey.g63,
                      ),
                    ),
                    SizedBox(width: Shape.s(4)),
                    GestureDetector(
                      onTap: () => _closeSession(i),
                      child: Text('×', style: TextStyles.micro(Grey.g56)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _planBar(List<PlanEntry> entries) => Container(
    margin: EdgeInsets.fromLTRB(
      WindowTokens.inset,
      Shape.s(6),
      WindowTokens.inset,
      0,
    ),
    padding: EdgeInsets.all(Shape.s(6)),
    decoration: BoxDecoration(
      color: WindowTokens.well,
      borderRadius: Shape.round(WindowTokens.radius),
      border: Border.all(color: WindowTokens.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in entries.take(6))
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(2)),
            child: Row(
              children: [
                Text(
                  switch (p.status) {
                    PlanEntryStatus.completed => '✓ ',
                    PlanEntryStatus.inProgress => '● ',
                    PlanEntryStatus.pending => '○ ',
                  },
                  style: TextStyles.micro(
                    p.status == PlanEntryStatus.completed
                        ? Accent.ink
                        : p.status == PlanEntryStatus.inProgress
                        ? Accent.fill
                        : Grey.g56,
                  ),
                ),
                Expanded(
                  child: Text(
                    p.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.micro(
                      p.status == PlanEntryStatus.completed
                          ? Grey.g56
                          : Grey.g91,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  /// Has the engine read a file the agent wrote, including `.ui.js` cards and Vism panels.
  void _read(WorkspaceController ws, AcpChatSession talk, String file) {
    if (file.endsWith('.ui.js') ||
        file.endsWith('.way') ||
        (file.contains('/panels/') && file.endsWith('.js'))) {
      reloadAgentShelves(ws);
      return;
    }
    if (!RegExp(r'\.(wgsl|fs|js|css|am|mjs)$').hasMatch(file)) return;
    readCodeFile(ws, file, (done, why) {
      if (!done) {
        talk.tell('${file.split('/').last} does not run: ${why.trim()}');
      }
      ws.reread();
    });
  }

  /// What a request will carry: current editing situation (selection, focus, playhead, BPM).
  Widget _with(BuildContext context, AcpChatSession talk) {
    final ws = WorkspaceScope.of(context, {
      WorkspaceAspect.picked,
      WorkspaceAspect.document,
      WorkspaceAspect.layers,
      WorkspaceAspect.structure,
    });
    return ListenableBuilder(
      listenable: ws.playhead.moment,
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(
          WindowTokens.inset,
          Shape.s(6),
          WindowTokens.inset,
          0,
        ),
        // The magpie is the agent's face: it hops while the agent works, which Stop in the header also says.
        child: Row(
          children: [
            Magpie(dot: Shape.s(2), hopping: talk.sending),
            SizedBox(width: Shape.s(6)),
            Expanded(
              child: Text(
                situationSummary(ws),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.label(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _link(String label, VoidCallback onTap) => DockHover(
    onTap: onTap,
    builder: (context, h) => Padding(
      padding: EdgeInsets.only(left: Shape.s(10)),
      child: Text(label, style: TextStyles.label(h ? Grey.g95 : Grey.g63)),
    ),
  );

  Widget _list() => FutureBuilder(
    future: _agents,
    builder: (context, list) {
      if (!list.hasData) return _note('Reading the ACP registry');
      final word = _find.text.toLowerCase();
      final shown = [
        for (final a in list.data!)
          if (a.name.toLowerCase().contains(word) ||
              a.description.toLowerCase().contains(word))
            a,
      ];
      if (list.data!.isEmpty) {
        return _note('No agent list: offline, and never read before');
      }
      if (shown.isEmpty) return _note('No matching agents');
      final ready = [
        for (final a in shown)
          if (a.installed) a,
      ];
      final rest = [
        for (final a in shown)
          if (!a.installed) a,
      ];
      return ListView(
        padding: EdgeInsets.symmetric(vertical: Shape.s(2)),
        children: [
          if (ready.isNotEmpty) ...[
            _section('INSTALLED', ready.length),
            for (final a in ready) _agentRow(a),
          ],
          if (rest.isNotEmpty) ...[
            if (ready.isNotEmpty) SizedBox(height: Shape.s(6)),
            _section(ready.isNotEmpty ? 'REGISTRY' : 'ALL AGENTS', rest.length),
            for (final a in rest) _agentRow(a),
          ],
        ],
      );
    },
  );

  Widget _section(String title, int count) => Padding(
    padding: EdgeInsets.fromLTRB(
      WindowTokens.inset,
      Shape.s(4),
      WindowTokens.inset,
      Shape.s(2),
    ),
    child: Row(
      children: [
        Text(
          title,
          style: TextStyles.micro(Grey.g56)
              .copyWith(fontWeight: FontWeight.w700, letterSpacing: .4),
        ),
        SizedBox(width: Shape.s(4)),
        Text('$count', style: TextStyles.micro(Grey.g44)),
      ],
    ),
  );

  Widget _agentRow(AgentEntry a) => DockHover(
    onTap: () => _choose(a),
    builder: (context, h) => Container(
      color: h ? WindowTokens.card : null,
      padding: EdgeInsets.symmetric(
        horizontal: WindowTokens.inset,
        vertical: Shape.s(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: Shape.z(6),
                height: Shape.z(6),
                decoration: BoxDecoration(
                  color: a.installed ? Accent.fill : Grey.g38,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: Shape.s(6)),
              Expanded(
                child: Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.name(
                    h ? Grey.g100 : Grey.g91,
                  ).copyWith(fontWeight: a.installed ? FontWeight.w600 : null),
                ),
              ),
              if (a.installed || a.method.isNotEmpty) ...[
                SizedBox(width: Shape.s(6)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Shape.s(5),
                    vertical: Shape.s(1),
                  ),
                  decoration: BoxDecoration(
                    color: a.installed
                        ? WindowTokens.accent
                        : WindowTokens.well,
                    borderRadius: Shape.round(WindowTokens.chipRadius),
                  ),
                  child: Text(
                    a.installed ? 'ready' : a.method,
                    style:
                        TextStyles.micro(
                          a.installed ? WindowTokens.onAccent : Grey.g56,
                        ).copyWith(
                          fontSize: TextStyles.px(9),
                          fontWeight: a.installed ? FontWeight.w700 : null,
                        ),
                  ),
                ),
              ],
            ],
          ),
          if (a.description.isNotEmpty) ...[
            SizedBox(height: Shape.s(2)),
            Padding(
              padding: EdgeInsets.only(left: Shape.z(6) + Shape.s(6)),
              child: Text(
                a.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.micro(Grey.g56),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _note(String s) => Padding(
    padding: EdgeInsets.all(WindowTokens.inset),
    child: Text(s, style: TextStyles.label()),
  );

  /// What was said, newest at the bottom, kept in view as it grows.
  /// What the pane is for, under the magpie: shown before an agent is chosen and while nothing has been said.
  Widget _intro({bool choose = false}) => Padding(
    padding: EdgeInsets.all(WindowTokens.inset),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Magpie(),
        SizedBox(height: Shape.s(10)),
        for (final line in [
          'Ask in a few words — your selection, playhead, focus group, and whole scene are sent automatically.',
          'Bounce ideas and get feedback on your cut, or ask to build animations, shaders, expressions, and custom Vism panels.',
          if (choose)
            'Choose an agent below. Every agent of the ACP registry works the '
                'same way.',
        ])
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(4)),
            child: Text(line, style: TextStyles.name(Grey.g76, 11, null, 1.4)),
          ),
      ],
    ),
  );

  Widget _conversation(AcpChatSession talk) => talk.entries.isEmpty
      ? SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _intro(),
              Builder(
                builder: (context) {
                  final ws = WorkspaceScope.of(context, {
                    WorkspaceAspect.picked,
                    WorkspaceAspect.structure,
                  });
                  return AgentStarterPrompts(
                    prompts: startersFor(ws),
                    onPick: (prompt) {
                      if (talk.ready && !talk.sending) {
                        _send(talk, prompt);
                      } else {
                        _say.text = prompt;
                        _say.selection = TextSelection.collapsed(
                          offset: prompt.length,
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        )
      : ListView(
          reverse: true,
          padding: EdgeInsets.all(WindowTokens.inset),
          children: [
            for (final (i, e) in talk.entries.indexed.toList().reversed)
              Padding(
                padding: EdgeInsets.only(top: Shape.s(8)),
                child: _line(talk, i, e),
              ),
          ],
        );

  Widget _line(AcpChatSession talk, int index, Entry e) => switch (e.who) {
    Said.you => Container(
      padding: EdgeInsets.all(Shape.s(6)),
      decoration: BoxDecoration(
        color: WindowTokens.card,
        borderRadius: Shape.round(WindowTokens.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.text, style: TextStyles.name(Grey.g95, 11, null, 1.4)),
          if (e.note.isNotEmpty) ...[
            SizedBox(height: Shape.s(4)),
            Text(e.note, style: TextStyles.label()),
          ],
        ],
      ),
    ),
    Said.agent => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (e.text.isNotEmpty)
          MarkdownBody(data: e.text, styleSheet: _markdown),
        if (e.imageBase64 case final b64?)
          Padding(
            padding: EdgeInsets.only(top: Shape.s(4)),
            child: ClipRRect(
              borderRadius: Shape.round(WindowTokens.radius),
              child: Image.memory(base64Decode(b64), fit: BoxFit.contain),
            ),
          ),
      ],
    ),
    Said.thought => GestureDetector(
      onTap: () => setState(() {
        if (!_expandedThoughts.remove(index)) _expandedThoughts.add(index);
      }),
      child: Container(
        padding: EdgeInsets.all(Shape.s(5)),
        decoration: BoxDecoration(
          color: WindowTokens.well,
          borderRadius: Shape.round(WindowTokens.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _expandedThoughts.contains(index) ? '▾ Thinking' : '▸ Thinking',
              style: TextStyles.micro(Grey.g56),
            ),
            if (_expandedThoughts.contains(index)) ...[
              SizedBox(height: Shape.s(3)),
              Text(e.text, style: TextStyles.micro(Grey.g63)),
            ],
          ],
        ),
      ),
    ),
    Said.tool => _tool(e.call),
    Said.error => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(e.text, style: TextStyles.name(Role.error, 11, null, 1.4)),
        SizedBox(height: Shape.s(6)),
        Wrap(
          spacing: Shape.s(6),
          runSpacing: Shape.s(6),
          children: [
            if (talk.ready && !talk.sending)
              Forms.worn.action(
                context,
                ActionSpec(
                  'Fix with agent',
                  () => _send(
                    talk,
                    'Motolii reported an error — please inspect and fix it:\n${e.text}',
                  ),
                ),
              ),
            if (!talk.ready && !talk.starting) ...[
              Forms.worn.action(
                context,
                ActionSpec('Retry', () => talk.retry()),
              ),
              Forms.worn.action(
                context,
                ActionSpec(
                  'Switch Agent',
                  () => setState(() => _choosing = true),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  };

  /// A tool call as one row: its state as a dot, its title and the files it touched; under it, a diff's lines.
  Widget _tool(Map<String, Object?> call) {
    final status = '${call['status'] ?? ''}';
    final dot = switch (status) {
      'completed' => Accent.fill,
      'failed' => Role.error,
      _ => Grey.g56,
    };
    final files = [
      for (final l in (call['locations'] as List?) ?? const [])
        '${(l as Map)['path']}'.split('/').last,
    ];
    final diffs = [
      for (final c in (call['content'] as List?) ?? const [])
        if ((c as Map)['type'] == 'diff') c,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            SizedBox(width: Shape.s(6)),
            Flexible(
              child: Text(
                '${call['title'] ?? call['kind'] ?? 'Tool'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.name(Grey.g91),
              ),
            ),
            if (files.isNotEmpty) ...[
              SizedBox(width: Shape.s(6)),
              Text(files.toSet().join(', '), style: TextStyles.label()),
            ],
          ],
        ),
        for (final d in diffs)
          _diff('${d['oldText'] ?? ''}', '${d['newText'] ?? ''}'),
      ],
    );
  }

  /// The lines a diff took out and put in, at most twelve. Lines are compared as sets, not in order.
  Widget _diff(String was, String now) {
    final before = was.split('\n').toSet(), after = now.split('\n').toSet();
    final lines = [
      for (final l in before.difference(after)) ('- ', l, Role.error),
      for (final l in after.difference(before)) ('+ ', l, Accent.ink),
    ];
    return Container(
      margin: EdgeInsets.only(top: Shape.s(4), left: Shape.s(12)),
      padding: EdgeInsets.all(Shape.s(4)),
      color: WindowTokens.well,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (mark, l, c) in lines.take(12))
            Text(
              '$mark$l',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.value(c),
            ),
          if (lines.length > 12)
            Text('${lines.length - 12} more lines', style: TextStyles.label()),
        ],
      ),
    );
  }

  /// What the agent asks leave for, with its own answers as the skin's buttons.
  Widget _question(
    BuildContext context,
    AcpChatSession talk,
    RequestPermissionRequest r,
  ) => Container(
    margin: EdgeInsets.symmetric(horizontal: WindowTokens.inset),
    padding: EdgeInsets.all(Shape.s(6)),
    color: WindowTokens.card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.toolCall.title ?? 'The agent asks',
          style: TextStyles.name(Grey.g95),
        ),
        SizedBox(height: Shape.s(6)),
        Wrap(
          spacing: Shape.s(6),
          runSpacing: Shape.s(6),
          children: [
            for (final o in r.options)
              Forms.worn.action(
                context,
                ActionSpec(o.name, () => talk.answer(o.optionId)),
              ),
          ],
        ),
      ],
    ),
  );

  MarkdownStyleSheet get _markdown {
    final body = TextStyles.name(Grey.g91, 11, null, 1.45);
    final block = BoxDecoration(
      color: WindowTokens.well,
      borderRadius: Shape.round(WindowTokens.radius),
    );
    return MarkdownStyleSheet(
      p: body,
      listBullet: body,
      tableBody: body,
      tableHead: body.bold,
      h1: TextStyles.title(),
      h2: TextStyles.title(),
      h3: TextStyles.name(Grey.g95, 11, FontWeight.w700),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      em: const TextStyle(fontStyle: FontStyle.italic),
      a: TextStyle(color: Accent.ink),
      code: TextStyles.value(Grey.g95)
          .copyWith(backgroundColor: WindowTokens.well),
      codeblockDecoration: block,
      codeblockPadding: EdgeInsets.all(Shape.s(6)),
      blockquoteDecoration: block,
      blockquotePadding: EdgeInsets.all(Shape.s(6)),
      blockSpacing: Shape.s(6),
    );
  }
}

/// Starter prompts shown before the first message so a new user can try Motolii's ACP workflow in one click.
typedef AgentStarter = ({String id, String title, String prompt});

const agentStarterPrompts = <AgentStarter>[
  (
    id: 'jp-wave',
    title: '波打つ日本語タイトル',
    prompt: '選択中レイヤーのテキストが1文字ずつ波打つエクスプレッションを作って',
  ),
  (
    id: 'custom-card',
    title: 'カスタムカード付きエフェクト',
    prompt: '選択中レイヤーにグリッチ風シェーダー（.fs）とカスタム操作カード（.ui.js）を作って',
  ),
  (
    id: 'audio-bounce',
    title: '音に反応して弾む動き',
    prompt: '音声の音量に合わせて選択中レイヤーが弾むエクスプレッションを作って',
  ),
  (
    id: 'tool-panel',
    title: 'Tool Panel 用ツール',
    prompt: '選択中レイヤーを整列・複製する QuickJS ツールパネル（shelves/panels/）を作って',
  ),
];

/// Returns context-aware starter prompts tailored to what the user is editing right now.
List<AgentStarter> startersFor(WorkspaceController ws) {
  if (!projectOpen(ws) || ws.layers.isEmpty) {
    return const [
      (
        id: 'empty-brainstorm',
        title: '作品の方向性を相談する',
        prompt: 'これから作る映像の構成や演出の方向性を一緒に壁打ちしたい。いくつか面白そうな切り口を提案して（まだシーンは作らなくてOK）',
      ),
      (
        id: 'empty-title',
        title: 'タイトル演出をゼロから組む',
        prompt: '今いる時刻から4秒の日本語タイトルイントロを、背景・光・気持ちいい登場モーション付きで作って',
      ),
      (
        id: 'empty-3d-phys',
        title: '3D＋物理で弾むシーン',
        prompt: '3Dガラスオブジェクトとライト・カメラを置いて、ビートに合わせて物理で弾むシーンを作って',
      ),
      (
        id: 'empty-vism',
        title: '専用 Vism パネルを生やす',
        prompt: 'カメラワークやエフェクトをぐりぐり操作できる専用 Vism パネルを作ってドッキング表示して',
      ),
    ];
  }
  if (ws.stretches.isNotEmpty) {
    return const [
      (
        id: 'ease-overshoot',
        title: 'この動きを気持ちよく弾ませる',
        prompt: '今選んでいる区間の動きに、キレのあるオーバーシュートと余韻を付けて',
      ),
      (
        id: 'ease-follow',
        title: '他レイヤーを遅延追従させる',
        prompt: 'この動きに合わせて関連レイヤーが少し遅れて追従する式を付けて',
      ),
      ...agentStarterPrompts,
    ].take(4).toList();
  }
  if (ws.isolatedGroup != null) {
    return const [
      (
        id: 'focus-rig',
        title: 'このグループを自動リグ',
        prompt: 'フォーカス中のグループ内のパーツに適切な pivot と親子関係、遅延揺れエクスプレッションを組んで',
      ),
      (
        id: 'focus-picker',
        title: '専用リグ操作 Vism パネル',
        prompt: 'このグループを直感的に動かせる専用 Vism パネル（ボディピッカー＆表情プリセット）を作って開いて',
      ),
      (
        id: 'focus-motion',
        title: '自然な待機＆反応モーション',
        prompt: 'このグループに呼吸や揺れなどの自然なループモーションを付けて',
      ),
      (
        id: 'focus-check',
        title: 'パーツのズレを視覚チェック',
        prompt: '複数フレームを描画して、関節のズレや重なり順の破綻があれば直して',
      ),
    ];
  }
  if (ws.many.length > 1) {
    return const [
      (
        id: 'multi-stagger',
        title: '順番にずらして登場させる',
        prompt: '選択中のレイヤーを今の再生位置から順番に気持ちよくスタガー登場させて',
      ),
      (
        id: 'multi-rig',
        title: '親子＆連動リグを組む',
        prompt: '選択中のレイヤーを先頭リーダーに連動する親子・遅延追従リグにして',
      ),
      (
        id: 'multi-panel',
        title: '一括操作 Vism パネルを作る',
        prompt: '選択中のレイヤー群をまとめて操作できる専用 Vism パネルを作って開いて',
      ),
      (
        id: 'multi-layout',
        title: 'レイアウトと重なりを整える',
        prompt: '選択中のレイヤーの配置・サイズ・バランスを画面に気持ちよく整えて',
      ),
    ];
  }
  final sel = ws.layer;
  if (sel != null && sel.kind == LayerKind.text) {
    return const [
      (
        id: 'text-critique',
        title: 'この文字の演出を相談する',
        prompt: '今のテキストの見た目・配置・視認性を見て、もっと映える演出案を3つ提案して（まだ変更しないで）',
      ),
      (
        id: 'text-wave',
        title: '1文字ずつ波打つ演出',
        prompt: 'このテキストが今の再生位置から1文字ずつ波打って登場する式を付けて',
      ),
      (
        id: 'text-gg',
        title: 'GG 輪郭分解×ビート登場',
        prompt: 'このテキストを strokes で輪郭パーツ分解して、リズムに合わせて弾け飛ぶ登場演出にして',
      ),
      (
        id: 'text-card',
        title: 'カスタムカード付きエフェクト',
        prompt: 'このテキストに専用シェーダーと Vism 操作カード（.ui.js）を付けて',
      ),
    ];
  }
  return const [
    (
      id: 'scene-critique',
      title: '今のカットを相談・講評してもらう',
      prompt: '今のシーンの見た目・テンポ・構成を見て、良くなっている点ともう一段良くする具体的な演出案を3つ提案して（まだ変更しないで）',
    ),
    (
      id: 'scene-next-cut',
      title: 'ここからの展開を一緒に考える',
      prompt: '今の再生位置から次にどう繋ぐと気持ちいいか、Motoliiの表現を活かした展開案を一緒に考えて',
    ),
    (
      id: 'custom-card',
      title: 'カスタムカード付きエフェクト',
      prompt: '選択中レイヤーにグリッチ風シェーダー（.fs）とカスタム操作カード（.ui.js）を作って',
    ),
    (
      id: 'audio-bounce',
      title: '音に反応して弾む動き',
      prompt: '音声の音量に合わせて選択中レイヤーが弾むエクスプレッションを作って',
    ),
  ];
}

/// Clickable starter prompt cards under the empty-conversation intro.
class AgentStarterPrompts extends StatelessWidget {
  const AgentStarterPrompts({super.key, required this.onPick, this.prompts});

  final void Function(String prompt) onPick;
  final List<AgentStarter>? prompts;

  @override
  Widget build(BuildContext context) {
    final items = prompts ?? agentStarterPrompts;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        WindowTokens.inset,
        0,
        WindowTokens.inset,
        WindowTokens.inset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TRY ASKING',
            style: TextStyles.micro(Grey.g56)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: .4),
          ),
          SizedBox(height: Shape.s(6)),
          for (final s in items)
            Padding(
              padding: EdgeInsets.only(bottom: Shape.s(6)),
              child: DockHover(
                key: ValueKey('agent-starter-${s.id}'),
                onTap: () => onPick(s.prompt),
                builder: (context, h) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Shape.s(8),
                    vertical: Shape.s(6),
                  ),
                  decoration: BoxDecoration(
                    color: h ? WindowTokens.well : WindowTokens.card,
                    borderRadius: Shape.round(WindowTokens.radius),
                    border: Border.all(
                      color: h ? Accent.fill : WindowTokens.line,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: TextStyles.name(
                          h ? Grey.g100 : Grey.g91,
                          11,
                          FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: Shape.s(2)),
                      Text(
                        s.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.micro(Grey.g63),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
