// The sidebar of the home screen: a wordmark, a search, a list of recent projects, and a folder badge at the bottom.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/disk.dart' show imageFile;
import 'package:motolii/storage/host_platform.dart' show homeFolder;
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show IconPress, Pressable;
import 'package:motolii/workspace/dock/common/shelf_search_field.dart';
import 'package:motolii/workspace/window/home_card.dart' show homeCaps;
import 'package:motolii/workspace/window/home_project.dart';

class HomeSidebar extends StatelessWidget {
  const HomeSidebar({
    super.key,
    required this.docs,
    required this.folder,
    required this.selected,
    required this.find,
    required this.onChoose,
    required this.onClose,
    required this.settings,
    required this.onSettings,
  });
  final List<HomeProject> docs;
  final String folder;
  final String? selected;
  final TextEditingController find;
  final void Function(String path) onChoose;
  final VoidCallback onClose;
  final bool settings;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final recent = [...docs]..sort((a, b) => b.changed.compareTo(a.changed));
    final bytes = docs.fold(0, (sum, d) => sum + d.bytes);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Shape.s(14),
        Shape.s(16),
        Shape.s(10),
        Shape.s(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(width: Shape.s(8)),
              Container(
                width: Shape.z(22),
                height: Shape.z(22),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WindowTokens.accent,
                  borderRadius: Shape.round(7),
                ),
                child: Text(
                  'M',
                  style: TextStyles.name(
                    WindowTokens.onAccent,
                    13,
                    FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: Shape.s(8)),
              Text(
                'Motolii',
                style: TextStyles.name(
                  Grey.g95,
                  16,
                  FontWeight.w800,
                ).copyWith(letterSpacing: -.5),
              ),
              const Spacer(),
              IconPress(
                (c) => Glyph(AppGlyphs.tools, size: Shape.z(13), color: c),
                key: const ValueKey('home-settings'),
                tip: 'Settings',
                onTap: onSettings,
                size: Shape.z(24),
                ink: settings ? WindowTokens.accent : Grey.g56,
              ),
              SizedBox(width: Shape.s(4)),
              IconPress(
                (c) => Glyph(AppGlyphs.close, size: Shape.z(12), color: c),
                key: const ValueKey('home-close'),
                tip: 'Close',
                onTap: onClose,
                size: Shape.z(24),
                ink: Grey.g56,
              ),
            ],
          ),
          SizedBox(height: Shape.s(24)),
          SizedBox(
            height: Shape.z(28),
            child: ShelfSearchField(controller: find, hint: 'Search'),
          ),
          SizedBox(height: Shape.s(28)),
          Padding(
            padding: EdgeInsets.only(left: Shape.s(8)),
            child: Text('RECENT', style: homeCaps(Grey.g56)),
          ),
          SizedBox(height: Shape.s(8)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final d in recent.take(6))
                  HomeSidebarItem(
                    d: d,
                    selected: d.path == selected,
                    onTap: () => onChoose(d.path),
                  ),
              ],
            ),
          ),
          // On a solid block, so it reads over the collage.
          Container(
            padding: EdgeInsets.all(Shape.s(10)),
            decoration: BoxDecoration(
              color: Grey.g07,
              borderRadius: Shape.round(12),
            ),
            child: Row(
              children: [
                Glyph(AppGlyphs.folder, size: Shape.z(14), color: Grey.g76),
                SizedBox(width: Shape.s(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folderName(folder),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.label(Grey.g91),
                      ),
                      SizedBox(height: Shape.s(4)),
                      Text(
                        '${docs.length} projects · ${homeBytes(bytes)}',
                        style: TextStyles.micro(Grey.g63),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A recent project in the sidebar. The chosen one is drawn inverted: dark words on a light block.
class HomeSidebarItem extends StatelessWidget {
  const HomeSidebarItem({
    super.key,
    required this.d,
    required this.selected,
    required this.onTap,
  });
  final HomeProject d;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (context, hot) => AnimatedContainer(
      duration: Motion.dur,
      padding: EdgeInsets.all(Shape.s(8)),
      decoration: BoxDecoration(
        color: selected
            ? Grey.g20
            : hot
            ? Grey.g13
            : Grey.g00,
        borderRadius: Shape.round(10),
      ),
      child: Row(
        children: [
          Container(
            width: Shape.z(44),
            height: Shape.z(28),
            decoration: BoxDecoration(
              color: Grey.g13,
              borderRadius: Shape.round(5),
            ),
            clipBehavior: Clip.antiAlias,
            child: d.picture != null
                ? Image(image: imageFile(d.picture!), fit: BoxFit.cover)
                : null,
          ),
          SizedBox(width: Shape.s(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.name(
                    selected
                        ? Grey.g100
                        : hot
                        ? Grey.g95
                        : Grey.g76,
                    11,
                    selected ? FontWeight.w700 : null,
                  ),
                ),
                SizedBox(height: Shape.s(4)),
                Text(
                  homeAge(d.changed),
                  style: TextStyles.micro(selected ? Grey.g63 : Grey.g56),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shortens a folder path by replacing the home directory with ~.
String folderName(String folder) {
  final home = homeFolder;
  return home != null && folder.startsWith(home)
      ? '~${folder.substring(home.length)}'
      : folder;
}
