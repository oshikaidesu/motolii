# How to make a skin

[日本語](README.ja.md)

This is the first page for anyone who wants to make a skin: one folder (a `theme.xml`, plus pictures or fonts if you like) that changes only how the app looks. Put it in your own `skins/` folder and it appears under View › Skin.

A skin is a theme: the colours, type, shapes and SVG parts of the window. Nothing on the engine side (project, motion, pictures) changes.
A skin is one folder, placed in the `skins/` folder inside your own folder (on a Mac `~/Library/Application Support/Motolii/`, on Windows `%APPDATA%\Motolii\`; `MOTOLII_OWN` changes it, as for every other shelf). A shelf is one of the tabs on the left of the window, where bundled and user content appears, as in Blender's Asset Shelf. If a name is the same, yours wins. A skin in the older location `~/.motolii/skins/` is still read.

The samples in this folder (they appear under View › Skin as they are):

| Skin | Look |
|---|---|
| `labs` | Black text on white, round pills, pale icons. A worked-out sample: every grey step is written and the icon pictures are replaced |
| `lighttable` | Film on a glowing light table. Milky ground, black bands, grease-pencil orange only where you touch |
| `paper` | The shortest sample: only three colours and square corners |
| `poster` | A Swiss geometric poster. Flat red, yellow, blue, green and pink, heavy grotesque type |
| `sheet` | A ground of one sheet of paper and ink lines. Red only for where you are now (mode, key) |
| `streets` | Black boxes, white text, money green, square corners. The Render button and the cards have frames of their own (`parts/frame.*.svg`) |

```
<your folder>/skins/my_skin/
  theme.xml      <- colours, shapes, fonts (this alone is a skin)
  parts/*.svg    <- icon pictures (optional)
  *.otf / *.ttf  <- font files (optional)
  preview.png    <- a screenshot of the app wearing the skin (optional)
```

## 1. The shortest skin

Three colours change the whole app. The grey steps (ground, card, line, quiet text and so on) are all made from `Background` and `Foreground`, and a light ground gives a light skin.

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

This is the sample [paper](./paper/theme.xml). For a worked-out sample see [labs](./labs/theme.xml) (every grey step is written and the icon pictures are replaced).

## 2. Wear it, fix it, look at it

- **Wear it**: put the folder in `skins/` in your own folder and choose it from the app's menu **View › Skin**. **Show Skins Folder** opens that folder. **Default** goes back to the app's usual look.
- **Fix it**: save `theme.xml` while wearing it and the app rereads it at once.
- A name you leave out keeps the app's usual value. All the names are in [ROLES.md](ROLES.md). [labs](./labs/theme.xml) is a sample that writes every grey step.

## 3. Colours

Write `<Name Value="#rrggbb"/>` (with transparency, `#rrggbbaa`). All the names are in [ROLES.md](ROLES.md) (keep them the same as the names the app reads).

- **Background / Foreground**: the colour of a panel's ground and the colour of text. The colours you write become the ground and the text as they are, and the other grey steps (gaps, cards, fields, lines, quiet text and so on) are made between these two. A light ground gives a light skin (`Shade` is not needed).
- **Grey00 to Grey100**: to decide the grey steps one by one (only the steps you write are overridden). Which step is where in the app is in the table of [ROLES.md](ROLES.md). [labs](./labs/theme.xml) is an example that writes the steps one by one.
- **ChosenDefault**: the accent (what is selected, what is pressed, the fill of Render). The text on it is **ControlOnForeground**.
- **Clip1 to Clip7**: the colours of layer kinds (1 shape, 2 text, 3 image or video, 4 camera, 5 group, 6 particles, 7 audio). They are used for the timeline's bars and for the cards and marks of that kind. **Keyframe**: the mark of a keyframe.
- **Tone…**: the colour of each kind of card in the inspector (layer, blend, place, text animation, time, layout).

## 4. Shapes (numbers)

Each one is "how many times the usual". 1 is the usual size.

| Name | What changes | Range that takes effect | Example |
|---|---|---|---|
| `Corner` | How round corners are | 0 to 10 | 0 is square, 3.5 is a round pill |
| `Spacing` | Margins and gaps | 0 to 2 | 1.25 is roomy |
| `Size` | The size of every part of the app (rows, bands, columns, cards, icons, figures) | 0.85 to 1.5 | 1.15 is larger |
| `TextScale` | The size of text | 0.85 to 1.3 | 1.08 |

The app does not break when you write a number outside the range, a word that is not a number (`NaN`, `big`), a colour that cannot be read, or a font or folder that does not exist. A number is pulled to the end of its range, and anything else becomes the usual value. The ranges reach as far as text is not clipped and parts do not overflow.

## 5. Fonts

```xml
<FontSans Value="Avenir Next"/>
<FontMono Value="JetBrains Mono"/>
```

For a font already on the Mac, the name is enough. Even a wide font (Monaco and the like) does not clip text; where it does not fit, it is drawn smaller. If it gets too small, raise `Size` a little. For a font that is not installed, put the file in the skin's folder and write where it is.

```xml
<FontSans Value="Inter"/>
<FontSansFile Value="Inter.ttf"/>
```

## 6. Icon pictures (SVG)

```xml
<Parts Value="parts"/>
```

With this, `name.svg` in that folder is drawn in place of the app's icon. All the names are in [PARTS.md](PARTS.md) (the play button is `tp.play.svg`, the select tool is `glyph.select.svg`, and so on).

- Draw in a `viewBox="0 0 24 24"` frame.
- The app repaints the colour with the colour of that place, so only the shape matters (any colour will do).
- A name you do not have stays the app's usual picture. Replacing just one is fine.
- The folder may be given relative to theme.xml, as `~/`, or as an absolute path. Keep it relative and the whole folder can be handed out.

### Frames: change the shape of a part

Put `parts/frame.render.svg` (the Render button) or `parts/frame.card.svg` (a card of the inspector) and the shape of that part changes entirely. The four corners are kept, the sides are stretched, and it fits a part of any size. The colours stay as drawn. How to write one is in "Frames" of [PARTS.md](PARTS.md).

## 6b. Forms: change how a part is put together (headless UI)

Colours, numbers, icons and frames only change appearance. A form goes further: it changes what shape a button is, how choices line up and how a card is built. It is split the way React Aria and Radix split "headless UI":

- **What the app passes in**: the words of a part, its current value and what a press does (`ActionSpec`, `ChoiceSpec`, `SwitchSpec`, `CardSpec` and others in `lib/skin/forms/forms.dart`)
- **What a hand does**: [naked_ui](https://pub.dev/packages/naked_ui) (press, hover, select, toggle, and screen-reader support)
- **What the form writes**: only how these are put together and drawn

A form is one Dart class (`lib/skin/forms/poster_forms.dart` is a sample). The three functions every form must write:

| Form function | Part of the app |
|---|---|
| `action` | The Render button |
| `onOff` | On and off switches (Animate all and others) |
| `card` | One card of the inspector |

The others (`segment`, `flag`, `chips`, `track`, `number` and more) are optional and have a usual drawing. They are listed in [HANDOFF.md](../../docs/app/skins/HANDOFF.md).

To add a form, write a class that extends `Forms` in `lib/skin/forms/<name>_forms.dart`, add one line to `forms` in `lib/skin/forms/forms.dart`, and write `<Forms Value="<name>"/>` in the skin's theme.xml.

**To try it at once**: open the app with `app/tool/live.sh`, and the open app redraws the moment you save the form file (its state stays as it is).

A form is compiled into the app, so a skin that brings one cannot be worn by just dropping it in place (colours, numbers, icons and frames can).

## 7. What a skin does not change

- **The inside of the preview**: including the dark area outside its frame, it is the work's own picture.
- **Layout**: where panels sit and how big they are is each person's choice, in the dock.
- **The scale of the whole app**: this is the viewer's preference. Scrub "100%" in the top bar in steps of 1% (it is kept in `~/.motolii/window.xml`).
- **How things move**: a skin is only the look.

## 8. Handing it out

Zip the folder as it is. Whoever receives it puts it in `skins/` in their own folder and chooses it in View › Skin.

## 9. Asking an LLM

A request you can hand over as it is:

> Read `shelves/skins/README.md` and `shelves/skins/ROLES.md`, then write a skin of "(the look you want)" to `~/Library/Application Support/Motolii/skins/<name>/theme.xml`. Open the app with `app/tool/live.sh`, look, fix whatever bothers you, and look again. Repeat until no text is unreadable and no accent colour is lost.

## Text is never clipped

When text becomes wider than its box, the app does not cut it with "…". It draws the text smaller until it fits (a long name wraps to two lines). Even with a large `Size`, `TextScale` or `Spacing`, or a wide font, words are not split or lost.
The pass mark is no clipping, no overflow, and no tab disappearing.

## What is not possible yet

- There is no tool in the app to pick colours and make a skin. You write theme.xml.
- Making text larger (`TextScale`) does not change the height of rows or cards; only `Size` does. If you make text larger, raise `Size` by about the same amount, and less text has to be shrunk to fit.
