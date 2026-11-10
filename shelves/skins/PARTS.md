# Names of the pictures a skin can replace

This is the reference for people who make a skin: the names of the app's icon pictures that a skin can replace. Write `<Parts Value="folder"/>` in `theme.xml`, and `name.svg` in that folder is drawn instead of the app's picture, repainted in the colour the app uses there.

The folder may be given relative to theme.xml, from `~/`, or as an absolute path. Only the shape of the SVG is used. A name you do not have stays the app's usual picture. For how to make a skin, see [README.md](README.md).

- The frame is `viewBox="0 0 24 24"`. The app draws it shrunk to about 12 to 22 pixels (it changes with `Size`), so a line weight of 1.5 to 2 in the 24 frame is just right.
- Both filled shapes and line-only shapes (`fill="none"` with `stroke`) are repainted. The colour is the colour of that place: usually the grey of text, and the accent (`ChosenInk`) while pressed or playing.
- An icon is drawn to fill the frame. To match the size of the usual icons, leave a margin of 2 to 3 inside the 24 frame.
- Only the icons the app shows now are listed here.

## Frames (frame.): the shape of a part itself
Unlike icons, a frame is drawn **in the colours you drew**, stretched around the part (the same as CSS border-image). The four corners are kept as drawn, and the sides and the middle stretch. Write the size of the corners as `data-slice="9"` on the outermost tag of the SVG (if you do not, it is one third of the shorter side). A part that has a frame does not draw its usual fill and corners.

| Name | Part |
|---|---|
| `frame.render` | The Render button in the top bar (`frame.render.hover`: when a hand is over it) |
| `frame.card` | One card of the inspector (the header band is included: the header is about 26 high from the top) |

The sample is [streets](./streets/parts) (Render as a black box with a thick white border, and cards with a blue header band).

## Tools (glyph.): the vertical column of tools to the left of the preview
| Name | Icon |
|---|---|
| `glyph.select` | Select (arrow) |
| `glyph.move` | Move (cross arrows) |
| `glyph.rect` `glyph.ellipse` `glyph.shape` | Draw a rectangle, an ellipse, a shape |
| `glyph.pen` | Pen |
| `glyph.text` | Text |
| `glyph.brush` | Brush (freehand) |
| `glyph.image` `glyph.media` `glyph.camera` `glyph.grid` | Image, media, camera, grid |

## Timeline (tp.): the band above the timeline, and the layer rows
| Name | Icon |
|---|---|
| `tp.play` `tp.pause` | Play, pause |
| `tp.toStart` `tp.stepBack` `tp.stepFwd` | To the start, back one frame, forward one frame |
| `tp.loop` | Loop |
| `tp.fit` `tp.plus` `tp.minus` | Fit everything, widen the time, narrow the time |
| `tp.eye` `tp.eyeOff` | A layer row's "visible, not visible" |
| `tp.solo` | A layer row's "show only this" |
| `tp.lock` `tp.unlock` | A layer row's "cannot be touched, can be touched" |
| `tp.caretR` `tp.caretD` | The triangle of a layer row: closed, open |

## Dock (dock.): the icons of panel headers, and of the create shelf and the effects shelf (the name is the content: `dock.media` is the Media panel, `dock.star` makes a star shape)
`dock.media` `dock.effects` `dock.fonts` `dock.colors` `dock.create` `dock.program` `dock.search` `dock.close` `dock.reload` `dock.chevron` `dock.grid` `dock.list` `dock.particles` `dock.plus` `dock.light` `dock.copies` `dock.text` `dock.time` `dock.shape` `dock.camera` `dock.nullObj` `dock.rect` `dock.ellipse` `dock.polygon` `dock.star` `dock.line` `dock.radial` `dock.folder` `dock.files` `dock.comp` `dock.image` `dock.audio` `dock.video` `dock.font` `dock.link` `dock.stage` `dock.inspector` `dock.timeline` `dock.toolPanel` `dock.more`

## Tool panel tools (dock.)
`dock.tools` `dock.blend` `dock.align`

## Others
`undo` (redo uses the same picture flipped), `shade` (the light and dark switch), `stage.safe`, `stage.grid`, `stage.snap` (keep the current picture), `stage.show` (look at the kept picture)
