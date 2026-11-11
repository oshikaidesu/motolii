// What is known of an effect before its tile is taken: what the table says of it (the showcase), what the engine reads from the file
// (its tags, the choices and audio inputs an ISF file names), and what the reviewer recorded (TileReview). It decides whether the effect
// runs by the clock, hears, is tried on the moving card first, and which parameter is turned. It reads files and the engine; it takes no picture.
import 'dart:io';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/workspace/shelf/effect_tiles_review.dart';
import 'package:motolii/workspace/shelf/effect_tiles_showcase.dart';

class TileProfile {
  TileProfile._({
    required this.show,
    required this.said,
    required this.plays,
    required this.lists,
    required this.ears,
    required this.hears,
    required this.weights,
    required this.time,
    required this.chosen,
    required this.timed,
    required this.runs,
    required this.first,
  });

  /// What the table says of the effect, if it has a line there.
  final TileShow? show;

  /// The tags the engine reads from the file, and whether the effect keeps its previous frame (ISF's PERSISTENT).
  final Set<String> said;
  final bool plays;

  /// ISF's "long" inputs (a choice, which the engine takes as a range), and its audio and audioFFT inputs.
  final List<String> lists;
  final List<String> ears;

  /// Whether the effect hears: an audio input, a sound tag, or the reviewer says it needs sound.
  final bool hears;

  /// How much turning each parameter alone shows the effect, and how much letting it run shows it.
  final Map<String, double> weights;
  final double time;

  /// What the reviewer chose after moving each parameter on the sample.
  final (String, double, double)? chosen;

  /// Its weights say letting it run shows it best, so no parameter is turned, as for AbsentMotion's Noise Displace.
  final bool timed;

  /// Whether the effect runs by the clock, and whether to try the moving card first.
  final bool runs, first;

  /// Reads the effect [f] of the folder [dir]; [shows] is AbsentMotion's table.
  factory TileProfile.of(
    Motolii m,
    String dir,
    String f,
    Map<String, dynamic> shows,
  ) {
    final show = f.endsWith('.wgsl') || f.endsWith('.am')
        ? showcase(f, File(f).readAsStringSync(), shows)
        : null;
    final said = m.tags(f),
        plays =
            said.contains(
              'feedback',
            ), // ISF's PERSISTENT: the engine reads it (isf_tags).
        isf = f.endsWith('.fs') ? File(f).readAsStringSync() : '';
    final lists = [
      for (final l in RegExp(
        r'\{[^{}]*"TYPE"\s*:\s*"long"[^{}]*\}',
      ).allMatches(isf))
        '_${RegExp(r'"NAME"\s*:\s*"([^"]+)"').firstMatch(l.group(0)!)?.group(1)}',
    ]; // ISF's "long" inputs: a choice, which the engine takes as a range.
    final ears = [
      for (final l in RegExp(
        r'\{[^{}]*"TYPE"\s*:\s*"audio(FFT)?"[^{}]*\}',
      ).allMatches(isf))
        ?RegExp(r'"NAME"\s*:\s*"([^"]+)"').firstMatch(l.group(0)!)?.group(1),
    ]; // ISF_Spec's audio and audioFFT inputs.
    final hears =
        ears.isNotEmpty ||
        said.contains('sound') ||
        TileReview.needs(dir, f) == 'sound';
    final weights = TileReview.weighed(dir, f), time = weights['_time'] ?? 0;
    final chosen = TileReview.best(
      dir,
      f,
    ); // What the reviewer chose, after moving each parameter on the sample.
    final timed =
        chosen?.$1 == '_time' ||
        (time > 0 &&
            weights.entries.every((w) => w.key == '_time' || w.value <= time)); // Its weights say letting it run shows it best, so no parameter is turned, as for AbsentMotion's Noise Displace.
    final runs = said.contains('time') || plays || timed;
    // Whether to try the moving card first. Effects of what came before, and cut-out effects (they need an edge with room around it), have something to see.
    // A glass over the whole photo would just turn it black. An effect that hears goes on the whole picture first, so its sound is drawn large.
    final first =
        ((show?.moves ?? false) ||
            plays ||
            TileReview.needs(dir, f) == 'shape') &&
        !hears;
    return TileProfile._(
      show: show,
      said: said,
      plays: plays,
      lists: lists,
      ears: ears,
      hears: hears,
      weights: weights,
      time: time,
      chosen: chosen,
      timed: timed,
      runs: runs,
      first: first,
    );
  }
}
