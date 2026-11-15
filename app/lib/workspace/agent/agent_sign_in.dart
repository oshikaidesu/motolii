// Signing in to an agent, as ACP lays it down (agentclientprotocol.com; the auth types of @agentclientprotocol/sdk
// 2.6.0): the agent lists its ways in initialize's authMethods, and answers a session it cannot open with
// auth_required (-32000). A `terminal` way is the agent's own command run again with the way's args and env, in a
// terminal, where the person signs in; exit status 0 is success. Any other way is carried out by the agent on
// `authenticate`. Motolii keeps no key or password: the agent stores what it gets, where it always does.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/sign_in_script.dart';
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/workspace/agent/acp_chat_session.dart';

/// One way to sign in, as the agent sent it in authMethods.
class SignInWay {
  SignInWay(Map<Object?, Object?> m)
    : id = '${m['id']}',
      name = '${m['name'] ?? m['id']}',
      about = m['description'] is String ? '${m['description']}'.trim() : '',
      terminal = m['type'] == 'terminal',
      args = [for (final a in (m['args'] as List?) ?? const []) '$a'],
      env = {
        for (final e in ((m['env'] as Map?) ?? const {}).entries)
          '${e.key}': '${e.value}',
      };
  final String id, name, about;
  final bool terminal;
  final List<String> args;
  final Map<String, String> env;
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

/// The pane's card while the agent waits for sign-in: why, and one button per way it offered.
Widget signInCard(BuildContext context, AcpChatSession talk) => Container(
  margin: EdgeInsets.all(WindowTokens.inset),
  padding: EdgeInsets.all(Shape.s(6)),
  color: WindowTokens.card,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        talk.signingIn
            ? 'Signing in to ${talk.agentName}…'
            : 'Sign in to ${talk.agentName}',
        style: TextStyles.name(Grey.g95),
      ),
      SizedBox(height: Shape.s(4)),
      Text(
        talk.signingIn
            ? 'Finish in the window that opened. The conversation starts '
                  'when it is done.'
            : talk.ways.isEmpty
            ? '${talk.agentName} offers no way to sign in from here. '
                  '${talk.signInWhy}'
            : talk.signInWhy,
        style: TextStyles.name(Grey.g76, 11, null, 1.4),
      ),
      if (talk.signingIn) ...[
        SizedBox(height: Shape.s(6)),
        Align(
          alignment: Alignment.centerLeft,
          child: Forms.worn.action(
            context,
            ActionSpec('Cancel', talk.stopSignIn),
          ),
        ),
      ] else ...[
        SizedBox(height: Shape.s(6)),
        for (final w in talk.ways)
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(6)),
            child: Row(
              children: [
                Forms.worn.action(
                  context,
                  ActionSpec(w.name, () => talk.signIn(w)),
                ),
                SizedBox(width: Shape.s(8)),
                Expanded(
                  child: Text(
                    [
                      if (w.about.isNotEmpty)
                        RegExp(r'[.!?]$').hasMatch(w.about)
                            ? w.about
                            : '${w.about}.',
                      if (w.terminal) 'Opens a terminal.',
                    ].join(' '),
                    style: TextStyles.label(Grey.g56),
                  ),
                ),
              ],
            ),
          ),
      ],
    ],
  ),
);
