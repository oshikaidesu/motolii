// Golden contact sheet showcasing all 5 pro VST custom card capabilities:
// 09. Audio Waveform + Beat Strikes + 16-Step Sequencer + Stereo VU (`Beat Sync Pro`)
// 10. Live GPU FragmentShader (`holo` / `metaball` / `vhs` / `grid`) + Gradient Bar (`Shader FX`)
// 11. Live2D / Rigify Character Body Picker + Expression Faders (`Rig Picker`)
// 12. FabFilter Multi-Point Curve Editor + Studio Console Faders + VU (`Pro Curve & Mix`)
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/card_declaration.dart' show CardDeclaration;
import 'package:motolii/inspector/inspected_layer.dart';
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_host.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/values_card.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';

const _params = '''
struct Params {
  /// @label(Amount) @ui(bar) @range(0, 1) @default(0.72)
  js_pro_amount: f32,
  /// @label(Drive) @ui(bar) @range(0, 1) @default(0.45)
  js_pro_drive: f32,
}
''';

const _characterSilhouetteSvg = '''
<svg viewBox="0 0 220 156" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bodyGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#3B4258"/>
      <stop offset="100%" stop-color="#222636"/>
    </linearGradient>
    <linearGradient id="hairGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#FF66A8"/>
      <stop offset="100%" stop-color="#8B5CF6"/>
    </linearGradient>
  </defs>
  <!-- Soft studio backdrop ring -->
  <circle cx="110" cy="76" r="64" fill="#181C28" stroke="#2D354C" stroke-width="1.2" stroke-dasharray="3 3"/>
  <!-- Shoulders & torso -->
  <path d="M62 154 C64 118 82 104 110 104 C138 104 156 118 158 154 Z" fill="url(#bodyGrad)" stroke="#556080" stroke-width="1.5"/>
  <!-- Neck -->
  <rect x="101" y="92" width="18" height="16" rx="6" fill="#E6C6B8"/>
  <!-- Back hair -->
  <path d="M72 62 C68 96 76 116 86 122 L134 122 C144 116 152 96 148 62 Z" fill="url(#hairGrad)" opacity="0.85"/>
  <!-- Head -->
  <ellipse cx="110" cy="64" rx="30" ry="33" fill="#F7DDD0" stroke="#4A3A40" stroke-width="1.4"/>
  <!-- Bangs -->
  <path d="M78 58 C82 28 138 28 142 58 C134 45 122 44 110 52 C98 44 86 46 78 58 Z" fill="url(#hairGrad)"/>
  <!-- Eyes & smile -->
  <ellipse cx="98" cy="66" rx="4.2" ry="5.2" fill="#2A1F33"/>
  <ellipse cx="122" cy="66" rx="4.2" ry="5.2" fill="#2A1F33"/>
  <circle cx="96.5" cy="64.2" r="1.4" fill="#FFFFFF"/>
  <circle cx="120.5" cy="64.2" r="1.4" fill="#FFFFFF"/>
  <path d="M103 80 Q110 86 117 80" fill="none" stroke="#B85675" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

List<double> _syntheticWave(double phase) => [
  for (var i = 0; i < 48; i++)
    () {
      final u = i / 47.0;
      final beat = (i % 12 == 2 || i % 12 == 8) ? 0.42 : 0.0;
      final v =
          0.16 +
          0.32 * math.sin(u * 15.0 + phase).abs() +
          0.22 * math.cos(u * 31.0 - phase * 1.4).abs() +
          beat;
      return v.clamp(0.06, 0.98);
    }(),
];

Widget _cardCol({
  required String cardTitle,
  required String tag,
  required Color tone,
  required Map<String, Object?> payload,
  required ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>
  live,
}) {
  final decl = CardDeclaration(cardTitle, _params, toneOf: () => tone);
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.micro(Grey.g63)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ),
        InspectorHost(
          layer: InspectedLayer(
            kind: Kind.shape,
            title: 'Hero Layer',
            cards: [decl],
            movable: [cardTitle],
          ),
          snapshot: const InspectorSnapshot(
            numbers: {'v_js_pro_amount': 0.72, 'v_js_pro_drive': 0.45},
          ),
          actions: CardActions(
            cardCustomUi: (title, names) => title == cardTitle
                ? (
                    uiFile: '$cardTitle.ui.js',
                    render: (_) => jsonEncode({'ok': true, 'ui': payload}),
                    action: (_, _) => '{"ok":true,"result":{}}',
                    liveSignal: null,
                    contextExtra: null,
                    applyOps: null,
                  )
                : null,
          ),
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
          child: ValuesCard(decl),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets(
    'VST pro cards showcase (waveform, sequencer, GPU shader, rig picker, curve/faders)',
    (tester) async {
      const w = 1360.0;
      const h = 440.0;
      tester.view.physicalSize = const Size(w * 2, h * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final live =
          ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>((
            const {},
            const {},
          ));
      addTearDown(live.dispose);

      // 09. Audio Waveform + Beat Strikes + 16-Step Sequencer + Stereo VU
      final beatSyncCard = {
        'hide': ['amount', 'drive'],
        'surface': {
          'bg': '#11141C',
          'bg2': '#1A1F2E',
          'fg': '#EDF2FF',
          'muted': '#818EA8',
          'accent': '#FF5E3A',
          'border': '#2C3448',
          'borderWidth': 1.4,
          'radius': 10,
          'pad': 10,
          'mono': true,
        },
        'ui': {
          'type': 'column',
          'style': {'gap': 8},
          'children': [
            {
              'type': 'row',
              'children': [
                {
                  'type': 'badge',
                  'text': '128 BPM · LIVE',
                  'style': {
                    'bg': '#FF5E3A',
                    'fg': '#FFFFFF',
                    'borderWidth': 0,
                    'radius': 4,
                    'mono': true,
                  },
                },
                {'type': 'spacer'},
                {
                  'type': 'text',
                  'text': 'THR 62%',
                  'style': {'fg': '#FFB547', 'mono': true, 'fontSize': 9},
                },
              ],
            },
            {
              'type': 'waveform',
              'id': 'wave',
              'height': 74,
              'samples': _syntheticWave(0.4),
              'playhead': 0.50,
              'threshold': 0.62,
              'strikes': [0.16, 0.42, 0.68, 0.90],
              'color': '#38BDF8',
              'peakColor': '#FF5E3A',
              'style': {'bg': '#0A0D13', 'border': '#273046', 'radius': 6},
            },
            {
              'type': 'sequencer',
              'id': 'seq',
              'label': '16-STEP BEAT TRIGGER',
              'cols': 8,
              'activeStep': 5,
              'color': '#FF5E3A',
              'steps': [1, 0, 0.5, 0, 1, 1, 0, 0.6, 1, 0, 0.8, 0, 1, 0, 0.5, 1],
              'style': {
                'bg': '#0D1018',
                'border': '#293247',
                'radius': 4,
                'height': 22,
              },
            },
            {
              'type': 'vu',
              'label': 'STEREO AUDIO DRIVE',
              'value': 0.78,
              'right': 0.71,
              'peak': 0.91,
              'segments': 20,
              'height': 13,
            },
          ],
        },
      };

      // 10. GPU FragmentShader Visualizer + Multi-Stop Gradient
      final gpuShaderCard = {
        'hide': ['amount', 'drive'],
        'surface': {
          'bg': '#12101A',
          'bg2': '#1B1628',
          'fg': '#F5ECFF',
          'muted': '#9A8CB5',
          'accent': '#E879F9',
          'border': '#382C54',
          'borderWidth': 1.4,
          'radius': 12,
          'pad': 10,
        },
        'ui': {
          'type': 'column',
          'style': {'gap': 8},
          'children': [
            {
              'type': 'stack',
              'children': [
                {
                  'type': 'shader',
                  'id': 'sh',
                  'preset': 'metaball',
                  'height': 124,
                  'time': 1.6,
                  'paramA': 0.76,
                  'paramB': 0.52,
                  'mouseX': 0.62,
                  'mouseY': 0.44,
                  'color': '#FF4DCA',
                  'color2': '#38BDF8',
                  'color3': '#7C3AED',
                  'style': {
                    'border': '#E879F966',
                    'borderWidth': 1.4,
                    'radius': 8,
                  },
                },
                {
                  'type': 'badge',
                  'text': 'GLSL · 60FPS',
                  'align': 'topLeft',
                  'inset': 7,
                  'style': {
                    'bg': '#120C20CC',
                    'fg': '#F0ABFC',
                    'border': '#E879F988',
                    'radius': 4,
                    'mono': true,
                    'fontSize': 8.5,
                  },
                },
              ],
            },
            {
              'type': 'gradient',
              'id': 'grad',
              'label': 'SHADER PALETTE (DRAG STOPS)',
              'height': 20,
              'stops': [
                {'pos': 0.0, 'color': '#FF4DCA'},
                {'pos': 0.48, 'color': '#8B5CF6'},
                {'pos': 1.0, 'color': '#38BDF8'},
              ],
            },
            {
              'type': 'row',
              'children': [
                {
                  'type': 'knob',
                  'id': 'amount',
                  'label': 'MORPH',
                  'value': 0.76,
                  'min': 0,
                  'max': 1,
                  'look': 'arc',
                  'size': 38,
                  'color': '#FF4DCA',
                  'capColor': '#1F1830',
                },
                {
                  'type': 'knob',
                  'id': 'drive',
                  'label': 'WARP',
                  'value': 0.52,
                  'min': 0,
                  'max': 1,
                  'look': 'arc',
                  'size': 38,
                  'color': '#38BDF8',
                  'capColor': '#1F1830',
                },
                {
                  'type': 'knob',
                  'id': 'glow',
                  'label': 'GLOW',
                  'value': 0.84,
                  'min': 0,
                  'max': 1,
                  'look': 'arc',
                  'size': 38,
                  'color': '#A78BFA',
                  'capColor': '#1F1830',
                },
              ],
            },
            {
              'type': 'select',
              'id': 'preset',
              'value': 'LIQUID',
              'options': ['HOLO', 'LIQUID', 'VHS', 'AURORA'],
              'style': {
                'bg': '#141022',
                'fg': '#B4A4D4',
                'accent': '#E879F9',
                'border': '#382C54',
                'radius': 5,
                'height': 22,
              },
            },
          ],
        },
      };

      // 11. Live2D / Rigify Character Body Picker + Expression Faders
      final rigPickerCard = {
        'hide': ['amount', 'drive'],
        'surface': {
          'bg': '#191D28',
          'bg2': '#12151E',
          'fg': '#F1F5FF',
          'muted': '#8E99B5',
          'accent': '#FF66A8',
          'border': '#323A52',
          'borderWidth': 1.4,
          'radius': 12,
          'pad': 10,
        },
        'ui': {
          'type': 'column',
          'style': {'gap': 8},
          'children': [
            {
              'type': 'picker',
              'id': 'rig',
              'label': 'CHARACTER RIG PICKER (DRAG PINS)',
              'height': 152,
              'svg': _characterSilhouetteSvg,
              'style': {'bg': '#10131C', 'border': '#2D354C', 'radius': 8},
              'pins': [
                {
                  'id': 'head',
                  'label': 'Head',
                  'x': 0.50,
                  'y': 0.24,
                  'color': '#FF66A8',
                  'active': true,
                },
                {
                  'id': 'eye_l',
                  'label': 'Eyes',
                  'x': 0.36,
                  'y': 0.42,
                  'color': '#38BDF8',
                },
                {
                  'id': 'mouth',
                  'label': 'Mouth',
                  'x': 0.50,
                  'y': 0.55,
                  'color': '#F59E0B',
                },
                {
                  'id': 'hair',
                  'label': 'Hair',
                  'x': 0.26,
                  'y': 0.66,
                  'color': '#A855F7',
                },
                {
                  'id': 'body',
                  'label': 'Body',
                  'x': 0.50,
                  'y': 0.80,
                  'color': '#10B981',
                },
              ],
            },
            {
              'type': 'row',
              'children': [
                {
                  'type': 'knob',
                  'id': 'blink',
                  'label': 'BLINK',
                  'value': 0.20,
                  'min': 0,
                  'max': 1,
                  'look': 'minimal',
                  'size': 38,
                  'color': '#38BDF8',
                },
                {
                  'type': 'knob',
                  'id': 'smile',
                  'label': 'SMILE',
                  'value': 0.78,
                  'min': 0,
                  'max': 1,
                  'look': 'minimal',
                  'size': 38,
                  'color': '#FF66A8',
                },
                {
                  'type': 'knob',
                  'id': 'sway',
                  'label': 'SWAY',
                  'value': 0.62,
                  'min': 0,
                  'max': 1,
                  'look': 'minimal',
                  'size': 38,
                  'color': '#A855F7',
                },
              ],
            },
            {
              'type': 'row',
              'children': [
                {
                  'type': 'button',
                  'id': 'p_idle',
                  'label': 'Idle',
                  'accent': true,
                },
                {'type': 'button', 'id': 'p_wink', 'label': 'Wink'},
                {'type': 'button', 'id': 'p_reset', 'label': 'Reset'},
              ],
            },
          ],
        },
      };

      // 12. FabFilter Multi-Point Curve Editor + Studio Console Faders
      final proCurveCard = {
        'hide': ['amount', 'drive'],
        'surface': {
          'bg': '#15181E',
          'bg2': '#0E1015',
          'fg': '#E8EEF5',
          'muted': '#7F8B9C',
          'accent': '#F59E0B',
          'border': '#2A303C',
          'borderWidth': 1.4,
          'radius': 10,
          'pad': 10,
          'mono': true,
        },
        'ui': {
          'type': 'column',
          'style': {'gap': 8},
          'children': [
            {
              'type': 'curve',
              'id': 'eq',
              'label': 'RESPONSE CURVE (DRAG NODES)',
              'height': 92,
              'color': '#F59E0B',
              'points': [
                {'x': 0.04, 'y': 0.35},
                {'x': 0.28, 'y': 0.78},
                {'x': 0.54, 'y': 0.42},
                {'x': 0.78, 'y': 0.86},
                {'x': 0.96, 'y': 0.60},
              ],
              'style': {'bg': '#0A0C10', 'border': '#272D38', 'radius': 6},
            },
            {
              'type': 'row',
              'children': [
                {
                  'type': 'fader',
                  'id': 'f_sub',
                  'label': 'SUB',
                  'value': 0.74,
                  'min': 0,
                  'max': 1,
                  'height': 96,
                  'color': '#F59E0B',
                },
                {
                  'type': 'fader',
                  'id': 'f_low',
                  'label': 'LOW',
                  'value': 0.56,
                  'min': 0,
                  'max': 1,
                  'height': 96,
                  'color': '#38BDF8',
                },
                {
                  'type': 'fader',
                  'id': 'f_mid',
                  'label': 'MID',
                  'value': 0.82,
                  'min': 0,
                  'max': 1,
                  'height': 96,
                  'color': '#A855F7',
                },
                {
                  'type': 'fader',
                  'id': 'f_air',
                  'label': 'AIR',
                  'value': 0.64,
                  'min': 0,
                  'max': 1,
                  'height': 96,
                  'color': '#10B981',
                },
              ],
            },
            {
              'type': 'vu',
              'value': 0.84,
              'right': 0.80,
              'peak': 0.94,
              'segments': 20,
              'height': 12,
            },
          ],
        },
      };

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        WidgetsApp(
          color: Grey.g07,
          debugShowCheckedModeBanner: false,
          pageRouteBuilder: <T>(settings, builder) =>
              PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
          home: RepaintBoundary(
            key: repaintKey,
            child: Container(
              color: Grey.g07,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MOTOLII VISM PRO CAPABILITIES · AUDIO WAVEFORM · 16-STEP SEQ · GLSL GPU SHADER · RIG PICKER · CURVE & FADERS',
                    style: TextStyles.name(Grey.g91).copyWith(
                      fontSize: 11,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardCol(
                        cardTitle: 'Beat Sync Pro',
                        tag: '09 · WAVEFORM + 16-STEP SEQUENCER + VU',
                        tone: InspectorSkin.tonePlace,
                        payload: beatSyncCard,
                        live: live,
                      ),
                      const SizedBox(width: 12),
                      _cardCol(
                        cardTitle: 'Holo & Liquid FX',
                        tag: '10 · LIVE GLSL GPU SHADER + GRADIENT',
                        tone: InspectorSkin.toneTime,
                        payload: gpuShaderCard,
                        live: live,
                      ),
                      const SizedBox(width: 12),
                      _cardCol(
                        cardTitle: 'Live2D Rig Picker',
                        tag: '11 · CHARACTER BODY PICKER + PINS',
                        tone: InspectorSkin.toneLayout,
                        payload: rigPickerCard,
                        live: live,
                      ),
                      const SizedBox(width: 12),
                      _cardCol(
                        cardTitle: 'Pro Curve & Mix',
                        tag: '12 · MULTI-POINT CURVE + CONSOLE FADERS',
                        tone: InspectorSkin.toneTextAnim,
                        payload: proCurveCard,
                        live: live,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Allow async FragmentProgram.fromAsset to finish loading in test bundle.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beat Sync Pro'), findsOneWidget);
      expect(find.text('Holo & Liquid FX'), findsOneWidget);
      expect(find.text('Live2D Rig Picker'), findsOneWidget);
      expect(find.text('Pro Curve & Mix'), findsOneWidget);

      final outPath = Platform.environment['MOTOLII_VST_PRO_PNG'];
      if (outPath != null && outPath.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary =
              repaintKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final img = await boundary.toImage(pixelRatio: 2.0);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          if (data != null) {
            final f = File(outPath);
            f.parent.createSync(recursive: true);
            f.writeAsBytesSync(data.buffer.asUint8List());
          }
        });
      }

      final spinDir = Platform.environment['MOTOLII_VST_PRO_SPIN_DIR'];
      if (spinDir != null && spinDir.isNotEmpty) {
        Directory(spinDir).createSync(recursive: true);
        const frames = 20;
        for (var fi = 0; fi < frames; fi++) {
          final frac = fi / frames;
          final ang = frac * math.pi * 2.0;

          // Animate waveform + active sequencer step + stereo VU
          final wf =
              ((beatSyncCard['ui'] as Map)['children'] as List)[1] as Map;
          wf['samples'] = _syntheticWave(0.4 + ang * 2.0);
          wf['playhead'] = (0.1 + frac * 0.8);
          (((beatSyncCard['ui'] as Map)['children'] as List)[2]
                  as Map)['activeStep'] =
              fi % 16;
          final vu =
              ((beatSyncCard['ui'] as Map)['children'] as List)[3] as Map;
          vu['value'] = 0.45 + 0.45 * math.sin(ang * 2.0).abs();
          vu['right'] = 0.40 + 0.48 * math.cos(ang * 2.0).abs();

          // Animate GLSL GPU shader time & mouse orbit
          final sh =
              (((gpuShaderCard['ui'] as Map)['children'] as List)[0]
                      as Map)['children'][0]
                  as Map;
          sh['time'] = 1.6 + frac * 4.0;
          sh['mouseX'] = 0.5 + 0.24 * math.cos(ang);
          sh['mouseY'] = 0.5 + 0.22 * math.sin(ang);

          // Animate rig head pin sway
          final rig =
              ((rigPickerCard['ui'] as Map)['children'] as List)[0] as Map;
          final pins = rig['pins'] as List;
          (pins[0] as Map)['x'] = 0.50 + 0.08 * math.sin(ang);
          (pins[0] as Map)['y'] = 0.24 + 0.04 * math.cos(ang);

          // Animate curve center node & faders
          final eq =
              ((proCurveCard['ui'] as Map)['children'] as List)[0] as Map;
          final pts = eq['points'] as List;
          (pts[2] as Map)['y'] = 0.50 + 0.30 * math.sin(ang);
          final faders =
              (((proCurveCard['ui'] as Map)['children'] as List)[1]
                      as Map)['children']
                  as List;
          (faders[1] as Map)['value'] = 0.50 + 0.32 * math.sin(ang);
          (faders[2] as Map)['value'] = 0.62 + 0.26 * math.cos(ang);

          live.value = ({'v_js_pro_amount': frac}, const {});
          await tester.pump();
          await tester.runAsync(() async {
            final boundary =
                repaintKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final img = await boundary.toImage(pixelRatio: 1.0);
            final data = await img.toByteData(format: ui.ImageByteFormat.png);
            if (data != null) {
              final num = fi.toString().padLeft(3, '0');
              File('$spinDir/frame_$num.png')
                  .writeAsBytesSync(data.buffer.asUint8List());
            }
          });
        }
      }
    },
  );
}
