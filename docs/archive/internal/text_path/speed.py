# How long the engine takes to draw N letters as a text (a picture, as today) and as a path shape made of the same
# letters' outlines (the shape route), with nothing added to the engine: the path is written here from the font by
# fontTools, as cubic curves, and said to a path shape. Times are the shell's own ("still: done, X ms").
#   python3 speed.py <letters>
import re, subprocess, sys, time
from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen

FONT = '/Users/member_ottoto/motolii/engine/third_party/filament_src/assets/fonts/Roboto-Medium.ttf'
HERE = '/Users/member_ottoto/motolii/docs/internal/text_path'
ENGINE = '/Users/member_ottoto/motolii/engine/out/filament_webgpu'
N = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
PER_ROW = 50
words = ('Thequickbrownfoxjumpsoverthelazydog' * (N // 35 + 1))[:N]

font = TTFont(FONT); gs = font.getGlyphSet(); cmap = font.getBestCmap(); upm = font['head'].unitsPerEm
hhea = font['hhea']; line = (hhea.ascent - hhea.descent) / upm   # one line's height in ems

class Svg(BasePen):          # (BasePen turns the font's quadratic curves into cubics: _qCurveToOne)
    def __init__(self, glyphset, dx, dy, k):
        super().__init__(glyphset); self.d, self.dx, self.dy, self.k = [], dx, dy, k
    def at(self, p): return '%.5f %.5f' % ((p[0] + self.dx) * self.k, (self.dy - p[1]) * self.k)   # y down
    def _moveTo(self, p): self.d.append('M' + self.at(p))
    def _lineTo(self, p): self.d.append('L' + self.at(p))
    def _curveToOne(self, a, b, c): self.d.append('C' + ' '.join(map(self.at, (a, b, c))))
    def _closePath(self): self.d.append('Z')

def path_of(text):
    rows = [text[i:i + PER_ROW] for i in range(0, len(text), PER_ROW)]
    k = 1 / (upm * line)                       # one line is 1 high, as a text's size is
    width = max(sum(font['hmtx'][cmap[ord(c)]][0] for c in r) for r in rows)
    parts, contours = [], 0
    for j, r in enumerate(rows):
        x = -width / 2
        for c in r:
            g = cmap[ord(c)]
            pen = Svg(gs, x, (j - (len(rows) - 1) / 2) * upm * line, k); gs[g].draw(pen)
            parts += pen.d; contours += sum(1 for s in pen.d if s[0] == 'M'); x += font['hmtx'][g][0]
    return ' '.join(parts), width * k, len(rows), contours

def run(name, calls):
    doc = f'{HERE}/speed_{name}_{int(time.time() * 1000)}.motolii'
    out = subprocess.run(['../edit_wgpu', doc], input=calls, capture_output=True, text=True, cwd=ENGINE,
                         env={'BACKEND': 'webgpu', 'SIZE': '1920x1080', 'PATH': '/usr/bin:/bin', 'HOME': '/Users/member_ottoto'}).stdout
    bad = [l for l in out.splitlines() if 'NOT done' in l or 'not a call' in l]
    return [(m.group(1), float(m.group(2))) for m in re.finditer(r'^(\w+): done, ([0-9.]+) ms', out, re.M)], bad

path, wide, rows, contours = path_of(words)
size = 0.9 / rows
stills = lambda tag: ''.join(f'still {HERE}/speed_{tag}.png\n' for _ in range(4))
cases = {
    'text (a picture, today)':
        f'add text {FONT}\nsay 1 wrap character\nset 1 wrap_at {wide:.3f}\nset 1 size {size:.4f}\nsay 1 text {words}\n' + stills('text')
        + f'set 1 x 0.05\n' + stills('text') + f'say 1 text {words[1:] + "X"}\n' + stills('text'),
    'path shape, filled (mesh)':
        f'add shape path\nset 1 size {size:.4f}\nset 1 wide {wide:.3f}\nsay 1 fill 7f7f7f\nsay 1 path {path}\n' + stills('path')
        + f'set 1 x 0.05\n' + stills('path') + f'say 1 path {path} M0 0 L0.001 0 L0 0.001 Z\n' + stills('path'),
    'path shape, stroke only (ThorVG image)':
        f'add shape path\nset 1 size {size:.4f}\nset 1 wide {wide:.3f}\nsay 1 fill none\nsay 1 stroke ffffff\nset 1 stroke_width 4\nsay 1 path {path}\n' + stills('stroke')
        + f'set 1 x 0.05\n' + stills('stroke') + f'say 1 path {path} M0 0 L0.001 0 L0 0.001 Z\n' + stills('stroke'),
}
print(f'{N} letters in {rows} rows, {contours} contours, path data {len(path) // 1024} KB')
for name, calls in cases.items():
    times, bad = run(re.sub(r'\W+', '_', name), calls)
    st = [t for c, t in times if c == 'still']
    said = [t for c, t in times if c in ('say', 'set')]
    if bad or len(st) != 12: print(f'  {name}: FAILED {bad[:2]} ({len(st)} stills)'); continue
    print(f'  {name}: first picture {st[0]:.1f} ms; then {min(st[1:4]):.1f}; after a move {st[4]:.1f}, then {min(st[5:8]):.1f};'
          f' after the letters change {st[8]:.1f} (the change itself {said[-1]:.1f}), then {min(st[9:12]):.1f}')
