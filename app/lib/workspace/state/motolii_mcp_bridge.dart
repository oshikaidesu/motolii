// Built-in local MCP server for ACP agents: exposes live Motolii scene state,
// arbitrary-timestamp frame rendering (image), unrestricted single-undo ops,
// shelf search, code hot-reload with compiler feedback, Vism panel docking,
// export/pack, and host TypeScript API references.
import 'dart:async';
import 'dart:convert';

import 'package:acpd/acpd.dart' show HttpHeader, McpServer, McpServerHttp;

import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/storage/agent_files.dart'
    show readBase64Image, readOptionalTextFile;
import 'package:motolii/storage/agent_mcp_transport.dart';
import 'package:motolii/storage/shelf_disk.dart' show makeFolder;
import 'package:motolii/storage/shelf_meta.dart' show clearShelfMetaCache;
import 'package:motolii/widgets/custom_ui/panel_node.dart'
    show PanelOp, parsePanelList;
import 'package:motolii/workspace/inspector_feed/cards.dart' show valueCards;
import 'package:motolii/workspace/shelf/effect_code.dart' show EffectCode;
import 'package:motolii/workspace/state/agent_context.dart' show cardValueLines;
import 'package:motolii/workspace/state/custom_panel_service.dart'
    show
        applyCustomPanelOps,
        clearCustomCardUiCache,
        customPanelCtxJson,
        customPanelListRaw,
        openVismPanelInDock,
        panelDocOpOf;
import 'package:motolii/workspace/state/document/expression_engine.dart'
    show readCodeFile;
import 'package:motolii/workspace/state/engine_access.dart'
    show engineFolder, ownFolder, shelvesFolder;
import 'package:motolii/workspace/state/workspace_controller.dart';

/// Singleton loopback MCP server attached to the active [WorkspaceController].
class MotoliiMcpBridge {
  MotoliiMcpBridge._();
  static final instance = MotoliiMcpBridge._();

  AgentMcpTransport? _transport;
  Future<AgentMcpTransport?>? _starting;
  WorkspaceController? _ws;

  /// Binds the active workspace so tool calls operate on the currently open project.
  void attach(WorkspaceController ws) => _ws = ws;

  /// Ensures the local HTTP MCP server is running and returns the ACP
  /// [McpServerHttp] descriptor to inject into `session/new`.
  Future<McpServer?> ensureServer(WorkspaceController ws) async {
    _ws = ws;
    final t = _transport ?? await (_starting ??= _start());
    if (t == null) return null;
    return McpServerHttp(
      name: 'motolii',
      url: t.url,
      headers: [HttpHeader(name: 'Authorization', value: 'Bearer ${t.token}')],
    );
  }

  Future<AgentMcpTransport?> _start() async {
    try {
      return _transport = await AgentMcpTransport.start(
        listTools: _toolSchemas,
        callTool: _callTool,
      );
    } catch (_) {
      _starting = null;
      return null;
    }
  }

  /// Directly invokes a tool (also used by unit tests without needing HTTP).
  Future<Map<String, Object?>> invokeTool(
    String name,
    Map<String, Object?> args,
  ) => _callTool(name, args);

