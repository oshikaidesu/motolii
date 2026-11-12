// One conversation with an agent that speaks the Agent Client Protocol (agentclientprotocol.com), as Zed's agent panel
// holds one. acpd_io starts the agent and acpd speaks the protocol (fluttercandies/acpd, Apache-2.0). A tool call is
// kept as the ACP JSON it came as (title, status, kind, content with diffs, locations); the pane reads those fields.
import 'dart:async';

import 'package:acpd/acpd.dart';
import 'package:acpd_io/acpd_io.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Who said a line of the conversation.
enum Said { you, agent, tool, error }

/// One line of the conversation: [text], or for a tool call its ACP JSON in [call]. A request's [note] says what was
/// sent with it.
class Entry {
  Entry(this.who, this.text, [this.call = const {}, this.note = '']);
  final Said who;
  String text;
  Map<String, Object?> call;
  final String note;
}

class AcpChatSession extends ChangeNotifier {
  AcpChatSession(this.agentName, this._config, this.folder);

  final String agentName;
  final AcpAgentConfig _config;

  /// The folder the agent works in: the user's own folder, where the code a layer runs is kept.
  final String folder;

  final entries = <Entry>[];
  var starting = true, sending = false;

  /// Called when a tool call ends and when the agent's turn ends: a file may have been written, by whatever tool
  /// (an edit, or a shell command the agent ran), so the pane looks at the files.
  void Function()? settled;

  /// The settings the agent offers for this session (ACP session config options: model, effort, mode…), as it
  /// declared them; each [choose] sends one back. Motolii keeps no list of its own.
  var options = <SessionConfigOption>[];

  /// The session's context as the agent last told it (ACP usage_update): tokens in use and the window's size.
  int? used, size;

  /// What the agent said of its usage limit, as it sent it in usage_update's free-form _meta (Claude Agent:
  /// `_claude/rateLimit` with each window's utilization); empty when it said nothing.
  Map<String, Object?> limit = const {};

  /// What the agent asks leave for, and the answers it offers; null when it asks nothing.
  RequestPermissionRequest? asked;

  AcpAgent? _agent;
  ClientConnection? _client;
  String? _session;
  final _toolAt = <String, Entry>{};
  Completer<RequestPermissionOutcome>? _answer;

  /// Starts the agent and opens a session in [folder]. A failure is shown in the pane with the agent's last words.
  Future<void> start() async {
    try {
      final agent = _agent = await AcpAgent.start(_config);
      final client = _client =
          (ClientRole()
                ..handleNotification('session/update', (p, _) {
                  final n = SessionUpdateNotification.fromJson(p);
                  if (n.sessionId == _session || _session == null) {
                    _take(n.update);
                  }
                })
                ..onRequestPermission((_, r, _) => _ask(r)))
              .connect(agent.transport);
      await client.client.initialize(
        const InitializeRequest(
          protocolVersion: ProtocolVersion.v1,
          clientInfo: Implementation(name: 'Motolii', version: '0'),
        ),
      );
      final session = await client.client.newSession(
        NewSessionRequest(cwd: folder),
      );
      _session = session.sessionId;
      options = session.configOptions;
    } catch (e) {
      entries.add(
        Entry(
          Said.error,
          '$agentName did not start: $e\n${_agent?.stderrTail ?? ''}'.trim(),
        ),
      );
    }
    starting = false;
    notifyListeners();
  }

  bool get ready => !starting && _session != null;

  /// Sends [text] with [more] (such as the selected layer's files), noted on the line as [note].
  Future<void> send(
    String text, {
    List<ContentBlock> more = const [],
    String note = '',
  }) async {
    final client = _client, session = _session;
    if (client == null || session == null || text.trim().isEmpty) return;
    entries.add(Entry(Said.you, text, const {}, note));
    sending = true;
    notifyListeners();
    try {
      await client.client.prompt(
        PromptRequest(
          sessionId: session,
          prompt: [
            TextContentBlock(text: text),
            ...more,
          ],
        ),
      );
    } catch (e) {
      entries.add(Entry(Said.error, '$e'));
    }
    settled?.call();
    sending = false;
    notifyListeners();
  }

  /// Sets the agent's setting [id] to [value]; the agent answers with all its settings as they now are.
  Future<void> choose(String id, String value) async {
    final client = _client, session = _session;
    if (client == null || session == null) return;
    try {
      options = (await client.client.setSessionConfigOption(
        SetValueIdConfigOption(sessionId: session, configId: id, value: value),
      )).configOptions;
    } catch (e) {
      entries.add(Entry(Said.error, '$e'));
    }
    notifyListeners();
  }

  void stop() {
    if (_session case final s?) _client?.client.cancel(s);
    answer(null);
  }

  /// Answers what the agent asked with one of its options, or cancels it with null.
  void answer(String? optionId) {
    final a = _answer;
    _answer = null;
    asked = null;
    if (a != null && !a.isCompleted) {
      a.complete(
        optionId == null
            ? const PermissionCancelled()
            : PermissionSelected(optionId: optionId),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    answer(null);
    unawaited(_client?.close());
    unawaited(_agent?.close());
    super.dispose();
  }

  void _take(SessionUpdate u) {
    switch (u) {
      case AgentMessageChunk(
        chunk: ContentChunk(content: TextContentBlock(:final text)),
      ):
        final last = entries.lastOrNull;
        if (last != null && last.who == Said.agent) {
          last.text += text;
        } else {
          entries.add(Entry(Said.agent, text));
        }
      case ConfigOptionSessionUpdate(:final configOptions):
        options = configOptions;
      case UsageSessionUpdate(used: final u, size: final z, :final meta):
        used = u ?? used;
        size = z ?? size;
        if (meta['_claude/rateLimit'] case final Map<String, Object?> l) {
          limit = l;
        }
      case ToolCallUpdateSession(:final toolCall):
        _tool(toolCall.toolCallId, toolCall.toJson());
      case ToolCallStatusUpdate(:final update):
        _tool(update.toolCallId, update.toJson());
      default:
        return;
    }
    notifyListeners();
  }

  /// A tool call's line: its ACP fields, each update laid over the last.
  void _tool(String id, Map<String, Object?> json) {
    final e = _toolAt[id];
    if (e == null) {
      entries.add(_toolAt[id] = Entry(Said.tool, '', json));
    } else {
      e.call = {...e.call, ...json};
    }
    if (json['status'] case 'completed' || 'failed') settled?.call();
  }

  /// Adds a line saying what went wrong outside the agent, such as code the engine refused.
  void tell(String why) {
    entries.add(Entry(Said.error, why));
    notifyListeners();
  }

  Future<RequestPermissionResponse> _ask(RequestPermissionRequest r) async {
    answer(null);
    final a = _answer = Completer();
    asked = r;
    notifyListeners();
    return RequestPermissionResponse(outcome: await a.future);
  }
}
