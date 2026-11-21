# Creating Skins

[日本語](README.ja.md)

A **skin** customizes Motolii's visual appearance (colors, typography, corner radii, spacing, SVG icons, and control frames) without changing any engine behavior.

Each skin is a folder placed under `skins/` in your user folder:
- **macOS:** `~/Library/Application Support/Motolii/skins/`
- **Windows:** `%APPDATA%\Motolii\skins\`
- **Override:** `$MOTOLII_OWN/skins/` (legacy `~/.motolii/skins/` is also still loaded)

User skins override bundled skins of the same name.

## Bundled examples

These skins ship with Motolii and appear under **View › Skin**:

| Skin | Style |
|---|---|
| `labs` | Black text on white, pill shapes, subtle icons. Overrides every grey ramp step and replaces SVG icons |
| `lighttable` | Film on a backlit light table: milky background, black bars, grease-pencil orange accents |
| `paper` | Minimal example using only 3 colors and square corners |
| `poster` | Swiss geometric poster: flat primary accents and bold grotesque typography |
| `sheet` | Paper ground with ink borders; red reserved for active state |
| `streets` | High-contrast dark boxes, green accents, square corners, custom SVG frames (`parts/frame.*.svg`) |

## Folder layout

```text
<user-folder>/skins/my_skin/
  theme.xml      # Colors, dimensions, and fonts (required; sufficient on its own)
  parts/*.svg    # Custom SVG icons and frames (optional)
  *.otf / *.ttf  # Bundled font files (optional)
  preview.png    # Preview screenshot (optional)
```

## 1. Minimal skin

Just three colors are enough to theme the entire UI. All intermediate grey shades (backgrounds, cards, borders, secondary text, etc.) are interpolated automatically between `Background` and `Foreground`. Using a light `Background` automatically produces a light theme.

```xml
<Motolii>
  <Theme>
    <Background Value="#f1ead9"/>
    <Foreground Value="#2b2118"/>
    <ChosenDefault Value="#e0452b"/>
    <Corner Value="0"/>
    <FontSans Value="Georgia"/>
  </Theme>
</Motolii>
```

See [paper/theme.xml](./paper/theme.xml) for this minimal example, or [labs/theme.xml](./labs/theme.xml) for a full override with custom grey steps and SVG icons.

## 2. Applying & live-reloading

- **Apply:** Put the folder in your `skins/` directory and select it from **View › Skin** (use **Show Skins Folder** to open the directory, or **Default** to revert).
- **Live reload:** Saving `theme.xml` while the skin is active reloads the UI immediately.
- Omitted keys fall back to Motolii's defaults. See [ROLES.md](ROLES.md) for the complete list of keys.

## 3. Colors

Colors use `#rrggbb` or `#rrggbbaa` (with alpha). See [ROLES.md](ROLES.md) for all role names.

- **`Background` / `Foreground`:** Base surface and primary text colors. All intermediate grey tokens are derived between them automatically.
- **`Grey00`–`Grey100`:** Optional per-step overrides for fine-grained contrast control (see [labs/theme.xml](./labs/theme.xml)).
- **`ChosenDefault` / `ControlOnForeground`:** Accent color (selections, active controls, Render button) and the text/icon color rendered on top of it.
- **`Clip1`–`Clip7` & `Keyframe`:** Layer type colors (`1` shape, `2` text, `3` image/video, `4` camera, `5` group, `6` particles, `7` audio) and keyframe markers.
- **`Tone…`:** Inspector card category tints.

## 4. Dimensions & scale

All numeric factors are multipliers relative to the default (`1.0`):

| Key | Controls | Valid range | Example |
|---|---|---|---|
| `Corner` | Corner radius multiplier | `0`–`10` | `0` (square), `3.5` (pill) |
| `Spacing` | Padding and gaps | `0`–`2` | `1.25` (spacious) |
| `Size` | Overall UI control scale (rows, bars, cards, icons) | `0.85`–`1.5` | `1.15` |
| `TextScale` | Typography scale | `0.85`–`1.3` | `1.08` |

Out-of-range numbers are clamped safely; invalid values, malformed colors, or missing fonts/paths fall back cleanly to defaults without crashing.

## 5. Typography

```xml
<FontSans Value="Avenir Next"/>
<FontMono Value="JetBrains Mono"/>
```

System-installed fonts only need their family name. To ship custom fonts with your skin, place the `.ttf`/`.otf` file inside the skin folder and specify `*File`:

```xml
<FontSans Value="Inter"/>
<FontSansFile Value="Inter.ttf"/>
```

## 6. Custom SVG icons & frames

```xml
<Parts Value="parts"/>
```

Motolii replaces built-in icons with matching `<name>.svg` files inside the `Parts` folder (see [PARTS.md](PARTS.md) for all icon IDs such as `tp.play.svg` and `glyph.select.svg`).

- Author icons on a `viewBox="0 0 24 24"` canvas.
- Icons are recolored dynamically by the UI, so stroke/fill color inside the SVG does not matter.
- Missing icons fall back to Motolii's defaults (you can override as few as one icon).
- Use paths relative to `theme.xml` so the skin remains portable.

### 9-slice control frames

Adding `parts/frame.render.svg` (Render button) or `parts/frame.card.svg` (Inspector card) replaces the control's frame geometry using 9-slice scaling (corners stay fixed, edges stretch, SVG colors are preserved). See the "Frames" section of [PARTS.md](PARTS.md).

## 7. Custom Forms (headless UI, Dart)

Colors, metrics, icons, and frames customize appearance via XML alone. To change the structure of controls themselves (button layout, toggle styling, card chrome), Motolii exposes a headless **Forms** layer built on [naked_ui](https://pub.dev/packages/naked_ui):

- **App supplies data & callbacks:** `ActionSpec`, `ChoiceSpec`, `SwitchSpec`, `CardSpec` in `lib/widgets/forms/forms.dart`.
- **`naked_ui` handles interaction & accessibility:** press, hover, focus, selection, and semantics.
- **A `Forms` subclass builds the visual widget tree** (see `lib/widgets/forms/poster_forms.dart`).

Required overrides: `action` (Render button), `onOff` (toggles), and `card` (Inspector card). Other controls (`segment`, `flag`, `chips`, `track`, `number`, etc.) are optional and fall back to defaults. Register the class in `lib/widgets/forms/forms.dart` and reference it with `<Forms Value="<name>"/>` in `theme.xml`. Note that custom `Forms` require compiling into the app, whereas XML/SVG/font skins are drop-in.

## 8. Scope & limitations

- **Not affected by skins:** Stage viewport content (including pasteboard), dock panel layout, global window zoom (`~/.motolii/window.xml`), and editor behavior.
- **Text fitting:** Labels shrink or wrap (up to 2 lines) rather than truncating with `…`. If you increase `TextScale`, raise `Size` proportionally so rows and cards have enough vertical room.
- **No in-app skin editor yet:** Skins are authored directly in `theme.xml`.

## 9. Sharing & LLM prompt

To share a skin, zip its folder; recipients extract it into their `skins/` folder and enable it via **View › Skin**.

Example prompt for generating a skin with an AI coding agent:

> Read `shelves/skins/README.md` and `shelves/skins/ROLES.md`, then create a skin matching "<desired look>" at `~/Library/Application Support/Motolii/skins/<name>/theme.xml`. Launch the app with `app/tool/live.sh`, inspect the UI, and iterate until all text is legible and accent colors have clear contrast.
