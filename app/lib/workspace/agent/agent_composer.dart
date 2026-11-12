// Where a request is written, laid out as the Claude app's message box: one well with the text on top and, under it
// at the right, the agent's settings and usage (agent_settings.dart) and Send (Stop while the agent works). The text is naked_ui's NakedTextField (EditableText with
// Flutter TextField's gestures, IME and keys), so Motolii draws only its looks. Enter sends; Shift-Enter starts a line.
import 'package:flutter/services.dart' show LogicalKeyboardKey, TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/agent/acp_chat_session.dart';
import 'package:motolii/workspace/agent/agent_settings.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

class AgentComposer extends StatefulWidget {
  const AgentComposer({
    super.key,
    required this.talk,
    required this.controller,
    required this.onSend,
  });
  final AcpChatSession talk;
  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  State<AgentComposer> createState() => _AgentComposerState();
}

class _AgentComposerState extends State<AgentComposer> {
  final _focus = FocusNode();

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
        ? 'Ask ${talk.agentName}'
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
          borderRadius: BorderRadius.all(Shape.r(WindowTokens.radius * 2)),
          border: Border.all(
            color: _focus.hasFocus ? WindowTokens.accentInk : WindowTokens.well,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                AgentSettings(talk),
                SizedBox(width: Shape.s(8)),
                _button(talk),
              ],
            ),
          ],
        ),
      ),
    );
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
