// Part of dock_parts.dart: the stars: the star that keeps an item in Starred, and where the starred are kept.
part of 'dock_parts.dart';

/// The star that keeps an item in Starred; shown on hover, on the picked row, or when set.
class DockStar extends StatelessWidget {
  const DockStar({super.key, required this.on, required this.onTap, this.ink});
  final bool on;
  final VoidCallback onTap;
  final Color? ink;
  @override
  Widget build(BuildContext context) => DockHover(
    onTap: onTap,
    builder: (context, h) {
      final col = ink ?? (on ? Pop.keyDot : (h ? Grey.g91 : Grey.g56));
      return SizedBox(
        width: Shape.z(20),
        height: Shape.z(20),
        child: Center(child: glyph(11, (cv, s) => drawStar(cv, s, col, on), [col, on])),
      );
    },
  );
}

/// Where the starred effects are kept (a test points it elsewhere: [dockStarsAt]), in the Ease desk's way (ease_stars.json).
File _starsFile = File('${Platform.environment['HOME']}/.motolii/effect_stars.json');
void dockStarsAt(File f) => _starsFile = f;
Set<String> _starsRead() {
  try {
    return {for (final s in jsonDecode(_starsFile.readAsStringSync()) as List) '$s'};
  } catch (_) {
    return {};
  }
}

void _starsKeep(Set<String> all) {
  try {
    _starsFile.parent.createSync(recursive: true);
    _starsFile.writeAsStringSync(jsonEncode(all.toList()));
  } catch (_) {}
}
