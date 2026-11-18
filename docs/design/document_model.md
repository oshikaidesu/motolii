# Document model

The document is a table of keyframes: `(layer, name, at, value)`. A property
with one keyframe is constant; with several it interpolates. Each API call
makes one change (one undo step), and the canvas shows the change before the
call returns. A change the canvas cannot show is not made.

## Easing

A keyframe's easing defines the curve from it to the next. The built-in kinds
are in `easing_curves.h`. A custom easing is an SQLite expression whose
variables are:

| var | meaning |
|-----|---------|
| `u` | progress 0→1 |
| `t` | seconds since segment start |
| `d` | segment length in seconds |
| `a`, `b` | values of the two keyframes |
| `p1`–`p4` | supplied numbers |

A custom easing is accepted only if it evaluates to `a` at `u=0` and `b` at
`u=1`.

## Storage and undo

SQLite is both the file format and the undo engine. A change is in the file
when its call returns. Undo uses the session extension: each change is a
changeset, and undo applies it inverted. Undo steps are stored in the file.

## Naming

Property names follow ThorVG where it has a name for the same thing (x, y,
rotate, size, blend, text, fill, begin). Time uses GES names (start, duration).
