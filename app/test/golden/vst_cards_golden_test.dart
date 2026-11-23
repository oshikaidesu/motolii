// Golden contact sheet showcasing 8 distinct VST-style custom Inspector card vectors:
// 1. Flat-Pop / Neubrutalism (`Pop Bounce 3D`)
// 2. Serum / Vital 3D Synth (`Wavetable Warp`)
// 3. Teenage Engineering / Braun Industrial Hardware (`OP-Motion Field`)
// 4. Studio PBR 3D Lighting Rig (`Studio Light Rig`)
// 5. Retro Y2K / Win95 Arcade (`Chiptune Glitch 98`)
// 6. Kawaii Pastel Glass Pop (`Dreamy Prism`)
// 7. Manga / Comic Impact Pop (`Impact Frame`)
// 8. Modular Eurorack Patchbay (`Eurorack Mod`)
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

const _demoParams = '''
struct Params {
  /// @label(Amount) @ui(bar) @range(0, 1) @default(0.68)
  js_demo_amount: f32,
  /// @label(Warp) @ui(bar) @range(0, 1) @default(0.42)
  js_demo_warp: f32,
  /// @label(Mix) @ui(bar) @range(0, 1) @default(0.80)
  js_demo_mix: f32,
}
''';

const _sparkleSvg = '''
<svg viewBox="0 0 260 116" xmlns="http://www.w3.org/2000/svg">
  <path d="M214 18 L217 26 L225 29 L217 32 L214 40 L211 32 L203 29 L211 26 Z" fill="#FF66A8" opacity="0.85"/>
  <path d="M44 76 L46 82 L52 84 L46 86 L44 92 L42 86 L36 84 L42 82 Z" fill="#9C7BFF" opacity="0.80"/>
  <circle cx="204" cy="48" r="2.6" fill="#5CC8FF" opacity="0.85"/>
  <circle cx="62" cy="30" r="2.2" fill="#FF85C0" opacity="0.75"/>
</svg>
''';

const _mangaSpeedlinesSvg = '''
<svg viewBox="0 0 260 116" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="260" height="116" fill="#FFFFFF"/>
  <g stroke="#111111" stroke-linecap="round">
    <line x1="0" y1="0" x2="72" y2="34" stroke-width="2.2"/>
    <line x1="34" y1="0" x2="88" y2="28" stroke-width="1.4"/>
    <line x1="260" y1="0" x2="188" y2="34" stroke-width="2.4"/>
    <line x1="226" y1="0" x2="174" y2="28" stroke-width="1.3"/>
    <line x1="0" y1="58" x2="54" y2="58" stroke-width="2.0"/>
    <line x1="260" y1="58" x2="206" y2="58" stroke-width="2.0"/>
    <line x1="0" y1="116" x2="76" y2="82" stroke-width="2.4"/>
    <line x1="38" y1="116" x2="90" y2="88" stroke-width="1.4"/>
    <line x1="260" y1="116" x2="184" y2="82" stroke-width="2.2"/>
    <line x1="222" y1="116" x2="170" y2="88" stroke-width="1.3"/>
  </g>
  <circle cx="130" cy="58" r="46" fill="#FFE600" opacity="0.28"/>
</svg>
''';

