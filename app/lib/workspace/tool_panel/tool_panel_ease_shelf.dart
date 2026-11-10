// The shelf of saved easings that slides out from the right of the Ease panel and slides back.
// It opens as a column of its own and pushes the rest left, so the flow stays in view and its cards can be dragged onto the shelf.
// It slides like the colour boxes (dock_make_2.dart) and uses as many columns as the pane has room for, like Easey's presetsPage.js.
// Dragging a card over the grip opens the shelf, like a Finder folder opening under a dragged item (macOS spring-loaded folders).
import 'package:motolii/skin/window_tokens.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_cards.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_easing_presets.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_side.dart' show drawEaseChevron;
import 'package:motolii/widgets/media.dart' show Draw;

import 'package:motolii/widgets/controls.dart' show Hov;
import 'package:motolii/storage/kept_file.dart' show fileKeep, fileList;

/// The easings the user saved: a curve, a card or all the cards, each stored as its name string.
/// Saving works like saving a device preset in Ableton Live (manual, 23.2.5 Saving Presets).
/// The list lives in ~/.motolii/ease_kept.json, next to colors.json.
File _keptFile = File('${Platform.environment['HOME']}/.motolii/ease_kept.json');
List<String>? _kept;

/// Points the list at another file and forgets what was read. Tests use this, as they do with coloursAt.
void easeKeptAt(File f) => (_keptFile = f, _kept = null);

List<String> easeKept() => _kept ??= [for (final w in fileList(_keptFile)) '$w'];

/// Saves [word], or removes it when [off] is set.
void easeKeep(String word, {bool off = false}) {
  final kept = easeKept()..remove(word);
  if (!off) kept.add(word);
  // The list is also held in memory, so it is known while the app is open even if writing the file fails.
  fileKeep(_keptFile, jsonEncode(kept));
}

// Each saved easing is parsed once, so fifty of them are not parsed again whenever a handle moves.
final _tiles = <String, Ease>{};

double get easeGripWide => Shape.z(8);

/// The tab at the right edge that draws the shelf out, and at its side puts it away.
class EaseGrip extends StatelessWidget {
  const EaseGrip({super.key, required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Hov(
    onTap: onTap,
    builder: (_, h) => Container(
      width: easeGripWide,
      height: Shape.z(34),
      decoration: BoxDecoration(
        color: h ? Grey.g56 : Grey.g38,
        borderRadius: BorderRadius.horizontal(left: Shape.r(4)),
      ),
      child: CustomPaint(painter: Draw((cv, s) => drawEaseChevron(cv, s, h ? Grey.g95 : Grey.g76, !open), (h, open))),
    ),
  );
}

/// The shelf of easings.
///
/// The saved easings come first, followed by an empty slot for the next one. Below a divider are the easings from the
/// project and from the shelves/ease folder, so a file put there appears as one more tile.
/// Clicking a tile replaces the whole easing on the keyframe interval, so the user can try one after another.
/// Dropping a card on the shelf saves it, and so does clicking the empty slot, which saves the current easing
/// as an empty swatch in Photoshop's Swatches panel takes the current colour.
/// A saved tile is removed with its x button.
class EaseShelf extends StatelessWidget {
  const EaseShelf({
    super.key,
    required this.now,
    required this.ways,
    required this.columns,
    required this.pitch,
    required this.side,
    required this.onPick,
    required this.onKeep,
    required this.onForget,
    required this.inside,
  });

  /// The easing on the keyframe interval, as its name string.
  final String now;

  /// The easings from the project and the shelves/ease folder.
  final List<Ease> ways;

  final int columns;
  final double pitch, side;
  final Motolii? inside;
  final ValueChanged<Ease> onPick, onForget;

  /// Called with the index of a dropped card, or a negative number to save all the cards.
  final ValueChanged<int> onKeep;

  @override
  Widget build(BuildContext context) {
    final kept = easeKept();
    final across = SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: pitch);
    Widget tile(Ease e, Key key) => EasingPresetTile(e, key: key, on: said(e) == now, side: side, onTap: () => said(e) == now ? null : onPick(e));
    return DragTarget<int>(
      onAcceptWithDetails: (d) => onKeep(d.data),
      builder: (_, hot, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: WsT.card,
          border: hot.isEmpty ? Border(left: BorderSide(color: Grey.g38)) : Border.all(color: WsT.accent, width: 2),
        ),
        child: CustomScrollView(
          slivers: [
            SliverGrid.builder(
              gridDelegate: across,
              itemCount: kept.length + 1,
              itemBuilder: (_, i) => i == kept.length
                  ? Hov(
                      key: const ValueKey('ease.shelf.slot'),
                      onTap: () => onKeep(-1),
                      builder: (_, h) => Center(
                        child: EaseSlot(side: side, ink: h ? Grey.g76 : Grey.g38),
                      ),
                    )
                  : Hov(
                      cursor: MouseCursor.defer,
                      builder: (_, h) {
                        final e = _tiles[kept[i]] ??= easeCard(kept[i], inside);
                        return Stack(
                          children: [
                            Positioned.fill(child: tile(e, ValueKey('ease.kept.${kept[i]}'))),
                            if (h)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: EaseOff(key: ValueKey('ease.forget.${kept[i]}'), onTap: () => onForget(e)),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 1,
                margin: EdgeInsets.symmetric(vertical: Shape.s(3), horizontal: Shape.s(4)),
                color: Grey.g38,
              ),
            ),
            SliverGrid.builder(gridDelegate: across, itemCount: ways.length, itemBuilder: (_, i) => tile(ways[i], ValueKey('ease.${ways[i].name}'))),
          ],
        ),
      ),
    );
  }
}
