// The Agent pane: any agent of the ACP registry, chosen in a list like a shelf, writing the code a layer runs.
// Zed's agent panel is the model: every agent equal, one dense column of what was said and done.
// It is drawn with the app's own parts: PanelHeader, the shelf's search field (also the message field), DockHover
// rows, the skin's Forms for the agent's questions. A reply is Markdown, laid out by flutter_markdown_plus (BSD-3,
// the Flutter authors' flutter_markdown carried on) in the app's text styles.
import 'package:acpd/acpd.dart'
    show ContentBlock, RequestPermissionRequest, ResourceLink;
import 'package:acpd_io/acpd_io.dart' show AcpAgentConfig;
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/disk.dart' show modifiedOf;
import 'package:motolii/storage/folder_files.dart';
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
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/document/expression_engine.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The conversation outlives the pane, as a docked tab is rebuilt when it is moved or brought back.
final _talk = ValueNotifier<AcpChatSession?>(null);

class AgentPane extends StatefulWidget {
  const AgentPane({super.key});
  @override
  State<AgentPane> createState() => _AgentPaneState();
}

class _AgentPaneState extends State<AgentPane> {
  late final _agents = agentRegistry(ownFolder());
  final _find = TextEditingController(), _say = TextEditingController();
  var _choosing = false;

  @override
  void dispose() {
    _find.dispose();
    _say.dispose();
    super.dispose();
  }

  void _choose(AgentEntry a) {
    _talk.value?.dispose();
    final c = a.config;
    _talk.value = AcpChatSession(
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
    )..start();
    setState(() => _choosing = false);
  }

  /// Sends [text] with the selected layer (layer_code.dart), each code file first made the layer's own. Each time a
  /// tool call ends, a file sent whose time changed is read again, and a file new in the request's folder is put on
  /// the layer as a new card, whatever tool wrote it.
  Future<void> _send(AcpChatSession talk, String text) async {
    if (!talk.ready || talk.sending || text.trim().isEmpty) return;
    _say.clear();
    final ws = WorkspaceScope.read(context), code = layerCode(ws);
    final fresh = newFolder();
    final more = code == null
        ? const <ContentBlock>[]
        : await ownedFor(ws, code, fresh);
    DateTime? time(String f) => modifiedOf(f);
    final seen = <String, DateTime?>{
      for (final b in more)
        if (b is ResourceLink)
          Uri.parse(b.uri).toFilePath(): time(Uri.parse(b.uri).toFilePath()),
    };
    talk.settled = () {
      for (final f in filesIn(fresh)) {
        if (!seen.containsKey(f)) {
          seen[f] = time(f);
          _put(ws, talk, f);
        }
      }
      for (final f in seen.keys) {
        if (time(f) case final t when t != seen[f]) {
          seen[f] = t;
          _read(ws, talk, f);
        }
      }
    };
    talk.send(text, more: more, note: code?.line ?? '');
  }

  /// Puts a new file the agent wrote on the selected layer, as the Effects shelf puts an empty one (empty_effect.dart).
  void _put(WorkspaceController ws, AcpChatSession talk, String file) {
    if (!RegExp(r'\.(fs|js)$').hasMatch(file)) return;
    putEffectFile(
      ws,
      file,
      expression: file.endsWith('.js'),
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
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _talk,
    builder: (context, talk, _) => ListenableBuilder(
      listenable: Listenable.merge([?talk, _find]),
      builder: (context, _) {
        final listing = talk == null || _choosing;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelHeader(
              talk?.agentName ?? 'Agent',
              trailing: [
                if (talk != null)
                  _link(
                    _choosing ? 'Back' : 'Agents',
                    () => setState(() => _choosing = !_choosing),
                  ),
              ],
            ),
            if (listing) ...[
              if (talk == null) _intro(choose: true),
              ShelfSearchField(controller: _find, hint: 'Search agents'),
              Expanded(child: _list()),
            ] else ...[
              if (talk.needsSignIn) signInCard(context, talk),
              Expanded(child: _conversation(talk)),
              if (talk.asked case final r?) _question(context, talk, r),
              _with(context, talk),
              AgentComposer(
                talk: talk,
                controller: _say,
                onSend: (t) => _send(talk, t),
              ),
            ],
          ],
        );
      },
    ),
  );

  /// Has the engine read a file the agent wrote, as a cell's save does (EffectCode._saved): the engine looks at a
  /// file's time only when told (files_changed), so a write from outside the app is otherwise not seen.
  void _read(WorkspaceController ws, AcpChatSession talk, String file) {
    if (!RegExp(r'\.(wgsl|fs|js)$').hasMatch(file)) return;
    readCodeFile(ws, file, (done, why) {
      if (!done) {
        talk.tell('${file.split('/').last} does not run: ${why.trim()}');
      }
      ws.reread();
    });
  }

  /// What a request will carry: the selected layer and its cards with code, read as the selection changes.
  Widget _with(BuildContext context, AcpChatSession talk) {
    final code = layerCode(
      WorkspaceScope.of(context, {
        WorkspaceAspect.picked,
        WorkspaceAspect.document,
      }),
    );
    return Padding(
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
              code == null ? 'No layer selected' : 'With ${code.line}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.label(),
            ),
          ),
        ],
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
          'Pick a layer, then ask in your own words.',
          'The agent knows the layer\'s cards and code. It writes its '
              'expressions and effects, and the picture changes as it saves.',
          'Something new comes as a new card. Code already there is changed '
              'only when you ask for it.',
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
      ? Align(alignment: Alignment.topLeft, child: _intro())
      : ListView(
          reverse: true,
          padding: EdgeInsets.all(WindowTokens.inset),
          children: [
            for (final e in talk.entries.reversed)
              Padding(
                padding: EdgeInsets.only(top: Shape.s(8)),
                child: _line(e),
              ),
          ],
        );

  Widget _line(Entry e) => switch (e.who) {
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
    Said.agent => MarkdownBody(data: e.text, styleSheet: _markdown),
    Said.tool => _tool(e.call),
    Said.error => Text(
      e.text,
      style: TextStyles.name(Role.error, 11, null, 1.4),
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
