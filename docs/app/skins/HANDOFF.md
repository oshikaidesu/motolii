# How the app's look is built

This document is for developers and AI agents who carry on the app's look: it lists the three layers that change it without touching projects, motion or pictures, and where each is written. To only make a skin, read [shelves/skins/README.md](../../../shelves/skins/README.md).

The look of the app (Flutter, in `app/`) can be changed in three layers without touching the engine side (project, motion, pictures). A "skin" is one such set of changes: a theme made of colours, type, shapes and SVG parts. A "shelf" is a tab on the left of the window where bundled and user content appears, as in Blender's Asset Shelf. Skins are listed under View › Skin, and a user's own skins sit in a `skins/` folder like the content of any other shelf.

## 1. The three layers

| Layer | What it changes | What you write | How it is delivered |
|---|---|---|---|
| 1. Values | Colours, light or dark, corners, spacing, sizes, text size, fonts | `theme.xml` (a list of names and values) | Drop the folder in place |
| 2. Pictures | Icons, and the frames of parts | `parts/*.svg` | Drop the folder in place |
| 3. Forms | How a part is **put together** (what shape a button is, how choices line up, how a card is built) | One Dart class (`lib/skin/forms/<name>_forms.dart`) | Compiled into the app |

Layers 1 and 2 are fully described in [README.md](../../../shelves/skins/README.md), [ROLES.md](../../../shelves/skins/ROLES.md) and [PARTS.md](../../../shelves/skins/PARTS.md). Layer 3 is headless UI, split the way React Aria and Radix split it. The rest of this document is mostly about layer 3.

## 2. Map of the files

Paths are relative to [`app/`](../../../app/).

| Where | What |
|---|---|
| `lib/skin/theme.dart` | Reads and watches `theme.xml` (`ColorTheme`). The skin being worn is `Skin` in `~/.motolii/window.xml` |
| `lib/skin/tokens.dart` | The grey ramp (`Grey`, built from Background and Foreground in HCT), the accent (`Accent`), `Shape.r/s/z` (corners, spacing, sizes), `TextStyles` (type and `TextStyles.px`), and `Motion`. The ranges a number may take are here too |
| `lib/skin/window_tokens.dart` | The window's grounds, accent shortcuts and layer-kind colours (`WindowTokens`) |
| `lib/skin/inspector_tokens.dart` | The inspector's colours and spacing (`InspectorSkin`), including the colour of each card kind |
| `lib/skin/layer_colors.dart` | The sixteen label colours of layers (`Label1` to `Label16`) |
| `lib/storage/window_settings.dart` | Reads and writes `~/.motolii/window.xml` (the zoom and the skin being worn) |
| `lib/skin/skin_parts.dart` | The icon SVGs (`SkinParts.draw`) and the frame pictures (`SkinParts.frame`). The frame widget `SkinFrame` is `lib/widgets/skin_frame.dart` |
| `lib/skin/forms/forms.dart` | **The contract of forms**: the specs the app passes, the functions a form writes, and the table `forms` |
| `lib/skin/forms/base_controls.dart` | The default drawing of the optional form functions |
| `lib/skin/forms/own_forms.dart` | The usual look of the app |
| `lib/skin/forms/poster_forms.dart` | A sample: a Swiss geometric poster |
| `lib/skin/forms/lighttable_forms.dart` | A sample: film on a light table |
| `lib/skin/forms/sheet_forms.dart` | A sample: ink lines on one sheet of paper |
| `../shelves/skins/<name>/` | The sample skins in the repository (labs, paper, streets, poster, lighttable, sheet) |
| `tool/live.sh` | Runs the app and redraws it the moment a `.dart` file under `lib/` is saved, keeping its state |

## 3. Writing a form

### The split

