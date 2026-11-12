// How each shelf's tiles look: the forms a tile can take and the look of every shelf (shelfLooks).
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/skin/tokens.dart';

export '../../bridge/motolii.dart' show ShelfItem;

/// The three forms a tile can take.
///
/// - [under]: the name in a bar under the image (Effects, Code, Media).
/// - [over]: the name laid over the image (Create).
/// - [words]: the art is text set in a typeface (Fonts).
enum ShelfForm { under, over, words }

/// How one shelf's tiles look: an entry of [shelfLooks].
///
/// Sizes are in logical pixels and scale with the skin's size (Shape.z) where drawn; [cell] scales only when [sized].
class ShelfLook {
  const ShelfLook(
    this.form, {
    required this.cell,
    this.sized = false,
    this.min = 1,
    this.aspect = 1,
    this.height,
    this.row = 34,
    this.rowArt = const Size(40, 28),
    this.rowGap = 8,
    this.top = 0,
    this.eased = true,
  });

  /// How the tile is laid out.
  final ShelfForm form;

  /// The minimum width of a cell. At least [min] cells fit across (gridColumns).
  final double cell;

  /// Whether [cell] scales with the skin's size.
  final bool sized;

  /// The least number of cells across.
  final int min;

  /// The image's width over its height for [ShelfForm.under]. Ignored where [height] fixes the whole tile's height.
  final double aspect;

  /// The fixed height of the whole tile, or null to derive it from [aspect].
  final double? height;

  /// In list form, the row's height.
  final double row;

  /// In list form, the image's size.
  final Size rowArt;

  /// In list form, the gap between the image and the name.
  final double rowGap;

  /// The space above the first tiles.
  final double top;

  /// Whether the fill animates to its next colour over [Motion.dur] instead of changing at once.
  final bool eased;
}

const _square = ShelfLook(
  ShelfForm.under,
  cell: 84,
  sized: true,
  row: 22,
  rowArt: Size(18, 18),
  rowGap: 6,
  eased: false,
);

/// The look of every shelf, keyed by the shelf's name (ShelfContext.shelf).
const shelfLooks = <String, ShelfLook>{
  'Effects': _square,
  'Code': _square,
  'Media': ShelfLook(
    ShelfForm.under,
    cell: 76,
    min: 2,
    aspect: 16 / 9,
    top: WindowTokens.gutter,
  ),
  'Create': ShelfLook(ShelfForm.over, cell: 74, min: 2, height: 70),
  'Fonts': ShelfLook(ShelfForm.words, cell: 200, height: 96, row: 46),
};
