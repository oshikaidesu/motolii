// The agents that speak ACP, as the ACP registry lists them (github.com/agentclientprotocol/registry, Apache-2.0),
// the list Zed and JetBrains read. A copy is kept as agents/registry.json in the own folder, so the list opens offline.
// Each entry is started as the registry says: `npx <package>` or `uvx <package>` with its args and env, or a binary
// by its command name. The command runs in the login shell, so a Finder-opened app finds npx where a terminal does.
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:acpd_io/acpd_io.dart' show AcpAgentConfig;

import 'package:motolii/bridge/engine_paths.dart' show motoliiOwn;

const _registry =
    'https://cdn.agentclientprotocol.com/registry/v1/latest/registry.json';

class AgentEntry {
  const AgentEntry(this.id, this.name, this.config);
  final String id, name;
  final AcpAgentConfig config;
}

/// Every agent in the registry this machine can start, newest list first, the kept copy when offline.
Future<List<AgentEntry>> agentRegistry() async {
  final kept = File('$motoliiOwn/agents/registry.json');
  String? text;
  try {
    final request = await HttpClient().getUrl(Uri.parse(_registry));
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      text = await response.transform(utf8.decoder).join();
      kept
        ..createSync(recursive: true)
        ..writeAsStringSync(text);
    }
  } catch (_) {}
  text ??= kept.existsSync() ? kept.readAsStringSync() : null;
  if (text == null) return const [];
  final agents = (jsonDecode(text) as Map)['agents'] as List;
  return [
    for (final a in agents.cast<Map>())
      if (_command(a['distribution'] as Map) case final c?)
        AgentEntry('${a['id']}', '${a['name']}', c),
  ];
}

AcpAgentConfig? _command(Map d) {
  final (List<String> line, Map? env) = switch (d) {
    {'npx': final Map n} => (
      ['npx', '-y', '${n['package']}', ..._words(n['args'])],
      n['env'] as Map?,
    ),
    {'uvx': final Map u} => (
      ['uvx', '${u['package']}', ..._words(u['args'])],
      u['env'] as Map?,
    ),
    {'binary': final Map b} when b[_platform] is Map => (
      [
        '${(b[_platform] as Map)['cmd']}'.split('/').last,
        ..._words((b[_platform] as Map)['args']),
      ],
      (b[_platform] as Map)['env'] as Map?,
    ),
    _ => (const <String>[], null),
  };
  if (line.isEmpty) return null;
  final environment = {
    for (final e in (env ?? const {}).entries) '${e.key}': '${e.value}',
  };
  if (Platform.isWindows) {
    return AcpAgentConfig(
      command: 'cmd',
      args: ['/c', ...line],
      env: environment,
    );
  }
  final quoted = line.map((w) => "'${w.replaceAll("'", r"'\''")}'").join(' ');
  return AcpAgentConfig(
    command: Platform.environment['SHELL'] ?? '/bin/sh',
    args: ['-lc', 'exec $quoted'],
    env: environment,
  );
}

List<String> _words(Object? args) => [
  for (final a in (args as List?) ?? const []) '$a',
];

/// The registry's name for this machine, as `darwin-aarch64`.
String get _platform {
  final os = Platform.isMacOS ? 'darwin' : Platform.operatingSystem;
  final arm = '${Abi.current()}'.contains('arm64');
  return '$os-${arm ? 'aarch64' : 'x86_64'}';
}
