// The free space of the disk a folder is on, as the Mac's df reports it, or Windows' cmd dir.
import 'dart:io';

/// The Available column of `df -k` for the disk holding [folder], in 1024-byte blocks. Throws when df fails.
/// On Windows: the last number of `dir`'s last line, the free bytes of its disk.
int freeKilobytesOn(String folder) {
  if (Platform.isWindows) {
    final last =
        (Process.runSync('cmd', [
                  '/c',
                  'dir',
                  '/-c',
                  folder.replaceAll('/', r'\'),
                ]).stdout
                as String)
            .trim()
            .split('\n')
            .last;
    return int.parse(RegExp(r'\d+').allMatches(last).last[0]!) ~/ 1024;
  }
  final cols = (Process.runSync('df', ['-k', folder]).stdout as String)
      .trim()
      .split('\n')
      .last
      .split(RegExp(r'\s+'));
  return int.parse(cols[3]);
}
