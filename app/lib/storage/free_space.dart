// The free space of the disk a folder is on, as the Mac's df reports it.
import 'dart:io';

/// The Available column of `df -k` for the disk holding [folder], in 1024-byte blocks. Throws when df fails.
int freeKilobytesOn(String folder) {
  final cols = (Process.runSync('df', ['-k', folder]).stdout as String)
      .trim()
      .split('\n')
      .last
      .split(RegExp(r'\s+'));
  return int.parse(cols[3]);
}
