# The outline Motolii made of a text against the font's own outlines as fontTools reads them (an outside reader of the
# same .ttf): for each contour its width, height and area and where its middle lies across, each as a fraction of the
# whole text's width, height or area, so no scale has to be known. fontTools sets the glyphs by their advances and the
# font's kern table.   python3 against_fonttools.py <font.ttf> <text> <document.motolii> <layer>
import sys, sqlite3
from fontTools.ttLib import TTFont
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.areaPen import AreaPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import parse_path

def contours(rec):
    out, cur = [], []
    for op, args in rec.value:
        cur.append((op, args))
        if op in ('closePath', 'endPath'): out.append(cur); cur = []
    return out
def measure(cs, glyphset=None):
    rows = []
    for c in cs:
        b, a = BoundsPen(glyphset), AreaPen(glyphset)
        for pen in (b, a):
            r = RecordingPen(); r.value = c; r.replay(pen)
        x0, y0, x1, y1 = b.bounds
        rows.append((x0, y0, x1, y1, abs(a.value)))
    X0, Y0 = min(r[0] for r in rows), min(r[1] for r in rows); X1, Y1 = max(r[2] for r in rows), max(r[3] for r in rows)
    A = sum(r[4] for r in rows)
    return sorted((round(((r[0] + r[2]) / 2 - X0) / (X1 - X0), 4), round((r[2] - r[0]) / (X1 - X0), 4), round((r[3] - r[1]) / (Y1 - Y0), 4), round(r[4] / A, 4)) for r in rows)

font_file, text, doc, layer = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
font = TTFont(font_file); gs = font.getGlyphSet(); cmap = font.getBestCmap()
kern = {}
if 'kern' in font:
    for t in font['kern'].kernTables: kern.update(getattr(t, 'kernTable', {}))
rec, x, prev = RecordingPen(), 0, None
for ch in text:
    g = cmap[ord(ch)]
    if prev: x += kern.get((prev, g), 0)
    gs[g].draw(TransformPen(rec, (1, 0, 0, 1, x, 0)))
    x += font['hmtx'][g][0]; prev = g
theirs = measure(contours(rec), gs)
path = sqlite3.connect(doc).execute("select value from keyframe where layer = ? and name = 'path'", (layer,)).fetchone()[0]
ours_rec = RecordingPen(); parse_path(path, ours_rec)
ours = measure(contours(ours_rec))
print(len(ours), 'contours ours,', len(theirs), 'in the font; kern pairs in the font:', len(kern))
worst = 0
for o, t in zip(ours, theirs):
    d = max(abs(a - b) for a, b in zip(o, t)); worst = max(worst, d)
    if d > 0.002: print('  off:', o, t)
print('worst difference', round(worst, 5), '(fractions of the whole text)')
sys.exit(0 if len(ours) == len(theirs) and worst <= 0.002 else 1)
