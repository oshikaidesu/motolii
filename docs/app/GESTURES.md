# Gestures

This document defines what a press, a double press, a right press, a drag, a wheel, a hover and each key mean on every control of the app, for anyone who builds or changes a panel.

The Dart code of the app is a thin layer over input and has no style of its own. The same gesture means the same thing, with the same numbers, on every control of the same kind. An exception stands only when it has a reason from the side of the person using the app. Basic gestures follow After Effects.

Read this before making a panel. A panel built from the standard parts in `app/lib/widgets/` gets these rules from the parts. For how the app looks, see [DESIGN.md](DESIGN.md).

A "shelf" is one of the tabs on the left of the window, where bundled and user content (colours, easings, effects) appears, as in Blender's Asset Shelf.

Each rule is one line, found by its name at the front (for example `press.1`). The tag at the end of a line says where the rule comes from:

- `[AE]` After Effects. `[Mac]` macOS, Finder and Apple's guidelines. `[Alight]` Alight Motion.
- `[other: name]` Another app or standard that users already know.
- `[Maintainer]` Decided by the maintainer. `[DESIGN]` A rule of DESIGN.md.
- `[common]` No outside source. Most apps already do it this way.

The shared numbers are meant to be written once, in a `Gestures` class in `app/lib/widgets/`, and read from there by every part (section 12). That class does not exist yet, so until it does this document is the reference for the values.

---

## 1. Press

- `press.1` Buttons and chips: a press with the primary button acts once, when released inside. Releasing outside cancels. No waiting. `[common]`
- `press.2` Selecting or grabbing (tiles, rows, layers in the preview, keyframes, handles): takes effect when the button goes down. A selection alone leaves nothing in undo. `[Mac]` `[Maintainer]`
- `press.3` Toggles (eye, switch): one press flips it on the spot and the result is visible at once. No press-and-hold, no cycling. A label with a switch is one part. `[Alight]`
- `press.4` Choices: one press makes it the choice and it lights up. Pressing the lit one writes nothing. No cycling. Five or more choices open a floating list. `[common]`
- `press.5` Numbers: a press released in place opens typing, with the whole number selected. `[AE]`
- `press.6` Sliders and colours: the value under the pointer is taken at once and follows the hand. A colour swatch becomes that colour with one press. `[other: CLIP STUDIO PAINT]` `[Alight]`
- `press.7` Text fields: a press puts the caret, a double press selects a word, a drag selects a range, Shift+press extends. A one-line name or value field takes keys with everything selected. `[Mac]`
- `press.8` Views (preview, ruler, bands): act where pressed, and only the view and the selection move. Pressing empty space clears the selection. Nothing is created except by a creating tool. Playback stops when the button goes down. `[AE]` `[Alight]`

## 2. Double press and hold

- `double.1` Numbers and sliders: back to the default value (if the first press opened typing, the second closes it). `[Maintainer]`
- `double.2` Names: rewrite in place, with everything selected. `[other: Final Cut Pro, Figma]`
- `double.3` Tiles: use it (apply, create, place or open). One undo step. Repeating does not remove it. `[Mac]`
- `double.4` Empty space in a view, and the ruler: zoom to the selection, or to everything when nothing is selected. `[other: Ableton Live]`
- `double.5` A graph line: puts one point there. `[other: Ableton Live]`
- `double.6` Dividers and height handles: back to the default size. `[common]`
- `double.7` A layer in the preview: enters editing of that layer (a crop for an image). `[other: Figma, Keynote]`
- `long.1` Holding a button, chip or toggle longer than `Gestures.longPress` does nothing. `[common]`

## 3. Right press

- `right.1` Opens the menu of that item at the pointer when the button goes down. The item is selected first. `[other: Ableton Live, Figma]`
- `right.2` An item that can be deleted, renamed or duplicated has Delete, Rename… and Duplicate in its menu. `[common]`
- `right.3` Numbers: the value menu (Reset, Copy, Paste, and the keyframe rows). `[AE]`
- `right.4` A right press moves nothing (no scrubbing, no turning, no colouring, no extra undo step). On an item with no menu nothing happens. `[common]`

## 4. Drag

