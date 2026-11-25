// Where a request is written, laid out as the Claude app's message box: one well with the text on top and, under it
// at the right, the agent's settings and usage (agent_settings.dart) and Send (Stop while the agent works). The text is naked_ui's NakedTextField (EditableText with
// Flutter TextField's gestures, IME and keys), so Motolii draws only its looks. Enter sends; Shift-Enter starts a line.
import 'package:flutter/services.dart' show LogicalKeyboardKey, TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/agent/acp_chat_session.dart';
import 'package:motolii/workspace/agent/agent_settings.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

class AgentComposer extends StatefulWidget {
  const AgentComposer({
    super.key,
    required this.talk,
    required this.controller,
    required this.onSend,
    this.hint,
    this.attachments = const [],
    this.onAttach,
    this.onRemoveAttachment,
  });
  final AcpChatSession talk;
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final String? hint;
  final List<String> attachments;
  final VoidCallback? onAttach;
  final ValueChanged<String>? onRemoveAttachment;

  @override
  State<AgentComposer> createState() => _AgentComposerState();
}

class _AgentComposerState extends State<AgentComposer> {
  final _focus = FocusNode();
  final _cmdMenu = GlobalKey<ContextMenuState>();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _send() => widget.onSend(widget.controller.text);

  @override
  Widget build(BuildContext context) {
    final talk = widget.talk;
    final hint = talk.ready
        ? (widget.hint ?? 'Ask ${talk.agentName}')
        : talk.needsSignIn
        ? 'Sign in above, then ask'
        : talk.starting
        ? 'Starting ${talk.agentName}'
        : 'Not started';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        WindowTokens.inset,
        Shape.s(4),
        WindowTokens.inset,
        WindowTokens.inset,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          Shape.s(8),
          Shape.s(6),
          Shape.s(6),
          Shape.s(6),
        ),
        decoration: BoxDecoration(
          color: WindowTokens.well,
          borderRadius: Shape.round(WindowTokens.radius * 2),
          border: Border.all(
            color: _focus.hasFocus ? WindowTokens.accentInk : WindowTokens.well,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.attachments.isNotEmpty) ...[
              Wrap(
                spacing: Shape.s(4),
                runSpacing: Shape.s(4),
                children: [
                  for (final path in widget.attachments)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Shape.s(6),
                        vertical: Shape.s(2),
                      ),
                      decoration: BoxDecoration(
                        color: WindowTokens.card,
                        borderRadius: Shape.round(WindowTokens.chipRadius),
                        border: Border.all(color: WindowTokens.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            path.split('/').last,
                            style: TextStyles.micro(Grey.g91),
                          ),
                          if (widget.onRemoveAttachment != null) ...[
                            SizedBox(width: Shape.s(4)),
                            GestureDetector(
                              onTap: () => widget.onRemoveAttachment!(path),
                              child: Text(
                                '×',
                                style: TextStyles.micro(Grey.g56),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: Shape.s(6)),
            ],
            // Shift-Enter is a new line; Enter alone goes to the text input as its send action.
            Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.enter, shift: true):
                    _NewLine(),
              },
              child: Actions(
                actions: {
                  _NewLine: CallbackAction<_NewLine>(
                    onInvoke: (_) => _newLine(),
                  ),
                },
                child: NakedTextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  minLines: 2,
                  maxLines: 10,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: TextStyles.name(Grey.g95, 11, null, 1.4),
                  cursorColor: WindowTokens.accent,
                  cursorWidth: 1.5,
                  builder: (context, field, editable) => Stack(
                    children: [
                      if (!field.hasText)
                        IgnorePointer(
                          child: Text(
                            hint,
                            style: TextStyles.name(Grey.g56, 11, null, 1.4),
                          ),
                        ),
                      editable,
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: Shape.s(6)),
            ContextMenu(
              key: _cmdMenu,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.onAttach != null)
                    DockHover(
                      onTap: widget.onAttach,
                      builder: (context, h) => Padding(
                        padding: EdgeInsets.only(right: Shape.s(8)),
                        child: Text(
                          '+ File',
                          style: TextStyles.label(h ? Grey.g95 : Grey.g63),
                        ),
                      ),
                    ),
                  if (talk.commands.isNotEmpty)
                    GestureDetector(
                      onTapUp: (d) => _showCommands(d.globalPosition),
                      child: DockHover(
                        builder: (context, h) => Padding(
                          padding: EdgeInsets.only(right: Shape.s(8)),
                          child: Text(
                            '/',
                            style: TextStyles.label(h ? Grey.g95 : Grey.g63),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  AgentSettings(talk),
                  SizedBox(width: Shape.s(8)),
                  _button(talk),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommands(Offset global) {
    final box = _cmdMenu.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _cmdMenu.currentState?.show(box.globalToLocal(global), [
      for (final cmd in widget.talk.commands)
        ContextMenuItem(
          '/${cmd.name}',
          () {
            final prefix = '/${cmd.name} ';
            widget.controller
              ..text = prefix
              ..selection = TextSelection.collapsed(offset: prefix.length);
            _focus.requestFocus();
          },
          why: cmd.description,
          id: 'agent-cmd-${cmd.name}',
        ),
    ]);
  }

  /// Puts a line break where the caret is, as Shift-Enter does in the Claude app.
  void _newLine() {
    final c = widget.controller, at = c.selection;
    if (!at.isValid) return;
    c.value = c.value.replaced(at, '\n');
  }

  /// Send, or Stop while the agent works: a round button at the end of the row.
  Widget _button(AcpChatSession talk) {
    final working = talk.sending,
        can =
            working || (talk.ready && widget.controller.text.trim().isNotEmpty);
    return DockHover(
      onTap: !can ? null : (working ? talk.stop : _send),
      builder: (context, h) => Container(
        width: Shape.z(22),
        height: Shape.z(22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: !can
              ? Grey.g26
              : (h ? WindowTokens.accentInk : WindowTokens.accent),
        ),
        child: Text(
          working ? '■' : '↑',
          style: TextStyles.name(can ? Grey.g07 : Grey.g56, 11),
        ),
      ),
    );
  }
}

class _NewLine extends Intent {
  const _NewLine();
}
