// Signing in to an agent in a terminal: a script that runs the agent's own command with the way's args and env, and
// writes its exit status to a file, which is read until it appears.
import 'dart:async';
import 'dart:io';

/// Runs [words] (the agent's command and the way's args), with [env] set, in [folder], in the system's terminal, and
/// gives its exit status once it ends: null if the terminal could not be opened, or once [waiting] says no one waits
/// any more (the window was closed before it ended).
Future<int?> runSignInScript({
  required String id,
  required List<String> words,
  required Map<String, String> env,
  required String folder,
  required bool Function() waiting,
}) async {
  final dir = Directory('${Directory.systemTemp.path}/motolii-sign-in')
    ..createSync(recursive: true);
  final status = File('${dir.path}/$id.status');
  if (status.existsSync()) status.deleteSync();
  final File script;
  final List<String> open;
  if (Platform.isWindows) {
    String q(String w) => '"${w.replaceAll('"', '""')}"';
    script = File('${dir.path}/$id.bat')
      ..writeAsStringSync(
        [
          'cd /d ${q(folder)}',
          for (final e in env.entries) 'set "${e.key}=${e.value}"',
          words.map(q).join(' '),
          'echo %errorlevel%> ${q(status.path)}',
        ].join('\r\n'),
      );
    open = ['cmd', '/c', 'start', '', 'cmd', '/c', script.path];
  } else {
    String q(String w) => "'${w.replaceAll("'", r"'\''")}'";
    final shell = Platform.environment['SHELL'] ?? '/bin/sh';
    script = File('${dir.path}/$id.command')
      ..writeAsStringSync(
        [
          '#!/bin/sh',
          'cd ${q(folder)}',
          for (final e in env.entries) 'export ${e.key}=${q(e.value)}',
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
