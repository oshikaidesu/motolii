// Part of effect_tiles.dart: whether a tile shows its effect at all. Its pictures are compared with the sample's using
// ffmpeg's psnr and the mean difference that AbsentMotion's effect_thumbs.py takes.
part of 'effect_tiles.dart';

/// How far each try differs from the usual picture, as (try number, mean squared error from ffmpeg psnr), in one run.
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
    File('$folder/try_$i.png').deleteSync(); // The next effect may have fewer tries.
  }
  if (r == null) return const []; // ffmpeg is missing where the app was started from, so nothing is measured.
  return [
    for (final l in '${r.stdout}'.split('\n'))
      if (RegExp(r'n:(\d+) mse_avg:([\d.]+)').firstMatch(l) case final w?) (int.parse(w.group(1)!) - 1, double.parse(w.group(2)!)),
  ];
}

// _plain is the mean squared error at 40 dB, below which a change is not seen. _clear is the error at 24 dB, which is
// plainly visible with the picture still there, as measured on these tiles.
final _plain = 255 * 255 / 10000.0, _clear = 255 * 255 / 251.0;

/// Whether two pictures (or `_%d` runs of them) look the same: every frame differs by less than 2.0, the threshold
/// AbsentMotion's effect_thumbs.py uses. False when nothing could be measured because ffmpeg is missing.
bool _same(String a, String b) {
  final changes = _differ(a, b);
  return changes.isNotEmpty && changes.every((c) => c < 2.0);
}

/// Runs ffmpeg over a tile's pictures. Returns null when ffmpeg is missing, as where the app was started from;
/// the tile is then its still alone.
ProcessResult? ffmpeg(List<String> also, {Encoding? stdoutEncoding = systemEncoding}) {
  try {
    return Process.runSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', ...also], stdoutEncoding: stdoutEncoding);
  } on ProcessException {
    return null;
  }
}

/// How far pictures differ, frame by frame, measured as AbsentMotion's effect_thumbs.py change() does: each picture is
/// laid over grey and the mean difference per channel, out of 255, is taken. ffmpeg puts the two side by side and the
/// mean is taken here. Empty when ffmpeg is missing, so nothing is measured.
List<double> _differ(String a, String b) {
  try {
    final head = File(a.replaceFirst('%d', '0')).openSync()..setPositionSync(16); // The PNG header holds the width and height.
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
