// Signing in to an agent, as ACP lays it down (agentclientprotocol.com; the auth types of @agentclientprotocol/sdk
// 2.6.0): the agent lists its ways in initialize's authMethods, and answers a session it cannot open with
// auth_required (-32000). A `terminal` way is the agent's own command run again with the way's args and env, in a
// terminal, where the person signs in; exit status 0 is success. An `env_var` way collects session-only variables
// (kept in memory, never written to disk) and restarts the agent with them. Any other way runs `authenticate`.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/sign_in_script.dart';
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/widgets/text_gestures.dart';
import 'package:motolii/workspace/agent/acp_chat_session.dart';

/// One way to sign in, as the agent sent it in authMethods.
class SignInWay {
  SignInWay(Map<Object?, Object?> m)
    : id = '${m['id']}',
      name = '${m['name'] ?? m['id']}',
      about = m['description'] is String ? '${m['description']}'.trim() : '',
      terminal =
          m['type'] == 'terminal' ||
          (m['_meta'] is Map &&
              (m['_meta'] as Map).containsKey('terminal-auth')),
      args = [
        for (final a
            in (m['args'] as List?) ??
                ((m['_meta'] is Map &&
                        (m['_meta'] as Map)['terminal-auth'] is Map)
                    ? (((m['_meta'] as Map)['terminal-auth'] as Map)['args']
                              as List?) ??
                          const []
                    : const []))
          '$a',
      ],
      env = {
        for (final e in ((m['env'] as Map?) ?? const {}).entries)
          '${e.key}': '${e.value}',
      },
      envVars = [
        for (final v in (m['vars'] as List?) ?? const [])
          if (v is Map && v['name'] is String)
            (
              name: '${v['name']}',
              label: '${v['label'] ?? v['name']}',
              optional: v['optional'] == true,
            ),
      ];
  final String id, name, about;
  final bool terminal;
  final List<String> args;
  final Map<String, String> env;
  final List<({String name, String label, bool optional})> envVars;
}

/// Runs [line], the agent's own command, with [way]'s args and env in the system's terminal, and gives its exit
/// status once it ends: null if the terminal could not be opened, or once [waiting] says no one waits any more (the
/// window was closed before it ended).
Future<int?> signInInTerminal(
  List<String> line,
  Map<String, String> env,
  SignInWay way,
  String folder,
  bool Function() waiting,
) => runSignInScript(
  id: way.id,
  words: [...line, ...way.args],
  env: {...env, ...way.env},
  folder: folder,
  waiting: waiting,
);

/// The pane's card while the agent waits for sign-in: clear auth instructions,
/// ACP authMethods buttons (terminal, agent, or inline env_var), and fallback
/// terminal login + Retry so the user is never left at a dead-end error.
Widget signInCard(
  BuildContext context,
  AcpChatSession talk, {
  VoidCallback? onSwitchAgent,
}) => _SignInCard(talk: talk, onSwitchAgent: onSwitchAgent);

class _SignInCard extends StatefulWidget {
  const _SignInCard({required this.talk, this.onSwitchAgent});
  final AcpChatSession talk;
  final VoidCallback? onSwitchAgent;
  @override
  State<_SignInCard> createState() => _SignInCardState();
}

