// Selection gestures for the app's text fields: a click places the caret, a double-click selects a word, a drag selects a range
// and a Shift-click extends it.
//
// This wraps Flutter's TextSelectionGestureDetectorBuilder around the field the way TextField wraps its EditableText
// (see material/text_field.dart in Flutter: buildGestureDetector, translucent behavior, EditableText keyed by the delegate,
// rendererIgnoresPointer). A bare EditableText only places the caret and cannot select a word by double-click.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';

/// Gives an [EditableText] Flutter's text selection gestures.
class TextGestures extends StatefulWidget {
  const TextGestures({super.key, required this.field});

  /// Builds the field. It must use the given key and set rendererIgnoresPointer to true, because the pointer is handled here.
  final EditableText Function(GlobalKey<EditableTextState> key) field;

  @override
  State<TextGestures> createState() => _TextGesturesState();
}

class _TextGesturesState extends State<TextGestures>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final editableTextKey = GlobalKey<EditableTextState>();
  @override
  bool get forcePressEnabled => false;
  @override
  bool get selectionEnabled => true;
  late final _gestures = TextSelectionGestureDetectorBuilder(delegate: this);

  @override
  Widget build(BuildContext context) => _gestures.buildGestureDetector(
    behavior: HitTestBehavior.translucent,
    child: widget.field(editableTextKey),
  );
}

/// The app's single text field for typing.
///
/// [onDone] is called once when the user leaves the field, with the typed text. Return leaves with the text; Esc cancels,
/// restores the old text and passes null. The field owns its controller and focus node. The caller only decides whether it is shown.
class TypedField extends StatefulWidget {
  const TypedField({
    super.key,
    required this.text,
    required this.style,
    required this.cursor,
    required this.onDone,
    this.selection,
    this.backgroundCursor,
    this.cursorWidth = 2.0,
    this.align = TextAlign.start,
    this.lines = 1,
    this.take = false,
    this.standing = false,
    this.pickOnFocus = false,
    this.sayOnLeave = true,
    this.escapes = false,
    this.hold,
    this.onPick,
    this.styled,
  });
  final String text;
  final TextStyle style;
  final Color cursor;
  final Color? selection, backgroundCursor;
  final double cursorWidth;
  final TextAlign align;
  final int lines;

  /// [take]: when built with true, takes focus and selects all the text.
  /// [standing]: the field is always shown, displays [text] while unfocused, and reports only a changed text.
  /// [pickOnFocus]: selects all the text whenever the field gains focus.
  /// [sayOnLeave]: when false, only Return reports the text.
  /// [escapes]: Esc cancels.
  final bool take, standing, pickOnFocus, sayOnLeave, escapes;
  final void Function(String? said) onDone;

  /// When it returns true, leaving the field is ignored.
  final bool Function()? hold;

  /// Called while the field has focus with its text and selection.
  final ValueChanged<TextEditingValue>? onPick;

  /// Sets the text in spans of their own styles, as a rich text box does; the text typed stays plain.
  /// With it, Return starts a new line and only leaving the field reports the text.
  final InlineSpan Function(String text, TextStyle style)? styled;
  @override
  State<TypedField> createState() => TypedFieldState();
}

class TypedFieldState extends State<TypedField> {
  late final TextEditingController _c = _Styled(this, widget.text)
    ..addListener(() => _f.hasFocus ? widget.onPick?.call(_c.value) : null);
  late final FocusNode _f = FocusNode()..addListener(_moved);
  // The text when the user entered the field. Null while the field is not focused.
  String? _was;
  bool _took = false;
  // How the user is leaving: true for Return, false for Esc.
  bool? _end;

  /// Replaces the text. For the caller to use while the field stays shown.
  void put(String text) => _c.text = text;

  /// Whether the field has focus.
  bool get focused => _f.hasFocus;

  void _take() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _c.selection = TextSelection(baseOffset: 0, extentOffset: _c.text.length);
    _f.requestFocus();
  });

  void _leave(bool returned) {
    _end = returned;
    _f.unfocus();
  }

  void _moved() {
    if (_f.hasFocus) {
      _was = _c.text;
      if (widget.pickOnFocus) _take();
      return;
    }
    final was = _was;
    if (was == null || (widget.hold?.call() ?? false)) return;
    final said =
        _end != false &&
            (widget.sayOnLeave || _end == true) &&
            (!widget.standing || _c.text != was)
        ? _c.text
        : null;
    if (_end == false) _c.text = was;
    _was = _end = null;
    widget.onDone(said);
  }

  @override
  void dispose() {
    _f.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    // Once for each request.
    if (w.take != _took && (_took = w.take)) _take();
    // Without focus the field shows the caller's current text.
    if (w.standing && !_f.hasFocus && _c.text != w.text) _c.text = w.text;
    final field = TextGestures(
      field: (k) => EditableText(
        key: k,
        rendererIgnoresPointer: true,
        controller: _c,
        focusNode: _f,
        style: w.style,
        cursorColor: w.cursor,
        backgroundCursorColor: w.backgroundCursor ?? Grey.g38,
        selectionColor: w.selection,
        cursorWidth: w.cursorWidth,
        textAlign: w.align,
        minLines: w.lines,
        maxLines: w.styled == null ? w.lines : null,
        keyboardType: w.styled == null ? null : TextInputType.multiline,
        onSubmitted: w.styled == null ? (_) => _leave(true) : null,
      ),
    );
    return w.escapes
        ? CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  _leave(false),
            },
            child: field,
          )
        : field;
  }
}

/// The field's text, set in the spans [TypedField.styled] gives.
class _Styled extends TextEditingController {
  _Styled(this.of, String text) : super(text: text);
  final TypedFieldState of;
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => switch (of.widget.styled) {
    final styled? when !value.composing.isValid || !withComposing => TextSpan(
      style: style,
      children: [styled(text, style ?? const TextStyle())],
    ),
    _ => super.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    ),
  };
}

/// The selection in an item's text, kept after the field loses focus so a colour can be applied to it.
/// Figma and Canva also keep the text selection while a colour is chosen.
/// Holds the text and the start and end of the selection, or null when nothing is selected.
final wordsPicked = ValueNotifier<({String text, int start, int end})?>(null);

/// Whether the next text-content field should take keyboard focus with all its text selected.
/// The preview sets it when it places a new text, so that typing replaces the text at once.
/// AbsentMotion's addText opens its EditText panel, and Figma's text tool types where the text was placed.
bool textToType = false;
