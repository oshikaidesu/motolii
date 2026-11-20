// The app's default drawing of the controls a form may replace. A form that does not override a control keeps this one.
import 'package:flutter/widgets.dart';

import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/forms/forms.dart';

abstract final class BaseControls {
  /// A row of round options in a well, with the selected one filled.
  static Widget segment(BuildContext context, ChoiceSpec c) => Container(
    height: Shape.z(20),
    padding: EdgeInsets.all(Shape.s(2)),
    decoration: BoxDecoration(
      color: WindowTokens.well,
      borderRadius: Shape.round(WindowTokens.radius),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < c.labels.length; i++)
          Pressable(
            onTap: () => c.onSelect(i),
            builder: (_, h) => AnimatedContainer(
              duration: Motion.dur,
              curve: Motion.ease,
              height: Shape.z(16),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == c.selected
                    ? WindowTokens.accent
                    : (h ? WindowTokens.raised : WindowTokens.well),
                borderRadius: Shape.round(WindowTokens.chipRadius),
              ),
              child: Text(
                c.labels[i],
                style: TextStyles.label(
                  i == c.selected
                      ? WindowTokens.onAccent
                      : (h ? Grey.g95 : Grey.g76),
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    ),
  );

  /// The press, the hover and the dimming of a switch that is off limits, shared by the skins that draw their own look.
  /// [look] draws the switch; it is told whether the pointer is over it.
  static Widget toggle(SwitchSpec s, Widget Function(bool hovered) look) =>
      NakedToggle(
        value: s.on,
        asSwitch: true,
        enabled: s.enabled,
        onChanged: s.onChanged,
        builder: (context, st, _) =>
            Opacity(opacity: s.enabled ? 1 : .4, child: look(st.isHovered)),
      );

  /// An on/off chip. When on, it is raised and the mark is drawn in the accent colour.
  static Widget flag(BuildContext context, FlagSpec f) => Pressable(
    onTap: f.onTap,
    builder: (_, h) {
      final ink = f.on ? WindowTokens.accent : (h ? Grey.g91 : Grey.g56);
      return AnimatedContainer(
        duration: Motion.dur,
        curve: Motion.ease,
        height: Shape.z(20),
        padding: EdgeInsets.only(left: Shape.s(6), right: Shape.s(8)),
        decoration: BoxDecoration(
          color: f.on
              ? Grey.g26
              : (h ? WindowTokens.raised : WindowTokens.well),
          borderRadius: Shape.round(WindowTokens.radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (f.mark != null) f.mark!(ink),
            if (f.mark != null) SizedBox(width: Shape.s(5)),
            Text(
              f.label,
              style: TextStyles.label(f.on || h ? Grey.g95 : Grey.g63)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    },
  );

  /// Round filter chips in a horizontal scroll view, with the active chip in the accent colour.
  /// It scrolls like any horizontal list on a Mac: a trackpad's sideways swipe, or the mouse wheel with Shift held
  /// (Flutter's ScrollBehavior.pointerAxisModifiers). The wheel alone scrolls the vertical list around it, not this one.
  static Widget chips(BuildContext context, ChipsSpec c) => SizedBox(
    height: Shape.z(28),
    child: FadedHorizontalScroll(
      padding: EdgeInsets.fromLTRB(
        WindowTokens.inset,
        Shape.s(2),
        WindowTokens.inset,
        Shape.s(6),
      ),
      child: Row(
        children: [
          for (final (name, n) in c.chips) ...[
            Pressable(
              onTap: () => c.onPick(name),
              builder: (_, h) {
                final on = name == c.active;
                return AnimatedContainer(
                  duration: Motion.dur,
                  curve: Motion.ease,
                  height: Shape.z(20),
                  padding: EdgeInsets.symmetric(horizontal: Shape.s(7)),
                  decoration: BoxDecoration(
                    color: on
                        ? WindowTokens.accent
                        : (h ? WindowTokens.raised : WindowTokens.well),
                    borderRadius: Shape.round(WindowTokens.radius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style:
                            TextStyles.micro(
                              on ? WindowTokens.onAccent : Grey.g91,
                            ).copyWith(
                              fontWeight: on
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                      if (n != null) ...[
                        SizedBox(width: Shape.s(4)),
                        Text(
                          '$n',
                          style: TextStyles.value(
                            on ? WindowTokens.onAccent : Grey.g56,
                          ).copyWith(fontSize: TextStyles.px(10)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            SizedBox(width: WindowTokens.gap),
          ],
        ],
      ),
    ),
  );

  /// One layer name in the timeline: a band, an accent edge when selected, the kind icon and the three toggles.
  /// If [banded] is false the row has no band or edge. A [mark] is drawn at the left.
  static Widget track(
    BuildContext context,
    TrackSpec t, {
    bool banded = true,
    Widget? mark,
    Color? index,
    Color? ink,
    FontWeight rest = FontWeight.w500,
    FontWeight picked = FontWeight.w700,
    double left = 8,
    double bottom = 1,
  }) {
    final row = Padding(
      padding: EdgeInsets.only(left: Shape.s(left), right: Shape.s(6)),
      child: Row(
        children: [
          if (mark != null) ...[mark, SizedBox(width: Shape.s(6))],
          SizedBox(
            width: 14,
            child: Text(
              '${t.index + 1}',
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyles.value(
                index ?? (t.selected ? Grey.g91 : Grey.g56),
              ).copyWith(fontSize: TextStyles.px(10)),
            ),
          ),
          SizedBox(width: Shape.s(6)),
          t.kind,
          SizedBox(width: Shape.s(7)),
          Expanded(
            child: Text(
              t.name,
              style: TextStyles.name(
                t.dim ? Grey.g56 : (ink ?? (t.selected ? Grey.g100 : Grey.g91)),
              ).copyWith(fontWeight: t.selected ? picked : rest),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          t.eye,
          t.solo,
          t.lock,
          t.clip,
        ],
      ),
    );
    return NakedButton(
      onPressed: t.onSelect,
      enableFeedback: false,
      child: Container(
        color: banded
            ? (t.selected
                  ? Grey.g20
                  : (t.hot
                        ? Grey.g15
                        : (t.index.isEven ? Grey.bandA : Grey.bandB)))
            : null,
        padding: EdgeInsets.only(bottom: Shape.s(bottom)),
        child: !banded
            ? row
            : Stack(
                children: [
                  if (t.selected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: Shape.z(3),
                      child: ColoredBox(color: WindowTokens.accent),
                    ),
                  row,
                ],
              ),
      ),
    );
  }
}

/// Horizontal scroll view that fades any edge with hidden overflow so scrollable chip rows read as scrollable.
class FadedHorizontalScroll extends StatefulWidget {
  const FadedHorizontalScroll({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  @override
  State<FadedHorizontalScroll> createState() => _FadedHorizontalScrollState();
}

class _FadedHorizontalScrollState extends State<FadedHorizontalScroll> {
  final _scroll = ScrollController();
  bool _left = false, _right = false;

  void _sync(ScrollMetrics m) {
    final l = m.pixels > 0.5;
    final r = m.pixels < m.maxScrollExtent - 0.5;
    if (l != _left || r != _right) {
      setState(() {
        _left = l;
        _right = r;
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        _sync(n.metrics);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _sync(n.metrics);
          return false;
        },
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
    if (!_left && !_right) return view;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final f = bounds.width <= 0
            ? 0.0
            : (18.0 / bounds.width).clamp(0.0, 0.25);
        final opaque = Grey.g100;
        final clear = opaque.withValues(alpha: 0);
        return LinearGradient(
          colors: [
            _left ? clear : opaque,
            opaque,
            opaque,
            _right ? clear : opaque,
          ],
          stops: [0.0, _left ? f : 0.0, _right ? 1.0 - f : 1.0, 1.0],
        ).createShader(bounds);
      },
      child: view,
    );
  }
}
