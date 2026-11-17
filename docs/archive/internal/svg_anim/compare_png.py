# Motolii's still of a spinner layer against Chrome's picture of the same time: both made masks of drawn (dark, opaque)
# pixels; Motolii's square (the layer, found as the given box) scaled to Chrome's 480 px; IoU of the two masks.
#   python3 compare_png.py <motolii.png> <chrome.png> x y side
import sys
from PIL import Image
m, c = Image.open(sys.argv[1]).convert('RGBA'), Image.open(sys.argv[2]).convert('RGBA')
x, y, side = (int(v) for v in sys.argv[3:6])
m = m.crop((x, y, x + side, y + side)).resize(c.size, Image.BILINEAR)
ink = lambda p: p[3] > 128 and sum(p[:3]) < 3 * 128
a, b = [ink(p) for p in m.getdata()], [ink(p) for p in c.getdata()]
both, either = sum(p and q for p, q in zip(a, b)), sum(p or q for p, q in zip(a, b))
print(f'IoU {both / max(1, either):.3f}')
