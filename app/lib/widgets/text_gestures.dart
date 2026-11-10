// text_gestures.dart: what a hand does in a field: a click puts the caret, a double click picks a word, a drag picks a
// range, a shift-click stretches it. Flutter's own TextSelectionGestureDetectorBuilder, wrapped round the field as its
// TextField wraps its EditableText (material/text_field.dart: buildGestureDetector, translucent, the EditableText keyed
// by the delegate and rendererIgnoresPointer). The window's fields are bare EditableTexts, which put the caret and no
// more (golf_noise.md ④: a word not picked by a double click).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';

class TextGestures extends StatefulWidget {
  const TextGestures({super.key, required this.field});

  /// The field, carrying [key] and rendererIgnoresPointer: true (the hand is this one's, not the field's own).
  final EditableText Function(GlobalKey<EditableTextState> key) field;

  @override
  State<TextGestures> createState() => _TextGesturesState();
}

class _TextGesturesState extends State<TextGestures> implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final editableTextKey = GlobalKey<EditableTextState>();
  @override
  bool get forcePressEnabled => false;
  @override
  bool get selectionEnabled => true;
  late final _gestures = TextSelectionGestureDetectorBuilder(delegate: this);

  @override
  Widget build(BuildContext context) => _gestures.buildGestureDetector(behavior: HitTestBehavior.translucent, child: widget.field(editableTextKey));
}

/// The one field the window types in: it says what was typed once, when the hand leaves it ([onDone]; Return leaves, Esc
/// cancels and puts the old back with null). It owns its controller and focus; the owner holds only whether it is shown.
/// [take]: takes the keys with all of it picked, when built so. [standing]: always there, shows [text] while unfocused and
/// says only a change. [sayOnLeave] false: only Return says. [escapes]: Esc is the cancel. [hold]: true, a leave is ignored.
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
  });
  final String text;
  final TextStyle style;
  final Color cursor;
  final Color? selection, backgroundCursor;
  final double cursorWidth;
  final TextAlign align;
  final int lines;
  final bool take, standing, pickOnFocus, sayOnLeave, escapes;
  final void Function(String? said) onDone;
  final bool Function()? hold;
  final ValueChanged<TextEditingValue>? onPick; // (while focused, its text and what is picked of it)
  @override
  State<TypedField> createState() => TypedFieldState();
}

class TypedFieldState extends State<TypedField> {
  late final TextEditingController _c = TextEditingController(text: widget.text)..addListener(() => _f.hasFocus ? widget.onPick?.call(_c.value) : null);
  late final FocusNode _f = FocusNode()..addListener(_moved);
  String? _was; // (what it held as the hand came in: null, the hand is not in)
  bool _took = false;
  bool? _end; // (how the hand is leaving: true Return, false Esc)

  /// Writes over what is in it, and whether the hand is in it (the owner's, while the field stays).
  void put(String text) => _c.text = text;
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
    final said = _end != false && (widget.sayOnLeave || _end == true) && (!widget.standing || _c.text != was) ? _c.text : null;
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
    if (w.take != _took && (_took = w.take)) _take(); // (once each time it is asked)
    if (w.standing && !_f.hasFocus && _c.text != w.text) _c.text = w.text; // (out of the field it is what the owner has now)
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
        maxLines: w.lines,
        onSubmitted: (_) => _leave(true),
      ),
    );
    return w.escapes ? CallbackShortcuts(bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _leave(false)}, child: field) : field;
  }
}

/// The letters picked in a thing's words, kept after the field lets go of the hand (Figma's and Canva's text keep their
/// selection while a colour is chosen for it): which words, and from where to where in them; null, none picked.
final wordsPicked = ValueNotifier<({String text, int start, int end})?>(null);