- `drag.1` A press becomes a drag when the pointer moves `Gestures.dragSlop` from where it went down. This holds for values, items, views and marquees alike. `[common]`
- `drag.2` Numbers: scrub sideways. Right increases. The value stays visible while moving and the panel does not scroll. `[AE]`
- `drag.3` Items and handles: the nearest one within `Gestures.grab` is grabbed when the button goes down. It does not jump, and moves by exactly the hand's movement. It lights up while held, and the number being made appears at the hand. `[other: Figma]` `[Alight]`
- `drag.4` Timeline bars and keyframes: move in whole frames. They stop within `Gestures.snap` of other stopping points, and a line shows where. `[Alight]`
- `drag.5` Carrying a tile: a 22 px accent square follows the pointer. Dropping it on the preview is the same as a double press. Dropping it elsewhere does nothing. `[other: Ableton Live]`
- `drag.6` Carrying into a list: the place it will enter shows as a 2 px accent line or ring. Releasing puts it there. With no place to receive it, it stays where it was. A drop never deletes. `[AE]` `[Alight]`
- `drag.7` Empty space in a view that has selectable items: draws a marquee that selects what it touches. In a view that only shows, the view pans. `[AE]`
- `drag.8` One drag is one undo step. A drag that changed nothing leaves nothing in undo. `[common]`
- `drag.9` The visible range of a number is for display. Scrubbing stops at the end of the range, and Option goes past it. A typed value is never clipped by the range. To really limit a value, write the source that limits the same value next to the number. `[AE]` `[Maintainer]`

## 5. Wheel and two fingers

- `wheel.1` Numbers: without pressing, a horizontal wheel turn or a two-finger horizontal slide over the number changes it at the same speed as scrubbing. Vertical scrolls the panel. `[common]`
- `wheel.2` A run of wheel or slide events that changes a value is one undo step. It closes when the hand has rested for `Gestures.burstRest`. `[AE]`
- `wheel.3` Views: the wheel pans (vertical; horizontal, or Shift+wheel, for sideways). Zoom is Cmd+wheel, centred under the pointer, by a factor of 1.0015 per tick. `[Mac]` `[common]`
- `wheel.4` Views: two fingers carry what is visible with the fingers (1 px per 1 px). Pinching zooms around the fingers. `[Mac]`
- `wheel.5` Lists, menus and rows of chips: the wheel scrolls (a horizontal row scrolls with a horizontal slide or Shift+wheel). No row is ever cut off. `[Mac]`
- `wheel.6` Two fingers are not a press. They never drag a value, handle or bar; they only pan or rotate the view. Only a mouse, a finger or a pen presses (`wsPressing`). `[other: Blender]`

## 6. Hover and cursor

- `hover.1` Something that can be pressed gets one step brighter the moment a hand is over it (`Gestures.hover`): a grey ground becomes `WindowTokens.raised`, text becomes `Grey.g95`, an accent ground becomes `WindowTokens.accentHot`, and a mark or word with no ground changes its text only. Something that cannot be pressed now does not light up. `[common]`
- `hover.2` Cursor: a hand for what acts on press, left-right arrows for a number that scrubs, an I-beam while typing, grab for what can be carried, and the plain arrow for what does nothing. `[common]`
- `hover.3` State changes (on and off, switches, fold marks) take `Gestures.change`. `[DESIGN]`
- `hover.4` A tile gets a 1 px g76 border on its picture, and a moving picture plays under the hand. A row's ground goes one step up. Hover is always weaker than "selected" (the selected look is in DESIGN.md section 4). `[common]`
- `hover.5` Over views and bars, the cursor says what a press would do (edge: left-right arrows, body: grab, keyframe: hand). `[common]`
- `hover.6` The accent colour means "on" or "selected". It is not used for hover. `[common]`

## 7. Return, Escape and leaving

- `key.1` Return: commits the typed text once and leaves the field. Empty text commits nothing and keeps the old value. Text that cannot be read is refused with a reason and the field stays open. `[common]`
- `key.2` Leaving the field (pressing elsewhere, Tab) commits, like Return. `[Mac]`
- `key.3` Escape: discards. The old text returns and nothing is committed. In a dialog it is Cancel, and settings changed since it opened are put back. `[Mac]`
- `key.4` Escape in the middle of a drag: the item and the value go back, and nothing is left in undo. `[common]`
- `key.5` Escape closes the topmost floating thing (menu, list, dialog). Pressing outside closes it too (with any button, and that press also reaches what is below). `[Mac]`
- `key.6` Return and Space: press the button that has the key focus. Return on a number opens typing. `[common]`
- `key.7` While a floating thing is open, the app's keys do not reach the project behind it. `[common]`

## 8. Delete

