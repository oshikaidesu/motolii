// Golden: inspector host cards contact sheet.
// Renders every custom host card side by side at real inspector width (340px)
// so visual tone, containers, icons, and density can be compared at a glance.
// Run with:
//   flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes --update-goldens test/golden/host_cards_golden_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/card_declaration.dart' show CardDeclaration;
import 'package:motolii/inspector/inspected_layer.dart';
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_host.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/values_card.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/font_files.dart' show loadFontFile;

import '../main_tests_only.dart';

const _transform = '''
struct Params {
  /// @label(Space) @enum(2d, 2.5d, 3d) @default(0)
  space: u32,
  /// @label(Parent) @enum(None, Title) @default(0)
  parent: u32,
  /// @label(Position X) @ui(bipolar) @range(-3840, 3840) @unit(px) @default(960)
  x: f32,
  /// @label(Position Y) @ui(bipolar) @range(-2160, 2160) @unit(px) @default(540)
  y: f32,
  /// @label(Position Z) @ui(bipolar) @range(-5000, 5000) @unit(px) @default(0)
  z: f32,
  /// @label(Scale X) @ui(bar) @range(0, 400) @unit(%) @default(100)
  scale_x: f32,
  /// @label(Scale Y) @ui(bar) @range(0, 400) @unit(%) @default(100)
  scale_y: f32,
  /// @label(Scale Z) @ui(bar) @range(0, 400) @unit(%) @default(100)
  scale_z: f32,
  /// @label(Rotation X) @ui(angle) @range(-360, 360) @unit(°) @default(0)
  rotate_x: f32,
  /// @label(Rotation Y) @ui(angle) @range(-360, 360) @unit(°) @default(0)
  rotate_y: f32,
  /// @label(Rotation) @ui(angle) @range(-360, 360) @unit(°) @default(12)
  rotate: f32,
  /// @label(Opacity) @ui(percent) @range(0, 100) @unit(%) @default(100)
  opacity: f32,
  // @advanced(Anchor)
  /// @label(Anchor X) @ui(bar) @range(0, 100) @unit(%) @default(50)
  anchor_x: f32,
  /// @label(Anchor Y) @ui(bar) @range(0, 100) @unit(%) @default(50)
  anchor_y: f32,
  /// @label(Anchor Z) @ui(bipolar) @range(-50, 50) @unit(%) @default(0)
  anchor_z: f32,
}
''';

const _fill = '''
struct Params {
  /// @label(Fill) @unit(colours)
  fill: vec3<f32>,
  /// @label(Gradient) @enum(linear, radial) @default(0)
  gradient: u32,
  /// @label(Stroke) @unit(colours)
  stroke: vec3<f32>,
  /// @label(Stroke width) @ui(bar) @range(0, 16) @unit(px) @default(2)
  stroke_width: f32,
  /// @label(Align) @enum(center, inside, outside) @default(2)
  stroke_align: u32,
  // @advanced(Gradient)
  /// @label(Angle) @ui(angle) @range(-180, 180) @unit(°) @default(45)
  gradient_angle: f32,
  /// @label(Stretch) @ui(bar) @range(0.1, 4) @unit(×) @default(1)
  gradient_scale: f32,
  /// @label(Past end) @enum(pad, reflect, repeat) @default(0)
  gradient_spread: u32,
}
''';

const _extraStroke = '''
struct Params {
  /// @label(Stroke) @unit(colours)
  a1b2c3:stroke: vec3<f32>,
  /// @label(Width) @ui(bar) @range(0, 16) @unit(px) @default(4)
  a1b2c3:stroke_width: f32,
  /// @label(Cap) @enum(butt, round, square) @default(1)
  a1b2c3:cap: u32,
  /// @label(Join) @enum(miter, round, bevel) @default(1)
  a1b2c3:join: u32,
  /// @label(Align) @enum(center, inside, outside) @default(1)
  a1b2c3:stroke_align: u32,
}
''';

const _blending = '''
struct Params {
  /// @label(Blend) @enum(normal, add, multiply, screen, overlay, soft_light, difference) @default(4)
  blend: u32,
  /// @label(Clip to below) @toggle @range(0, 1) @default(1)
  clip: u32,
  /// @label(Matte) @enum(alpha, luma) @default(0)
  clip_matte: u32,
  /// @label(Invert) @toggle @range(0, 1) @default(0)
  clip_invert: u32,
  /// @label(Feather) @ui(bar) @range(0, 100) @unit(px) @default(12)
  clip_feather: f32,
}
''';

