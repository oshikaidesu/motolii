// Tests for Motolii's built-in loopback MCP transport, custom ACP agent
// discovery, ACP text/image file helpers, and unrestricted PanelOp parsing.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/custom_card_body.dart' show CardParamNames;
import 'package:motolii/storage/agent_files.dart';
import 'package:motolii/storage/agent_mcp_transport.dart';
import 'package:motolii/widgets/custom_ui/panel_node.dart'
    show parsePanelOpsJson;
import 'package:motolii/workspace/agent/agent_pane.dart'
    show AgentStarterPrompts;
import 'package:motolii/workspace/agent/agent_registry.dart' show agentRegistry;
import 'package:motolii/workspace/agent/layer_code.dart' show buildMotoliiGuide;
import 'package:motolii/workspace/state/custom_panel_service.dart'
    show normalizePanelColorWord;
import 'package:motolii/workspace/state/tiles/effect_code_cards.dart'
    show isVismPackPath, readVismPack, vismPackCells;

class _PassthroughHttpOverrides extends HttpOverrides {}

Future<(int, Map<String, Object?>?)> _postJson(
  String url,
  Object body, {
  String? bearer,
}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse(url));
    req.headers.contentType = ContentType.json;
    if (bearer != null) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
    }
    req.write(jsonEncode(body));
    final res = await req.close();
    final text = await utf8.decoder.bind(res).join();
    return (
      res.statusCode,
      text.trim().isEmpty ? null : jsonDecode(text) as Map<String, Object?>,
    );
  } finally {
    client.close(force: true);
  }
}

