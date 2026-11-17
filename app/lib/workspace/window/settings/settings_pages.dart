// The content of each settings page: 15 pages of tiles.
import 'package:flutter/widgets.dart';
import 'package:settings_ui/settings_ui.dart';

import 'package:motolii/skin/layer_colors.dart' show labelColor;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/window_settings.dart' show WindowFile;
import 'package:motolii/storage/open_in_host.dart' show pickFolder;
import 'package:motolii/workspace/commands/keymap.dart'
    show defaultKeys, keyLabel, activatorOf;
import 'package:motolii/workspace/state/window_zoom.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/workspace/window/home_card.dart' show homeCaps;
import 'package:motolii/workspace/window/home_sidebar.dart' show folderName;
import 'package:motolii/workspace/window/settings/settings_popover.dart'
    show SettingsPage;

/// Builds the sections for the given settings [page].
///
/// [onChanged] triggers a setState in the popover so that the UI reflects the new value.
List<AbstractSettingsSection> settingsSections({
  required SettingsPage page,
  required bool dark,
  required String folder,
  required VoidCallback? onFolder,
  required void Function(String?) onSkin,
  required VoidCallback onChanged,
}) {
  List<SettingsTile> pick(
    String key,
    String fallback,
    List<(String, String)> items,
  ) => [
    for (final (value, label) in items)
      SettingsTile(
        title: Text(label),
        trailing: (WindowFile.get(key) ?? fallback) == value
            ? Glyph(
                AppGlyphs.check,
                size: Shape.z(14),
                color: WindowTokens.accent,
              )
            : null,
        onPressed: (_) {
          WindowFile.set(key, value);
          onChanged();
        },
      ),
  ];

  return switch (page) {
    SettingsPage.appearance => [
      SettingsSection(
        title: Text('APPEARANCE'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Dark Mode'),
            initialValue: !Grey.light,
            activeSwitchColor: WindowTokens.accent,
            onToggle: (value) {
              Grey.shade.value = value ? Shade.dark : Shade.light;
              WidgetsBinding.instance.reassembleApplication();
            },
          ),
        ],
      ),
    ],
    SettingsPage.skin => [
      SettingsSection(
        title: Text('SKIN'),
        tiles: [
          SettingsTile(
            title: const Text('Default'),
            trailing: ColorTheme.skin == null
                ? Glyph(
                    AppGlyphs.check,
                    size: Shape.z(14),
                    color: WindowTokens.accent,
                  )
                : null,
            onPressed: (_) => onSkin(null),
          ),
          for (final s in ColorTheme.skinNames())
            SettingsTile(
              title: Text(s),
              trailing: ColorTheme.skin == s
                  ? Glyph(
                      AppGlyphs.check,
                      size: Shape.z(14),
                      color: WindowTokens.accent,
                    )
                  : null,
              onPressed: (_) => onSkin(s),
            ),
        ],
      ),
    ],
    SettingsPage.display => [
      SettingsSection(
        title: Text('DISPLAY'),
        tiles: [
          CustomSettingsTile(
            child: ValueListenableBuilder<double>(
              valueListenable: WindowZoom.value,
              builder: (context, zoom, _) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Shape.s(10),
                  vertical: Shape.s(10),
                ),
                child: Row(
                  children: [
                    Text(
                      'UI Zoom',
                      style: TextStyles.name(
                        dark ? Grey.g91 : Grey.g13,
                        13,
                        FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(zoom * 100).round()}%',
                      style: TextStyles.label(Grey.g56),
                    ),
                    SizedBox(width: Shape.s(10)),
                    Pressable(
                      key: const ValueKey('settings-zoom-down'),
                      onTap: () => WindowZoom.set(zoom - .01),
                      builder: (context, hot) => Text(
                        '−',
                        style: TextStyles.name(
                          hot ? Grey.g100 : Grey.g56,
                          14,
                          FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: Shape.s(6)),
                    Pressable(
                      key: const ValueKey('settings-zoom-up'),
                      onTap: () => WindowZoom.set(zoom + .01),
                      builder: (context, hot) => Text(
                        '+',
                        style: TextStyles.name(
                          hot ? Grey.g100 : Grey.g56,
                          14,
                          FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: Shape.s(8)),
                    Pressable(
                      key: const ValueKey('settings-zoom-reset'),
                      onTap: () => WindowZoom.set(WindowZoom.usual),
                      builder: (context, hot) => Text(
                        'RESET',
                        style: homeCaps(hot ? Grey.g100 : WindowTokens.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ],
    SettingsPage.autoSave => [
      SettingsSection(
        title: Text('AUTO SAVE'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Enable Auto Save'),
            initialValue: (WindowFile.get('AutoSave') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) {
              WindowFile.set('AutoSave', '$v');
              onChanged();
            },
          ),
        ],
      ),
      SettingsSection(
        title: Text('INTERVAL'),
        tiles: pick('AutoSaveInterval', '5', [
          ('1', '1 minute'),
          ('2', '2 minutes'),
          ('5', '5 minutes'),
          ('10', '10 minutes'),
          ('15', '15 minutes'),
          ('30', '30 minutes'),
        ]),
      ),
      SettingsSection(
        title: Text('MAX BACKUPS'),
        tiles: pick('AutoSaveBackups', '3', [
          ('1', '1'),
          ('3', '3'),
          ('5', '5'),
          ('10', '10'),
        ]),
      ),
    ],
    SettingsPage.playback => [
      SettingsSection(
        title: Text('PLAYBACK'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Loop Playback'),
            initialValue: (WindowFile.get('PlaybackLoop') ?? 'false') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) {
              WindowFile.set('PlaybackLoop', '$v');
              onChanged();
            },
          ),
          SettingsTile.switchTile(
            title: const Text('Audio During Scrub'),
            initialValue: (WindowFile.get('AudioScrub') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) {
              WindowFile.set('AudioScrub', '$v');
              onChanged();
            },
          ),
        ],
      ),
      SettingsSection(
        title: Text('PREVIEW QUALITY'),
        tiles: pick('PreviewQuality', 'full', [
          ('full', 'Full'),
          ('half', 'Half'),
          ('quarter', 'Quarter'),
        ]),
      ),
    ],
    SettingsPage.audio => [
      SettingsSection(
        title: Text('SAMPLE RATE'),
        tiles: pick('SampleRate', '44100', [
          ('44100', '44100 Hz'),
          ('48000', '48000 Hz'),
          ('96000', '96000 Hz'),
        ]),
      ),
      SettingsSection(
        title: Text('DEVICE'),
        tiles: [
          SettingsTile(
            title: const Text('Audio Device'),
            value: const Text('System default'),
            enabled: false,
          ),
        ],
      ),
    ],
    SettingsPage.performance => [
      SettingsSection(
        title: Text('PERFORMANCE'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('GPU Acceleration'),
            initialValue: (WindowFile.get('GpuAccel') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) {
              WindowFile.set('GpuAccel', '$v');
              onChanged();
            },
          ),
        ],
      ),
      SettingsSection(
        title: Text('CACHE SIZE LIMIT'),
        tiles: pick('CacheSize', '10', [
          ('2', '2 GB'),
          ('5', '5 GB'),
          ('10', '10 GB'),
          ('20', '20 GB'),
          ('50', '50 GB'),
        ]),
      ),
    ],
    SettingsPage.rendering => [
      SettingsSection(
        title: Text('DEFAULT FORMAT'),
        tiles: pick('ExportFormat', 'mp4', [
          ('mp4', '.mp4'),
          ('mov', '.mov'),
          ('gif', '.gif'),
          ('png', '.png sequence'),
        ]),
      ),
      SettingsSection(
        title: Text('OUTPUT'),
        tiles: [
          SettingsTile(
            title: const Text('Output Folder'),
            value: Text(
              folderName(WindowFile.get('ExportFolder') ?? '~/Movies'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: (_) async {
              final f = await pickFolder(prompt: 'Choose export folder');
              if (f != null) {
                WindowFile.set('ExportFolder', f);
                onChanged();
              }
            },
          ),
        ],
      ),
    ],
    SettingsPage.timeline => [
      SettingsSection(
        title: Text('TIMELINE'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Snap to Grid'),
            description: const Text('Hold ⌘ to snap freely'),
            initialValue: (WindowFile.get('SnapTimeline') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) {
              WindowFile.set('SnapTimeline', '$v');
              onChanged();
            },
          ),
          SettingsTile.switchTile(
            title: const Text('Follow Playhead'),
            initialValue:
                (WindowFile.get('FollowPlayhead') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) {
              WindowFile.set('FollowPlayhead', '$v');
              onChanged();
            },
          ),
        ],
      ),
    ],
    SettingsPage.keyboard => [
      SettingsSection(
        title: Text('KEYBOARD SHORTCUTS'),
        tiles: [
          for (final (key, cmd) in defaultKeys)
            SettingsTile(
              title: Text(cmd),
              trailing: Text(
                keyLabel(activatorOf(key)),
                style: TextStyles.label(Grey.g56),
              ),
            ),
        ],
      ),
      SettingsSection(
        title: Text('CUSTOMISE'),
        tiles: [
          SettingsTile(
            title: const Text('Keybindings File'),
            value: const Text('~/.motolii/keybindings.json'),
          ),
        ],
      ),
    ],
    SettingsPage.labels => [
      SettingsSection(
        title: Text('LABEL COLOURS'),
        tiles: [
          CustomSettingsTile(
            child: Padding(
              padding: EdgeInsets.all(Shape.s(10)),
              child: Wrap(
                spacing: Shape.s(8),
                runSpacing: Shape.s(8),
                children: [
                  for (var k = 0; k < 16; k++)
                    Container(
                      width: Shape.z(28),
                      height: Shape.z(28),
                      decoration: BoxDecoration(
                        color: labelColor(k),
                        borderRadius: Shape.round(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${k + 1}',
                        style: TextStyles.micro(Grey.g00),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SettingsTile(
            title: const Text('Override'),
            value: const Text('Skins can set Label1–Label16'),
            enabled: false,
          ),
        ],
      ),
    ],
    SettingsPage.canvas => [
      SettingsSection(
        title: Text('CANVAS'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Show Grid'),
            initialValue: (WindowFile.get('ShowGrid') ?? 'false') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) {
              WindowFile.set('ShowGrid', '$v');
              onChanged();
            },
          ),
          SettingsTile.switchTile(
            title: const Text('Show Safe Area'),
            initialValue: (WindowFile.get('ShowSafe') ?? 'false') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) {
              WindowFile.set('ShowSafe', '$v');
              onChanged();
            },
          ),
          SettingsTile.switchTile(
            title: const Text('Snap to Objects'),
            initialValue: (WindowFile.get('SnapStage') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) {
              WindowFile.set('SnapStage', '$v');
              onChanged();
            },
          ),
        ],
      ),
    ],
    SettingsPage.scripting => [
      SettingsSection(
        title: Text('EXPRESSION ENGINES'),
        tiles: [
          SettingsTile(
            title: const Text('QuickJS'),
            value: const Text('JavaScript expressions'),
            enabled: false,
          ),
          SettingsTile(
            title: const Text('Lua'),
            value: const Text('Lua scripting'),
            enabled: false,
          ),
          SettingsTile(
            title: const Text('Lottie Expressions'),
            value: const Text('After Effects expression subset'),
            enabled: false,
          ),
        ],
      ),
    ],
    SettingsPage.projectDefaults => [
      SettingsSection(
        title: Text('FRAME SIZE'),
        tiles: [
          for (final (w, h, label) in [
            ('1920', '1080', '1920 × 1080 (Full HD)'),
            ('3840', '2160', '3840 × 2160 (4K)'),
            ('1280', '720', '1280 × 720 (HD)'),
            ('1080', '1080', '1080 × 1080 (Square)'),
            ('1080', '1920', '1080 × 1920 (Vertical)'),
          ])
            SettingsTile(
              title: Text(label),
              trailing:
                  (WindowFile.get('DefaultWidth') ?? '1920') == w &&
                      (WindowFile.get('DefaultHeight') ?? '1080') == h
                  ? Glyph(
                      AppGlyphs.check,
                      size: Shape.z(14),
                      color: WindowTokens.accent,
                    )
                  : null,
              onPressed: (_) {
                WindowFile.set('DefaultWidth', w);
                WindowFile.set('DefaultHeight', h);
                onChanged();
              },
            ),
        ],
      ),
      SettingsSection(
        title: Text('FRAME RATE'),
        tiles: pick('DefaultFrameRate', '30', [
          ('24', '24 fps (Film)'),
          ('25', '25 fps (PAL)'),
          ('30', '30 fps'),
          ('50', '50 fps'),
          ('60', '60 fps'),
        ]),
      ),
      SettingsSection(
        title: Text('DURATION'),
        tiles: pick('DefaultDuration', '240', [
          ('60', '60 frames (2 s)'),
          ('120', '120 frames (4 s)'),
          ('240', '240 frames (8 s)'),
          ('300', '300 frames (10 s)'),
          ('600', '600 frames (20 s)'),
          ('900', '900 frames (30 s)'),
        ]),
      ),
    ],
    SettingsPage.storage => [
      SettingsSection(
        title: Text('STORAGE'),
        tiles: [
          SettingsTile(
            leading: Glyph(
              AppGlyphs.folder,
              size: Shape.z(16),
              color: Grey.g56,
            ),
            title: const Text('Projects Folder'),
            value: Text(
              folderName(folder),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: onFolder != null ? (_) => onFolder() : null,
          ),
        ],
      ),
    ],
  };
}