- **The app passes in**: the words of a part, its current value and what a press does (the specs below).
- **What a hand does**: [naked_ui](https://pub.dev/packages/naked_ui) (BSD-3). Press, hover, select, toggle and screen-reader support. It has `NakedButton`, `NakedToggle` (a switch with `asSwitch: true`), `NakedToggleGroup` with `NakedToggleOption` (exactly one of several), and also `NakedSlider`, `NakedTabs`, `NakedSelect`, `NakedMenu` and more. The builder receives the state (`isHovered`, `isPressed`, `isSelected`, `isFocused`, `isDisabled`).
- **The form writes**: only how these are put together and drawn. **Do not rebuild the behaviour yourself.** Use naked_ui and do not add a `GestureDetector`.

### The contract (`lib/skin/forms/forms.dart`)

A form is a class that extends `Forms`. It must write `action`, `onOff` and `card`. The others have a default in `BaseControls` and may be left out.

| Function | What is passed | Part of the app |
|---|---|---|
| `action(context, ActionSpec)` | `label`, `onPressed` | Render in the top bar |
| `onOff(context, SwitchSpec)` | `on`, `onChanged`, `enabled` | On and off switches (Animate all and others) |
| `card(context, CardSpec)` | `title`, `tone` (the colour of the card's kind), `open`, `onToggle`, `trailing`, `body` (the rows), `head` and `own` (the app's usual build) | One card of the inspector |
| `segment` (optional) | `ChoiceSpec` (`labels`, `selected`, `onSelect`; the width follows the words) | Fit, 50%, 100%, Layer, Group and similar |
| `flag` (optional) | `FlagSpec` (`label`, `on`, `onTap`, `mark`) | Snap, Safe, Grid and similar |
| `chips` (optional) | `ChipsSpec` (`chips` as name and optional count, `active`, `onPick`) | A shelf's filter chips |
| `track` (optional) | `TrackSpec` (`index`, `name`, `selected`, `dim`, `hot`, `onSelect`, and the finished `kind`, `eye`, `solo` and `lock` widgets) | A layer's name in the timeline |
| `number` (optional) | `NumberSpec` (in `lib/widgets/number_field_look.dart`: the number's text, the field being typed in, the range and more) | A number field. Scrubbing it is the app's |
| `trackFill`, `trackRadius`, `trackBar`, `trackBand` (optional) | The kind colour and state of a layer; the row index | The bar of a layer in the timeline and the band behind its row |
| `paneMark`, `plainTabs` (optional) | `selected` and the app's own `mark`; whether the tab strip drops the package's cards | The mark at the front of a dock tab |

Details of the contract:

- `FlagSpec.mark` is a function from the colour the form chooses to the app's icon for the chip. Draw it in that colour.
- `CardSpec.head` is the app's usual header row, already built (fold mark, kind mark, title, keyframe dot, summary when folded, `trailing`). Drop it if you build your own header. But there are cards that have a `head` and a `null` `title` (cards with only `trailing`). For those, show `head`.
- `CardSpec.own` is the whole content of the card, header and rows wrapped in padding, with no outer frame. To change only the outer frame, wrap `own` in your own frame (`own_forms.dart` does this).
- Animation of the look (`AnimatedContainer`, `TweenAnimationBuilder` and so on) is free. Receiving the hand (`GestureDetector`, `MouseRegion`, `Listener`) is left to naked_ui.

### Materials you can use

| Kind | Name | What it is |
|---|---|---|
| Text style | `TextStyles.title()` `TextStyles.name()` `TextStyles.label()` `TextStyles.micro()` | Font is the skin's `FontSans`. Title, name, small label, smallest |
| Text style | `TextStyles.value()` | Font is the skin's `FontMono` (monospaced). For numbers and times |
| Text size | `TextStyles.px(11)` | A size multiplied by the skin's `TextScale` (`.copyWith(fontSize: TextStyles.px(n))`) |
| Font name | `TextStyles.sans` `TextStyles.mono` | The font names the skin gives |
| Colour | `Grey.g00` to `Grey.g100`, `Grey.bandA` and others | The grey ramp (which step is where in the app is in the table of [ROLES.md](../../../shelves/skins/ROLES.md)). Built from the skin's Background and Foreground |
| Colour | `Accent.fill` `Accent.on` `Accent.ink` | The accent, the ink on it, and the accent as a line or text on a ground (also as `WindowTokens.accent`, `onAccent` and `accentInk` in `lib/skin/window_tokens.dart`) |
| Colour | `tone` of a spec | The colour of a card's kind |
| Shape | `Shape.r(n)` | A corner radius (`Radius`, multiplied by the skin's Corner) |
| Shape | `Shape.s(n)` `Shape.z(n)` | A margin, and a size (multiplied by the skin's Spacing and Size) |

A form may also have colours of its own (`poster_forms.dart` has constants for its own colours). Use the materials above only where the form should follow the skin's colours.

### Steps

1. Write `class XForms extends Forms` in `lib/skin/forms/<name>_forms.dart`, with at least `action`, `onOff` and `card` (`poster_forms.dart` is a sample).
2. Add `'<name>': XForms()` to `forms` in `lib/skin/forms/forms.dart`, and import it.
3. In the skin folder's `theme.xml`, write `<Forms Value="<name>"/>` (the colours go in the same theme.xml).
4. Look at it: open the app with `app/tool/live.sh`, wear the skin in View › Skin, and watch it redraw every time the form file is saved. Check hover and press by hand in that app.
5. Check it: no clipped text and no overflow. Colour does not affect how text fits, so what you write is the form and the fonts (and Size and TextScale if the skin changes them).

### Rules

- Sizes go through `Shape.z()`, margins through `Shape.s()`, and text through `TextStyles.*` (`TextStyles.name()` and so on) and `TextStyles.px()`, so that the skin's Size, Spacing and TextScale take effect.
- Never clip text. When it is wider than its box, shrink it with `FittedBox(fit: BoxFit.scaleDown)` (long names use auto_size_text, up to two lines).
- `own_forms.dart` is the reference for the usual look. When you touch it, do not change the look by one pixel.

## 4. Design direction

Anthropic's guidance ([the frontend-design skill](https://github.com/anthropics/skills/tree/main/skills/frontend-design), [the blog post](https://claude.com/blog/improving-frontend-design-through-skills), [the cookbook](https://platform.claude.com/cookbook/coding-prompting-for-frontend-aesthetics)) together with what this project has decided:

- **Root it in the subject.** Motolii is a tool for making a music video quickly, by the strength of an idea. Choose from the materials of that world. Common defaults (Inter, a purple gradient on white, the same rounded card repeated, cream with serif and terracotta, black with neon green, all-caps small headings) are not a choice.
- **Colour is meaning.** Give a colour only where it means something, such as the kind of a card or of a layer. Do not pick a colour from a name.
- **Boldness in one place.** Only on what is selected and on a lead such as Render. Keep the rest quiet.
- **Type is character.** Go to extremes in weight and size (thin against extra bold, a threefold jump). Avoid text that is all capitals.
- **Density.** Keep it readable at a glance, like Ableton. Add no explanatory sentences and no hover tips. The video is the lead.
- **Motion.** Only motion that shows what changed as a result of a touch.
- **Work in two passes.** First write four to six colours, the fonts and an ASCII layout, and correct them against the request. Then write the code. Take a picture and critique it yourself.

Direction for the poster sample: a Swiss geometric poster (Posterlad's Checkers, Xavito deVito's gig poster) in a quiet version. Colour only for kind, loud only for the selection and Render, rows as dense as a mixing desk. `poster_forms.dart` still picks a card's colour from its title, which goes against this.

## 5. Asking an AI

**A skin of values and pictures** (wearable once it is dropped in place):

> Read `shelves/skins/README.md` and `shelves/skins/ROLES.md`, then write a skin of "(the look you want)" to `~/Library/Application Support/Motolii/skins/<name>/theme.xml`. Open the app with `app/tool/live.sh`, look, fix, and look again, until no text is unreadable and no accent colour is lost.

**A form** (changes how parts are put together). The parts it reaches are in the table in section 3. The dock tab itself (drawn by the `docking` package) is still outside, apart from its mark (section 7).

> Read `docs/app/skins/HANDOFF.md`, write a form of "(the look you want)" in `lib/skin/forms/<name>_forms.dart`, register it, and make a skin that wears it in `shelves/skins/<name>/theme.xml`. First write four to six colours, the fonts and an ASCII layout, and correct the common defaults, then write the code. Write `action`, `onOff` and `card` (a function you do not write stays the app's usual drawing). Open the app with `app/tool/live.sh`, look and fix. In the end check that nothing is clipped and nothing overflows.

## 6. Pitfalls

- **Flexible in a row that scrolls sideways.** Putting `Flexible` or `Expanded` in a child of a scrolling `Row` (for example a strip under the preview) leaves the screen unable to lay out.
- **const.** `Shape.z()` and its relatives are getters, so they cannot be used inside `const`. Remove the `const` where the analyzer's `const_*` lints point.
- **Keep ROLES.md in step with the app.** Every name the app reads through `ColorTheme.of`, `ColorTheme.number` and `ColorTheme.word` is listed in ROLES.md, and nothing else is.
- **Ranges of numbers.** Size 0.85 to 1.5, TextScale 0.85 to 1.3, Spacing 0 to 2, Corner 0 to 10. Outside them the value is pulled to the end (outside them tabs disappear and text is clipped).
- **The colour of an automatic card.** The inspector's automatic cards read their colour when they paint (`CardDeclaration.toneOf` in `lib/inspector/inspector_card.dart`). Do not store the colour when the card is made.

## 7. Not done yet

- The parts that go through forms are Render, the on and off switches, cards, the small choices and chips (Fit, Layer and Group, Snap, Safe, Grid), a shelf's filter chips, a layer's name and its bar in the timeline (the corner and ground of the bar are `trackRadius` and `trackBand`), the mark of a dock tab (`paneMark`), and number fields. The dock tab itself (drawn by the `docking` package) is still outside forms.
- A form is compiled into the app, so a skin that brings one cannot be worn by just dropping it in place.
- The width of a thin (1 pixel) line does not change with the skin.
- The inside of the preview (including the dark area outside its frame) is the work's picture, so a skin does not change it.