class _SignInCardState extends State<_SignInCard> {
  final _values = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final talk = widget.talk;
    return Container(
      margin: EdgeInsets.all(WindowTokens.inset),
      padding: EdgeInsets.all(Shape.s(8)),
      decoration: BoxDecoration(
        color: WindowTokens.card,
        borderRadius: Shape.round(WindowTokens.radius),
        border: Border.all(color: WindowTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            talk.signingIn
                ? 'Signing in to ${talk.agentName}…'
                : 'Sign in to ${talk.agentName}',
            style: TextStyles.name(Grey.g95).bold,
          ),
          SizedBox(height: Shape.s(4)),
          Text(
            talk.signingIn
                ? 'Finish signing in in the window that opened. Motolii will reconnect automatically.'
                : talk.ways.isEmpty
                ? '${talk.agentName} needs authentication before starting a session. '
                      'Sign in with its CLI in Terminal, then click Retry.'
                : 'Choose how to authenticate with ${talk.agentName}:',
            style: TextStyles.name(Grey.g76, 11, null, 1.4),
          ),
          if (!talk.signingIn && talk.signInWhy.isNotEmpty) ...[
            SizedBox(height: Shape.s(4)),
            Text(
              talk.signInWhy,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.label(Grey.g56),
            ),
          ],
          SizedBox(height: Shape.s(8)),
          if (talk.signingIn)
            Align(
              alignment: Alignment.centerLeft,
              child: Forms.worn.action(
                context,
                ActionSpec('Cancel', talk.stopSignIn),
              ),
            )
          else ...[
            for (final w in talk.ways) _wayRow(context, talk, w),
            if (talk.ways.isEmpty && talk.line.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: Shape.s(6)),
                child: Row(
                  children: [
                    Forms.worn.action(
                      context,
                      ActionSpec(
                        'Open Terminal',
                        talk.signInWithTerminalFallback,
                      ),
                    ),
                    SizedBox(width: Shape.s(8)),
                    Expanded(
                      child: Text(
                        'Runs ${talk.line.first} so you can log in.',
                        style: TextStyles.label(Grey.g56),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Forms.worn.action(
                  context,
                  ActionSpec('Retry', () => talk.retry()),
                ),
                if (widget.onSwitchAgent != null) ...[
                  SizedBox(width: Shape.s(6)),
                  Forms.worn.action(
                    context,
                    ActionSpec('Switch Agent', widget.onSwitchAgent!),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _wayRow(BuildContext context, AcpChatSession talk, SignInWay w) {
    if (w.envVars.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: Shape.s(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.name, style: TextStyles.name(Grey.g91, 11)),
            if (w.about.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: Shape.s(2)),
                child: Text(w.about, style: TextStyles.label(Grey.g56)),
              ),
            SizedBox(height: Shape.s(4)),
            for (final v in w.envVars)
              Padding(
                padding: EdgeInsets.only(bottom: Shape.s(6)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.optional ? '${v.label} (optional)' : v.label,
                      style: TextStyles.label(Grey.g63),
                    ),
                    SizedBox(height: Shape.s(2)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Shape.s(6),
                        vertical: Shape.s(4),
                      ),
                      decoration: BoxDecoration(
                        color: WindowTokens.well,
                        borderRadius: Shape.round(WindowTokens.chipRadius),
                        border: Border.all(color: WindowTokens.line),
                      ),
                      child: TypedField(
                        text: _values[v.name] ?? '',
                        standing: true,
                        style: TextStyles.value(Grey.g95),
                        cursor: WindowTokens.accent,
                        selection: WindowTokens.accent.withValues(alpha: .3),
                        onPick: (val) => _values[v.name] = val.text,
                        onDone: (val) {
                          if (val != null) _values[v.name] = val;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Forms.worn.action(
              context,
              ActionSpec('Connect', () {
                final values = <String, String>{
                  for (final v in w.envVars)
                    if ((_values[v.name] ?? '').trim().isNotEmpty)
                      v.name: _values[v.name]!.trim(),
                };
                if (values.isNotEmpty) talk.signIn(w, envValues: values);
              }),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: Shape.s(6)),
      child: Row(
        children: [
          Forms.worn.action(context, ActionSpec(w.name, () => talk.signIn(w))),
          SizedBox(width: Shape.s(8)),
          Expanded(
            child: Text(
              [
                if (w.about.isNotEmpty)
                  RegExp(r'[.!?]$').hasMatch(w.about) ? w.about : '${w.about}.',
                if (w.terminal) 'Opens a terminal.',
              ].join(' '),
              style: TextStyles.label(Grey.g56),
            ),
          ),
        ],
      ),
    );
  }
}
