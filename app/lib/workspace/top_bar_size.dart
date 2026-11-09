// The top bar's picture size: the chip that shows it, scrubbed or typed, and the shapes and heights it offers.
part of 'top_bar.dart';

/// The document's size, beside the others: pressed twice it is written over (a width alone keeps the shape; width and
/// height, as 1080x1920, set both), scrubbed sideways it moves the width 1% every 3 px, the shape kept, and
/// the document is opened again at it when the hand lets go.
class _SizeChip extends StatefulWidget {
  const _SizeChip();
  @override
  State<_SizeChip> createState() => _SizeChipState();
}

/// Alight Motion's new-project box, its shapes and its resolutions (each the shorter side, as its 2160p to 270p are):
/// a shape and a resolution pressed is the document's size, opened again at it.
const sizeShapes = [('16:9', 16, 9), ('9:16', 9, 16), ('4:5', 4, 5), ('1:1', 1, 1), ('4:3', 4, 3)];

const sizeResolutions = [2160, 1440, 1080, 720, 540, 360, 270];

(int, int) sizeOf((String, int, int) shape, int p) {
  final (_, a, b) = shape;
  int even(double v) => (v / 2).round() * 2; // (an even number of pixels: H.264 asks it)
  return a >= b ? (even(p * a / b), p) : (p, even(p * b / a));
}

/// A new document asks for its size, as Alight Motion's new-project box comes first: the size chip's box opened once the
/// window shows the new one (true until it is).
final wsAskSize = ValueNotifier<bool>(false);

class _SizeChipState extends State<_SizeChip> {
  final _text = TextEditingController(), _focus = FocusNode(), _box = OverlayPortalController(), _boxKeys = FocusNode(debugLabel: 'document box');
  bool _editing = false;
  double? _scrub; // (the width being scrubbed to)
  double _dx = 0;

  @override
  void initState() {
    super.initState();
    wsAskSize.addListener(_asked);
    WidgetsBinding.instance.addPostFrameCallback((_) => _asked()); // (asked while the window was opening the new one)
  }

  void _asked() {
    if (!mounted || !wsAskSize.value || WsScope.read(context).onSize == null) return;
    wsAskSize.value = false;
    _box.show();
  }

  @override
  void dispose() {
    wsAskSize.removeListener(_asked);
    _text.dispose();
    _focus.dispose();
    _boxKeys.dispose();
    super.dispose();
  }

