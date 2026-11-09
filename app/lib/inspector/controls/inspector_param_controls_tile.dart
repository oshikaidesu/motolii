// One parameter. The number is NumField. A choice is the segmented control already built on naked_ui.
import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart';

/// One parameter. A number is [NumField] (scrub, type, past the range). A choice is [Segmented].
/// Words, a file and a colour show the text the document already holds.
class ParamTile extends StatelessWidget {
  const ParamTile(this.fx, this.p, {super.key});
  final String fx;
  final Param p;

  String get id => '${fx}_${p.id}';

  Widget _num(BuildContext context, {String? sub, String? caption}) {
    final fid = sub == null ? id : '$id.$sub';
    return RowInfo(
      unit: null,
      keys: Ctx.of(context).doc.keys[id] ?? KeyS.off,
      child: NumField(
        id: fid,
        caption: caption ?? p.label,
        unit: p.unit,
        decimals: p.dec,
        min: p.min,
        max: p.max,
        open: p.open,
        validMin: p.validMin,
        validMax: p.validMax,
        perPx: p.perPx,
        step: p.dec > 0 ? p.step * 10 : 1,
        bipolar: p.look == ParamLook.bipolar,
        turns: p.look == ParamLook.angle,
        enabled: !RowOff.offOf(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (p.look) {
      case ParamLook.toggle:
        final doc = Ctx.of(context).doc, on = !RowOff.offOf(context), b = (doc.get(id) ?? 0) > 0;
        return Hov(
          onTap: on ? () => doc.set(id, b ? 0 : 1) : null,
          builder: (_, h) => Row(
            key: ValueKey('toggle:$id'),
            children: [
              PopSwitch(on: b),
              SizedBox(width: Shape.s(6)),
              Text(b ? 'On' : 'Off', style: T.label(h && on ? Grey.g95 : Grey.g76)),
            ],
          ),
        );
      case ParamLook.choice:
        final n = p.options.length;
        if (n == 0) return _num(context);
        final doc = Ctx.of(context).doc;
        return Dis(
          key: ValueKey('choice:$id'),
          child: Segmented(
            items: p.options,
            index: (doc.get(id) ?? 0).round().clamp(0, n - 1),
            onChanged: (i) => doc.set(id, i.toDouble()),
          ),
        );
      case ParamLook.color:
        final shown = Ctx.of(context).doc.s2[id] ?? '—';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.micro(Grey.g63)),
            Text(shown, key: ValueKey('words:$id'), maxLines: 2, overflow: TextOverflow.ellipsis, style: T.label(Grey.g76)),
          ],
        );
      case ParamLook.point || ParamLook.size:
        final point = p.look == ParamLook.point;
        return Row(
          children: [
            Expanded(child: _num(context, sub: 'x', caption: '${p.label} ${point ? 'X' : 'W'}')),
            SizedBox(width: Pop.tileGap),
            Expanded(child: _num(context, sub: 'y', caption: point ? 'Y' : 'H')),
          ],
        );
      default:
        return _num(context);
    }
  }
}