  static List<Map<String, Object?>> _toolSchemas() => const [
    {
      'name': 'get_scene',
      'description': 'Read the complete live Motolii scene: layers (id, name, kind, parent, transform, anchor, fx, text, bounds), comp size/fps/duration, bpm, marks, audio spectrum/waveform, selection, and project/shelf folder paths.',
      'inputSchema': {'type': 'object', 'properties': {}},
    },
    {
      'name': 'render_frame',
      'description': 'Render the Motolii stage at an optional timestamp (in seconds) and return the PNG image directly so you can visually inspect your edits across multiple frames.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'at': {
            'type': 'number',
            'description':
                'Timestamp in seconds (defaults to current playhead).',
          },
        },
      },
    },
    {
      'name': 'apply_ops',
      'description': 'Apply one or more Motolii document/workspace operations in a single undo step. Layer 0 targets stage/composition settings (fps, seconds, bpm, width, height, fx, etc.), layer -1 targets the most recently added layer. Supported ops: set, say, key, add, create (recipe), psd, pivot, explode, outline, remove, fx, undo, redo, select, time, play, reload_shelves, open_panel, and later (raw engine motolii_later verb: mark, guide, split, brush, fx_move, isolate, ...).',
      'inputSchema': {
        'type': 'object',
        'required': ['ops'],
        'properties': {
          'ops': {
            'type': 'array',
            'items': {'type': 'object'},
          },
          'notice': {'type': 'string'},
        },
      },
    },
    {
      'name': 'read_layer_cards',
      'description': 'Read every Inspector card, current parameter values, and attached code files for a layer (defaults to selected layer).',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'layer': {
            'type': 'integer',
            'description':
                'Layer ID (0 for stage, omit for currently selected layer).',
          },
        },
      },
    },
    {
      'name': 'list_shelves',
      'description': 'Search or list Motolii shelves: effects (.fs/.wgsl/AviUtl/AE), animators (expressions), relations, recipes (create scripts), presets, panels (Vism tools), or layer_effects.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'kind': {
            'type': 'string',
            'enum': [
              'effects',
              'animators',
              'relations',
              'recipes',
              'presets',
              'panels',
              'layer_effects',
            ],
          },
          'query': {'type': 'string'},
          'limit': {'type': 'integer'},
        },
      },
    },
    {
      'name': 'reload_file',
      'description': 'Hot-reload a code file you created or edited (.js, .fs, .wgsl, .ui.js, panels/*.js, .css, .way, .am, .mjs) in the live engine and return any compile/runtime error immediately.',
      'inputSchema': {
        'type': 'object',
        'required': ['path'],
        'properties': {
          'path': {'type': 'string'},
          'openPanel': {
            'type': 'boolean',
            'description':
                'If true and the file is a Vism panel, dock and open it.',
          },
        },
      },
    },
    {
      'name': 'open_panel',
      'description': 'Reload discovered Vism panels (shelves/panels/*.js or user panels/*.js) and open one immediately as a live docking tab.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'path': {'type': 'string'},
          'name': {'type': 'string'},
        },
      },
    },
    {
      'name': 'export_media',
      'description': 'Export a still PNG frame or package the project and its media into a portable folder (mode: "still" or "pack").',
      'inputSchema': {
        'type': 'object',
        'required': ['mode', 'path'],
        'properties': {
          'mode': {
            'type': 'string',
            'enum': ['still', 'pack'],
          },
          'path': {
            'type': 'string',
            'description':
                'Output PNG file path (for still) or target folder (for pack).',
          },
          'name': {
            'type': 'string',
            'description': 'Package name when mode is "pack".',
          },
          'at': {
            'type': 'number',
            'description':
                'Optional timestamp in seconds before taking a still.',
          },
        },
      },
    },
    {
      'name': 'get_host_reference',
      'description': 'Get paths (and optionally full contents) of Motolii TypeScript API definitions: motolii-host.d.ts (expressions & Vism host API), motolii-ui.d.ts (Vism UI / custom cards), and AE expression globals.',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'topic': {
            'type': 'string',
            'enum': ['host', 'ui', 'ae', 'paths'],
          },
        },
      },
    },
  ];

  static Map<String, Object?> _text(String s, {bool isError = false}) => {
    if (isError) 'isError': true,
    'content': [
      {'type': 'text', 'text': s},
    ],
  };

  Future<Map<String, Object?>> _callTool(
    String name,
    Map<String, Object?> args,
  ) async {
    final ws = _ws;
    if (ws == null || ws.inside == null) {
      return _text('No open Motolii project.', isError: true);
    }
    final m = ws.inside!;
    switch (name) {
      case 'get_scene':
        final scene = jsonDecode(customPanelCtxJson(ws, const {})) as Map;
        scene['paths'] = {
          'document': ws.document,
          'documentFolder': ws.documentFolder,
          'ownFolder': ownFolder(),
          'shelvesFolder': shelvesFolder(),
          'hostTypes': '${shelvesFolder()}/motolii-host.d.ts',
          'uiTypes': '${shelvesFolder()}/motolii-ui.d.ts',
        };
        return _text(const JsonEncoder.withIndent('  ').convert(scene));

      case 'render_frame':
        if (args['at'] case final num sec) {
          final fps = WorkspaceController.fps > 0
              ? WorkspaceController.fps
              : 60;
          ws.frame = (sec.toDouble() * fps).round();
          m.at(sec.toDouble());
          await Future<void>.delayed(const Duration(milliseconds: 90));
        }
        final dir = '${ownFolder()}/programs/fx/_mcp';
        makeFolder(dir);
        final out =
            '$dir/frame_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}.png';
        if (!m.still(out)) {
          return _text('Failed to render stage frame.', isError: true);
        }
        final img = readBase64Image(out);
        final atSec =
            ws.frame /
            (WorkspaceController.fps > 0 ? WorkspaceController.fps : 60);
        return {
          'content': [
            {
              'type': 'text',
              'text': jsonEncode({
                'ok': true,
                'path': out,
                'frame': ws.frame,
                'time': atSec,
              }),
            },
            if (img != null)
              {'type': 'image', 'data': img.data, 'mimeType': img.mimeType},
          ],
        };

      case 'apply_ops':
        final rawOps = args['ops'];
        if (rawOps is! List) {
          return _text('"ops" must be a JSON array.', isError: true);
        }
        final parsed = <PanelOp>[];
        for (final item in rawOps) {
          final op = PanelOp.fromJson(item);
          if (op != null) parsed.add(op);
        }
        if (parsed.isEmpty) {
          return _text('No valid ops found in array.', isError: true);
        }
        applyCustomPanelOps(ws, [for (final o in parsed) panelDocOpOf(o)]);
        final notice = args['notice']?.toString() ?? '';
        if (notice.isNotEmpty) ws.notice = notice;
        await Future<void>.delayed(const Duration(milliseconds: 90));
        return _text(
          jsonEncode({
            'ok': true,
            'applied': parsed.length,
            'layerCount': ws.layers.length,
            'selected': ws.many.isNotEmpty ? ws.many.toList() : [?ws.selected],
            'frame': ws.frame,
          }),
        );

      case 'read_layer_cards':
        final id = (args['layer'] is num)
            ? (args['layer'] as num).toInt()
            : ws.selected;
        if (id == null) {
          return _text(
            'No layer selected and no layer ID given.',
            isError: true,
          );
        }
        final cards = valueCards(ws, id) ?? const [];
        final codeFiles = <Map<String, String>>[
          for (final c in cards)
            if (EffectCode.ofCard(ws, id, c.name, [
                  for (final p in c.params) p.id,
                ])
                case final code?)
              {'card': c.name, 'file': code.word, 'slot': code.slot},
        ];
        return _text(
          const JsonEncoder.withIndent('  ').convert({
            'layer': id,
            'values': cardValueLines(ws, id),
            'codeFiles': codeFiles,
          }),
        );

      case 'list_shelves':
        final kind = '${args['kind'] ?? 'effects'}';
        final query = '${args['query'] ?? ''}'.trim().toLowerCase();
        final limit = (args['limit'] is num)
            ? (args['limit'] as num).toInt().clamp(1, 200)
            : 40;
        final rows = <Map<String, Object?>>[];
        if (kind == 'panels') {
          for (final p in parsePanelList(customPanelListRaw(ws))) {
            rows.add({
              'name': p.name,
              'path': p.path,
              'about': p.about,
              'acts': p.acts,
            });
          }
        } else if (kind == 'recipes') {
          for (final (n, what) in m.createScripts) {
            rows.add({'name': n, 'about': what});
          }
        } else {
          final pairs = switch (kind) {
            'animators' => m.animators,
            'relations' => m.relations,
            'presets' => m.presets,
            'layer_effects' => m.layerEffects,
            _ => m.effects,
          };
          for (final (n, f) in pairs) {
            rows.add({
              'name': n,
              'path': f,
              'about': m.about(f),
              'tags': m.tags(f).toList(),
            });
          }
        }
        final filtered = query.isEmpty
            ? rows
            : [
                for (final r in rows)
                  if ('${r['name']} ${r['path']} ${r['about']} ${r['tags']}'
                      .toLowerCase()
                      .contains(query))
                    r,
              ];
        return _text(
          jsonEncode({
            'kind': kind,
            'total': filtered.length,
            'items': filtered.take(limit).toList(),
          }),
        );

      case 'reload_file':
        final path = '${args['path'] ?? ''}'.trim();
        if (path.isEmpty) {
          return _text('Missing "path".', isError: true);
        }
        clearShelfMetaCache();
        clearCustomCardUiCache();
        m.forgetFolders();
        final isPanel =
            path.contains('/panels/') &&
            path.endsWith('.js') &&
            !path.endsWith('.ui.js');
        if (path.endsWith('.ui.js') || isPanel || path.endsWith('.way')) {
          ws.reread();
          String? opened;
          if (isPanel && args['openPanel'] == true) {
            opened = openVismPanelInDock(ws, path: path);
          }
          return _text(
            jsonEncode({'ok': true, 'reloaded': path, 'openedPanel': ?opened}),
          );
        }
        final completer = Completer<(bool, String)>();
        readCodeFile(ws, path, (done, why) {
          ws.reread();
          if (!completer.isCompleted) completer.complete((done, why));
        });
        final (ok, why) = await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () => (true, ''),
        );
        return _text(
          jsonEncode({'ok': ok, 'path': path, if (!ok) 'error': why.trim()}),
          isError: !ok,
        );

      case 'open_panel':
        final opened = openVismPanelInDock(
          ws,
          path: args['path']?.toString(),
          name: args['name']?.toString(),
        );
        if (opened == null) {
          return _text(
            'Panel not found. Save a .js panel under ${ownFolder()}/panels/ or ${shelvesFolder()}/panels/.',
            isError: true,
          );
        }
        return _text(jsonEncode({'ok': true, 'openedPanel': opened}));

      case 'export_media':
        final mode = '${args['mode'] ?? ''}';
        final path = '${args['path'] ?? ''}'.trim();
        if (path.isEmpty) return _text('Missing "path".', isError: true);
        if (mode == 'still') {
          if (args['at'] case final num sec) {
            m.at(sec.toDouble());
            await Future<void>.delayed(const Duration(milliseconds: 80));
          }
          final ok = m.still(path);
          return _text(jsonEncode({'ok': ok, 'path': path}), isError: !ok);
        }
        if (mode == 'pack') {
          final packName = '${args['name'] ?? 'project'}'.trim();
          final count = m.pack(path, packName.isEmpty ? 'project' : packName);
          return _text(
            jsonEncode({'ok': count >= 0, 'folder': path, 'files': count}),
            isError: count < 0,
          );
        }
        return _text('Unsupported export mode: $mode', isError: true);

      case 'get_host_reference':
        final hostPath = '${shelvesFolder()}/motolii-host.d.ts';
        final uiPath = '${shelvesFolder()}/motolii-ui.d.ts';
        final aePath =
            '${engineFolder()}/third_party/js/expression-globals-typescript/index.d.ts';
        final topic = '${args['topic'] ?? 'paths'}';
        if (topic == 'host') {
          return _text(
            readOptionalTextFile(hostPath) ?? 'Not found: $hostPath',
          );
        }
        if (topic == 'ui') {
          return _text(readOptionalTextFile(uiPath) ?? 'Not found: $uiPath');
        }
        if (topic == 'ae') {
          return _text(readOptionalTextFile(aePath) ?? 'Not found: $aePath');
        }
        return _text(
          jsonEncode({
            'motoliiHostTypes': hostPath,
            'motoliiUiTypes': uiPath,
            'aeExpressionGlobals': aePath,
            'shelvesFolder': shelvesFolder(),
            'userOwnFolder': ownFolder(),
          }),
        );

      default:
        return _text('Unknown tool: $name', isError: true);
    }
  }
}
