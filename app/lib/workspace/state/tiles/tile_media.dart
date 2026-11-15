// Runs ffmpeg for the effect tiles, and measures how far an effect changed its picture, as AbsentMotion's effect_thumbs.py
// does, so that a tile which shows nothing is told so.
import 'package:motolii/bridge/engine_paths.dart' show findProgram, motoliiDir;
import 'package:motolii/storage/shelf_disk.dart';

/// Whether two pictures (or `_%d` runs of them) look the same: every frame differs by less than 2.0, the threshold
/// AbsentMotion's effect_thumbs.py uses. False when nothing could be measured because ffmpeg is missing.
bool looksSame(String a, String b) {
  final changes = _differ(a, b);
  return changes.isNotEmpty && changes.every((c) => c < 2.0);
}

/// Runs ffmpeg over a tile's pictures: the LGPL-only one the build made (deps/ffmpeg.sh) if it is there. Returns null when
/// ffmpeg is missing;
/// the tile is then its still alone. With [raw] its output is the bytes, not text.
ToolRun? ffmpeg(List<String> also, {bool raw = false}) => runToolIfThere(
  findProgram(
    'ffmpeg',
    '$motoliiDir/third_party/ffmpeg_lgpl/bin:${envVar('PATH') ?? ''}',
  ),
  ['-hide_banner', '-loglevel', 'error', '-y', ...also],
  raw: raw,
);

/// How far pictures differ, frame by frame, measured as AbsentMotion's effect_thumbs.py change() does: each picture is
/// laid over grey and the mean difference per channel, out of 255, is taken. ffmpeg puts the two side by side and the
/// mean is taken here. Empty when ffmpeg is missing, so nothing is measured.
List<double> _differ(String a, String b) {
  // The PNG header holds the width and height.
  final wh = readBytesAt(a.replaceFirst('%d', '0'), 16, 8);
  if (wh == null) return const [];
  final w = wh[0] << 24 | wh[1] << 16 | wh[2] << 8 | wh[3],
      h = wh[4] << 24 | wh[5] << 16 | wh[6] << 8 | wh[7];
  final r = ffmpeg([
    '-i',
    a,
    '-i',
    b,
    '-lavfi',
    '[0:v]format=rgba[a];[1:v]format=rgba[b];[a][b]hstack=shortest=1',
    '-f',
    'rawvideo',
    '-pix_fmt',
    'rgba',
    '-',
  ], raw: true);
  final d = r?.bytes ?? const <int>[], row = w * 4, frame = 2 * row * h;
  if (r == null || r.exitCode != 0 || frame == 0) return const [];
  double change(int f) {
    var sum = 0.0;
    for (var y = 0; y < h; y++) {
      for (var x = f + y * 2 * row, end = x + row; x < end; x += 4) {
        final pa = d[x + 3] / 255, pb = d[x + row + 3] / 255;
        for (var c = 0; c < 3; c++) {
          sum +=
              (d[x + c] * pa +
                      128 * (1 - pa) -
                      d[x + row + c] * pb -
                      128 * (1 - pb))
                  .abs();
        }
      }
    }
    return sum / (w * h * 3);
  }

  return [for (var f = 0; f + frame <= d.length; f += frame) change(f)];
}