- `del.1` Delete or Backspace deletes the selection, wherever the item can be deleted (layers, markers, effect cards, decks, your own colours, saved easings). One undo step restores it. `[other: Ableton Live]`
- `del.2` A file on disk is moved to the trash, after asking. `[Mac]`
- `del.3` On a number with the key focus: back to the default value (same as double press and the menu's Reset). While typing it deletes characters. `[common]`

## 9. Tab, arrows and character keys

- `tab.1` Tab: commits the current field and opens the next one for typing. Shift+Tab goes to the previous one. `[AE]`
- `tab.2` Tab also reaches buttons, chips and toggles, and a mark shows where it landed. `[common]`
- `arrow.1` Numbers (with key focus, and while typing): Up and Right increase, Down and Left decrease. One step is the last visible digit (1 for an integer). Shift and Cmd follow `mod.1`. `[AE]`
- `arrow.2` Items and time: one unit (1 frame, 1 row, the next tile). Shift moves `Gestures.nudgeShift` units. `[AE]`
- `arrow.3` Choices, lists and menus: arrows only move the mark (and stop at the ends). Return or Space decides. Home and End go to the ends. `[other: W3C ARIA]`
- `arrow.4` Sliders: one step is 1 px of the track. Shift and Cmd follow `mod.1`. Page moves a tenth of the width, Home and End go to the ends. `[common]`
- `keys.1` A one-letter command (the tool keys V, M, R and so on) works anywhere the app holds the keys, except while typing text. A letter shown in a menu follows the key bindings (`keybindings.json`). `[AE]` `[other: VS Code]`
- `keys.2` Typing a digit, `.` or `-` on a number with the key focus starts typing with that character. `[common]`

## 10. Shift, Cmd and Option

- `mod.1` Values (scrub, wheel, slide, arrows; numbers and sliders alike): Shift is 10 times, Cmd is a tenth. They are read each time, so pressing or releasing one mid-gesture is fine. `[AE]`
- `mod.2` Selecting: Shift+press selects from the last selected row to here in a list, and adds in the preview, bars and keyframes (or removes, if already selected). Cmd+press adds or removes one. A marquee adds in the same way. `[AE]` `[Mac]`
- `mod.3` Dragging items and handles: Shift constrains (aspect ratio, one axis, 15 degree steps). Option resizes from the centre. `[other: Illustrator, Figma]`
- `mod.4` Cmd during a drag turns off snapping to stopping points. `[other: Ableton Live]`
- `mod.5` Wherever this document says Cmd, it means Cmd or Ctrl (`Gestures.cmd`). `[common]`
- `mod.6` Option: on a fold header it acts on all siblings (`fold.2`). On a number scrub it goes past the end of the visible range (`drag.9`). `[Mac]` `[other: Houdini]`

## 11. Frames around parts

These are about the frame of a part (card, row, tile, tab), not about the controls inside it.

**Fold**

- `fold.1` Pressing the header folds. If the header does nothing else, all of it is pressable. If pressing a row selects or navigates, only the mark folds. `[common]`
- `fold.2` Option+press puts all siblings in the same state. `[Mac]`
- `fold.3` The fold mark turns over `Gestures.change` in every skin. A row that was folded appears at once. `[DESIGN]`
- `fold.4` Fold state is part of how the app looks, and it is remembered. It is not written to the project and not in undo. `[common]`

**Reorder**

- `reorder.1` An item in a list is carried by grabbing its header or row (from `Gestures.dragSlop`). Released without moving, it stays a press. `[AE]`
- `reorder.2` A grip mark (≡) may stay as a mark. The grip must not be the only place that can be grabbed. `[AE]`
- `reorder.3` While carried, a floating copy follows the hand and a 2 px accent line shows where it will enter. Releasing is one undo step. Escape, or releasing where nothing receives it, puts it back. `[Alight]`

**Remove**

- `remove.1` The mark: a trash can on a header that has other marks. On a tile or card with no header, a round × outside the top right corner (-4, -3). `[other: AbsentMotion, Cavalry]`
- `remove.2` Without the mark, selecting and pressing Delete (`del.1`) or the menu's Delete (`right.2`) also removes. `[common]`
- `remove.3` Removing does not ask. One undo step restores it. Only a file on disk asks first, then goes to the trash (`del.2`). `[Mac]`

**Hide**

- `hide.1` One press on the eye hides, another restores. The value is kept. The eye mark swaps and hidden things are drawn faint. For something in the project, it is one undo step. `[Alight]`
- `hide.2` Hide, delete and duplicate act on everything selected, however many items. `[common]`

**Rename**

- `rename.1` Double press on the name, Rename… in the menu, or select and Cmd+R: write in place, with everything selected. A tile uses double press for "use", so rename it from the menu. `[Mac]` `[other: Ableton Live]`
- `rename.2` Return or leaving commits. Escape keeps the old name. An empty name or the same name does nothing. A name that cannot be taken is refused with a reason. `[Mac]`

**Menu**

- `menu.1` There is one floating menu: width `Gestures.menuWidth`, rows `Gestures.menuRow`, height up to half the app. It opens at the pointer when the button goes down (below the button when opened from a button; above if it does not fit). `[other: Ableton Live]`
- `menu.2` Pressing a row closes the menu first, then acts once. A row that changes the project is one undo step. A row that cannot act now shows why, does not light up and does nothing. `[common]`
- `menu.3` The word for a deleting row is Delete everywhere (not Remove, not "Delete this palette"). `[other: Ableton Live]`
- `menu.4` Escape or a press outside closes it (`key.5`). Arrows and Return choose (`arrow.3`). `[Mac]`
- `menu.5` A ⋮ or ⋯ button opens the same menu as a right press. What can be done to an item is in that item's menu. `[other: Ableton Live]`

---

## 12. Numbers

The values for the `Gestures` class. Parts and panels read them by these names and do not write numbers of their own.

| `Gestures` name | Value | Source |
|---|---|---|
| `dragSlop` | 4 px (on screen) | `[common]` Number scrubbing and the marquee already use this value |
| `doubleTap` | 300 ms | `[other: Flutter]` `kDoubleTapTimeout` |
| `doubleTapSlop` | 100 px | `[other: Flutter]` `kDoubleTapSlop` |
| `longPress` | 500 ms | `[other: Flutter]` `kLongPressTimeout` |
| `grab` | 8 px (around a point, keyframe, handle or edge) | `[common]` The preview's handles and keyframes use this value |
| `snap` | 8 px | `[Alight]` Stops at the nearest point within 8 points |
| `coarse` | 10 times (Shift on a value) | `[AE]` Shift makes scrubbing 10 times faster (community.adobe.com/t5/after-effects-discussions/shortcut-for-scale-dragging/m-p/9417731) |
| `fine` | one tenth (Cmd or Ctrl on a value) | `[AE]` Same source: Command and Control divide by 10 |
| `nudgeShift` | 10 (Shift+arrow on items and time) | `[AE]` Shift+arrow moves by 10 |
| `hover` | 0 ms | `[common]` |
| `change` | 120 ms (`Motion.dur`) | `[DESIGN]` The one motion |
| `menuWidth` | 220 px | `[common]` |
| `menuRow` | 22 px | `[common]` |
| `menuMaxHeight` | half the height of the app | `[common]` |
| `burstRest` | 300 ms | `[AE]` The Unified Camera tool's wheel: one step after it stops |
| `cmd`, `valueFactor` | How to read the key (Cmd or Ctrl) and the factor applied to a value | `mod.5`, `mod.1` |

## 13. Standing exceptions

Only things that have a reason from the side of the person using the app. Each reason is quoted from the research it came from. A difference that is not listed here should be fixed to follow the rules above.

| Part | Where it differs from the rules | Reason | Where (`app/lib/`) |
|---|---|---|---|
| Undo and Redo in the top bar | A press writes what was undone in the notice | "as After Effects' and Premiere Pro's Edit menu names the step" | `workspace/top_bar/top_bar.dart` |
| The Overshoot chip of Ease | Turns itself on when the curve goes outside 0 to 1. Turning it off pulls the handles back in | "a number written turned it on unseen, and the curve went out of reach" (maintainer) | `workspace/tool_panel/ease/ease_numbers.dart` |
| Show (snapshot) in the preview | Not a toggle. It shows only while held | "After Effects' Show Snapshot: seen while it is held; let go, the picture as it is now" | `workspace/stage/stage.dart` |
| A Chooser with five or more choices | The first press opens a list and the second decides | "A short list lives in a segmented control; a long one opens a searchable list" | `inspector/chooser.dart` |
| The menu bar | It is the OS menu, not the app's menu | "every command in the menu bar, where the Help menu's search finds it by its name, Apple's HIG" | `workspace/commands/menu_bar.dart` |
| The row of Ease shapes (Linear, In, Out …) | Tiles, but one press applies. They rise 2 px under a hand | "the shapes, one row, one press each" (maintainer) | `workspace/tool_panel/ease/ease_side.dart` |
| Tiles on the Ease shelf | One press replaces the whole stretch with that tile | "A press puts a tile on the stretch whole, in place of all that is there, so one after another can be tried" | `workspace/tool_panel/ease/ease_shelf.dart` |
| The dot at the corner of an Inspector number | A press neither types nor scrubs. It sets or clears a keyframe at that frame | "Alight Motion's diamond beside each value, After Effects' and Premiere Pro's stopwatch" | `inspector/controls/inspector_number_field.dart` |
| The colour boxes in the tool column (fill, stroke) | A press does not colour anything. It points the Colors shelf at that ink | "Illustrator's Fill and Stroke boxes: the one chosen is edited" | `workspace/stage/stage.dart` |
| The Camera View tab | Takes no press and no drag | "Nothing to hold here: a look, the hand is on the stage." | `workspace/stage/stage_camera.dart` |
| The axis gizmo of the Relations map | A press does not select. It turns the view to look from that axis | "an axis of the gizmo: seen from that side, as Blender's" | `workspace/tool_panel/relations.dart` |
| The Rectangle, Ellipse and Text tools | A press creates one item and the tool returns to Select | "Alight Motion's Add is one act and Figma's tool goes back to select" | `workspace/stage/draw_tools.dart` |
| The marker flag on the ruler | A press selects, moves the playhead there and stops playback | "Live's locators (a click picks and goes to one)" | `workspace/timeline/timeline_requests.dart` |
| The Relations map | A drag turns the view instead of panning it. Two fingers turn it too | "a trackpad's two fingers turn the view, as Blender's do" | `workspace/tool_panel/relations.dart` |
| The Camera tool (drag) | The camera turns (0.25 degrees per px). With a free view only the view moves | "After Effects' Unified Camera tool: a drag turns the camera round where it looks" | `workspace/stage/camera_gestures.dart` |
| The ends of the work-area band | Cannot be made shorter than 0.5 seconds (a bar can go down to 1 frame) | "never shut to nothing: half a second at least, so the document cannot be dragged out of sight" | `workspace/timeline/ruler_marks.dart` |
| The angle dial | Turns with the angle of the pointer instead of scrubbing sideways | "one turn of the pointer is one turn of the value", After Effects' angle | `inspector/controls/inspector_param_controls_angle_dial.dart` |
| The point and size pads | For a point, down increases. For a size, up increases | "Y follows the canvas (down is more) for a point, and up is more for a height" | `inspector/controls/inspector_param_controls_tile.dart` |
| The turning mark of the camera gizmo | Turns the opposite way to the Camera tool, at a speed set by the size of the circle | "it goes the way the hand does; a turn as far as the hand has gone on the circle it goes round" | `workspace/stage/camera_gestures.dart` |
| The Camera tool (wheel) | The camera moves closer or further instead of the view moving | "After Effects' Unified Camera tool's wheel: the camera nearer or further from where it looks" | `workspace/stage/camera_gestures.dart` |
| A colour box in Colors (hover) | A hand over it puts a rainbow rim on every box of the same palette | "a rim, not the others darkened" | `workspace/dock/dock_make_colors.dart` |
| The deck name field (Save Favorites…) | Saving under a name empties Favorites, and this cannot be undone | "as Lightroom's Clear Quick Collection After Saving" | `workspace/dock/dock_effect_places.dart` |
| The menu of a number | Right pressing the same number again reopens the menu there without closing it | "right pressed here again: its place, as a Mac's" | `widgets/float_shut.dart` |
| Delete with a stretch selected | The stretch is not removed. Its easing returns to Linear | "a stretch picked: its way off, straight again, not the thing" | `workspace/commands/menu_bar.dart` |
| The code field of Program | Does not add closing brackets. Undo belongs to the field, not to the project | "exactly what is typed" | `workspace/shelf/program_code.dart` |
| The effect code of a card | The first edit copies the shelf's file and writes to the copy | "the shelf's file is never written over" | `workspace/shelf/fx_code.dart` |
| Scrubbing on the ruler | Snapping is off by default and Shift turns it on (bars and keyframes are the other way round) | "After Effects': Shift held while the time indicator is dragged, it rests on what it passes" | `workspace/timeline/ruler_marks.dart` |
