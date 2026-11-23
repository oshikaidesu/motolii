// Shared native Flutter renderer for declarative QuickJS UI trees
// (used by both Custom Docking Tabs and Effect Custom Inspector Cards).
// 詳細: docs/design/custom_panels.md
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/script_files.dart' show readRelativeBytes;
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/custom_ui/panel_knob.dart';
import 'package:motolii/widgets/custom_ui/panel_node.dart';
import 'package:motolii/widgets/custom_ui/scene3d_view.dart';
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/number_field.dart';
import 'package:motolii/widgets/number_format.dart';
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// Callback fired whenever a control in the declarative UI tree is interacted with.
typedef PanelActionCallback = void Function(
  String id,
  Object? value, {
  bool live,
});

/// Renders a [PanelNode] tree using Motolii's native widgets and current skin
/// (or a creator's VST faceplate theme when `surface` / `style` is declared).
class PanelTreeView extends StatelessWidget {
  const PanelTreeView({
    required this.node,
    required this.onAction,
    this.baseFile = '',
    super.key,
  });

  final PanelNode node;
  final PanelActionCallback onAction;
  final String baseFile;

  @override
  Widget build(BuildContext context) => _buildNode(context, node);

  Alignment _parseAlign(String align) => switch (align) {
    'topLeft' => Alignment.topLeft,
    'topCenter' => Alignment.topCenter,
    'topRight' => Alignment.topRight,
    'centerLeft' => Alignment.centerLeft,
    'centerRight' => Alignment.centerRight,
    'bottomLeft' => Alignment.bottomLeft,
    'bottomCenter' => Alignment.bottomCenter,
    'bottomRight' => Alignment.bottomRight,
    _ => Alignment.center,
  };

  TextAlign _parseTextAlign(String align) => switch (align) {
    'center' => TextAlign.center,
    'right' => TextAlign.right,
    _ => TextAlign.left,
  };

