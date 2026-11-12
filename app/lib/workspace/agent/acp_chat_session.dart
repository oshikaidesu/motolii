// One conversation with an agent that speaks the Agent Client Protocol (agentclientprotocol.com), as Zed's agent panel
// holds one. acpd_io starts the agent and acpd speaks the protocol (fluttercandies/acpd, Apache-2.0). What the agent
// sends is handed to ianvs_agent_chat (robinfai/ianvs-acp, Apache-2.0) as it came: a tool call stays its ACP JSON,
// whose title, status, kind, content (diffs as oldText/newText) and locations ianvs reads itself.
import 'dart:async';

import 'package:acpd/acpd.dart';
import 'package:acpd_io/acpd_io.dart';
import 'package:ianvs_agent_core/ianvs_agent_core.dart';

class AcpChatSession extends ChatSession {
  AcpChatSession(this.agentName, this._config, this.folder);

  final String agentName;
  final AcpAgentConfig _config;

  /// The folder the agent works in: the user's own folder, where the code a layer runs is kept.
  final String folder;

  AcpAgent? _agent;
  ClientConnection? _client;
  String? _session;
  final _messages = <ChatMessageData>[];
  final _toolAt = <String, int>{};
  var _revision = 0, _loading = true, _sending = false;
  String? _error;
  ChatPermissionRequest? _permission;
  List<PermissionOption> _options = const [];
  Completer<RequestPermissionOutcome>? _answer;

  @override
  ChatSessionState get state => ChatSessionState(
    identity: this,
    agentName: agentName,
    messages: List.unmodifiable(_messages),
    messagesRevision: _revision,
    isLoading: _loading,
    enabled: !_loading && _session != null,
    isSending: _sending,
    capabilities: const ChatCapabilities(tools: true, permissions: true),
    permission: _permission,
    workspaceRoots: [folder],
    error: _error,
  );

  /// Starts the agent and opens a session in [folder]. A failure is shown in the panel with the agent's last words.
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
      _session = (await client.client.newSession(
        NewSessionRequest(cwd: folder),
      )).sessionId;
    } catch (e) {
      _error = '$agentName did not start: $e\n${_agent?.stderrTail ?? ''}'
          .trim();
    }
    _loading = false;
    _changed();
  }

  @override
  Future<void> send(
    String text, {
    List<PromptAttachment> attachments = const [],
  }) async {
    final client = _client, session = _session;
    if (client == null || session == null || text.trim().isEmpty) return;
    _messages.add(_message(ChatMessageRole.user, text));
    _sending = true;
    _changed();
    try {
      await client.client.prompt(
        PromptRequest(
          sessionId: session,
          prompt: [TextContentBlock(text: text)],
        ),
      );
    } catch (e) {
      _messages.add(_message(ChatMessageRole.error, '$e'));
    }
    _sending = false;
    _changed();
  }

  @override
  Future<void> stop() async {
    if (_session case final s?) _client?.client.cancel(s);
    _settle(const PermissionCancelled());
  }

  @override
  Future<void> selectPermissionOption(String optionId) async =>
      _settle(PermissionSelected(optionId: optionId));

  @override
  Future<void> resolvePermission(ChatPermissionDecision decision) async {
    final want = decision == ChatPermissionDecision.allow
        ? const [
            PermissionOptionKind.allowOnce,
            PermissionOptionKind.allowAlways,
          ]
        : const [
            PermissionOptionKind.rejectOnce,
            PermissionOptionKind.rejectAlways,
          ];
    final o = decision == ChatPermissionDecision.cancel
        ? null
        : _options.where((o) => want.contains(o.kind)).firstOrNull;
    _settle(
      o == null
          ? const PermissionCancelled()
          : PermissionSelected(optionId: o.optionId),
    );
  }

  @override
  void dispose() {
    _settle(const PermissionCancelled());
    unawaited(_client?.close());
    unawaited(_agent?.close());
    super.dispose();
  }

  void _take(SessionUpdate u) {
    switch (u) {
      case AgentMessageChunk(:final chunk):
        final text = chunk.content is TextContentBlock
            ? (chunk.content as TextContentBlock).text
            : '';
        final last = _messages.lastOrNull;
        if (last != null && last.role == ChatMessageRole.assistant) {
          _messages.last = last.copyWith(text: last.text + text);
        } else {
          _messages.add(_message(ChatMessageRole.assistant, text));
        }
      case ToolCallUpdateSession(:final toolCall):
        _tool(toolCall.toolCallId, toolCall.toJson());
      case ToolCallStatusUpdate(:final update):
        _tool(update.toolCallId, update.toJson());
      default:
        return;
    }
    _changed();
  }

  /// A tool call's row: its ACP fields, each update laid over the last.
  void _tool(String id, Map<String, Object?> json) {
    final at = _toolAt[id];
    if (at == null) {
      _toolAt[id] = _messages.length;
      _messages.add(
        _message(ChatMessageRole.tool, '${json['title'] ?? ''}', json),
      );
    } else {
      final m = _messages[at];
      _messages[at] = m.copyWith(metadata: {...m.metadata, ...json});
    }
  }

  Future<RequestPermissionResponse> _ask(RequestPermissionRequest r) async {
    _settle(const PermissionCancelled());
    final answer = _answer = Completer();
    _options = r.options;
    final title = r.toolCall.title ?? 'Tool call';
    _permission = ChatPermissionRequest(
      id: r.toolCall.toolCallId,
      title: title,
      rationale: '',
      sessionId: r.sessionId,
      toolName: title,
      options: [for (final o in r.options) o.name],
      choices: [
        for (final o in r.options)
          ChatPermissionChoice(
            optionId: o.optionId,
            name: o.name,
            kind: o.kind.toJson(),
          ),
      ],
      requestedAt: DateTime.now(),
      metadata: r.toolCall.toJson(),
    );
    _changed();
    return RequestPermissionResponse(outcome: await answer.future);
  }

  void _settle(RequestPermissionOutcome outcome) {
    final answer = _answer;
    _answer = null;
    if (answer == null || answer.isCompleted) return;
    _permission = null;
    _options = const [];
    answer.complete(outcome);
    _changed();
  }

  ChatMessageData _message(
    ChatMessageRole role,
    String text, [
    Map<String, Object?> metadata = const {},
  ]) => ChatMessageData(
    id: '${_messages.length}',
    role: role,
    text: text,
    metadata: metadata,
  );

  void _changed() {
    _revision++;
    notifySessionChanged();
  }
}
