// Builds rich situational context for ACP agents: current playhead/beat/marks,
// single or multi-layer selection, selected keyframes/stretches, Group Focus,
// compact scene tree, layer cards & own code copies, and accurate Motolii rules.
import 'package:acpd/acpd.dart'
    show ContentBlock, ImageContent, ResourceLink, TextContentBlock;

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/storage/agent_files.dart' show readBase64Image;
import 'package:motolii/workspace/inspector_feed/cards.dart';
import 'package:motolii/workspace/shelf/effect_code.dart';
import 'package:motolii/workspace/state/agent_context.dart';
import 'package:motolii/workspace/state/custom_panel_service.dart'
    show writeAgentSceneSnapshot;
import 'package:motolii/workspace/state/document/expression_engine.dart';
import 'package:motolii/workspace/state/engine_access.dart';
import 'package:motolii/workspace/state/layer.dart' show LayerKind;
import 'package:motolii/workspace/state/workspace_controller.dart';

class LayerCode {
  const LayerCode(this.thing, this.layer, this.cards, this.values, this.picked);
  final int thing;
  final String layer;

  /// Each card that has code: its title, its file as the layer's slot names it, and the slot.
  final List<(String, String, String)> cards;

  /// Every card of the Inspector as a line: its title, then each value as `Label (name)=value`.
  final List<String> values;

  /// The property picked in the Timeline (a stretch between two of its keyframes), or ''.
  final String picked;

  /// What is sent with a request, as one line: the layer, its cards with code and the picked property.
  String get line => [
    layer,
    if (cards.isNotEmpty) [for (final c in cards) c.$1].join(', '),
    if (picked.isNotEmpty) picked,
  ].join(' · ');
}

/// The selected layer as the agent is told of it, or null with no layer selected.
LayerCode? layerCode(WorkspaceController ws) {
  final t = ws.selected;
  if (!projectOpen(ws) || t == null) return null;
  final name = ws.layers.where((l) => l.id == t).firstOrNull?.name;
  final stretch = ws.selection.stretch;
  return LayerCode(
    t,
    name ?? 'Layer $t',
    [
      for (final c in valueCards(ws, ws.selected) ?? const <CardDeclaration>[])
        if (EffectCode.ofCard(ws, t, c.name, [for (final p in c.params) p.id])
            case final code?)
          (c.name, code.word, code.slot),
    ],
    cardValueLines(ws, t),
    stretch != null && stretch.layer == ws.selected ? stretch.name : '',
  );
}

/// Compact one-line summary of what the agent sees right now, shown above the composer.
String situationSummary(WorkspaceController ws) {
  if (!projectOpen(ws)) return 'No project open';
  final fps = WorkspaceController.fps > 0 ? WorkspaceController.fps : 60;
  final sec = ws.frame / fps;
  final parts = <String>[];
  if (ws.isolatedGroup case final g?) {
    final gName =
        ws.layers.where((l) => l.id == g).firstOrNull?.name ?? 'Group $g';
    parts.add('Focus: $gName');
  }
  if (ws.many.length > 1) {
    parts.add('${ws.many.length} layers');
  } else if (layerCode(ws) case final code?) {
    parts.add(code.line);
  } else if (ws.layers.isEmpty) {
    parts.add('Empty scene');
  } else {
    parts.add('Scene (${ws.layers.length} layers)');
  }
  if (ws.stretches.isNotEmpty) {
    final s = ws.stretches.first;
    parts.add(
      'Ease ${s.name} ${(s.from / fps).toStringAsFixed(2)}–${(s.to / fps).toStringAsFixed(2)}s',
    );
  } else if (ws.keys.isNotEmpty) {
    parts.add('${ws.keys.length} key${ws.keys.length == 1 ? '' : 's'}');
  }
  parts.add('${sec.toStringAsFixed(2)}s');
  if (ws.bpm > 0) parts.add('${ws.bpm.round()} BPM');
  return parts.join(' · ');
}

