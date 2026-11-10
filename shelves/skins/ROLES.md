# Names a skin can set (roles in theme.xml)

This is the reference for people who make a skin: every name a skin's `theme.xml` can set (`<Name Value="..."/>`), covering colours, numbers and words.

Write `<Name Value="..."/>` in the `theme.xml` of the skin's folder. A name you leave out keeps the app's usual value. The app rereads theme.xml the moment it changes. Samples are [paper](./paper/theme.xml) (short) and [labs](./labs/theme.xml) (worked out). For how to make a skin, see [README.md](README.md).
This list and the names the app reads are kept the same.

## Colours (`#rrggbb` or `#rrggbbaa`)

### Ground and text: these two first
| Name | Where in the app |
|---|---|
| `Background` | The ground of panels and the top bar. The colour you write becomes the ground as it is |
| `Foreground` | Text. The colour you write becomes the text as it is |

Write these two and all the grey steps below are made between them (a light ground gives a light skin, and `Shade` is not needed). Brightness runs in order between the two colours. The hue comes from the nearer one: the steps near the ground (Grey00 to Grey44) take Background's, and the steps near the text (Grey56 and up) take Foreground's, so even two strong colours such as a purple ground with yellow text do not turn muddy. Write a step by itself and only that step is overridden.

### Grey steps (darkest first; in a light skin, lightest first)
| Name | Where in the app |
|---|---|
| `Grey00` | The gap between panels (the deepest layer) |
| `Grey07` | The ground of a panel, the top bar (= Background) |
| `Grey10` | A ground one step down (around the preview, the ground of the timeline and the graph) |
| `Grey13` | Cards (the inspector's value cards), the ground of the ruler |
| `Grey15` | Input fields, the ground of things you press, the band of the ruler's ticks |
| `Grey20` | Divider lines, raised things, the ground under a hand |
| `Grey26` | Stronger lines, borders |
| `Grey38` | Ticks, the mark for unavailable |
| `Grey44` | Very quiet text |
| `Grey56` | Quiet text (small heading letters, units, descriptions) |
| `Grey63` `Grey76` | Slightly quiet text, marks |
| `Grey91` | Text (a little restrained) |
| `Grey95` | Text (= Foreground) |
| `Grey100` | The strongest text |

### Timeline
| Name | Where in the app |
|---|---|
| `BandA` `BandB` | The stripes of rows (alternating) |
| `RowLine` | The line between rows |
| `Clip1` `Clip2` `Clip3` `Clip4` `Clip5` `Clip6` `Clip7` | The colour of a layer kind: 1 shape, 2 text, 3 image or video, 4 camera, 5 group, 6 particles, 7 audio. Besides the timeline's bars, they are used for the cards and marks of that kind (the "Camera" card of the Camera panel uses 4, and so do the marks of the create shelf). A bar that is not selected is drawn with this colour moved a little toward the ground. Text on a bar is `ControlOnForeground` |
| `Label1` `Label2` `Label3` `Label4` `Label5` `Label6` `Label7` `Label8` `Label9` `Label10` `Label11` `Label12` `Label13` `Label14` `Label15` `Label16` | The sixteen label colours of layers. A layer's row, its dot on the Relations map, its frame in the preview and its name in lists use one of them |
| `ElementMark` | The mark of an element's intro end and outro start: a small triangle on the ruler of the selected group (Alight Motion's yellow mark) |
| `Keyframe` | The mark of a keyframe |

### Accent
| Name | Where in the app |
|---|---|
| `ChosenDefault` | The accent: what is selected, what is pressed, the fill of Render and Edit |
| `ControlOnForeground` | Text and marks on an accent fill (the letters of Render and Edit) |
| `ChosenInk` | The colour for using the accent as a line or text on a ground (if you leave it out, a light skin automatically darkens it until it can be read) |

### Others
| Name | Where in the app |
|---|---|
| `Alert` | The red dot of a notice (top bar) |
| `Shadow` | The shadow of floating things (an open list of choices, a card being held) |
| `ToneLayer` `ToneBlend` `TonePlace` `ToneTextAnim` `ToneTime` `ToneLayout` | The colour of the mark of each kind of inspector card (layer, blend, place, text animation, time, layout) |

## Numbers
`Corner` `Size` `Spacing` `TextScale`
(Each is "how many times the usual". Corner = how round corners are, 0 to 10; Size = the size of parts, 0.85 to 1.5; Spacing = margins and gaps, 0 to 2; TextScale = the size of text, 0.85 to 1.3. Outside the range it is pulled to the end.)

## Words
`FontMono` `FontSans` `Forms` `Parts` `Shade`

- Forms: the name of how parts are put together (own = the usual, poster = poster style, lighttable = film on a light table, sheet = ink lines on paper). The code is `lib/widgets/forms/<name>_forms.dart` (see "Forms" in the README)
- Shade: `light` or `dark`. Not needed if you write Background
- FontSans / FontMono: the name of a font. Write the file's location in `FontSansFile` / `FontMonoFile` and the file is loaded under that name
- Parts: the folder of icon pictures (the names are in PARTS.md). The location may be relative to theme.xml, `~/`, or absolute

## What a skin does not change
- The inside of the preview (including the dark area outside its frame): it is the work's own picture. The area outside the frame shows the work's world continued, darkened
- The colours of the project's contents (layer colours, palettes, the sample pictures of blends)
