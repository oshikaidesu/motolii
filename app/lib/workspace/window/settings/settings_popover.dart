// The settings popover: a sidebar of pages and the content of the chosen one.
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoTheme, CupertinoThemeData;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:settings_ui/settings_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/workspace/window/home_card.dart' show homeCaps;
import 'package:motolii/workspace/window/settings/settings_pages.dart';

enum SettingsPage {
  appearance,
  skin,
  display,
  autoSave,
  playback,
  audio,
  performance,
  rendering,
  timeline,
  keyboard,
  labels,
  canvas,
  scripting,
  projectDefaults,
  storage;

  String get label => switch (this) {
    appearance => 'Appearance',
    skin => 'Skin',
    display => 'Display',
    autoSave => 'Auto Save',
    playback => 'Playback',
    audio => 'Audio',
    performance => 'Performance',
    rendering => 'Export',
    timeline => 'Timeline',
    keyboard => 'Keyboard',
    labels => 'Labels',
    canvas => 'Canvas',
    scripting => 'Scripting',
    projectDefaults => 'Project Defaults',
    storage => 'Storage',
  };
}

class HomeSettingsPopover extends StatefulWidget {
  const HomeSettingsPopover({
    super.key,
    required this.folder,
    required this.onFolder,
    required this.onSkin,
  });
  final String folder;
  final VoidCallback? onFolder;
  final void Function(String?) onSkin;

  @override
  State<HomeSettingsPopover> createState() => _HomeSettingsPopoverState();
}

class _HomeSettingsPopoverState extends State<HomeSettingsPopover> {
  SettingsPage _page = SettingsPage.appearance;

  @override
  Widget build(BuildContext context) {
    final dark = !Grey.light;

    final theme = SettingsThemeData(
      settingsListBackground: Grey.g00.withValues(alpha: 0),
      settingsSectionBackground: dark ? Grey.g20 : Grey.g95,
      titleTextColor: Grey.g56,
      settingsTileTextColor: dark ? Grey.g91 : Grey.g13,
      tileDescriptionTextColor: Grey.g56,
      dividerColor: dark ? Grey.g26 : Grey.g91,
      leadingIconsColor: Grey.g56,
      trailingTextColor: Grey.g56,
      tileHighlightColor: dark ? Grey.g26 : Grey.g91,
      titleTextStyle: homeCaps(Grey.g56),
    );

    return Container(
      width: Shape.z(620),
      height: Shape.z(480),
      decoration: BoxDecoration(
        color: dark ? Grey.g13 : Grey.g100,
        borderRadius: Shape.round(14),
        border: Border.all(color: Grey.g26, width: 1),
        boxShadow: [
          BoxShadow(
            color: Grey.g00.withValues(alpha: .4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: Shape.round(14),
        child: mui.Theme(
          data: dark ? mui.ThemeData.dark() : mui.ThemeData.light(),
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: Shape.z(160),
                  decoration: BoxDecoration(
                    color: dark ? Grey.g10 : Grey.g95,
                    border: Border(
                      right: BorderSide(color: dark ? Grey.g26 : Grey.g91),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          Shape.s(14),
                          Shape.s(16),
                          Shape.s(14),
                          Shape.s(8),
                        ),
                        child: Text('SETTINGS', style: homeCaps(Grey.g44, 9)),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
                          children: [
                            for (final p in SettingsPage.values)
                              _navItem(p, dark),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(Shape.s(12)),
                        child: Text(
                          'Motolii v0.1.0',
                          style: TextStyles.micro(Grey.g44),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SettingsList(
                    platform: DevicePlatform.macOS,
                    brightness: dark ? Brightness.dark : Brightness.light,
                    applicationType: ApplicationType.material,
                    contentPadding: EdgeInsets.all(Shape.s(10)),
                    darkTheme: theme,
                    lightTheme: theme,
                    sections: settingsSections(
                      page: _page,
                      dark: dark,
                      folder: widget.folder,
                      onFolder: widget.onFolder,
                      onSkin: widget.onSkin,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(SettingsPage p, bool dark) {
    final on = _page == p;
    return Pressable(
      key: ValueKey('settings-nav-${p.name}'),
      onTap: () => setState(() => _page = p),
      builder: (context, hot) => AnimatedContainer(
        duration: Motion.dur,
        curve: Motion.ease,
        margin: EdgeInsets.only(bottom: Shape.s(2)),
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(10),
          vertical: Shape.s(8),
        ),
        decoration: BoxDecoration(
          color: on
              ? WindowTokens.accent
              : hot
              ? (dark ? Grey.g20 : Grey.g91)
              : Grey.g00.withValues(alpha: 0),
          borderRadius: Shape.round(8),
        ),
        child: Text(
          p.label,
          style: TextStyles.name(
            on
                ? WindowTokens.onAccent
                : hot
                ? (dark ? Grey.g91 : Grey.g13)
                : (dark ? Grey.g76 : Grey.g26),
            12,
            on ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