/// Accurate, pitfall-free Motolii quick reference injected into ACP context.
String buildMotoliiGuide({
  required bool hasMcp,
  required String fresh,
  required String opsPath,
  required String opsResultPath,
  required String hostTypes,
  required String uiTypes,
  required String aeReference,
  required String ownPath,
  required String shelvesPath,
}) {
  return [
    'Motolii folders: user own folder = $ownPath, built-in shelves = $shelvesPath '
        '(custom Vism panels: $ownPath/panels/<Name>.js; sidecar custom Inspector cards: <effect>.ui.js beside the effect).',
    if (hasMcp) 'Live Motolii MCP server "motolii" is connected: prefer get_scene, render_frame(at), apply_ops, read_layer_cards, list_shelves, reload_file, open_panel, export_media, get_host_reference for iterative inspect-edit-verify workflows.',
    'Motolii exact engine rules (follow strictly — any refused op rolls back the whole undo group):',
    '- Coordinates: stage origin (0,0) is center, +y is UP, +x is RIGHT. `anchor_x`/`anchor_y` are -1..1 (+y UP). Use `pivot` to move a joint without shifting visible position.',
    '- `add` kinds & files: shape = rect|circle|polygon|star|line|null|ring|arc|arrow|squircle|cog|path|spiral|chamfer (NO "ellipse" — use circle + scale_x/scale_y); solid = ring|gem|cube|ball|sketch or .glb/.gltf; image = .png/.jpg/.webp/.svg; text = "" or .ttf/.otf; video/sound = media path; camera; light = sun|point|spot; environment.',
    '- Stage (`layer: 0`) properties: `bpm`, `bpm_from`, `frame_rate`, `layer_length`, `background` (6-hex), `script` (NO `seconds` or `fps` properties).',
    '- Colors (`fill`, `stroke`, `background`, etc.): 6-digit hex without `#`, e.g. `ff3366`.',
    '- Expressions vs shaders: attach `.js` expressions via `say` `name: "script"` (or as an `fx` step; up to 8 `--track@` params, exposed as `js_<param>` after commit); attach `.fs`/`.wgsl` shaders via `fx`. Never `set` newly created `js_*` params in the same undo group as attaching the script/fx — put initial values in the script/shader defaults and let subsequent edits or Inspector Vism cards tweak them.',
    '- Vism first (Inspector Vism > Dock panel): Vism is NOT a plain knob macro — it is a visual, direct-manipulation instrument (`ui.svg`, `ui.scene3d`, `ui.shader`, `ui.waveform`, `ui.curve`, `ui.sequencer`, `ui.picker`) that lives inside the layer/group\'s Inspector `ValuesCard`. Prefer Inspector Vism (`<effect>.ui.js` or a multi-code `vism.json` pack combining Expression + p5.js/WGSL/ISF/TSL into one card with nested Code notebook cells). Use `panels/*.js` only for cross-layer workflow utilities.',
    '- Group array motion: attaching an expression (or Vism pack containing an expression) to a group layer runs `each(i, n, t, k, at)` across its child layers `[0..n-1]`, enabling repeater/stagger/falloff choreography across mixed children.',
    '- Craft principle: leverage existing Motolii strengths (shelves/ shaders, expressions, presets, 3D solids/lights/camera, Jolt rigid_body, SVG assets, audio FFT, Inspector Vism packs) instead of building crude placeholder shapes from scratch.',
    '- Implicit & creative partner mode: users often speak tersely ("ここ寂しい", "ちょっと強い", "1枚にまとめて") relying on your awareness of `Recent user activity`, selection, playhead, keyframes, and `stage.png`. Infer intent directly. When the user asks for critique/brainstorming, do NOT mutate the scene yet — inspect `stage.png`, timing, and layers, give concrete critique, and offer 2-3 options you can apply in 1 undo once they pick one.',
    'Fallback ops file (when MCP is unavailable): write a JSON array or {"ops":[...],"notice":"..."} to $opsPath. '
        'Motolii applies $opsPath ONCE when your turn ends (never mid-turn) and writes commit status/errors to $opsResultPath plus refreshed scene.json & stage.png. '
        'Supported ops: add (layer:-1 targets last added, layer:0 targets stage), create, psd, pivot, set, say, key (ease e.g. "Bezier 0.2 0 0.2 1"), fx, explode (mode: letters|strokes), outline, remove, select, time, play, open_panel, reload_shelves, later.',
    'Single new expression/shader for the selected layer: write .js/.fs/.wgsl/.css into $fresh (.ui.js and panels/*.js hot-reload without attaching as layer fx). '
        'Type definitions — Host API: $hostTypes | Vism UI: $uiTypes | AE globals: $aeReference.',
  ].join('\n');
}