const _paths = '''
struct Params {
  /// @label(Points) @ui(bar) @range(3, 12) @unit() @default(5)
  points: f32,
  /// @label(Inner) @ui(bar) @range(0, 1) @unit() @default(0.45)
  inner: f32,
  /// @label(Operators) @unit(words)
  path_ops: vec3<f32>,
  /// @label(Round) @ui(bar) @range(0, 1) @unit() @default(0.15)
  round: f32,
  /// @label(Bloat) @ui(bipolar) @range(-1, 1) @unit() @default(0)
  bloat: f32,
  /// @label(Offset) @ui(bipolar) @range(-20, 20) @unit(px) @default(0)
  offset: f32,
  /// @label(Zig zag) @ui(bar) @range(0, 20) @unit(px) @default(2)
  zigzag: f32,
  /// @label(Fill rule) @enum(nonzero, evenodd) @default(0)
  fill_rule: u32,
  /// @label(Trim) @ui(bar) @range(0, 1) @unit() @default(0.8)
  trim: f32,
  /// @label(Trim offset) @ui(bar) @range(0, 1) @unit() @default(0)
  trim_offset: f32,
  // @advanced(Zig zag)
  /// @label(Ridges) @ui(bar) @range(1, 30) @unit() @default(8)
  zigzag_ridges: f32,
  /// @label(Smooth) @ui(bar) @range(0, 1) @unit() @default(0.5)
  zigzag_smooth: f32,
}
''';

const _text = '''
struct Params {
  /// @label(Text) @unit(words)
  text: vec3<f32>,
  /// @label(Styles) @unit(words)
  text_styles: vec3<f32>,
  /// @label(Font) @unit(file)
  file: vec3<f32>,
  /// @label(Size) @ui(bar) @range(0, 2) @unit(px) @default(0.08)
  size: f32,
  /// @label(Tracking) @ui(bipolar) @range(-100, 500) @unit() @default(0)
  letter_spacing: f32,
  /// @label(Line Height) @ui(bar) @range(0.5, 3) @unit(×) @default(1.2)
  line_spacing: f32,
  /// @label(Align) @ui(percent) @range(0, 1) @unit(%) @default(0.5)
  align: f32,
  /// @label(Slant) @ui(bar) @range(0, 20) @unit(°) @default(0)
  italic: f32,
  /// @label(Direction) @enum(horizontal, vertical) @default(0)
  writing: u32,
  /// @label(Metrics) @enum(fixed, proportional, half_width) @default(1)
  metrics: u32,
  /// @label(Kinsoku) @enum(normal, strict, loose, none) @default(1)
  kinsoku: u32,
  /// @label(Hanging) @toggle @range(0, 1) @default(1)
  hanging: u32,
  /// @label(Features) @unit(words)
  font_features: vec3<f32>,
  /// @label(Wrap) @enum(none, character, word, smart, ellipsis, vertical) @default(0)
  wrap: u32,
  /// @label(Wrap at) @ui(bar) @range(0, 40) @unit(×) @default(12)
  wrap_at: f32,
}
''';

const _media = '''
struct Params {
  /// @label(In) @ui(bar) @range(0, 60) @unit(s) @default(12)
  begin: f32,
  /// @label(Speed) @ui(bipolar) @range(-4, 4) @unit(×) @default(1)
  speed: f32,
  /// @label(Hold at) @enum(start, playhead, end) @default(1)
  speed_hold: u32,
  /// @label(Frame rate) @ui(bar) @range(0, 60) @unit(fps) @default(24)
  frame_rate: f32,
  /// @label(Volume) @ui(percent) @range(0, 100) @unit(%) @default(100)
  volume: f32,
}
''';

const _camera = '''
struct Params {
  /// @label(Focal length) @ui(bar) @range(12, 200) @unit(mm) @default(50)
  focal_length: f32,
  /// @label(Focus) @ui(bar) @range(0.1, 20) @unit(m) @default(4)
  focus: f32,
  /// @label(Aperture) @ui(bar) @range(1.4, 22) @unit(f) @default(2.8)
  aperture: f32,
}
''';

Widget _host(
  List<CardDeclaration> cards, {
  Kind kind = Kind.shape,
  Map<String, double> numbers = const {},
  Map<String, String> words = const {},
  Map<String, bool> flags = const {},
  Map<String, KeyframeState> keyMarks = const {},
  CardActions actions = const CardActions(),
  bool openAnchor = false,
}) {
  final live = ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>(
    (const {}, const {}),
  );
  return InspectorHost(
    layer: InspectedLayer(kind: kind, title: 'Sample', cards: cards),
    snapshot: InspectorSnapshot(
      numbers: numbers,
      words: words,
      flags: flags,
      keyMarks: keyMarks,
    ),
    actions: actions,
    edits: InspectorEdits(
      onValues: (_, {required live}) {},
      onDrop: () {},
      onKey: (_, _) {},
      onWords: (_, {required live}) => true,
      onAnimateAll: (_) {},
      together: (tells) => tells(),
      onRoute: (_) {},
      onAim: (_) {},
    ),
    live: live,
    child: _ColumnCards(openAnchor: openAnchor),
  );
}

