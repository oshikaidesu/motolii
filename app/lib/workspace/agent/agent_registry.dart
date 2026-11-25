// The agents that speak ACP, as the ACP registry lists them (github.com/agentclientprotocol/registry, Apache-2.0),
// the list Zed and JetBrains read. A copy is kept as agents/registry.json in the own folder, so the list opens offline.
// Each entry is started as the registry says: `npx <package>` or `uvx <package>` with its args and env, or a binary
// by its command name. The command runs in the login shell, so a Finder-opened app finds npx where a terminal does.
import 'dart:convert';

import 'package:acpd_io/acpd_io.dart' show AcpAgentConfig;

import 'package:motolii/storage/agent_files.dart' show readCustomAgentsFile;
import 'package:motolii/storage/agent_registry_file.dart';
import 'package:motolii/storage/host_platform.dart';

const _registry =
    'https://cdn.agentclientprotocol.com/registry/v1/latest/registry.json';

class AgentEntry {
  const AgentEntry(
    this.id,
    this.name,
    this.line,
    this.env, {
    this.description = '',
    this.method = '',
    this.installed = false,
  });
  final String id, name, description, method;

  /// True when a native binary for this agent is already present locally.
  final bool installed;

  /// The agent's command, word by word, and its env, as the registry gives them.
  final List<String> line;
  final Map<String, String> env;

  /// How the agent is started: the command in the login shell (cmd on Windows).
  AcpAgentConfig get config {
    if (hostIsWindows) {
      return AcpAgentConfig(command: 'cmd', args: ['/c', ...line], env: env);
    }
    final quoted = line.map((w) => "'${w.replaceAll("'", r"'\''")}'").join(' ');
    return AcpAgentConfig(
      command: loginShell,
      args: ['-lc', 'exec $quoted'],
      env: env,
    );
  }
}

/// Every agent this machine can start: user-defined custom agents in
/// `<ownFolder>/agents/custom.json` first, followed by the ACP registry.
Future<List<AgentEntry>> agentRegistry(String ownFolder) async {
  final custom = _customAgents(ownFolder);
  final seenIds = {for (final a in custom) a.id};
  final text = await registryText(_registry, '$ownFolder/agents/registry.json');
  if (text == null) return custom;
  final agents = (jsonDecode(text) as Map)['agents'] as List;
  return [
    ...custom,
    for (final a in agents.cast<Map>())
      if (_command(a['distribution'] as Map)
          case (final line, final env, final method)
          when !seenIds.contains('${a['id']}'))
        AgentEntry(
          '${a['id']}',
          '${a['name']}',
          line,
          env,
          description: '${a['description'] ?? ''}'.trim(),
          method: method,
          installed: method == 'binary' && hostHasProgram(line.first),
        ),
  ];
}

List<AgentEntry> _customAgents(String ownFolder) {
  final out = <AgentEntry>[];
  for (final raw in readCustomAgentsFile(ownFolder)) {
    final cmd = '${raw['command'] ?? ''}'.trim();
    if (cmd.isEmpty) continue;
    final line = [cmd, ..._words(raw['args'])];
    final env = <String, String>{
      if (raw['env'] is Map)
        for (final e in (raw['env'] as Map).entries) '${e.key}': '${e.value}',
    };
    final id = '${raw['id'] ?? cmd}'.trim();
    final name = '${raw['name'] ?? id}'.trim();
    out.add(
      AgentEntry(
        id,
        name,
        line,
        env,
        description: '${raw['description'] ?? 'Custom ACP agent'}'.trim(),
        method: 'custom',
        installed: true,
      ),
    );
  }
  return out;
}

(List<String>, Map<String, String>, String)? _command(Map d) {
  Map<String, String> envOf(Map? env) => {
    for (final e in (env ?? const {}).entries) '${e.key}': '${e.value}',
  };
  if (d case {'binary': final Map b} when b[_platform] is Map) {
    final p = b[_platform] as Map;
    final line = ['${p['cmd']}'.split('/').last, ..._words(p['args'])];
    if (line.isNotEmpty && hostHasProgram(line.first)) {
      return (line, envOf(p['env'] as Map?), 'binary');
    }
  }
  final (List<String> line, Map? env, String method) = switch (d) {
    {'npx': final Map n} => (
      ['npx', '-y', '${n['package']}', ..._words(n['args'])],
      n['env'] as Map?,
      'npx',
    ),
    {'uvx': final Map u} => (
      ['uvx', '${u['package']}', ..._words(u['args'])],
      u['env'] as Map?,
      'uvx',
    ),
    {'binary': final Map b} when b[_platform] is Map => (
      [
        '${(b[_platform] as Map)['cmd']}'.split('/').last,
        ..._words((b[_platform] as Map)['args']),
      ],
      (b[_platform] as Map)['env'] as Map?,
      'binary',
    ),
    _ => (const <String>[], null, ''),
  };
  if (line.isEmpty) return null;
  return (line, envOf(env), method);
}

List<String> _words(Object? args) => [
  for (final a in (args as List?) ?? const []) '$a',
];

/// The registry's name for this machine, as `darwin-aarch64`.
String get _platform {
  final arm = hostIsArm64;
  return '$hostOperatingSystem-${arm ? 'aarch64' : 'x86_64'}';
}