/// The folder a request's new files go in: a fresh one under the own programs, as an empty expression's (empty_effect.dart).
String newFolder() =>
    '${ownFolder()}/programs/fx/${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

/// Builds ACP context blocks for the full scene (current editing situation,
/// single/multi selection, playhead/marks/audio, inline layer outline,
/// `scene.json` + `stage.png`, selected layer's cards/code, and attachments).
Future<List<ContentBlock>> ownedFor(
  WorkspaceController ws,
  LayerCode? code,
  String fresh, {
  bool supportsImage = false,
  bool hasMcp = false,
  List<String> attachments = const [],
}) async {
  final snap = writeAgentSceneSnapshot(ws, fresh);
  final files = code == null
      ? const <(String, String)>[]
      : [
          for (final (title, word, slot) in code.cards)
            (
              title,
              EffectCode.alone(ws, code.thing, word, slot)
                  ? EffectCode.source(word)
                  : EffectCode.copyOwn(ws, code.thing, word, slot).$2,
            ),
        ];
  if (code != null) ws.reread();
  final runs = <String>{};
  for (final (_, f) in files) {
    if (f.endsWith('.js')) {
      runs.addAll((await supportedIn(ws, f))?.keys ?? const []);
    }
  }
  final shelves = shelvesFolder();
  final hostTypes = '$shelves/motolii-host.d.ts';
  final uiTypes = '$shelves/motolii-ui.d.ts';
  final reference =
      '${engineFolder()}/third_party/js/expression-globals-typescript/index.d.ts';
  final opsPath = '$fresh/ops.json';
  final opsResultPath = '$fresh/ops_result.json';
  final stageImage = supportsImage && snap.stagePng != null
      ? readBase64Image(snap.stagePng!)
      : null;
  final extraBlocks = <ContentBlock>[];
  for (final path in attachments) {
    final img = supportsImage ? readBase64Image(path) : null;
    if (img != null) {
      extraBlocks.add(
        ImageContent(
          data: img.data,
          mimeType: img.mimeType,
          uri: Uri.file(path).toString(),
        ),
      );
    }
    extraBlocks.add(
      ResourceLink(
        name: path.split('/').last,
        title: path.split('/').last,
        uri: Uri.file(path).toString(),
      ),
    );
  }
  final situationLines = _describeSituation(ws, code, files);
  final outline = sceneOutlineLines(ws);
  return [
    TextContentBlock(
      text: [
        ...situationLines,
        if (outline.isNotEmpty) ...[
          'Current scene layers (* = selected):',
          ...outline,
        ] else
          'Scene is currently empty (0 layers).',
        if (ws.document != null)
          'Open project: ${ws.document} (folder: ${ws.documentFolder ?? ''}).',
        if (snap.sceneJson != null) 'Full scene JSON: ${snap.sceneJson}.',
        if (snap.stagePng != null) 'Current stage preview: ${snap.stagePng}.',
        buildMotoliiGuide(
          hasMcp: hasMcp,
          fresh: fresh,
          opsPath: opsPath,
          opsResultPath: opsResultPath,
          hostTypes: hostTypes,
          uiTypes: uiTypes,
          aeReference: reference,
          ownPath: ownFolder(),
          shelvesPath: shelves,
        ),
        if (runs.isNotEmpty)
          'Running host calls on selected layer: ${(runs.toList()..sort()).join(', ')}.',
      ].join('\n'),
    ),
    if (stageImage != null)
      ImageContent(
        data: stageImage.data,
        mimeType: stageImage.mimeType,
        uri: Uri.file(snap.stagePng!).toString(),
      ),
    if (snap.sceneJson case final s?)
      ResourceLink(
        name: 'scene.json',
        title: 'Scene JSON',
        uri: Uri.file(s).toString(),
      ),
    if (snap.stagePng case final p?)
      ResourceLink(
        name: 'stage.png',
        title: 'Stage Preview',
        uri: Uri.file(p).toString(),
      ),
    for (final (t, f) in files)
      ResourceLink(name: t, title: t, uri: Uri.file(f).toString()),
    ...extraBlocks,
  ];
}