class _ColumnCards extends StatefulWidget {
  const _ColumnCards({required this.openAnchor});
  final bool openAnchor;

  @override
  State<_ColumnCards> createState() => _ColumnCardsState();
}

class _ColumnCardsState extends State<_ColumnCards> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    if (widget.openAnchor && !_opened) {
      _opened = true;
      doc.flags['v.Transform.adv'] = true;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in doc.cards)
          if (c.name != 'Stroke') ValuesCard(c),
      ],
    );
  }
}

void main() {
  if (skipUnlessEveryTest()) return;

  testWidgets('host cards contact sheet', (tester) async {
    const colW = 340.0;
    const totalW = colW * 3 + 48.0;
    const totalH = 906.0;
    tester.view.physicalSize = const Size(totalW, totalH);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Load the real bundled Noto Sans JP font so the Text card preview renders
    // actual Japanese + Latin glyphs instead of Ahem tofu.
    await tester.runAsync(() => loadFontFile('fonts/NotoSansJP-Regular.otf'));

    CardDeclaration decl(String name, String wgsl) =>
        CardDeclaration(name, wgsl, toneOf: () => InspectorSkin.toneLayer);

    await tester.pumpWidget(
      WidgetsApp(
        color: Grey.g07,
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(settings, builder) =>
            PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
        home: ColoredBox(
          key: const ValueKey('contact-root'),
          color: Grey.g07,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: colW,
                  child: _host([
                    decl('Transform', _transform),
                  ], openAnchor: true),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: colW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _host(
                        [decl('Fill', _fill), decl('Stroke', _extraStroke)],
                        numbers: const {
                          'v_gradient': 0,
                          'v_stroke_width': 4,
                          'v_stroke_align': 2,
                          'v_a1b2c3:stroke_width': 3,
                          'v_a1b2c3:stroke_align': 1,
                        },
                        words: const {
                          'v_fill': '#59C3E8 #D64B7A',
                          'v_stroke': '#FFB84D #FF5A79',
                          'v_a1b2c3:stroke': '#FFFFFF',
                        },
                        actions: CardActions(
                          onAddStroke: () {},
                          onCardRemove: (_, _) {},
                        ),
                      ),
                      _host(
                        [decl('Blending', _blending)],
                        numbers: const {
                          'v_blend': 4,
                          'v_clip': 1,
                          'v_clip_matte': 0,
                          'v_clip_invert': 0,
                          'v_clip_feather': 12,
                        },
                      ),
                      _host(
                        [decl('Media', _media)],
                        kind: Kind.shape,
                        numbers: const {'v_begin': 18, 'v_speed': 1.5},
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: colW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _host(
                        [decl('Paths', _paths)],
                        numbers: const {
                          'v_points': 5,
                          'v_inner': 0.45,
                          'v_round': 0.15,
                          'v_zigzag': 2,
                          'v_zigzag_ridges': 8,
                          'v_zigzag_smooth': 0.5,
                          'v_trim': 0.8,
                        },
                        words: const {'shape': 'star'},
                        actions: CardActions(
                          shapeSvg: () =>
                              'M 0 -0.5 L 0.14 -0.15 L 0.48 -0.15 L 0.21 0.06 '
                              'L 0.30 0.40 L 0 0.20 L -0.30 0.40 L -0.21 0.06 '
                              'L -0.48 -0.15 L -0.14 -0.15 Z',
                        ),
                      ),
                      _host(
                        [decl('Text', _text)],
                        kind: Kind.text,
                        numbers: const {
                          'v_align': 0.5,
                          'v_metrics': 1,
                          'v_kinsoku': 1,
                          'v_hanging': 1,
                        },
                        words: const {
                          'v_text': 'Motolii 組版。\nひらがなテキスト',
                          'v_text_styles':
                              '@hiragana font-size: 85%\n0 7 color: #59C3E8',
                          'v_file': 'fonts/NotoSansJP-Regular.otf',
                          'v_font_features': 'tnum',
                        },
                        flags: const {'text.ot': true},
                        keyMarks: const {
                          'v_size': KeyframeState.at,
                          'v_italic': KeyframeState.off,
                          'v_letter_spacing': KeyframeState.off,
                          'v_line_spacing': KeyframeState.off,
                        },
                        actions: CardActions(
                          fontMeta: (_) =>
                              'features: kern liga palt tnum jp04 jp90 vert',
                        ),
                      ),
                      _host(
                        [decl('Camera', _camera)],
                        kind: Kind.camera,
                        numbers: const {
                          'v_rotate_x': -12,
                          'v_rotate_y': 24,
                          'v_rotate': 6,
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('contact-root')),
      matchesGoldenFile('goldens/host_cards_contact.png'),
    );
  });
}
