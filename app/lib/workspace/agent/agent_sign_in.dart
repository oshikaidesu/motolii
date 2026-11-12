// Signing in to an agent, as ACP lays it down (agentclientprotocol.com; the auth types of @agentclientprotocol/sdk
// 2.6.0): the agent lists its ways in initialize's authMethods, and answers a session it cannot open with
// auth_required (-32000). A `terminal` way is the agent's own command run again with the way's args and env, in a
// terminal, where the person signs in; exit status 0 is success. Any other way is carried out by the agent on
// `authenticate`. Motolii keeps no key or password: the agent stores what it gets, where it always does.
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
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
) async {
  final dir = Directory('${Directory.systemTemp.path}/motolii-sign-in')
    ..createSync(recursive: true);
  final status = File('${dir.path}/${way.id}.status');
  if (status.existsSync()) status.deleteSync();
  final words = [...line, ...way.args], all = {...env, ...way.env};
  final File script;
  final List<String> open;
  if (Platform.isWindows) {
    String q(String w) => '"${w.replaceAll('"', '""')}"';
    script = File('${dir.path}/${way.id}.bat')
      ..writeAsStringSync(
        [
          'cd /d ${q(folder)}',
          for (final e in all.entries) 'set "${e.key}=${e.value}"',
          words.map(q).join(' '),
          'echo %errorlevel%> ${q(status.path)}',
        ].join('\r\n'),
      );
    open = ['cmd', '/c', 'start', '', 'cmd', '/c', script.path];
  } else {
    String q(String w) => "'${w.replaceAll("'", r"'\''")}'";
    final shell = Platform.environment['SHELL'] ?? '/bin/sh';
    script = File('${dir.path}/${way.id}.command')
      ..writeAsStringSync(
        [
          '#!/bin/sh',
          'cd ${q(folder)}',
          for (final e in all.entries) 'export ${e.key}=${q(e.value)}',
          // The login shell, so npx is found as when the agent was started.
          '${q(shell)} -lc ${q('exec ${words.map(q).join(' ')}')}',
          'echo \$? > ${q(status.path)}',
        ].join('\n'),
      );
    await Process.run('chmod', ['+x', script.path]);
    open = Platform.isMacOS
        ? ['open', '-a', 'Terminal', script.path]
        : ['x-terminal-emulator', '-e', script.path];
  }
  try {
    final r = await Process.run(open.first, open.skip(1).toList());
    if (r.exitCode != 0) return null;
  } catch (_) {
    return null;
  }
  while (!status.existsSync() || status.readAsStringSync().trim().isEmpty) {
    if (!waiting()) return null;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  return int.tryParse(status.readAsStringSync().trim()) ?? 1;
}

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
        Forms.worn.action(context, ActionSpec('Cancel', talk.stopSignIn)),
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
                    [w.about, if (w.terminal) 'Opens a terminal.'].join(' '),
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