List<String> _describeSituation(
  WorkspaceController ws,
  LayerCode? code,
  List<(String, String)> files,
) {
  final fps = WorkspaceController.fps > 0 ? WorkspaceController.fps : 60;
  final sec = ws.frame / fps;
  final totalSec = WorkspaceController.duration / fps;
  final comp = WorkspaceController.comp;
  final (workFrom, workTo) = ws.work;
  final hasAudio = sceneHasAudio(ws);
  final hasCamera = ws.layers.any((l) => l.kind == LayerKind.camera);
  final lines = <String>[
    'Current Motolii editing situation (use this to infer the user\'s intent without asking them to repeat context):',
    '- Composition: ${comp.width.round()}x${comp.height.round()} @ ${fps}fps, '
        'duration ${totalSec.toStringAsFixed(2)}s, playhead at ${sec.toStringAsFixed(2)}s (frame ${ws.frame})'
        '${workTo > workFrom ? ', work area ${workFrom.toStringAsFixed(2)}s..${workTo.toStringAsFixed(2)}s' : ''}'
        '${ws.bpm > 0 ? ', BPM ${_fmtNum(ws.bpm)} (beat ${_fmtNum(sec * ws.bpm / 60)})' : ''}'
        '${hasAudio ? ', audio present (${ws.strikes.length} beat strikes)' : ''}'
        '${hasCamera ? ', 3D camera present' : ''}.',
  ];
  if (ws.marks.isNotEmpty) {
    final markList = [
      for (final (at, name) in ws.marks.take(12))
        '${at.toStringAsFixed(2)}s:"$name"',
    ].join(', ');
    lines.add('- Timeline markers: $markList.');
  }
  if (ws.isolatedGroup case final g?) {
    final gName =
        ws.layers.where((l) => l.id == g).firstOrNull?.name ?? 'Group $g';
    lines.add(
      '- Group Focus active on "$gName" (id $g): stage.png shows only this group centered and upright.',
    );
  }
  if (ws.many.length > 1) {
    final picked = [
      for (final id in ws.many)
        '"${ws.layers.where((l) => l.id == id).firstOrNull?.name ?? 'Layer $id'}" (id $id)',
    ].join(', ');
    lines.add(
      '- Multi-selection (${ws.many.length} layers${ws.manyInOrder ? ', first is leader' : ''}): $picked.',
    );
  } else if (code != null) {
    lines.add(
      '- Selected layer: "${code.layer}" (id ${code.thing}). Inspector cards now (card values override code defaults):',
    );
    for (final v in code.values) {
      lines.add('  * $v');
    }
    if (files.isNotEmpty) {
      lines.add(
        '- Selected layer\'s own code copies (editing saves directly to this layer, never the shelf):',
      );
      for (final (t, f) in files) {
        lines.add('  * $t: $f');
      }
    }
  } else {
    lines.add(
      '- No specific layer selected (user is asking about the whole scene or wants something created).',
    );
  }
  if (ws.stretches.isNotEmpty) {
    final st = [
      for (final s in ws.stretches)
        'layer ${s.layer} "${s.name}" ${(s.from / fps).toStringAsFixed(2)}s..${(s.to / fps).toStringAsFixed(2)}s',
    ].join(', ');
    lines.add(
      '- Selected timeline easing stretch(es): $st (user is likely tuning motion feel/easing on this span).',
    );
  } else if (ws.keys.isNotEmpty) {
    final ks = [
      for (final k in ws.keys.take(8))
        'layer ${k.layer} @ ${(k.frame / fps).toStringAsFixed(2)}s (frame ${k.frame})',
    ].join(', ');
    lines.add('- Selected keyframe(s): $ks.');
  }
  if (ws.recentActivity.isNotEmpty) {
    lines.add(
      '- Recent user activity (oldest → newest): ${ws.recentActivity.join(' -> ')}.',
    );
  }
  return lines;
}

/// One subtle, locally detected action chip (0ms, no LLM call) — short label only;
/// the underlying intent stays invisible so the pane never feels like a template list.
typedef ContextChip = ({String id, String label, String prompt});

