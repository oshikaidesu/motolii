// The pictures a skin brings, read from its folder (SkinParts in skin/skin_parts.dart draws them).
import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';

/// Each `.svg` file in [dir] as a picture, by its name without the extension. [onSlice] hears the corner size
/// (`data-slice`) of a picture that gives one. A file that cannot be read is skipped.
Future<Map<String, PictureInfo>> readSkinPictures(
  String dir,
  void Function(String name, double slice) onSlice,
) async {
  final next = <String, PictureInfo>{};
  final folder = Directory(dir);
  if (dir.isNotEmpty && folder.existsSync()) {
    for (final f in folder.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.svg'),
    )) {
      try {
        final name = f.uri.pathSegments.last.replaceAll('.svg', '');
        next[name] = await vg.loadPicture(SvgFileLoader(f), null);
        if (RegExp(r'data-slice="([0-9.]+)"').firstMatch(f.readAsStringSync())
            case final m?) {
          onSlice(name, double.parse(m.group(1)!));
        }
      } catch (_) {
        // A picture that cannot be read is skipped, so the built-in drawing stays.
      }
    }
  }
  return next;
}
