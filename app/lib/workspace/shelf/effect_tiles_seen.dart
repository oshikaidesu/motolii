// Part of effect_tiles.dart: whether a tile shows its effect at all: its pictures set beside the sample's with ffmpeg
// (psnr, and the mean difference AbsentMotion's effect_thumbs.py change() takes).
part of 'effect_tiles.dart';

/// How far each try is from the usual picture: (its number, ffmpeg psnr's mean squared error), one run for them all.
List<(int, double)> _changes(String folder) {
  final r = ffmpeg([
    '-loop',
    '1',
    '-i',
    '$folder/usual.png',
    '-i',
    '$folder/try_%d.png',
    '-lavfi',
    '[0:v][1:v]psnr=shortest=1:stats_file=-',
    '-f',
    'null',
    '-',
  ]);
  for (var i = 0; File('$folder/try_$i.png').existsSync(); i++) {
    File('$folder/try_$i.png').deleteSync(); // (the next effect's may be fewer)
  }
  if (r == null) return const []; // (no ffmpeg where the window was opened from: not measured)
  return [
    for (final l in '${r.stdout}'.split('\n'))
      if (RegExp(r'n:(\d+) mse_avg:([\d.]+)').firstMatch(l) case final w?) (int.parse(w.group(1)!) - 1, double.parse(w.group(2)!)),
  ];
}

final _plain = 255 * 255 / 10000.0,
    _clear =
        255 *
        255 /
        251.0; // (mean squared error at 40 dB, where _same stops seeing a change; at 24 dB, plainly seen and the picture still there, measured on these tiles)

/// Whether two pictures (or `_%d` runs of them) are not seen to differ: AbsentMotion's effect_thumbs.py, its SAME of 2.0 over
/// the frame that differs most. Not measured (no ffmpeg): not said to be.
bool _same(String a, String b) {
  final changes = _differ(a, b);
  return changes.isNotEmpty && changes.every((c) => c < 2.0);
}

/// ffmpeg over a tile's pictures; null where it did not run (none where the window was opened from: its still alone).
ProcessResult? ffmpeg(List<String> also, {Encoding? stdoutEncoding = systemEncoding}) {
  try {
    return Process.runSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', ...also], stdoutEncoding: stdoutEncoding);
  } on ProcessException {
    return null;
  }
}

/// How far pictures differ, frame by frame, as AbsentMotion's effect_thumbs.py tells it (change(): each laid over
/// grey, each channel's difference out of 255, the mean): ffmpeg lays the two side by side, the mean is taken here.
/// Empty: no ffmpeg where the window was opened from, not measured.
List<double> _differ(String a, String b) {
  try {
    final head = File(a.replaceFirst('%d', '0')).openSync()..setPositionSync(16); // (the PNG's IHDR: its width, its height)
    final wh = head.readSync(8);
    head.closeSync();
    final w = wh[0] << 24 | wh[1] << 16 | wh[2] << 8 | wh[3], h = wh[4] << 24 | wh[5] << 16 | wh[6] << 8 | wh[7];
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
    ], stdoutEncoding: null);
    final d = r?.stdout as List<int>? ?? const <int>[], row = w * 4, frame = 2 * row * h;
    if (r == null || r.exitCode != 0 || frame == 0) return const [];
    double change(int f) {
      var sum = 0.0;
      for (var y = 0; y < h; y++) {
        for (var x = f + y * 2 * row, end = x + row; x < end; x += 4) {
          final pa = d[x + 3] / 255, pb = d[x + row + 3] / 255;
          for (var c = 0; c < 3; c++) {
            sum += (d[x + c] * pa + 128 * (1 - pa) - d[x + row + c] * pb - 128 * (1 - pb)).abs();
          }
        }
      }
      return sum / (w * h * 3);
    }

    return [for (var f = 0; f + frame <= d.length; f += frame) change(f)];
  } on FileSystemException {
    return const [];
  }
}