void main() {
  test(
    'AgentMcpTransport serves authenticated MCP initialize, list, and call',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final transport = await AgentMcpTransport.start(
          listTools: () => [
            {
              'name': 'echo',
              'description': 'Echo input',
              'inputSchema': {'type': 'object'},
            },
          ],
          callTool: (name, args) => {
            'content': [
              {'type': 'text', 'text': '$name:${args['msg']}'},
            ],
          },
        );
        addTearDown(transport.close);

        // Rejects missing/wrong token.
        final (unauthCode, _) = await _postJson(transport.url, {
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'ping',
        });
        expect(unauthCode, HttpStatus.unauthorized);

        // Initialize + tools/list + tools/call with valid Bearer token.
        final (initCode, initBody) = await _postJson(transport.url, {
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'initialize',
          'params': {},
        }, bearer: transport.token);
        expect(initCode, HttpStatus.ok);
        expect((initBody?['result'] as Map)['serverInfo'], {
          'name': 'motolii',
          'version': '1.0.0',
        });

        final (listCode, listBody) = await _postJson(transport.url, {
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'tools/list',
        }, bearer: transport.token);
        expect(listCode, HttpStatus.ok);
        final tools = ((listBody?['result'] as Map)['tools'] as List);
        expect(tools.length, 1);
        expect((tools.first as Map)['name'], 'echo');

        final (callCode, callBody) = await _postJson(transport.url, {
          'jsonrpc': '2.0',
          'id': 3,
          'method': 'tools/call',
          'params': {
            'name': 'echo',
            'arguments': {'msg': 'hello'},
          },
        }, bearer: transport.token);
        expect(callCode, HttpStatus.ok);
        final content = ((callBody?['result'] as Map)['content'] as List);
        expect((content.first as Map)['text'], 'echo:hello');
      }, _PassthroughHttpOverrides());
    },
  );

  test(
    'agent_files reads line slices, writes files, and loads custom ACP agents',
    () async {
      final tmp = Directory.systemTemp.createTempSync('motolii_acp_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final txt = '${tmp.path}/nested/demo.txt';
      writeAgentTextFile(txt, 'a\nb\nc\nd');
      expect(readAgentTextFile(txt, line: 2, limit: 2), 'b\nc');

      // Write custom.json and cached empty registry.json so agentRegistry stays offline-safe.
      writeAgentTextFile(
        '${tmp.path}/agents/custom.json',
        jsonEncode([
          {
            'id': 'local-ollama',
            'name': 'Local Ollama ACP',
            'description': 'Offline local agent',
            'command': 'ollama-acp',
            'args': ['--model', 'qwen2.5-coder'],
            'env': {'OLLAMA_HOST': 'http://127.0.0.1:11434'},
          },
        ]),
      );
      writeAgentTextFile('${tmp.path}/agents/registry.json', '{"agents":[]}');

      final entries = await agentRegistry(tmp.path);
      expect(entries.any((e) => e.id == 'local-ollama'), isTrue);
      final custom = entries.firstWhere((e) => e.id == 'local-ollama');
      expect(custom.name, 'Local Ollama ACP');
      expect(custom.method, 'custom');
      expect(custom.installed, isTrue);
      expect(custom.line, ['ollama-acp', '--model', 'qwen2.5-coder']);
      expect(custom.env['OLLAMA_HOST'], 'http://127.0.0.1:11434');
    },
  );

  test('parsePanelOpsJson accepts stage layer 0, create, open_panel, and raw later ops', () {
    final res = parsePanelOpsJson(
      jsonEncode({
        'ops': [
          {'op': 'set', 'layer': 0, 'name': 'bpm', 'value': 128},
          {'op': 'create', 'word': 'Glow Title'},
          {'op': 'open_panel', 'file': '/tmp/my_tool.js'},
          {
            'op': 'later',
            'name': 'mark',
            'layer': 0,
            'word': 'Chorus',
            'at': 4.5,
          },
        ],
        'notice': 'Stage updated',
      }),
    );
    expect(res.error, isNull);
    expect(res.ops.length, 4);
    expect(res.ops[0].layer, 0);
    expect(res.ops[0].name, 'bpm');
    expect(res.ops[1].op, 'create');
    expect(res.ops[2].op, 'open_panel');
    expect(res.ops[3].op, 'later');
    expect(res.ops[3].at, 4.5);
    expect(res.notice, 'Stage updated');
  });

  test('normalizePanelColorWord strips leading # on color properties only', () {
    expect(normalizePanelColorWord('fill', '#ff3366'), 'ff3366');
    expect(normalizePanelColorWord('background', '#1A2B3C'), '1A2B3C');
    expect(
      normalizePanelColorWord('copy_fill', '#ff3366 #1b2fd8'),
      'ff3366 1b2fd8',
    );
    expect(normalizePanelColorWord('1:stroke', '#abcdef'), 'abcdef');
    expect(normalizePanelColorWord('text', '#ff3366 tag'), '#ff3366 tag');
  });

  test('buildMotoliiGuide documents exact engine shapes, stage props, and ops_result', () {
    final guide = buildMotoliiGuide(
      hasMcp: true,
      fresh: '/tmp/fx',
      opsPath: '/tmp/fx/ops.json',
      opsResultPath: '/tmp/fx/ops_result.json',
      hostTypes: '/shelves/motolii-host.d.ts',
      uiTypes: '/shelves/motolii-ui.d.ts',
      aeReference: '/ae/index.d.ts',
      ownPath: '/own',
      shelvesPath: '/shelves',
    );
    expect(guide, contains('rect|circle|polygon'));
    expect(guide, contains('NO "ellipse"'));
    expect(guide, contains('frame_rate'));
    expect(guide, contains('layer_length'));
    expect(guide, contains('/tmp/fx/ops_result.json'));
    expect(guide, contains('ONCE when your turn ends'));
    expect(guide, contains('Implicit & creative partner mode'));
    expect(guide, contains('Vism first (Inspector Vism > Dock panel)'));
    expect(guide, contains('Group array motion'));
    expect(guide, contains('say` `name: "script"'));
    expect(guide, contains('up to 8 `--track@` params'));
  });

  testWidgets('AgentStarterPrompts renders custom context-aware starters', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AgentStarterPrompts(
          prompts: const [(id: 'ctx-1', title: '空から作る', prompt: 'タイトル演出を組んで')],
          onPick: (p) => picked = p,
        ),
      ),
    );
    expect(find.text('空から作る'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('agent-starter-ctx-1')));
    expect(picked, 'タイトル演出を組んで');
  });

  test('readVismPack & vismPackCells parse bundled Kinetic Array pack', () {
    final pack =
        '${Directory.current.parent.path}/shelves/effects/stylize/Kinetic Array/vism.json';
    expect(isVismPackPath(pack), isTrue);
    final info = readVismPack(pack);
    expect(info, isNotNull);
    expect(info!.name, 'Kinetic Array');
    expect(info.uiFile, endsWith('Kinetic Array.ui.js'));
    expect(info.steps.length, 2);
    final cells = vismPackCells(pack);
    expect(cells.map((c) => c.role).toList(), [
      'Vism UI',
      'Step 1 · JS',
      'Step 2 · ISF',
    ]);
  });

  test(
    'CardParamNames exposes step-prefixed names and non-colliding leaf aliases',
    () {
      final card = CardDeclaration('Kinetic Array', '''
struct Params {
  /// @label(Speed) @default(0.5)
  js_speed: f32,
  /// @label(Aura Speed) @default(0.2)
  a1b2c3:js_aura_speed: f32,
  /// @label(Glow) @default(0.35)
  a1b2c3:js_aura_glow: f32,
}
''', toneOf: () => const Color(0xFF4ECDC4));
      final names = CardParamNames(card);
      expect(names.resolve('speed'), 'js_speed');
      expect(names.resolve('aura_speed'), 'a1b2c3:js_aura_speed');
      expect(names.resolve('aura_glow'), 'a1b2c3:js_aura_glow');
      expect(names.resolve('glow'), 'a1b2c3:js_aura_glow');
    },
  );
}