  void _commit(Ws ws) {
    final nums = RegExp(r'\d+').allMatches(_text.text).map((m) => int.parse(m.group(0)!)).toList();
    setState(() => _editing = false);
    if (nums.isEmpty || ws.onSize == null) return;
    final w0 = WsArt.comp.width, h0 = WsArt.comp.height;
    final w = nums[0], h = nums.length > 1 ? nums[1] : (nums[0] * h0 / w0).round();
    if (w >= 16 && h >= 16 && w <= 16384 && h <= 16384 && (w != w0.round() || h != h0.round())) ws.onSize!(w, h);
  }

  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.document}), w0 = WsArt.comp.width, h0 = WsArt.comp.height;
    final shownW = (_scrub ?? w0).round(), shownH = (shownW * h0 / w0).round();
    if (_editing) {
      return Container(
        height: Shape.z(20),
        width: Shape.z(92),
        padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: WsT.well,
          borderRadius: BorderRadius.all(Shape.r(WsT.chipRadius)),
          border: Border.all(color: WsT.accent),
        ),
        child: TextGestures(
          field: (k) => EditableText(
            key: k,
            rendererIgnoresPointer: true,
            controller: _text,
            focusNode: _focus,
            style: T.value(Grey.g95).copyWith(fontSize: T.px(10)),
            cursorColor: WsT.accent,
            backgroundCursorColor: Grey.g38,
            maxLines: 1,
            onSubmitted: (_) => _commit(ws),
            onTapOutside: (_) => _commit(ws),
          ),
        ),
      );
    }
    // (pressed once: the shapes and resolutions; the one it is now lit, a shape of its own said as it is)
    final short = math.min(w0, h0).round(), now = sizeShapes.where((s) => sizeOf(s, short) == (w0.round(), h0.round())).firstOrNull;
    // (Esc and ⌘. cancel, as the name box's above: a Mac dialog's Cancel; it has no field to hold the keys, so it holds
    //  them itself: golf_noise.md (75))
    Widget box(BuildContext _) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _box.isShowing && !_boxKeys.hasFocus ? _boxKeys.requestFocus() : null,
      ); // (the keys taken from whatever had them as it opens)
      return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _box.hide, const SingleActivator(LogicalKeyboardKey.period, meta: true): _box.hide},
        child: Focus(
          focusNode: _boxKeys,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _box.hide,
                  child: const ColoredBox(color: Color(0x88000000)),
                ),
              ),
              Center(
                child: Container(
                  key: const ValueKey('ws-size-box'),
                  width: Shape.z(380),
                  padding: EdgeInsets.all(Shape.s(16)),
                  decoration: BoxDecoration(
                    color: WsT.card,
                    borderRadius: BorderRadius.all(Shape.r(8)),
                    border: Border.all(color: WsT.line),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Document', style: T.title(Grey.g95).copyWith(fontWeight: FontWeight.w700)),
                      SizedBox(height: Shape.s(12)),
                      Text('Shape', style: T.label(Grey.g56)),
                      SizedBox(height: Shape.s(6)),
                      Wrap(
                        spacing: Shape.s(6),
                        runSpacing: Shape.s(6),
                        children: [
                          for (final s in sizeShapes)
                            ToolChip(key: ValueKey('size-${s.$1}'), label: s.$1, on: s == now, onTap: () => _to(ws, sizeOf(s, short))),
                          if (now == null) ToolChip(label: '$shownW:$shownH', on: true, onTap: () {}), // (its own: a size typed)
                        ],
                      ),
                      SizedBox(height: Shape.s(12)),
                      Text('Resolution', style: T.label(Grey.g56)),
                      SizedBox(height: Shape.s(6)),
                      Wrap(
                        spacing: Shape.s(6),
                        runSpacing: Shape.s(6),
                        children: [
                          for (final p in sizeResolutions)
                            ToolChip(
                              key: ValueKey('size-${p}p'),
                              label: '${p}p',
                              on: p == short,
                              onTap: () => _to(ws, now == null ? ((p * w0 / short).round(), (p * h0 / short).round()) : sizeOf(now, p)),
                            ),
                        ],
                      ),
                      SizedBox(height: Shape.s(12)),
                      Text(
                        'Frame rate',
                        style: T.label(Grey.g56),
                      ), // (Alight Motion's ten, as AbsentMotion's NewProjectSheet lists them: the document seen only at its frames, written at them too)
                      SizedBox(height: Shape.s(6)),
                      Wrap(
                        spacing: Shape.s(6),
                        runSpacing: Shape.s(6),
                        children: [
                          for (final r in const [12, 15, 18, 20, 24, 25, 30, 48, 50, 60])
                            ToolChip(
                              key: ValueKey('size-${r}fps'),
                              label: '$r',
                              on: r == Ws.fps,
                              onTap: ws.inside == null
                                  ? null
                                  : () => ws.after(
                                      ws.inside!.later('set', thing: 0, name: 'frame_rate', number: r == ws.inside!.rate ? 0 : r.toDouble()),
                                      (_, _) => ws.reread(),
                                    ),
                            ),
                        ],
                      ),
                      SizedBox(height: Shape.s(12)),
                      Text(
                        'Background',
                        style: T.label(Grey.g56),
                      ), // (AbsentMotion's NewProjectSheet's six: the colour behind everything, the stage's background; Transparent: none, and written clear)
                      SizedBox(height: Shape.s(6)),
                      Wrap(
                        spacing: Shape.s(6),
                        runSpacing: Shape.s(6),
                        children: [
                          for (final (label, hex) in const [
                            ('Black', '000000'),
                            ('White', 'ffffff'),
                            ('Light Gray', 'd8d8d8'),
                            ('Green', '00b140'),
                            ('Blue', '0047bb'),
                            ('Transparent', ''),
                          ])
                            ToolChip(
                              key: ValueKey('size-bg-$label'),
                              label: label,
                              on: (ws.inside?.word(0, 'background') ?? '') == hex,
                              onTap: ws.inside == null
                                  ? null
                                  : () {
                                      final m = ws.inside!;
                                      m.later('together', number: 1);
                                      m.later('say', thing: 0, name: 'background', word: hex);
                                      m.later('set', thing: 0, name: 'render_alpha', number: hex.isEmpty ? 1 : 0);
                                      ws.after(m.later('together'), (_, _) => ws.reread());
                                    },
                            ),
                        ],
                      ),
                      SizedBox(height: Shape.s(12)),
                      Text('New layer length', style: T.label(Grey.g56)), // (how long a thing put in lasts: AbsentMotion's settings' New Layer Length, its AppSettings.LAYER_DURATIONS; End, to the document's end)
                      SizedBox(height: Shape.s(6)),
                      Wrap(
                        spacing: Shape.s(6),
                        runSpacing: Shape.s(6),
                        children: [
                          for (final n in const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 45, 60])
                            ToolChip(
                              key: ValueKey('size-len-$n'),
                              label: n == 0 ? 'End' : '${n}s',
                              on: (ws.inside?.value(0, 'layer_length', 0) ?? 0).round() == n,
                              onTap: ws.inside == null
                                  ? null
                                  : () => ws.after(ws.inside!.later('set', thing: 0, name: 'layer_length', number: n.toDouble()), (_, _) => ws.reread()),
                            ),
                        ],
                      ),
                      SizedBox(height: Shape.s(12)),
                      Text('$shownW × $shownH  ·  ${Ws.fps} frames a second', style: T.value(Grey.g76)),
                      if (ws.inside case final m?) ...[
                        // (Alight Motion's Total Edit Time, in its settings: how long the document has been worked on)
                        SizedBox(height: Shape.s(6)),
                        Text('Total Edit Time  ${m.edited ~/ 3600}h ${(m.edited % 3600) ~/ 60}m', key: const ValueKey('size-edited'), style: T.value(Grey.g63)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return OverlayPortal(
      controller: _box,
      overlayChildBuilder: box,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          supportedDevices: wsPressing,
          key: const ValueKey('ws-top-size'),
          behavior: HitTestBehavior.opaque,
          onTap: ws.onSize == null ? null : _box.show,
          onDoubleTap: ws.onSize == null
              ? null
              : () {
                  _text.text = '${w0.round()}x${h0.round()}';
                  _text.selection = TextSelection(baseOffset: 0, extentOffset: _text.text.length);
                  setState(() => _editing = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
                },
          onHorizontalDragStart: (_) => _dx = 0,
          onHorizontalDragUpdate: (e) => setState(() => _scrub = math.max(16, w0 + w0 * ((_dx += e.delta.dx) / 3).round() / 100)),
          onHorizontalDragEnd: (_) {
            final w = _scrub?.round();
            setState(() => _scrub = null);
            if (w != null && w != w0.round() && ws.onSize != null) ws.onSize!(w, (w * h0 / w0).round());
          },
          child: _Chip('$shownW × $shownH'),
        ),
      ),
    );
  }

  void _to(Ws ws, (int, int) size) {
    _box.hide();
    if (size != (WsArt.comp.width.round(), WsArt.comp.height.round())) ws.onSize?.call(size.$1, size.$2);
  }
}
