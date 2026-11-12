// The settings an agent offers for its session (ACP session config options: model, effort, mode…) and what it
// reported of its usage, laid out as the Claude app lays out its message box: one button with the model and effort,
// beside a small ring for the context in use. The button opens one menu (the app's ContextMenu) with every setting
// under its name, the current choice ticked, and the usage in numbers at the end. The agent answers a choice with
// all its settings as they now are, so one it adds (Opus's Fast mode) shows at once. Motolii keeps no list of models
// or levels: what shows is what the agent declared, as in Zed's agent panel.
import 'dart:math' as math;

import 'package:acpd/acpd.dart'
    show
        SessionConfigGroupedOptions,
        SessionConfigOptionCategory,
        SessionConfigSelectOptionValue,
        SessionConfigUngroupedOptions;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/agent/acp_chat_session.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

class AgentSettings extends StatefulWidget {
  const AgentSettings(this.talk, {super.key});
  final AcpChatSession talk;

  @override
  State<AgentSettings> createState() => _AgentSettingsState();
}

class _AgentSettingsState extends State<AgentSettings> {
  final _menu = GlobalKey<ContextMenuState>();

  List<SessionConfigSelectOptionValue> get _selects => [
    for (final o in widget.talk.options)
      if (o is SessionConfigSelectOptionValue) o,
  ];

  static List<({String value, String name, String? about})> _choices(
    SessionConfigSelectOptionValue o,
  ) => [
    for (final c in switch (o.options) {
      SessionConfigUngroupedOptions(:final options) => options,
      SessionConfigGroupedOptions(:final groups) => [
        for (final g in groups) ...g.options,
      ],
    })
      (value: c.value, name: c.name, about: c.description),
  ];

  /// Whether choice [i] shows before "more": not when it says the same as a choice above, as an older one of it does
  /// (Claude Agent lists Opus 4.8 after Opus 5.5 in the same words, and its /model shows only the first). The current
  /// choice always shows.
  static bool _first(
    List<({String value, String name, String? about})> all,
    int i,
    String now,
  ) =>
      all[i].value == now ||
      all[i].about == null ||
      !all.take(i).any((c) => c.about == all[i].about);

  static String _now(SessionConfigSelectOptionValue o) =>
      _choices(o).where((c) => c.value == o.currentValue).firstOrNull?.name ??
      o.currentValue;

  /// The button's words: the model and the effort, as the Claude app shows "Opus 5.5" with its effort.
  String get _label => [
    for (final kind in [
      SessionConfigOptionCategory.model,
      SessionConfigOptionCategory.thoughtLevel,
    ])
      if (_selects.where((o) => o.category == kind).firstOrNull case final o?)
        _now(o),
  ].join(' · ');

  void _open(Offset global, {Set<String> more = const {}}) {
    final box = _menu.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final talk = widget.talk;
    _menu.currentState?.show(box.globalToLocal(global), [
      for (final (i, o) in _selects.indexed) ...[
        if (i > 0) const ContextMenuItem.rule(),
        ContextMenuItem(o.name, null, id: 'agent-${o.id}'),
        ..._rows(o, more, (more) => _open(global, more: more)),
      ],
      if (_usage(talk) case final rows when rows.isNotEmpty) ...[
        const ContextMenuItem.rule(),
        for (final (name, said) in rows)
          ContextMenuItem(name, null, why: said, id: 'agent-usage-$name'),
      ],
    ]);
  }

  /// One setting's choices, the current one ticked; older ones fold into a last "N more" row that opens the menu again
  /// with them shown.
  List<ContextMenuItem> _rows(
    SessionConfigSelectOptionValue o,
    Set<String> more,
    void Function(Set<String>) reopen,
  ) {
    final all = _choices(o);
    final shown = [
      for (var k = 0; k < all.length; k++)
        if (more.contains(o.id) || _first(all, k, o.currentValue)) all[k],
    ];
    return [
      for (final c in shown)
        ContextMenuItem(
          '  ${c.name}',
          () => widget.talk.choose(o.id, c.value),
          keys: c.value == o.currentValue ? '✓' : '',
          // Two settings may offer the same name (Default), so a row is named by its setting and value.
          id: 'agent-${o.id}-${c.value}',
        ),
      if (shown.length < all.length)
        ContextMenuItem(
          '  ${all.length - shown.length} more',
          () => reopen({...more, o.id}),
          keys: '▸',
          id: 'agent-${o.id}-more',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final talk = widget.talk, label = _label;
    final share = (talk.used != null && (talk.size ?? 0) > 0)
        ? talk.used! / talk.size!
        : null;
    return ContextMenu(
      key: _menu,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (share != null) ...[
            CustomPaint(size: Size.square(Shape.z(12)), painter: _Ring(share)),
            SizedBox(width: Shape.s(8)),
          ],
          if (_selects.isNotEmpty)
            GestureDetector(
              onTapUp: (d) => _open(d.globalPosition),
              child: DockHover(
                builder: (context, h) => Text(
                  '${label.isEmpty ? 'Settings' : label} ▾',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.label(h ? Grey.g95 : Grey.g76),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The usage the agent reported, as rows of the menu: the context in use, then each limit window.
List<(String, String)> _usage(AcpChatSession talk) {
  final (used, size) = (talk.used, talk.size);
  final windows = talk.limit['unifiedWindows'];
  return [
    if (used != null && size != null && size > 0)
      (
        'Context',
        '${_tokens(used)} of ${_tokens(size)} · ${(used * 100 / size).round()}%',
      ),
    if (windows is Map)
      for (final MapEntry(:key, :value) in windows.entries)
        if (value is Map && value['utilization'] is num)
          (
            '${_window('$key')} limit',
            '${((value['utilization'] as num) * 100).round()}% used',
          ),
  ];
}

String _tokens(int n) => n >= 1000000
    ? '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M'
    : n >= 1000
    ? '${(n / 1000).round()}k'
    : '$n';

/// A limit window's name as people say it: `seven_day` is 7-day, `five_hour` is 5-hour.
String _window(String key) {
  const numbers = {'one': '1', 'five': '5', 'seven': '7'};
  final parts = key.split('_');
  return parts.length == 2 && numbers[parts[0]] != null
      ? '${numbers[parts[0]]}-${parts[1]}'
      : key.replaceAll('_', ' ');
}

/// How much of the context is in use, as a ring that fills clockwise from the top.
class _Ring extends CustomPainter {
  _Ring(this.share);
  final double share;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width / 6;
    final box = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawCircle(
      box.center,
      box.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Grey.g38,
    );
    canvas.drawArc(
      box,
      -math.pi / 2,
      2 * math.pi * share.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = WindowTokens.accent,
    );
  }

  @override
  bool shouldRepaint(_Ring old) => old.share != share;
}
