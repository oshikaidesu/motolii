// Part of dock_widgets.dart: the star button, and the file that stores which effects are starred.
part of 'dock_widgets.dart';

/// The star button that adds an item to Starred. It is shown on hover, on the selected row, or when set.
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

/// Where the starred effects are stored, in the same way the Ease tool panel stores its stars (ease_stars.json).
/// A test can point it elsewhere with [dockStarsAt].
File _starsFile = File('${Platform.environment['HOME']}/.motolii/effect_stars.json');
void dockStarsAt(File f) => _starsFile = f;
Set<String> _starsRead() => {for (final s in fileList(_starsFile)) '$s'};

void _starsKeep(Set<String> all) => fileKeep(_starsFile, jsonEncode(all.toList()));