Widget _vstCardColumn({
  required String cardTitle,
  required String vectorTag,
  required Color tone,
  required Map<String, Object?> payload,
  required ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>
  live,
}) {
  final decl = CardDeclaration(cardTitle, _demoParams, toneOf: () => tone);
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            vectorTag,
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
            numbers: {
              'v_js_demo_amount': 0.68,
              'v_js_demo_warp': 0.42,
              'v_js_demo_mix': 0.80,
            },
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
  testWidgets('VST custom card 8-vector gallery renders cleanly', (
    tester,
  ) async {
    const w = 1340.0;
    const h = 768.0;
    tester.view.physicalSize = const Size(w * 2, h * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final live =
        ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>((
          const {},
          const {},
        ));
    addTearDown(live.dispose);

    // 1. Flat-Pop / Neubrutalism
    final popBounce = {
      'hide': ['amount', 'warp', 'mix'],
      'surface': {
        'bg': '#FFF4C4',
        'fg': '#141414',
        'muted': '#473F22',
        'accent': '#FF3B7F',
        'border': '#141414',
        'borderWidth': 2.5,
        'radius': 14,
        'pad': 10,
        'shadow': {'x': 4, 'y': 4, 'blur': 0, 'color': '#141414'},
      },
      'ui': {
        'type': 'column',
        'style': {'gap': 8},
        'children': [
          {
            'type': 'stack',
            'children': [
              {
                'type': 'scene3d',
                'id': 'orbit',
                'height': 116,
                'shape': 'cube',
                'look': 'toon',
                'yaw': 0.64,
                'pitch': 0.36,
                'zoom': 0.88,
                'color': '#00D4FF',
                'color2': '#B8FF2C',
                'outline': '#141414',
                'outlineWidth': 2.2,
                'bg': '#FFFFFF',
                'grid': true,
                'objects': [
                  {
                    'shape': 'icosahedron',
                    'x': 1.02,
                    'y': 0.56,
                    'z': 0.78,
                    'scale': 0.26,
                    'color': '#FF3B7F',
                    'look': 'toon',
                  },
                  {
                    'shape': 'pyramid',
                    'x': -1.12,
                    'y': -0.25,
                    'z': 0.3,
                    'scale': 0.26,
                    'color': '#FFE600',
                    'look': 'toon',
                  },
                ],
                'style': {
                  'border': '#141414',
                  'borderWidth': 2.4,
                  'radius': 10,
                  'shadow': {'x': 3, 'y': 3, 'blur': 0, 'color': '#141414'},
                },
              },
              {
                'type': 'badge',
                'text': 'POP 3D!',
                'align': 'topRight',
                'inset': 8,
                'style': {
                  'bg': '#FFE600',
                  'fg': '#141414',
                  'border': '#141414',
                  'borderWidth': 2,
                  'radius': 6,
                  'shadow': {'x': 2, 'y': 2, 'blur': 0, 'color': '#141414'},
                },
              },
            ],
          },
          {
            'type': 'row',
            'children': [
              {
                'type': 'knob',
                'id': 'amount',
                'label': 'BOUNCE',
                'value': 0.68,
                'min': 0,
                'max': 1,
                'look': 'pop',
                'size': 42,
                'color': '#FF3B7F',
                'capColor': '#FFFFFF',
                'borderColor': '#141414',
              },
              {
                'type': 'knob',
                'id': 'warp',
                'label': 'SQUASH',
                'value': 0.42,
                'min': 0,
                'max': 1,
                'look': 'pop',
                'size': 42,
                'color': '#00D4FF',
                'capColor': '#FFFFFF',
                'borderColor': '#141414',
              },
              {
                'type': 'knob',
                'id': 'mix',
                'label': 'POP',
                'value': 0.80,
                'min': 0,
                'max': 1,
                'look': 'pop',
                'size': 42,
                'color': '#B8FF2C',
                'capColor': '#FFFFFF',
                'borderColor': '#141414',
              },
            ],
          },
          {
            'type': 'select',
            'id': 'mode',
            'value': 'JELLY',
            'options': ['JELLY', 'COMIC', 'SPRING'],
            'style': {
              'bg': '#FFFFFF',
              'fg': '#141414',
              'accent': '#FF3B7F',
              'border': '#141414',
              'borderWidth': 2,
              'radius': 8,
              'height': 24,
              'shadow': {'x': 2, 'y': 2, 'blur': 0, 'color': '#141414'},
            },
          },
        ],
      },
    };

    // 2. Serum / Vital 3D Synth VST
    final wavetableSynth = {
      'hide': ['amount', 'warp', 'mix'],
      'surface': {
        'bg': '#0D1119',
        'bg2': '#161F31',
        'fg': '#E2F4FF',
        'muted': '#7D93B0',
        'accent': '#00F0FF',
        'border': '#25334C',
        'borderWidth': 1.4,
        'radius': 10,
        'pad': 10,
        'mono': true,
        'shadow': {'x': 0, 'y': 6, 'blur': 16, 'color': '#00F0FF22'},
      },
      'ui': {
        'type': 'column',
        'style': {'gap': 8},
        'children': [
          {
            'type': 'stack',
            'children': [
              {
                'type': 'scene3d',
                'id': 'wt',
                'height': 116,
                'shape': 'wavetable',
                'look': 'holo',
                'yaw': 0.56,
                'pitch': 0.44,
                'zoom': 1.0,
                'color': '#00F0FF',
                'color2': '#A855F7',
                'bg': '#070B12',
                'bg2': '#101829',
                'warp': 0.68,
                'phase': 1.8,
                'harmonics': 3.2,
                'style': {
                  'border': '#00F0FF55',
                  'borderWidth': 1.2,
                  'radius': 8,
                },
              },
              {
                'type': 'badge',
                'text': 'WT-3D · 60FPS',
                'align': 'topLeft',
                'inset': 7,
                'style': {
                  'bg': '#0B1628CC',
                  'fg': '#00F0FF',
                  'border': '#00F0FF88',
                  'borderWidth': 1,
                  'radius': 4,
                  'fontSize': 8.5,
                  'mono': true,
                },
              },
            ],
          },
          {
            'type': 'row',
            'children': [
              {
                'type': 'knob',
                'id': 'amount',
                'label': 'WT POS',
                'value': 0.68,
                'min': 0,
                'max': 1,
                'look': 'arc',
                'size': 42,
                'color': '#00F0FF',
                'capColor': '#141B29',
                'trackColor': '#1F2A3E',
              },
              {
                'type': 'knob',
                'id': 'warp',
                'label': 'WARP',
                'value': 0.42,
                'min': 0,
                'max': 1,
                'look': 'arc',
                'size': 42,
                'color': '#A855F7',
                'capColor': '#141B29',
                'trackColor': '#1F2A3E',
              },
              {
                'type': 'knob',
                'id': 'mix',
                'label': 'UNISON',
                'value': 0.80,
                'min': 0,
                'max': 1,
                'look': 'arc',
                'size': 42,
                'color': '#38BDF8',
                'capColor': '#141B29',
                'trackColor': '#1F2A3E',
              },
            ],
          },
          {
            'type': 'select',
            'id': 'osc',
            'value': 'OSC A',
            'options': ['OSC A', 'OSC B', 'SUB'],
            'style': {
              'bg': '#0C1220',
              'fg': '#90A7C4',
              'accent': '#00F0FF',
              'border': '#25334C',
              'radius': 5,
              'height': 24,
              'mono': true,
            },
          },
        ],
      },
    };

    // 3. Teenage Engineering / Braun Industrial Hardware
    final hardwareField = {
      'hide': ['amount', 'warp', 'mix'],
      'surface': {
        'bg': '#ECECE6',
        'fg': '#1E1E1C',
        'muted': '#6B6B64',
        'accent': '#FF521B',
        'border': '#C8C8BE',
        'borderWidth': 1.5,
        'radius': 10,
        'pad': 10,
        'letterSpacing': 0.8,
      },
      'ui': {
        'type': 'column',
        'style': {'gap': 8},
        'children': [
          {
            'type': 'box',
            'bg': '#111311',
            'border': '#2D302D',
            'borderWidth': 1.5,
            'radius': 6,
            'pad': 7,
            'gap': 3,
            'children': [
              {
                'type': 'row',
                'children': [
                  {
                    'type': 'text',
                    'text': 'OLED · FIELD',
                    'bold': true,
                    'style': {
                      'fg': '#F2F2EC',
                      'fontSize': 8.5,
                      'letterSpacing': 1.1,
                      'mono': true,
                    },
                  },
                  {'type': 'spacer'},
                  {
                    'type': 'text',
                    'text': '48kHz / 60FPS',
                    'style': {'fg': '#FF521B', 'fontSize': 8.5, 'mono': true},
                  },
                ],
              },
              {
                'type': 'scene3d',
                'id': 'ico',
                'height': 90,
                'shape': 'icosahedron',
                'look': 'wireframe',
                'yaw': 0.48,
                'pitch': 0.34,
                'zoom': 0.98,
                'color': '#F2F2EC',
                'axes': true,
                'framed': false,
              },
            ],
          },
          {
            'type': 'row',
            'children': [
              {
                'type': 'knob',
                'id': 'amount',
                'label': 'DRIVE',
                'value': 0.68,
                'min': 0,
                'max': 1,
                'look': 'hardware',
                'size': 42,
                'color': '#FF521B',
              },
              {
                'type': 'knob',
                'id': 'warp',
                'label': 'TILT',
                'value': 0.42,
                'min': 0,
                'max': 1,
                'look': 'hardware',
                'size': 42,
                'color': '#246BCE',
              },
              {
                'type': 'knob',
                'id': 'mix',
                'label': 'GAIN',
                'value': 0.80,
                'min': 0,
                'max': 1,
                'look': 'hardware',
                'size': 42,
                'color': '#E5A918',
              },
            ],
          },
          {
            'type': 'row',
            'children': [
              {
                'type': 'button',
                'id': 'rec',
                'label': '● REC',
                'style': {
                  'bg': '#FF521B',
                  'fg': '#FFFFFF',
                  'border': '#D94010',
                  'radius': 99,
                  'height': 24,
                },
              },
              {
                'type': 'button',
                'id': 'hold',
                'label': 'HOLD',
                'style': {
                  'bg': '#DFDFD7',
                  'fg': '#1E1E1C',
                  'border': '#BDBDB3',
                  'radius': 99,
                  'height': 24,
                },
              },
              {
                'type': 'button',
                'id': 'shift',
                'label': 'SHIFT',
                'style': {
                  'bg': '#222220',
                  'fg': '#F2F2EC',
                  'border': '#111110',
                  'radius': 99,
                  'height': 24,
                },
              },
            ],
          },
        ],
      },
    };

    // 4. Studio PBR 3D Lighting Rig
    final studioLight = {
      'hide': ['amount', 'warp', 'mix'],
      'surface': {
        'bg': '#191C24',
        'bg2': '#111319',
        'fg': '#F1F5F9',
        'muted': '#8A94A6',
        'accent': '#FFB547',
        'border': '#2D3442',
        'borderWidth': 1.2,
        'radius': 10,
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
                'type': 'scene3d',
                'id': 'rig',
                'height': 116,
                'shape': 'sphere',
                'look': 'studio',
                'yaw': 0.35,
                'pitch': 0.25,
                'zoom': 0.90,
                'color': '#64748B',
                'rimColor': '#38BDF8',
                'ambientColor': '#172033',
                'ambient': 0.32,
                'gloss': 0.92,
                'lightYaw': 0.85,
                'lightPitch': 0.65,
                'bg': '#13161D',
                'bg2': '#0A0C10',
                'grid': true,
                'shadow': true,
                'objects': [
                  {
                    'shape': 'icosahedron',
                    'x': 0.95,
                    'y': 0.68,
                    'z': 0.72,
                    'scale': 0.16,
                    'color': '#FFB547',
                    'look': 'toon',
                  },
                ],
                'style': {'border': '#2B313D', 'radius': 8},
              },
              {
                'type': 'badge',
                'text': 'KEY 5600K',
                'align': 'bottomLeft',
                'inset': 7,
                'style': {
                  'bg': '#111318CC',
                  'fg': '#FFB547',
                  'border': '#FFB54766',
                  'radius': 4,
                  'fontSize': 8.5,
                  'mono': true,
                },
              },
            ],
          },
          {
            'type': 'row',
            'children': [
              {
                'type': 'knob',
                'id': 'amount',
                'label': 'KEY',
                'value': 0.68,
                'min': 0,
                'max': 1,
                'look': 'arc',
                'size': 42,
                'color': '#FFB547',
                'capColor': '#1F2430',
              },
              {
                'type': 'knob',
                'id': 'warp',
                'label': 'RIM',
                'value': 0.42,
                'min': 0,
                'max': 1,
                'look': 'arc',
                'size': 42,
                'color': '#38BDF8',
                'capColor': '#1F2430',
              },
              {
                'type': 'knob',
                'id': 'mix',
                'label': 'GLOSS',
                'value': 0.80,
                'min': 0,
                'max': 1,
                'look': 'arc',
                'size': 42,
                'color': '#E2E8F0',
                'capColor': '#1F2430',
              },
            ],
          },
          {
            'type': 'grid',
            'cols': 5,
            'children': [
              {
                'type': 'swatch',
                'id': 'g1',
                'color': '#FFB547',
                'active': true,
              },
              {'type': 'swatch', 'id': 'g2', 'color': '#38BDF8'},
              {'type': 'swatch', 'id': 'g3', 'color': '#F43F5E'},
              {'type': 'swatch', 'id': 'g4', 'color': '#A855F7'},
              {'type': 'swatch', 'id': 'g5', 'color': '#F8FAFC'},
            ],
          },
        ],
      },
    };

    // 5. Retro Y2K / Win95 Arcade
    final retro98 = {
      'hide': ['amount', 'warp', 'mix'],
      'surface': {
        'bg': '#D4D0C8',
        'fg': '#000000',
        'muted': '#404040',
        'accent': '#0A246A',
        'border': '#404040',
        'borderWidth': 2,
        'radius': 0,
        'pad': 8,
        'mono': true,
        'shadow': {'x': 3, 'y': 3, 'blur': 0, 'color': '#00000088'},
      },
      'ui': {
        'type': 'column',
        'style': {'gap': 7},
        'children': [
          {
            'type': 'box',
            'bg': '#0A246A',
            'bg2': '#3A6EA5',
            'gradAngle': 0,
            'radius': 0,
            'padX': 7,
            'padY': 4,
            'borderWidth': 0,
            'children': [
              {
                'type': 'text',
                'text': 'GLITCH98.VST  [3D CRT]',
                'bold': true,
                'style': {'fg': '#FFFFFF', 'fontSize': 9.5, 'mono': true},
              },
            ],
          },
          {
            'type': 'scene3d',
            'id': 'crt',
            'height': 116,
            'shape': 'torus',
            'look': 'wireframe',
            'yaw': 0.52,
            'pitch': 0.56,
            'zoom': 0.96,
            'color': '#00FF66',
            'bg': '#051409',
            'grid': true,
            'style': {'border': '#404040', 'borderWidth': 2, 'radius': 0},
          },
          {
            'type': 'meter',
            'label': 'SCANLINE JITTER · 68%',
            'value': 0.68,
            'style': {
              'bg': '#FFFFFF',
              'accent': '#0A246A',
              'border': '#404040',
              'borderWidth': 1.5,
              'radius': 0,
              'height': 10,
            },
          },
          {
            'type': 'row',
            'style': {'gap': 4},
            'children': [
              {
                'type': 'button',
                'id': 'b1',
                'label': '8-BIT',
                'style': {
                  'bg': '#E6E2DA',
                  'fg': '#000000',
                  'border': '#404040',
                  'borderWidth': 1.5,
                  'radius': 0,
                  'mono': true,
                },
              },
              {
                'type': 'button',
                'id': 'b2',
                'label': 'CRT',
                'style': {
                  'bg': '#0A246A',
                  'fg': '#FFFFFF',
                  'border': '#000000',
                  'borderWidth': 1.5,
                  'radius': 0,
                  'mono': true,
                },
              },
              {
                'type': 'button',
                'id': 'b3',
                'label': 'VHS',
                'style': {
                  'bg': '#E6E2DA',
                  'fg': '#000000',
                  'border': '#404040',
                  'borderWidth': 1.5,
                  'radius': 0,
                  'mono': true,
                },
              },
            ],
          },
        ],
      },
    };

    // 6. Kawaii Pastel Glass Pop
    final kawaiiPrism = {
      'hide': ['amount', 'warp', 'mix'],
      'surface': {
        'bg': '#FFF0F7',
        'bg2': '#EAEFFF',
        'fg': '#4A2740',
        'muted': '#9A6D8E',
        'accent': '#FF66A8',
        'border': '#FFB8DA',
        'borderWidth': 1.8,
        'radius': 18,
        'pad': 10,
        'shadow': {'x': 0, 'y': 6, 'blur': 16, 'color': '#FF66A833'},
      },
      'ui': {
        'type': 'column',
        'style': {'gap': 8},
        'children': [
          {
            'type': 'stack',
            'children': [
              {
                'type': 'scene3d',
                'id': 'gem',
                'height': 116,
                'shape': 'crystal',
                'look': 'studio',
                'yaw': 0.42,
                'pitch': 0.24,
                'zoom': 0.96,
                'color': '#FF85C0',
                'color2': '#93B4FF',
                'rimColor': '#FFFFFF',
                'ambientColor': '#F7D8FF',
                'ambient': 0.58,
                'gloss': 0.95,
                'bg': '#FFF6FB',
                'bg2': '#EEF2FF',
                'shadow': true,
                'style': {
                  'border': '#FFC2E2',
                  'borderWidth': 1.5,
                  'radius': 14,
                },
              },
              {
                'type': 'svg',
                'height': 116,
                'svg': _sparkleSvg,
                'fit': 'fill',
                'framed': false,
                'align': 'fill',
              },
              {
                'type': 'badge',
                'text': '★ PRISM',
                'align': 'topLeft',
                'inset': 8,
                'style': {
                  'bg': '#FFFFFFE6',
                  'fg': '#E14B95',
                  'border': '#FFB8DA',
                  'borderWidth': 1.4,
                  'radius': 99,
                },
              },
              {
                'type': 'badge',
                'text': 'SOFT',
                'align': 'bottomRight',
                'inset': 8,
                'style': {
                  'bg': '#E4DCFF',
                  'fg': '#6B48D6',
                  'border': '#C4B5FD',
                  'borderWidth': 1.2,
                  'radius': 99,
                },
              },
            ],
          },
          {
            'type': 'row',
            'children': [
              {
                'type': 'knob',
                'id': 'amount',
                'label': 'PRISM',
                'value': 0.68,
                'min': 0,
                'max': 1,
                'look': 'minimal',
                'size': 42,
                'color': '#FF66A8',
                'trackColor': '#F9D5E8',
              },
              {
                'type': 'knob',
                'id': 'warp',
                'label': 'BLOOM',
                'value': 0.42,
                'min': 0,
                'max': 1,
                'look': 'minimal',
                'size': 42,
                'color': '#9C7BFF',
                'trackColor': '#E4DCFF',
              },
              {
                'type': 'knob',
                'id': 'mix',
                'label': 'GLOW',
                'value': 0.80,
                'min': 0,
                'max': 1,
                'look': 'minimal',
                'size': 42,
                'color': '#5CC8FF',
                'trackColor': '#D6F0FF',
              },
            ],
          },
          {
            'type': 'grid',
            'cols': 5,
            'children': [
              {
                'type': 'swatch',
                'id': 'p1',
                'color': '#FF85C0',
                'active': true,
                'style': {
                  'radius': 99,
                  'border': '#FFFFFF',
                  'borderWidth': 1.5,
                },
              },
              {
                'type': 'swatch',
                'id': 'p2',
                'color': '#A78BFA',
                'style': {
                  'radius': 99,
                  'border': '#FFFFFF',
                  'borderWidth': 1.5,
                },
              },
              {
                'type': 'swatch',
                'id': 'p3',
                'color': '#7DD3FC',
                'style': {
                  'radius': 99,
                  'border': '#FFFFFF',
                  'borderWidth': 1.5,
                },
              },
              {
                'type': 'swatch',
                'id': 'p4',
                'color': '#FDE68A',
                'style': {
                  'radius': 99,
                  'border': '#FFFFFF',
                  'borderWidth': 1.5,
                },
              },
              {
                'type': 'swatch',
                'id': 'p5',
                'color': '#6EE7B7',
                'style': {
                  'radius': 99,
                  'border': '#FFFFFF',
                  'borderWidth': 1.5,
                },
              },
            ],
          },
        ],
      },
    };

    // 7. Manga / Comic Impact Pop
    final mangaImpact = {
      'hide': ['amount', 'warp', 'mix'],
      'surface': {
        'bg': '#FFFFFF',
        'fg': '#111111',
        'muted': '#555555',
        'accent': '#FFE600',
        'border': '#111111',
        'borderWidth': 2.6,
        'radius': 4,
        'pad': 10,
        'shadow': {'x': 5, 'y': 5, 'blur': 0, 'color': '#FFE600'},
      },
      'ui': {
        'type': 'column',
        'style': {'gap': 8},
        'children': [
          {
            'type': 'box',
            'bg': '#FFFFFF',
            'border': '#111111',
            'borderWidth': 2.2,
            'radius': 2,
            'pad': 0,
            'children': [
              {
                'type': 'stack',
                'children': [
                  {
                    'type': 'svg',
                    'height': 112,
                    'svg': _mangaSpeedlinesSvg,
                    'fit': 'fill',
                    'framed': false,
                  },
                  {
                    'type': 'scene3d',
                    'id': 'pyr',
                    'height': 112,
                    'shape': 'pyramid',
                    'look': 'toon',
                    'yaw': 0.52,
                    'pitch': 0.30,
                    'zoom': 0.92,
                    'color': '#FFE600',
                    'outline': '#111111',
                    'outlineWidth': 2.4,
                    'shadow': false,
                    'framed': false,
                    'align': 'fill',
                  },
                  {
                    'type': 'badge',
                    'text': 'IMPACT!!',
                    'align': 'topLeft',
                    'inset': 6,
                    'style': {
                      'bg': '#111111',
                      'fg': '#FFE600',
                      'border': '#111111',
                      'radius': 2,
                      'letterSpacing': 0.9,
                    },
                  },
                ],
              },
            ],
          },
          {
            'type': 'row',
            'children': [
              {
                'type': 'knob',
                'id': 'amount',
                'label': 'FLASH',
                'value': 0.68,
                'min': 0,
                'max': 1,
                'look': 'pop',
                'size': 42,
                'color': '#FFE600',
                'capColor': '#111111',
                'borderColor': '#111111',
              },
              {
                'type': 'knob',
                'id': 'warp',
                'label': 'LINES',
                'value': 0.42,
                'min': 0,
                'max': 1,
                'look': 'pop',
                'size': 42,
                'color': '#111111',
                'capColor': '#FFFFFF',
                'borderColor': '#111111',
              },
              {
                'type': 'knob',
                'id': 'mix',
                'label': 'SHAKE',
                'value': 0.80,
                'min': 0,
                'max': 1,
                'look': 'pop',
                'size': 42,
                'color': '#FF2E54',
                'capColor': '#FFFFFF',
                'borderColor': '#111111',
              },
            ],
          },
          {
            'type': 'row',
            'children': [
              {
                'type': 'button',
                'id': 'm_bw',
                'label': 'INK B/W',
                'style': {
                  'bg': '#111111',
                  'fg': '#FFFFFF',
                  'border': '#111111',
                  'borderWidth': 2,
                  'radius': 2,
                  'height': 24,
                },
              },
              {
                'type': 'button',
                'id': 'm_hit',
                'label': 'HIT STOP',
                'style': {
                  'bg': '#FFE600',
                  'fg': '#111111',
                  'border': '#111111',
                  'borderWidth': 2,
                  'radius': 2,
                  'height': 24,
                },
              },
            ],
          },
        ],
      },
    };

    // 8. Modular Eurorack Patchbay
    final eurorackMod = {
      'hide': ['amount', 'warp', 'mix'],
      'surface': {
        'bg': '#24221F',
        'bg2': '#181715',
        'fg': '#E8DEC8',
        'muted': '#9A9180',
        'accent': '#F59E0B',
        'border': '#48433B',
        'borderWidth': 1.5,
        'radius': 6,
        'pad': 10,
        'mono': true,
      },
      'ui': {
        'type': 'column',
        'style': {'gap': 8},
        'children': [
          {
            'type': 'canvas',
            'id': 'patch',
            'height': 116,
            'style': {
              'bg': '#141311',
              'border': '#3B3730',
              'borderWidth': 1.2,
              'radius': 5,
            },
            'draw': [
              // Jack sockets
              {
                'op': 'circle',
                'x': 0.16,
                'y': 0.28,
                'r': 0.08,
                'fill': '#2E2B26',
                'stroke': '#A89F91',
                'width': 1.6,
              },
              {
                'op': 'circle',
                'x': 0.50,
                'y': 0.28,
                'r': 0.08,
                'fill': '#2E2B26',
                'stroke': '#A89F91',
                'width': 1.6,
              },
              {
                'op': 'circle',
                'x': 0.84,
                'y': 0.28,
                'r': 0.08,
                'fill': '#2E2B26',
                'stroke': '#A89F91',
                'width': 1.6,
              },
              {
                'op': 'circle',
                'x': 0.16,
                'y': 0.78,
                'r': 0.08,
                'fill': '#2E2B26',
                'stroke': '#A89F91',
                'width': 1.6,
              },
              {
                'op': 'circle',
                'x': 0.50,
                'y': 0.78,
                'r': 0.08,
                'fill': '#2E2B26',
                'stroke': '#A89F91',
                'width': 1.6,
              },
              {
                'op': 'circle',
                'x': 0.84,
                'y': 0.78,
                'r': 0.08,
                'fill': '#2E2B26',
                'stroke': '#A89F91',
                'width': 1.6,
              },
              // Patch cables (hanging catenary beziers)
              {
                'op': 'bezier',
                'x': 0.16,
                'y': 0.28,
                'cx1': 0.22,
                'cy1': 0.96,
                'cx2': 0.76,
                'cy2': 0.96,
                'x2': 0.84,
                'y2': 0.78,
                'stroke': '#F59E0B',
                'width': 3.4,
              },
              {
                'op': 'bezier',
                'x': 0.50,
                'y': 0.28,
                'cx1': 0.42,
                'cy1': 0.72,
                'cx2': 0.20,
                'cy2': 0.90,
                'x2': 0.16,
                'y2': 0.78,
                'stroke': '#EF4444',
                'width': 3.2,
              },
              {
                'op': 'bezier',
                'x': 0.84,
                'y': 0.28,
                'cx1': 0.76,
                'cy1': 0.68,
                'cx2': 0.58,
                'cy2': 0.88,
                'x2': 0.50,
                'y2': 0.78,
                'stroke': '#22D3EE',
                'width': 3.0,
              },
              // Plug tips
              {
                'op': 'circle',
                'x': 0.16,
                'y': 0.28,
                'r': 0.036,
                'fill': '#F59E0B',
              },
              {
                'op': 'circle',
                'x': 0.84,
                'y': 0.78,
                'r': 0.036,
                'fill': '#F59E0B',
              },
              {
                'op': 'circle',
                'x': 0.50,
                'y': 0.28,
                'r': 0.036,
                'fill': '#EF4444',
              },
              {
                'op': 'circle',
                'x': 0.16,
                'y': 0.78,
                'r': 0.036,
                'fill': '#EF4444',
              },
              {
                'op': 'circle',
                'x': 0.84,
                'y': 0.28,
                'r': 0.036,
                'fill': '#22D3EE',
              },
              {
                'op': 'circle',
                'x': 0.50,
                'y': 0.78,
                'r': 0.036,
                'fill': '#22D3EE',
              },
              // Labels
              {
                'op': 'text',
                'x': 0.16,
                'y': 0.11,
                'text': 'LFO',
                'fill': '#9A9180',
                'align': 'center',
              },
              {
                'op': 'text',
                'x': 0.50,
                'y': 0.11,
                'text': 'ENV',
                'fill': '#9A9180',
                'align': 'center',
              },
              {
                'op': 'text',
                'x': 0.84,
                'y': 0.11,
                'text': 'BPM',
                'fill': '#9A9180',
                'align': 'center',
              },
            ],
          },
          {
            'type': 'row',
            'children': [
              {
                'type': 'knob',
                'id': 'amount',
                'label': 'CV 1',
                'value': 0.68,
                'min': 0,
                'max': 1,
                'look': 'hardware',
                'size': 42,
                'color': '#F59E0B',
              },
              {
                'type': 'knob',
                'id': 'warp',
                'label': 'ATTN',
                'value': 0.42,
                'min': 0,
                'max': 1,
                'look': 'hardware',
                'size': 42,
                'color': '#EF4444',
              },
              {
                'type': 'knob',
                'id': 'mix',
                'label': 'SLEW',
                'value': 0.80,
                'min': 0,
                'max': 1,
                'look': 'hardware',
                'size': 42,
                'color': '#22D3EE',
              },
            ],
          },
          {
            'type': 'meter',
            'label': 'CV BUS OUT · +4.2V',
            'value': 0.76,
            'style': {
              'bg': '#141311',
              'accent': '#F59E0B',
              'border': '#3B3730',
              'borderWidth': 1,
              'radius': 2,
              'height': 8,
            },
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
                  'MOTOLII CUSTOM INSPECTOR CARDS · 8 VST DESIGN VECTORS (100% FLUTTER NATIVE · ZERO WEBVIEW)',
                  style: TextStyles.name(Grey.g91).copyWith(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _vstCardColumn(
                      cardTitle: 'Pop Bounce 3D',
                      vectorTag: '01 · FLAT-POP / NEUBRUTALISM',
                      tone: InspectorSkin.toneTime,
                      payload: popBounce,
                      live: live,
                    ),
                    const SizedBox(width: 12),
                    _vstCardColumn(
                      cardTitle: 'Wavetable Warp',
                      vectorTag: '02 · SERUM / VITAL 3D SYNTH',
                      tone: InspectorSkin.toneLayout,
                      payload: wavetableSynth,
                      live: live,
                    ),
                    const SizedBox(width: 12),
                    _vstCardColumn(
                      cardTitle: 'OP-Motion Field',
                      vectorTag: '03 · INDUSTRIAL HARDWARE',
                      tone: InspectorSkin.tonePlace,
                      payload: hardwareField,
                      live: live,
                    ),
                    const SizedBox(width: 12),
                    _vstCardColumn(
                      cardTitle: 'Studio Light Rig',
                      vectorTag: '04 · STUDIO PBR 3D RIG',
                      tone: InspectorSkin.toneTextAnim,
                      payload: studioLight,
                      live: live,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _vstCardColumn(
                      cardTitle: 'Chiptune Glitch 98',
                      vectorTag: '05 · RETRO Y2K / WIN95 CRT',
                      tone: InspectorSkin.toneBlend,
                      payload: retro98,
                      live: live,
                    ),
                    const SizedBox(width: 12),
                    _vstCardColumn(
                      cardTitle: 'Dreamy Prism',
                      vectorTag: '06 · KAWAII PASTEL 3D POP',
                      tone: InspectorSkin.toneTime,
                      payload: kawaiiPrism,
                      live: live,
                    ),
                    const SizedBox(width: 12),
                    _vstCardColumn(
                      cardTitle: 'Impact Frame',
                      vectorTag: '07 · MANGA / COMIC IMPACT',
                      tone: InspectorSkin.toneTextAnim,
                      payload: mangaImpact,
                      live: live,
                    ),
                    const SizedBox(width: 12),
                    _vstCardColumn(
                      cardTitle: 'Eurorack Mod',
                      vectorTag: '08 · MODULAR PATCHBAY VST',
                      tone: InspectorSkin.tonePlace,
                      payload: eurorackMod,
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
    await tester.pumpAndSettle();

    for (final name in const [
      'Pop Bounce 3D',
      'Wavetable Warp',
      'OP-Motion Field',
      'Studio Light Rig',
      'Chiptune Glitch 98',
      'Dreamy Prism',
      'Impact Frame',
      'Eurorack Mod',
    ]) {
      expect(find.text(name), findsOneWidget);
    }

    final outPath = Platform.environment['MOTOLII_VST_GALLERY_PNG'];
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

    // Optional animated frame sequence export (only when MOTOLII_VST_SPIN_DIR is set).
    final spinDir = Platform.environment['MOTOLII_VST_SPIN_DIR'];
    if (spinDir != null && spinDir.isNotEmpty) {
      Directory(spinDir).createSync(recursive: true);
      const frames = 24;
      for (var fi = 0; fi < frames; fi++) {
        final frac = fi / frames;
        final ang = frac * math.pi * 2.0;
        final waveAmt = 0.5 + 0.35 * math.sin(ang);
        final lightA = 0.85 + ang;
        final lx = math.cos(lightA) * 1.12;
        final lz = math.sin(lightA) * 1.12;

        // Mutate the 3D yaw/phase/light & animated knobs/meters in-place for this frame.
        (((popBounce['ui'] as Map)['children'] as List)[0]
                as Map)['children'][0]['yaw'] =
            0.64 + ang;
        (((popBounce['ui'] as Map)['children'] as List)[1]
                as Map)['children'][0]['value'] =
            0.5 + 0.38 * math.sin(ang);

        final wt3d =
            (((wavetableSynth['ui'] as Map)['children'] as List)[0]
                    as Map)['children'][0]
                as Map;
        wt3d['phase'] = 1.8 + ang * 2.0;
        wt3d['warp'] = 0.3 + 0.55 * (0.5 + 0.5 * math.sin(ang));
        wt3d['yaw'] = 0.56 + 0.25 * math.sin(ang);
        (((wavetableSynth['ui'] as Map)['children'] as List)[1]
                as Map)['children'][1]['value'] =
            0.5 + 0.35 * math.sin(ang);

        (((hardwareField['ui'] as Map)['children'] as List)[0]
                as Map)['children'][1]['yaw'] =
            0.48 + ang;
        (((hardwareField['ui'] as Map)['children'] as List)[1]
                as Map)['children'][0]['value'] =
            0.5 + 0.35 * math.cos(ang);

        final rig3d =
            (((studioLight['ui'] as Map)['children'] as List)[0]
                    as Map)['children'][0]
                as Map;
        rig3d['lightYaw'] = lightA;
        ((rig3d['objects'] as List)[0] as Map)['x'] = lx;
        ((rig3d['objects'] as List)[0] as Map)['z'] = lz;

        (((retro98['ui'] as Map)['children'] as List)[1] as Map)['yaw'] =
            0.52 + ang;
        (((retro98['ui'] as Map)['children'] as List)[2] as Map)['value'] =
            waveAmt;

        (((kawaiiPrism['ui'] as Map)['children'] as List)[0]
                as Map)['children'][0]['yaw'] =
            0.42 + ang;

        (((mangaImpact['ui'] as Map)['children'] as List)[0]
                as Map)['children'][0]['children'][1]['yaw'] =
            0.52 + ang;

        (((eurorackMod['ui'] as Map)['children'] as List)[2] as Map)['value'] =
            0.35 + 0.55 * (0.5 + 0.5 * math.sin(ang * 2.0));

        // Force live re-evaluation of all 8 cards.
        live.value = ({'v_js_demo_amount': waveAmt}, const {});
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
  });
}