  Widget _buildNode(BuildContext context, PanelNode n) {
    final theme = PanelThemeScope.of(context);
    final st = n.style;

    switch (n.type) {
      case 'column':
        final gap = st?.gap ?? Shape.s(6);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, c) in n.children.indexed) ...[
              if (i > 0) SizedBox(height: gap),
              _buildNode(context, c),
            ],
          ],
        );

      case 'row':
        final gap = st?.gap ?? Shape.s(5);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (i, c) in n.children.indexed) ...[
              if (i > 0) SizedBox(width: gap),
              if (c.type == 'spacer')
                (c.size == null
                    ? const Spacer()
                    : SizedBox(width: Shape.s(c.size!)))
              else if (c.type == 'badge' || c.type == 'text')
                _buildNode(context, c)
              else
                Expanded(child: _buildNode(context, c)),
            ],
          ],
        );

      case 'grid':
        final cols = n.cols.clamp(1, 12);
        final rows = (n.children.length / cols).ceil();
        final gap = st?.gap ?? Shape.s(4);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) SizedBox(height: gap),
              Row(
                children: [
                  for (var c = 0; c < cols; c++) ...[
                    if (c > 0) SizedBox(width: gap),
                    Expanded(
                      child: (r * cols + c) < n.children.length
                          ? _buildNode(context, n.children[r * cols + c])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );

      case 'box':
        final nextTheme = theme.mergeStyle(st);
        final gap = st?.gap ?? Shape.s(5);
        final pad = st?.resolvePadding() ?? EdgeInsets.all(Shape.s(8));
        final inner = n.children.length == 1
            ? _buildNode(context, n.children.first)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, c) in n.children.indexed) ...[
                    if (i > 0) SizedBox(height: gap),
                    _buildNode(context, c),
                  ],
                ],
              );
        final dec =
            st?.toDecoration(
              fallbackRadius: 8.0,
              fallbackBorder: theme.border,
              fallbackBorderWidth: theme.borderWidth ?? 1.0,
            ) ??
            BoxDecoration(
              color: WindowTokens.card,
              borderRadius: Shape.round(6),
              border: Border.all(color: Grey.g20),
            );
        final Widget box = Container(
          height: st?.height,
          padding: pad,
          decoration: dec,
          child: PanelThemeScope(data: nextTheme, child: inner),
        );
        if (n.id.isNotEmpty) {
          return Pressable(
            key: ValueKey('panel:box:${n.id}'),
            onTap: n.disabled ? null : () => onAction(n.id, true),
            builder: (_, _) => box,
          );
        }
        return box;

      case 'stack':
        return Stack(
          clipBehavior: Clip.none,
          alignment: _parseAlign(n.align),
          children: [
            for (final (i, c) in n.children.indexed)
              if (i == 0 && c.align.isEmpty)
                _buildNode(context, c)
              else if (c.align == 'fill')
                Positioned.fill(child: _buildNode(context, c))
              else
                Positioned.fill(
                  child: Align(
                    alignment: _parseAlign(c.align),
                    child: Padding(
                      padding: EdgeInsets.all(c.inset ?? 6.0),
                      child: _buildNode(context, c),
                    ),
                  ),
                ),
          ],
        );

      case 'section':
        return _PanelSection(
          title: n.title,
          initialOpen: n.open,
          style: st,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, c) in n.children.indexed) ...[
                if (i > 0) SizedBox(height: st?.gap ?? Shape.s(5)),
                _buildNode(context, c),
              ],
            ],
          ),
        );

      case 'divider':
        final col =
            resolvePanelColor(st?.border ?? '') ??
            resolvePanelColor(st?.bg ?? '') ??
            theme.border?.withValues(alpha: 0.35) ??
            Grey.g20;
        return Container(height: st?.height ?? 1.0, color: col);

      case 'spacer':
        return SizedBox(height: Shape.s(n.size ?? 6));

      case 'text':
        final ink =
            resolvePanelColor(st?.fg ?? '') ??
            (n.muted ? (theme.muted ?? Grey.g56) : (theme.fg ?? Grey.g91));
        final useMono = (st?.mono ?? false) || theme.mono;
        var ts = (n.bold ? TextStyles.name : TextStyles.micro)(ink);
        if (st?.fontSize != null || st?.letterSpacing != null || useMono) {
          ts = ts.copyWith(
            fontSize: st?.fontSize != null
                ? TextStyles.px(st!.fontSize!)
                : null,
            letterSpacing: st?.letterSpacing,
            fontFamily: useMono ? 'Menlo' : null,
          );
        }
        return Text(
          n.text,
          textAlign: _parseTextAlign(st?.align ?? n.align),
          style: ts,
        );

      case 'badge':
        final tone =
            resolvePanelColor(st?.accent ?? '') ??
            resolvePanelColor(st?.bg ?? '') ??
            (n.tone.isEmpty
                ? (theme.accent ?? Accent.fill)
                : panelToneColor(n.tone));
        final customBg = resolvePanelColor(st?.bg ?? '');
        final customFg = resolvePanelColor(st?.fg ?? '');
        final customBorder = resolvePanelColor(st?.border ?? '');
        final bw = st?.borderWidth ?? 1.0;
        final rad = st?.radius ?? 4.0;
        final useMono = (st?.mono ?? false) || theme.mono;
        return Container(
          padding:
              st?.resolvePadding() ??
              EdgeInsets.symmetric(
                horizontal: Shape.s(6),
                vertical: Shape.s(2),
              ),
          decoration: BoxDecoration(
            color: customBg ?? tone.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(rad),
            border: bw > 0
                ? Border.all(
                    color: customBorder ?? tone.withValues(alpha: 0.45),
                    width: bw,
                  )
                : null,
            boxShadow: st?.shadow == null ? null : [st!.shadow!.toBoxShadow()],
          ),
          child: Text(
            n.text,
            style:
                TextStyles.micro(
                  customFg ??
                      (customBg != null ? readableInkOn(customBg) : tone),
                ).copyWith(
                  fontSize: st?.fontSize != null
                      ? TextStyles.px(st!.fontSize!)
                      : null,
                  letterSpacing: st?.letterSpacing,
                  fontWeight: customBg != null ? FontWeight.w800 : null,
                  fontFamily: useMono ? 'Menlo' : null,
                ),
          ),
        );

      case 'meter':
        final tone =
            resolvePanelColor(st?.accent ?? '') ??
            (n.tone.isEmpty
                ? (theme.accent ?? Accent.fill)
                : panelToneColor(n.tone));
        final trackCol =
            resolvePanelColor(st?.bg ?? '') ?? theme.controlBg ?? Grey.g20;
        final borderCol = resolvePanelColor(st?.border ?? '') ?? theme.border;
        final v = (n.numValue ?? 0.0).clamp(0.0, 1.0);
        final rad = st?.radius ?? 3.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (n.label.isNotEmpty) ...[
              Text(
                n.label,
                style: TextStyles.micro(
                  resolvePanelColor(st?.muted ?? '') ?? theme.muted ?? Grey.g56,
                ),
              ),
              SizedBox(height: Shape.s(3)),
            ],
            Container(
              height: st?.height ?? Shape.z(6),
              decoration: BoxDecoration(
                color: trackCol,
                borderRadius: BorderRadius.circular(rad),
                border: borderCol != null && (st?.borderWidth ?? 0) > 0
                    ? Border.all(color: borderCol, width: st!.borderWidth!)
                    : null,
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: BorderRadius.circular(rad),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'swatch':
        final swatchColor = parseHexColor(n.color) ?? Grey.g56;
        final rad = st?.radius ?? theme.radius ?? 4.0;
        final borderCol =
            resolvePanelColor(st?.border ?? '') ?? theme.border ?? Grey.g26;
        final bw = st?.borderWidth ?? (n.active ? 1.8 : 1.0);
        return Pressable(
          key: n.id.isEmpty ? null : ValueKey('panel:swatch:${n.id}'),
          onTap: n.id.isEmpty ? null : () => onAction(n.id, n.color),
          builder: (_, hot) => Container(
            height: st?.height ?? Shape.z(22),
            decoration: BoxDecoration(
              color: swatchColor,
              borderRadius: BorderRadius.circular(rad),
              border: Border.all(
                color: n.active
                    ? (theme.fg ?? Grey.g95)
                    : (hot ? Grey.g76 : borderCol),
                width: n.active ? math.max(1.8, bw) : bw,
              ),
              boxShadow: st?.shadow == null
                  ? null
                  : [st!.shadow!.toBoxShadow()],
            ),
          ),
        );

      case 'button':
        final accentCol =
            resolvePanelColor(st?.accent ?? '') ?? theme.accent ?? Accent.fill;
        final customBg = resolvePanelColor(st?.bg ?? '');
        final baseBg = customBg ?? theme.controlBg;
        final customFg = resolvePanelColor(st?.fg ?? '');
        final borderCol =
            resolvePanelColor(st?.border ?? '') ??
            theme.controlBorder ??
            theme.border;
        final bw = st?.borderWidth ?? theme.borderWidth ?? 1.0;
        final rad = st?.radius ?? theme.radius ?? 5.0;
        final sh = st?.shadow;
        final useMono = (st?.mono ?? false) || theme.mono;
        final isSolidStyled =
            customBg != null || (n.accent && theme.accent != null);
        return Opacity(
          opacity: n.disabled ? 0.4 : 1.0,
          child: Pressable(
            key: n.id.isEmpty ? null : ValueKey('panel:btn:${n.id}'),
            onTap: n.disabled ? null : () => onAction(n.id, true),
            builder: (_, hot) {
              final fillCol = customBg != null
                  ? (hot
                        ? Color.lerp(customBg, DarkGrey.g100, 0.12)!
                        : customBg)
                  : (n.accent
                        ? (theme.accent != null
                              ? (hot
                                    ? Color.lerp(
                                        accentCol,
                                        DarkGrey.g100,
                                        0.12,
                                      )!
                                    : accentCol)
                              : accentCol.withValues(alpha: hot ? 0.28 : 0.18))
                        : (baseBg != null
                              ? (hot
                                    ? Color.lerp(baseBg, accentCol, 0.14)!
                                    : baseBg)
                              : (hot ? Grey.g26 : InspectorSkin.well)));
              final textCol =
                  customFg ??
                  (isSolidStyled
                      ? readableInkOn(fillCol)
                      : (n.accent
                            ? accentCol
                            : (theme.controlFg ??
                                  (hot ? Grey.g95 : Grey.g91))));
              final strokeCol =
                  borderCol ??
                  (n.accent ? accentCol.withValues(alpha: 0.70) : Grey.g26);
              return Container(
                height: st?.height ?? Shape.z(24),
                padding:
                    st?.resolvePadding() ??
                    EdgeInsets.symmetric(horizontal: Shape.s(8)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fillCol,
                  borderRadius: BorderRadius.circular(rad),
                  border: bw > 0
                      ? Border.all(color: strokeCol, width: bw)
                      : null,
                  boxShadow: sh == null ? null : [sh.toBoxShadow()],
                ),
                child: Text(
                  n.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.micro(textCol).copyWith(
                    fontSize: st?.fontSize != null
                        ? TextStyles.px(st!.fontSize!)
                        : null,
                    letterSpacing: st?.letterSpacing,
                    fontWeight: (isSolidStyled || bw >= 1.8)
                        ? FontWeight.w800
                        : null,
                    fontFamily: useMono ? 'Menlo' : null,
                  ),
                ),
              );
            },
          ),
        );

      case 'toggle':
        final on = n.boolValue ?? false;
        final accentCol =
            resolvePanelColor(st?.accent ?? '') ?? theme.accent ?? Accent.fill;
        final borderCol =
            resolvePanelColor(st?.border ?? '') ??
            theme.controlBorder ??
            theme.border;
        final bw = st?.borderWidth ?? theme.borderWidth ?? 1.0;
        return Pressable(
          key: n.id.isEmpty ? null : ValueKey('panel:toggle:${n.id}'),
          onTap: n.disabled ? null : () => onAction(n.id, !on),
          builder: (_, hot) => Row(
            children: [
              Container(
                width: Shape.z(14),
                height: Shape.z(14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? accentCol.withValues(alpha: 0.22)
                      : (theme.controlBg ??
                            (hot ? Grey.g26 : InspectorSkin.well)),
                  borderRadius: Shape.round(3),
                  border: Border.all(
                    color: on
                        ? accentCol
                        : (borderCol ?? (hot ? Grey.g56 : Grey.g38)),
                    width: bw,
                  ),
                ),
                child: on
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentCol,
                          borderRadius: Shape.round(1.5),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: Shape.s(6)),
              Expanded(
                child: Text(
                  n.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.micro(
                    resolvePanelColor(st?.fg ?? '') ??
                        theme.fg ??
                        (hot ? Grey.g95 : Grey.g91),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'knob':
        return PanelKnob(
          knobKey: n.id.isEmpty ? null : ValueKey('panel:knob:${n.id}'),
          label: n.label,
          value: n.numValue ?? 0.0,
          min: n.min ?? 0.0,
          max: n.max ?? 1.0,
          def: n.def,
          step: n.step,
          dec: n.dec,
          unit: n.unit,
          size: n.size ?? 44.0,
          look: n.look.isEmpty ? 'arc' : n.look,
          color: n.color,
          trackColor: n.trackColor,
          capColor: n.capColor,
          borderColor: n.borderColor,
          style: st,
          onChanged: (v, {bool live = false}) => onAction(n.id, v, live: live),
        );

      case 'number':
      case 'slider':
        final cur = n.numValue ?? 0.0;
        final min = n.min;
        final max = n.max;
        final step = n.step ?? (n.type == 'slider' ? 0.01 : 1.0);
        final dec = n.dec ?? (step < 1 ? (step < 0.1 ? 2 : 1) : 0);
        final span = (min != null && max != null && max > min)
            ? (max - min)
            : 100.0;
        return NumberField(
          key: n.id.isEmpty ? null : ValueKey('panel:num:${n.id}'),
          value: () => cur,
          text: (v, _) => formatNumber(v, dec),
          unit: (_, _) => n.unit,
          caption: n.label.isEmpty ? null : n.label,
          min: min,
          max: max,
          perPx: span / 140.0,
          step: step,
          reach: (to, _) =>
              (min != null && max != null) ? to.clamp(min, max).toDouble() : to,
          onChange: (v) => onAction(n.id, v, live: true),
          onType: (v) => onAction(n.id, v),
          onDrop: () => onAction(n.id, cur),
          height: st?.height ?? InspectorSkin.tile,
          pad: InspectorSkin.tilePad,
        );

      case 'select':
        final accentCol =
            resolvePanelColor(st?.accent ?? '') ?? theme.accent ?? Accent.fill;
        final customBg = resolvePanelColor(st?.bg ?? '') ?? theme.controlBg;
        final borderCol =
            resolvePanelColor(st?.border ?? '') ??
            theme.controlBorder ??
            theme.border;
        final bw = st?.borderWidth ?? theme.borderWidth ?? 1.0;
        final rad = st?.radius ?? theme.radius ?? 4.0;
        final useMono = (st?.mono ?? false) || theme.mono;
        final solidSelected =
            st?.accent.isNotEmpty == true || theme.accent != null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (n.label.isNotEmpty) ...[
              Text(
                n.label,
                style: TextStyles.micro(
                  resolvePanelColor(st?.muted ?? '') ?? theme.muted ?? Grey.g56,
                ),
              ),
              SizedBox(height: Shape.s(3)),
            ],
            Row(
              children: [
                for (final (i, opt) in n.options.indexed) ...[
                  if (i > 0) SizedBox(width: st?.gap ?? Shape.s(3)),
                  Expanded(
                    child: Pressable(
                      key: n.id.isEmpty
                          ? null
                          : ValueKey('panel:opt:${n.id}:$opt'),
                      onTap: () => onAction(n.id, opt),
                      builder: (_, hot) {
                        final selected = n.stringValue == opt;
                        final bgCol = selected
                            ? (solidSelected
                                  ? accentCol
                                  : accentCol.withValues(alpha: 0.20))
                            : (customBg ??
                                  (hot ? Grey.g26 : InspectorSkin.well));
                        final fgCol = selected
                            ? (solidSelected
                                  ? readableInkOn(accentCol)
                                  : accentCol)
                            : (resolvePanelColor(st?.fg ?? '') ??
                                  theme.controlFg ??
                                  (hot ? Grey.g95 : Grey.g76));
                        return Container(
                          height: st?.height ?? Shape.z(22),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: bgCol,
                            borderRadius: BorderRadius.circular(rad),
                            border: bw > 0
                                ? Border.all(
                                    color: selected
                                        ? (borderCol ??
                                              accentCol.withValues(alpha: 0.65))
                                        : (borderCol ?? Grey.g26),
                                    width: bw,
                                  )
                                : null,
                            boxShadow: st?.shadow == null
                                ? null
                                : [st!.shadow!.toBoxShadow()],
                          ),
                          child: Text(
                            opt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.micro(fgCol).copyWith(
                              fontSize: st?.fontSize != null
                                  ? TextStyles.px(st!.fontSize!)
                                  : null,
                              fontWeight: selected && solidSelected
                                  ? FontWeight.w800
                                  : null,
                              fontFamily: useMono ? 'Menlo' : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

      case 'input':
      case 'color':
        final swatch = n.type == 'color' ? parseHexColor(n.stringValue) : null;
        final bgCol =
            resolvePanelColor(st?.bg ?? '') ??
            theme.controlBg ??
            InspectorSkin.well;
        final borderCol =
            resolvePanelColor(st?.border ?? '') ??
            theme.controlBorder ??
            Grey.g26;
        final fgCol =
            resolvePanelColor(st?.fg ?? '') ?? theme.controlFg ?? Grey.g91;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (n.label.isNotEmpty) ...[
              Text(n.label, style: TextStyles.micro(theme.muted ?? Grey.g56)),
              SizedBox(height: Shape.s(3)),
            ],
            Container(
              height: st?.height ?? Shape.z(22),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
              decoration: BoxDecoration(
                color: bgCol,
                borderRadius: BorderRadius.circular(st?.radius ?? 4.0),
                border: Border.all(
                  color: borderCol,
                  width: st?.borderWidth ?? 1.0,
                ),
              ),
              child: Row(
                children: [
                  if (swatch != null) ...[
                    Container(
                      width: Shape.z(12),
                      height: Shape.z(12),
                      decoration: BoxDecoration(
                        color: swatch,
                        borderRadius: Shape.round(2),
                        border: Border.all(color: Grey.g38),
                      ),
                    ),
                    SizedBox(width: Shape.s(5)),
                  ],
                  Expanded(
                    child: TypedField(
                      key: n.id.isEmpty ? null : ValueKey('panel:in:${n.id}'),
                      text: n.stringValue,
                      standing: true,
                      escapes: true,
                      style: TextStyles.micro(fgCol),
                      cursor: fgCol,
                      backgroundCursor: Grey.g20,
                      selection: Role.selected.withValues(alpha: 0.4),
                      onDone: (said) {
                        if (said != null) onAction(n.id, said);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'xy':
        return _XyPad(
          padKey: n.id.isEmpty ? null : ValueKey('panel:xy:${n.id}'),
          label: n.label,
          x: n.x,
          y: n.y,
          min: n.min ?? -1.0,
          max: n.max ?? 1.0,
          snap9: n.snap9,
          style: st,
          onPick: (nx, ny, {bool live = false}) =>
              onAction(n.id, {'x': nx, 'y': ny}, live: live),
        );

      case 'canvas':
        return _InteractiveSurface(
          surfaceKey: n.id.isEmpty ? null : ValueKey('panel:canvas:${n.id}'),
          label: n.label,
          height: (n.height ?? 96.0).clamp(32.0, 360.0),
          interactive: n.id.isNotEmpty,
          framed: n.framed ?? st?.framed ?? true,
          style: st,
          onPointer: (x, y, phase, {bool live = false}) => onAction(n.id, {
            'x': x,
            'y': y,
            'phase': phase,
            'shift': HardwareKeyboard.instance.isShiftPressed,
          }, live: live),
          builder: (size) => CustomPaint(
            size: size,
            painter: Draw((c, s) => _drawCanvasOps(c, s, n.draw), n.draw),
          ),
        );

      case 'svg':
        final resolved = resolveSvgThemeVars(n.svg);
        final fit = switch (n.fit) {
          'fill' => BoxFit.fill,
          'cover' => BoxFit.cover,
          _ => BoxFit.contain,
        };
        return _InteractiveSurface(
          surfaceKey: n.id.isEmpty ? null : ValueKey('panel:svg:${n.id}'),
          label: n.label,
          height: (n.height ?? 96.0).clamp(20.0, 360.0),
          interactive: n.id.isNotEmpty,
          framed: n.framed ?? st?.framed ?? true,
          style: st,
          onPointer: (x, y, phase, {bool live = false}) => onAction(n.id, {
            'x': x,
            'y': y,
            'phase': phase,
            'shift': HardwareKeyboard.instance.isShiftPressed,
          }, live: live),
          builder: (size) => resolved.contains('<svg')
              ? SvgPicture.string(
                  resolved,
                  width: size.width,
                  height: size.height,
                  fit: fit,
                )
              : const SizedBox.shrink(),
        );

      case 'image':
        final bytes = _decodeImageBytes(n.src, baseFile);
        final fit = switch (n.fit) {
          'fill' => BoxFit.fill,
          'cover' => BoxFit.cover,
          _ => BoxFit.contain,
        };
        return _InteractiveSurface(
          surfaceKey: n.id.isEmpty ? null : ValueKey('panel:img:${n.id}'),
          label: n.label,
          height: (n.height ?? 96.0).clamp(24.0, 360.0),
          interactive: n.id.isNotEmpty,
          framed: n.framed ?? st?.framed ?? false,
          style: st,
          onPointer: (x, y, phase, {bool live = false}) => onAction(n.id, {
            'x': x,
            'y': y,
            'phase': phase,
            'shift': HardwareKeyboard.instance.isShiftPressed,
          }, live: live),
          builder: (size) => bytes != null
              ? Image.memory(
                  bytes,
                  width: size.width,
                  height: size.height,
                  fit: fit,
                  gaplessPlayback: true,
                )
              : const SizedBox.shrink(),
        );

      case 'scene3d':
        return PanelScene3d(
          surfaceKey: n.id.isEmpty ? null : ValueKey('panel:3d:${n.id}'),
          spec: n.scene3d ?? const Scene3dSpec(),
          height: (n.height ?? 120.0).clamp(48.0, 360.0),
          interactive: n.id.isNotEmpty,
          label: n.label,
          baseFile: baseFile,
          framed: n.framed ?? st?.framed ?? true,
          style: st,
          onOrbit: n.id.isEmpty
              ? null
              : (yaw, pitch, x, y, phase, {bool live = false}) =>
                    onAction(n.id, {
                      'yaw': yaw,
                      'pitch': pitch,
                      'x': x,
                      'y': y,
                      'phase': phase,
                      'shift': HardwareKeyboard.instance.isShiftPressed,
                    }, live: live),
        );

      default:
        return Text(
          'Unknown node: ${n.type}',
          style: TextStyles.micro(Grey.g44),
        );
    }
  }
}

Uint8List? _decodeImageBytes(String src, String baseFile) {
  final trimmed = src.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('data:image/')) {
    final comma = trimmed.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(trimmed.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
  return readRelativeBytes(baseFile, trimmed);
}

class _PanelSection extends StatefulWidget {
  const _PanelSection({
    required this.title,
    required this.initialOpen,
    required this.child,
    this.style,
  });

  final String title;
  final bool initialOpen;
  final Widget child;
  final PanelStyle? style;

  @override
  State<_PanelSection> createState() => _PanelSectionState();
}

class _PanelSectionState extends State<_PanelSection> {
  late bool _open = widget.initialOpen;

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = widget.style;
    final dec =
        st?.toDecoration(
          fallbackBg: theme.controlBg ?? WindowTokens.card,
          fallbackBorder: theme.border ?? Grey.g20,
          fallbackRadius: theme.radius ?? 6.0,
          forceBorder: true,
        ) ??
        BoxDecoration(
          color: theme.controlBg ?? WindowTokens.card,
          borderRadius: BorderRadius.circular(theme.radius ?? 6.0),
          border: Border.all(
            color: theme.border ?? Grey.g20,
            width: theme.borderWidth ?? 1.0,
          ),
        );
    return Container(
      padding: st?.resolvePadding() ?? EdgeInsets.all(Shape.s(6)),
      decoration: dec,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: () => setState(() => _open = !_open),
            builder: (_, hot) => Row(
              children: [
                CustomPaint(
                  size: const Size(8, 8),
                  painter: Draw(
                    (c, s) => _drawChevron(
                      c,
                      s,
                      _open,
                      hot ? (theme.fg ?? Grey.g95) : (theme.muted ?? Grey.g56),
                    ),
                    (_open, hot, theme.fg, theme.muted),
                  ),
                ),
                SizedBox(width: Shape.s(4)),
                Text(
                  widget.title,
                  style: TextStyles.micro(
                    hot ? (theme.fg ?? Grey.g95) : (theme.fg ?? Grey.g76),
                  ),
                ),
              ],
            ),
          ),
          if (_open) ...[SizedBox(height: Shape.s(5)), widget.child],
        ],
      ),
    );
  }
}

class _XyPad extends StatelessWidget {
  const _XyPad({
    this.padKey,
    required this.label,
    required this.x,
    required this.y,
    required this.min,
    required this.max,
    required this.snap9,
    required this.onPick,
    this.style,
  });

  final Key? padKey;
  final String label;
  final double x;
  final double y;
  final double min;
  final double max;
  final bool snap9;
  final PanelStyle? style;
  final void Function(double x, double y, {bool live}) onPick;

  (double, double) _toValue(Offset local, Size size) {
    final u = (local.dx / math.max(1.0, size.width)).clamp(0.0, 1.0);
    final v = (local.dy / math.max(1.0, size.height)).clamp(0.0, 1.0);
    var nx = min + (max - min) * u;
    var ny = min + (max - min) * v;
    if (snap9) {
      final mid = (min + max) * 0.5;
      final stops = [min, mid, max];
      double nearest(double val) {
        var best = stops.first;
        for (final s in stops) {
          if ((val - s).abs() < (val - best).abs()) best = s;
        }
        return best;
      }

      nx = nearest(nx);
      ny = nearest(ny);
    }
    return (nx, ny);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = style;
    final span = math.max(1e-6, max - min);
    final u = ((x - min) / span).clamp(0.0, 1.0);
    final v = ((y - min) / span).clamp(0.0, 1.0);
    final accentCol =
        resolvePanelColor(st?.accent ?? '') ?? theme.accent ?? Accent.fill;
    final bgCol =
        resolvePanelColor(st?.bg ?? '') ??
        theme.controlBg ??
        InspectorSkin.well;
    final borderCol =
        resolvePanelColor(st?.border ?? '') ?? theme.controlBorder ?? Grey.g26;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) ...[
          Row(
            children: [
              Text(label, style: TextStyles.micro(theme.muted ?? Grey.g56)),
              const Spacer(),
              Text(
                '${formatNumber(x, 2)}, ${formatNumber(y, 2)}',
                style: TextStyles.micro(theme.fg ?? Grey.g76),
              ),
            ],
          ),
          SizedBox(height: Shape.s(3)),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, st?.height ?? Shape.z(64));
            return GestureDetector(
              key: padKey,
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final (nx, ny) = _toValue(d.localPosition, size);
                onPick(nx, ny);
              },
              onPanUpdate: (d) {
                final (nx, ny) = _toValue(d.localPosition, size);
                onPick(nx, ny, live: true);
              },
              onPanEnd: (_) => onPick(x, y),
              child: Container(
                height: size.height,
                decoration: BoxDecoration(
                  color: bgCol,
                  borderRadius: BorderRadius.circular(st?.radius ?? 6.0),
                  border: Border.all(
                    color: borderCol,
                    width: st?.borderWidth ?? 1.0,
                  ),
                ),
                child: CustomPaint(
                  size: size,
                  painter: Draw(
                    (c, s) => _drawXyPad(
                      c,
                      s,
                      u,
                      v,
                      snap9: snap9,
                      accent: accentCol,
                      gridLine: borderCol,
                    ),
                    (u, v, snap9, accentCol, borderCol),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

void _drawXyPad(
  Canvas c,
  Size s,
  double u,
  double v, {
  required bool snap9,
  required Color accent,
  required Color gridLine,
}) {
  const pad = 10.0;
  final w = math.max(1.0, s.width - pad * 2);
  final h = math.max(1.0, s.height - pad * 2);

  final line = Paint()
    ..color = gridLine
    ..strokeWidth = 1;
  c.drawLine(Offset(pad + w * 0.5, pad), Offset(pad + w * 0.5, pad + h), line);
  c.drawLine(Offset(pad, pad + h * 0.5), Offset(pad + w, pad + h * 0.5), line);

  if (snap9) {
    final dot = Paint()..color = Grey.g44;
    for (final gx in const [0.0, 0.5, 1.0]) {
      for (final gy in const [0.0, 0.5, 1.0]) {
        c.drawCircle(Offset(pad + w * gx, pad + h * gy), 2.5, dot);
      }
    }
  }

  final px = pad + w * u;
  final py = pad + h * v;
  // Vector ray from center when free-form (non-snap9) so direction/length reads instantly.
  if (!snap9) {
    c.drawLine(
      Offset(pad + w * 0.5, pad + h * 0.5),
      Offset(px, py),
      Paint()
        ..color = accent.withValues(alpha: 0.70)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }
  c.drawCircle(
    Offset(px, py),
    5.5,
    Paint()..color = accent.withValues(alpha: 0.25),
  );
  c.drawCircle(Offset(px, py), 3.5, Paint()..color = accent);
}

void _drawChevron(Canvas c, Size s, bool open, Color col) {
  final p = Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final path = Path();
  if (open) {
    path
      ..moveTo(1.5, 2.5)
      ..lineTo(s.width * 0.5, s.height - 2.2)
      ..lineTo(s.width - 1.5, 2.5);
  } else {
    path
      ..moveTo(2.5, 1.5)
      ..lineTo(s.width - 2.2, s.height * 0.5)
      ..lineTo(2.5, s.height - 1.5);
  }
  c.drawPath(path, p);
}

/// Shared interactive vector/image surface for `ui.canvas`, `ui.svg`, and `ui.image`.
class _InteractiveSurface extends StatefulWidget {
  const _InteractiveSurface({
    this.surfaceKey,
    required this.label,
    required this.height,
    required this.interactive,
    required this.framed,
    required this.onPointer,
    required this.builder,
    this.style,
  });

  final Key? surfaceKey;
  final String label;
  final double height;
  final bool interactive;
  final bool framed;
  final PanelStyle? style;
  final void Function(double x, double y, String phase, {bool live}) onPointer;
  final Widget Function(Size size) builder;

  @override
  State<_InteractiveSurface> createState() => _InteractiveSurfaceState();
}

class _InteractiveSurfaceState extends State<_InteractiveSurface> {
  double _lastX = 0.5;
  double _lastY = 0.5;

  (double, double) _norm(Offset local, Size size) {
    final nx = (local.dx / math.max(1.0, size.width)).clamp(0.0, 1.0);
    final ny = (local.dy / math.max(1.0, size.height)).clamp(0.0, 1.0);
    _lastX = nx;
    _lastY = ny;
    return (nx, ny);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = widget.style;
    final h = Shape.z(widget.height);
    final rad = st?.radius ?? 6.0;
    final bg = resolvePanelColor(st?.bg ?? '');
    final borderCol = resolvePanelColor(st?.border ?? '') ?? Grey.g26;
    final bw = st?.borderWidth ?? 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: TextStyles.micro(theme.muted ?? Grey.g56)),
          SizedBox(height: Shape.s(3)),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, h);
            final surface = widget.framed
                ? Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: bg ?? InspectorSkin.well,
                      borderRadius: BorderRadius.circular(rad),
                      border: bw > 0
                          ? Border.all(color: borderCol, width: bw)
                          : null,
                      boxShadow: st?.shadow == null
                          ? null
                          : [st!.shadow!.toBoxShadow()],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(math.max(0, rad - 1)),
                      child: widget.builder(size),
                    ),
                  )
                : SizedBox(
                    height: h,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(st?.radius ?? 0),
                      child: widget.builder(size),
                    ),
                  );
            if (!widget.interactive) return surface;
            return GestureDetector(
              key: widget.surfaceKey,
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final (x, y) = _norm(d.localPosition, size);
                widget.onPointer(x, y, 'down');
              },
              onPanStart: (d) {
                final (x, y) = _norm(d.localPosition, size);
                widget.onPointer(x, y, 'down', live: true);
              },
              onPanUpdate: (d) {
                final (x, y) = _norm(d.localPosition, size);
                widget.onPointer(x, y, 'drag', live: true);
              },
              onPanEnd: (_) => widget.onPointer(_lastX, _lastY, 'up'),
              child: surface,
            );
          },
        ),
      ],
    );
  }
}

void _drawCanvasOps(Canvas c, Size s, List<CanvasDrawOp> ops) {
  final w = s.width;
  final h = s.height;
  final minSide = math.min(w, h);

  for (final o in ops) {
    final fillCol = resolveCanvasColor(o.fill)?.withValues(alpha: o.alpha);
    final strokeCol = resolveCanvasColor(o.stroke)?.withValues(alpha: o.alpha);

    void paintPath(Path path) {
      if (fillCol != null) c.drawPath(path, Paint()..color = fillCol);
      if (strokeCol != null) {
        c.drawPath(
          path,
          Paint()
            ..color = strokeCol
            ..style = PaintingStyle.stroke
            ..strokeWidth = o.strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    switch (o.op) {
      case 'line':
        if (strokeCol != null) {
          c.drawLine(
            Offset(o.x * w, o.y * h),
            Offset(o.x2 * w, o.y2 * h),
            Paint()
              ..color = strokeCol
              ..strokeWidth = o.strokeWidth
              ..strokeCap = StrokeCap.round,
          );
        }
      case 'rect':
        final rect = Rect.fromLTWH(o.x * w, o.y * h, o.w * w, o.h * h);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(o.radius));
        if (fillCol != null) c.drawRRect(rrect, Paint()..color = fillCol);
        if (strokeCol != null) {
          c.drawRRect(
            rrect,
            Paint()
              ..color = strokeCol
              ..style = PaintingStyle.stroke
              ..strokeWidth = o.strokeWidth,
          );
        }
      case 'circle':
        final center = Offset(o.x * w, o.y * h);
        final rad = o.r * minSide;
        if (fillCol != null) {
          c.drawCircle(center, rad, Paint()..color = fillCol);
        }
        if (strokeCol != null) {
          c.drawCircle(
            center,
            rad,
            Paint()
              ..color = strokeCol
              ..style = PaintingStyle.stroke
              ..strokeWidth = o.strokeWidth,
          );
        }
      case 'arc':
        final rect = Rect.fromCircle(
          center: Offset(o.x * w, o.y * h),
          radius: o.r * minSide,
        );
        if (strokeCol != null) {
          c.drawArc(
            rect,
            o.start,
            o.sweep,
            false,
            Paint()
              ..color = strokeCol
              ..style = PaintingStyle.stroke
              ..strokeWidth = o.strokeWidth
              ..strokeCap = StrokeCap.round,
          );
        }
      case 'polyline':
        if (o.points.length >= 2) {
          final path = Path()
            ..moveTo(o.points.first.$1 * w, o.points.first.$2 * h);
          for (final pt in o.points.skip(1)) {
            path.lineTo(pt.$1 * w, pt.$2 * h);
          }
          paintPath(path);
        }
      case 'bezier':
        final path = Path()
          ..moveTo(o.x * w, o.y * h)
          ..cubicTo(
            o.cx1 * w,
            o.cy1 * h,
            o.cx2 * w,
            o.cy2 * h,
            o.x2 * w,
            o.y2 * h,
          );
        paintPath(path);
      case 'text':
        if (o.text.isNotEmpty) {
          final tp = TextPainter(
            text: TextSpan(
              text: o.text,
              style: TextStyles.micro(fillCol ?? Grey.g76),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          final dx = switch (o.align) {
            'center' => o.x * w - tp.width * 0.5,
            'right' => o.x * w - tp.width,
            _ => o.x * w,
          };
          tp.paint(c, Offset(dx, o.y * h - tp.height * 0.5));
        }
    }
  }
}
