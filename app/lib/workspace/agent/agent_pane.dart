// The Agent pane: any agent of the ACP registry, chosen at the top, writing the code a layer runs; Zed's agent panel
// is the model (every agent equal, the screen follows the agent). The conversation is ianvs_agent_chat's AgentChatView
// as it is; this file only chooses the agent and gives it Motolii's skin. ianvs is built on Material and the app on
// WidgetsApp, so the pane carries Material's theme, words and surface for its own subtree.
import 'package:acpd_io/acpd_io.dart' show AcpAgentConfig;
import 'package:flutter/material.dart';
import 'package:ianvs_agent_chat/ianvs_agent_chat.dart';

import 'package:motolii/bridge/engine_paths.dart' show motoliiOwn;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/agent/acp_chat_session.dart';
import 'package:motolii/workspace/agent/agent_registry.dart';

/// The conversation outlives the pane, as a docked tab is rebuilt when it is moved or brought back.
final _talk = ValueNotifier<AcpChatSession?>(null);

class AgentPane extends StatefulWidget {
  const AgentPane({super.key});
  @override
  State<AgentPane> createState() => _AgentPaneState();
}

class _AgentPaneState extends State<AgentPane> {
  late final _agents = agentRegistry();

  void _choose(AgentEntry a) {
    _talk.value?.dispose();
    final c = a.config;
    _talk.value = AcpChatSession(
      a.name,
      AcpAgentConfig(
        command: c.command,
        args: c.args,
        env: c.env,
        workingDirectory: motoliiOwn,
      ),
      motoliiOwn,
    )..start();
  }

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    delegates: const [DefaultMaterialLocalizations.delegate],
    child: Theme(
      data: ThemeData(
        brightness: Grey.light ? Brightness.light : Brightness.dark,
        fontFamily: TextStyles.sans,
        colorSchemeSeed: Accent.fill,
      ),
      child: ChatTheme(
        data: ChatThemeData(
          bodyFontSize: 13,
          colors: {
            'bg': Grey.g10,
            'surface': Grey.g13,
            'surfaceMuted': Grey.g10,
            'surfaceRaised': Grey.g20,
            'userMessageSurface': Grey.g15,
            'border': Grey.g26,
            'borderSoft': Grey.g20,
            'textPrimary': Grey.g91,
            'textSecondary': Grey.g63,
            'textTertiary': Grey.g44,
            'accent': Accent.ink,
            'primary': Accent.fill,
            'warning': Role.warning,
            'danger': Role.error,
          },
        ),
        child: ScaffoldMessenger(
          child: Material(
            color: Grey.g10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FutureBuilder(
                  future: _agents,
                  builder: (context, list) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: DropdownMenu<AgentEntry>(
                      expandedInsets: EdgeInsets.zero,
                      enableFilter: true,
                      requestFocusOnTap: true,
                      hintText: list.hasData
                          ? (list.data!.isEmpty
                                ? 'No agent list (offline, never fetched)'
                                : 'Choose an agent')
                          : 'Reading the ACP registry',
                      dropdownMenuEntries: [
                        for (final a in list.data ?? const <AgentEntry>[])
                          DropdownMenuEntry(value: a, label: a.name),
                      ],
                      onSelected: (a) => a == null ? null : _choose(a),
                    ),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _talk,
                    builder: (context, talk, _) => talk == null
                        ? const SizedBox()
                        : AgentChatView(session: talk),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
