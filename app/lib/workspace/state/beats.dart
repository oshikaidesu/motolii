// The document's beats. When the document has a tempo, the timeline grid follows them.
// Modelled on Ableton Live's Tempo field and editing grid (Live manual, section 6.10): four beats to a bar.
import 'package:motolii/skin/tokens.dart' show halfWidth;

/// Parses a typed number, ignoring full-width characters and surrounding spaces. Returns null if it is not a number.
double? wsNumber(String said) => double.tryParse(halfWidth(said).trim());

/// The beat grid of a document, in frames.
class WsBeats {
  const WsBeats(this.first, this.every);

  /// The frame where a bar begins, and the number of frames from one beat to the next.
  final double first, every;

  /// The beats from frame [a] to frame [b], each paired with whether a bar begins there.
  Iterable<(double, bool)> between(double a, double b) sync* {
    for (var n = ((a - first) / every).ceil(); first + n * every <= b; n++) {
      yield (first + n * every, n % 4 == 0);
    }
  }

  /// The frame of the beat nearest to [frame].
  int nearest(int frame) => (first + ((frame - first) / every).round() * every).round();
}
