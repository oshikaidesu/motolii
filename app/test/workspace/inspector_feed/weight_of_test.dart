// An effect's values reach the Inspector named with the ID of its one use; their weights must still be found.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/bridge/engine_paths.dart' show motoliiShelves;
import 'package:motolii/workspace/inspector_feed/cards.dart' show weightOf;
import 'package:motolii/workspace/shelf/effect_tiles_review.dart';

void main() {
  final weights = TileReview.weighed(
    motoliiShelves,
    '$motoliiShelves/effects/glitch/Bad TV.fs',
  );

  test('a value named with the use ID finds its weight', () {
    // app/assets/effect_parameter_weights.json gives Bad TV's distortion1 an 8.
    expect(weightOf(weights, 'a1b2c3:js_Bad_TV_distortion1'), 8);
  });

  test('a value named without one still finds it', () {
    expect(weightOf(weights, 'js_Bad_TV_distortion1'), 8);
  });

  test('a value that was not weighed has none', () {
    expect(weightOf(weights, 'a1b2c3:js_Bad_TV_nothing'), isNull);
  });
}
