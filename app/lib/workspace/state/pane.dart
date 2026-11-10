// One tab of the window: its name, the glyph on its tab, its body and the strip it starts on.
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/glyphs.dart' show GlyphKind;

/// The strip a tab starts on; [catalog] is on no strip: it is opened inside the Tool Panel.
enum WsAt { shelves, stage, timeline, ease, inspector, tools, catalog }

/// One pane: its name (also its id), the glyph on its tab, and how to build its body.
///
/// An [iconOnly] tab shows the glyph alone. It suits panes whose body already shows the name in a header, and keeps a strip of many tabs narrow.
class WsPane {
  const WsPane(this.name, this.glyph, this.build, {this.at = WsAt.inspector, this.minSize = 160, this.iconOnly = false, this.tone, this.acts = ''});
  final String name;

  /// The glyph on the tab. If null, the tab shows the first letter of [name].
  final GlyphKind? glyph;
  final Widget Function() build;
  final double minSize;
  final bool iconOnly;
  final WsAt at;

  /// For a catalog row: the color of its sticker.
  final Color? tone;

  /// For a catalog row: what it works on.
  final String acts;
}
