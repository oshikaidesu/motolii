// The settings an agent offers for its session (ACP session config options: model, effort, mode…), each shown as its
// name and current choice under the Agent pane's header. A click opens the choices in the app's menu (ContextMenu);
// the agent answers a choice with all its settings as they now are, so one it adds (Opus's Fast mode) shows at once.
// Motolii keeps no list of models or levels: what shows is what the agent declared, as in Zed's agent panel.
import 'package:acpd/acpd.dart'
    show
        SessionConfigGroupedOptions,
        SessionConfigOptionCategory,
        SessionConfigSelectOptionValue,
        SessionConfigUngroupedOptions;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/agent/acp_chat_session.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

class AgentSettings extends StatefulWidget {
  const AgentSettings(this.talk, {super.key});
  final AcpChatSession talk;

  @override
  State<AgentSettings> createState() => _AgentSettingsState();
}

class _AgentSettingsState extends State<AgentSettings> {
  final _menu = GlobalKey<ContextMenuState>();

  /// The settings the agent offers (model, effort, mode…), each as its current choice; a click opens its choices in
  /// the app's menu. They are the agent's own (ACP session config options), as Zed's agent panel shows them.
  @override
  Widget build(BuildContext context) => ContextMenu(
    key: _menu,
    child: Wrap(
      spacing: Shape.s(10),
      runSpacing: Shape.s(4),
      children: [
        for (final o in widget.talk.options)
          if (o is SessionConfigSelectOptionValue) _setting(o),
      ],
    ),
  );

  /// A model, an effort or a mode is known by its choice alone, as the Claude app shows "Opus 5.5" and "High";
  /// any other setting also says its name ("Ultracode Off").
  static final _bare = {
    SessionConfigOptionCategory.model,
    SessionConfigOptionCategory.thoughtLevel,
    SessionConfigOptionCategory.mode,
  };

  Widget _setting(SessionConfigSelectOptionValue o) {
    final choices = switch (o.options) {
      SessionConfigUngroupedOptions(:final options) => options,
      SessionConfigGroupedOptions(:final groups) => [
        for (final g in groups) ...g.options,
      ],
    };
    final now =
        choices.where((c) => c.value == o.currentValue).firstOrNull?.name ??
        o.currentValue;
    return GestureDetector(
      onTapUp: (d) {
        final box = _menu.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        _menu.currentState?.show(box.globalToLocal(d.globalPosition), [
          for (final c in choices)
            ContextMenuItem(
              c.value == o.currentValue ? '${c.name}  ✓' : c.name,
              () => widget.talk.choose(o.id, c.value),
            ),
        ]);
      },
      child: DockHover(
        builder: (context, h) => Text.rich(
          TextSpan(
            children: [
              if (!_bare.contains(o.category))
                TextSpan(text: '${o.name} ', style: TextStyles.label()),
              TextSpan(
                text: '$now ▾',
                style: TextStyles.label(h ? Grey.g95 : Grey.g76),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