/// Detects at most 2 genuinely relevant context chips from the live scene structure.
List<ContextChip> contextChipsFor(WorkspaceController ws) {
  if (!projectOpen(ws)) return const [];
  final chips = <ContextChip>[];
  final sel = ws.layer;
  final fps = WorkspaceController.fps > 0 ? WorkspaceController.fps : 60;
  final totalSec = WorkspaceController.duration / fps;

  if (ws.stretches.isNotEmpty) {
    chips.add((
      id: 'ease-feel',
      label: '動きのキレを詰める',
      prompt: '今選んでいるイージング区間の動きを見て、もっと気持ちいい緩急に調整して',
    ));
  }
  if (sel != null) {
    final fxCount = ws.fxOf(sel.id).length;
    if (fxCount >= 2) {
      chips.add((
        id: 'pack-vism',
        label: '1枚のVismパックに束ねる',
        prompt: '選択中レイヤーに重なっているエフェクト・式を、可視化付きの1枚のInspector Vismパック（vism.json + .ui.js）に束ねて',
      ));
    }
    final children = ws.layers.where((l) => l.parent == sel.id).length;
    if (sel.kind == LayerKind.group && children >= 2) {
      chips.add((
        id: 'group-array',
        label: '子レイヤーを配列アニメ化',
        prompt: 'このグループの子レイヤー群を配列処理（each）でリピーター／スタッガー風に動かし、Inspector Vismカードで可視化・調整できるようにして',
      ));
    }
  }
  if (ws.many.length > 1) {
    chips.add((
      id: 'multi-group-vism',
      label: 'まとめて配列アニメ化',
      prompt: '選択中のレイヤー群をグループ化して配列モーションと可視化付きInspector Vismカードを付けて',
    ));
  }
  if (chips.length < 2 && ws.layers.isNotEmpty && totalSec >= 2.0) {
    int maxKey = -1;
    for (final l in ws.layers) {
      for (final f in l.keys) {
        if (f > maxKey) maxKey = f;
      }
    }
    final maxSec = maxKey >= 0 ? maxKey / fps : -1.0;
    if (maxSec > 0.1 && maxSec < totalSec * 0.45) {
      chips.add((
        id: 'hold-after-intro',
        label: '${maxSec.toStringAsFixed(1)}s以降の余韻を足す',
        prompt:
            '${maxSec.toStringAsFixed(1)}sまでの既存モーションは活かしつつ、それ以降も画面が生きて見える演出とInspector Vismカードを提案・構築して',
      ));
    }
  }
  if (chips.length < 2 && sceneHasAudio(ws)) {
    chips.add((
      id: 'audio-link',
      label: '音・ビートに連動',
      prompt: 'このシーンの音声・ビートに合わせて反応する表現と可視化付きInspector Vismカードを付けて',
    ));
  }
  if (chips.isEmpty && ws.layers.isNotEmpty) {
    chips.add((
      id: 'cut-review',
      label: '今のカットを見る',
      prompt: '今のカットの見た目・構成・テンポを見て、良くなっている点ともう一段良くする演出案を2〜3個提案して（まだ変更しないで）',
    ));
  }
  return chips.take(2).toList();
}

/// Quiet, context-sensitive single-line placeholder for the composer.
String composerHintFor(WorkspaceController ws, String agentName) {
  if (!projectOpen(ws) || ws.layers.isEmpty) {
    return '例:「タイトル演出を一緒に考えて」「3Dと音で…」';
  }
  if (ws.stretches.isNotEmpty) {
    return '例:「もう少しキレを出して」「余韻を長めに」…';
  }
  if (ws.many.length > 1) {
    return '例:「順番にずらして」「グループにして配列で動かして」…';
  }
  final sel = ws.layer;
  if (sel != null) {
    if (sel.kind == LayerKind.group) {
      return '例:「子レイヤーを波打たせて」「Vismカードで操れるように」…';
    }
    if (ws.fxOf(sel.id).length >= 2) {
      return '例:「重ねたFXを1枚のVismにまとめて」「強すぎた」…';
    }
    return '例:「ここ物足りない」「可視化付きVismカードにして」…';
  }
  return '一言でOK（例:「ここ寂しい」「次どう繋ごう？」）';
}

String _fmtNum(double v) =>
    v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);
