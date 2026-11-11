// A project as the home screen lists it, and what is said or done about one: the facts and sizes as text, the day it is filed under,
// copying it, and moving it to the Trash. None of it draws.
import 'dart:io';
import 'dart:math' as math;

import 'package:motolii/storage/unique_name.dart' show firstFree;

/// One project listed: its file, and the facts saved in it. [facts] and [picture] are null until read, or if the project saved none.
class HomeProject {
  HomeProject(this.path, this.changed, this.bytes);
  final String path;
  final DateTime changed;
  final int bytes;
  ({int wide, int high, double seconds, double rate})? facts;
  String? picture;
  String get name =>
      path.split('/').last.replaceFirst(RegExp(r'\.motolii$'), '');
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
// AbsentMotion's dateHeader in English: d MMMM yyyy.
String homeDay(DateTime t) => '${t.day} ${_months[t.month - 1]} ${t.year}';

/// The aspect ratio and resolution, then the frame rate, as AbsentMotion shows them.
/// A known ratio gives "9:16" and the shorter side as "1080p"; any other gives "1080x1350".
List<String> homeFacts(HomeProject d) {
  final f = d.facts;
  if (f == null) return const [];
  String? ratio;
  for (final (a, b) in const [(16, 9), (9, 16), (4, 5), (1, 1), (4, 3)]) {
    if ((f.wide * b - f.high * a).abs() <= math.max(a, b)) {
      ratio = '$a:$b';
      break;
    }
  }
  return [
    if (ratio != null) ...[
      ratio,
      '${math.min(f.wide, f.high)}p',
    ] else
      '${f.wide}x${f.high}',
    '${f.rate == f.rate.roundToDouble() ? f.rate.round() : f.rate}fps',
  ]; // The frame rate is the project's own frame_rate.
}

String homeBytes(int bytes) {
  // Follows ExportOptions.kt formatBytes.
  String f(double v, String unit) =>
      (v >= 10
          ? v.toStringAsFixed(0)
          : v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')) +
      unit;
  if (bytes < 1024) return '${math.max(bytes, 0)}B';
  if (bytes < 1024 * 1024 - 512) return f(bytes / 1024, 'KB');
  if (bytes < 1024 * 1024 * 1024 - 512 * 1024) {
    return f(bytes / (1024 * 1024), 'MB');
  }
  return f(bytes / (1024 * 1024 * 1024), 'GB');
}

String homeLength(double seconds) {
  // CapCut's "02:13"; an hour or more gives AbsentMotion's "01:02:13".
  final s = seconds.round();
  String two(int n) => n.toString().padLeft(2, '0');
  return s >= 3600
      ? '${two(s ~/ 3600)}:${two(s ~/ 60 % 60)}:${two(s % 60)}'
      : '${two(s ~/ 60)}:${two(s % 60)}';
}

/// Copies the project next to it, named "Name Copy" (AbsentMotion's naming), with a number added if that name is taken.
void duplicateProject(String folder, HomeProject d) {
  final to = firstFree(
    '$folder/${d.name} Copy.motolii',
    (f) => File(f).existsSync(),
    (n) => '$folder/${d.name} Copy $n.motolii',
  );
  File(d.path).copySync(to);
}

/// Moves the project to the user's ~/.Trash, as the Finder does, adding a number if the name is taken there. False if it could not be moved.
bool trashProject(HomeProject d) {
  final trash = '${Platform.environment['HOME']}/.Trash';
  final to = firstFree(
    '$trash/${d.name}.motolii',
    (f) => File(f).existsSync(),
    (n) => '$trash/${d.name} $n.motolii',
  );
  try {
    File(d.path).renameSync(to);
  } catch (_) {
    return false;
  }
  return true;
}
