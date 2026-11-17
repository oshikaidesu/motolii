# Each letter moving on its own (the shelf's fade_in.js), drawn at eight moments: a split text of N letters (strips of
# one picture, as today) against N copies of one letter's outline as a path shape (meshes). The shell's own times.
#   python3 speed_moving.py <letters>
import re, subprocess, sys, time
sys.argv = [sys.argv[0], sys.argv[1] if len(sys.argv) > 1 else '300']
exec(open('/Users/member_ottoto/motolii/docs/internal/text_path/speed.py').read().split("path, wide, rows, contours = path_of(words)")[0])
JS = '/Users/member_ottoto/motolii/shelves/expressions/fade_in.js'
one, _, _, _ = path_of('O')
moments = ''.join(f'at {0.2 + 0.11 * i:.2f}\nstill {HERE}/moving.png\n' for i in range(8))
cases = {
    'split text, each letter fading in (strips of a picture)':
        f'add text {FONT}\nset 1 size 0.02\nsay 1 text {words}\nsay 1 split letters\nlater fx_file 1 {JS}\n' + moments,
    'copies of one outline, each fading in (meshes)':
        f'add shape path\nset 1 size 0.02\nsay 1 fill 7f7f7f\nsay 1 path {one}\nset 1 copies {N}\nlater fx_file 1 {JS}\n' + moments,
    'nothing on the stage':
        moments,
}
for name, calls in cases.items():
    times, bad = run(re.sub(r'\W+', '_', name), calls)
    st = sorted(t for c, t in times if c == 'still')
    print(f'  {N} letters, {name}: {"FAILED " + str(bad[:1]) if bad else ""} median still {st[len(st) // 2]:.1f} ms, slowest {st[-1]:.1f}')
