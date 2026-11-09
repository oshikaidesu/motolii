#!/usr/bin/env python3
# A header of ours that is a part of another ("part of X.h, read only through X.h") cannot be read alone: it uses what
# the files before it in its translation unit said. clangd reads a header by itself, with a command borrowed from a
# source file near it (clangd.llvm.org/design/compile-commands), so such a part shows errors from its first line. Here
# each header gets its own entry in compile_commands.json: the flags of the first translation unit that includes it, and
# `-include out/clangd/<header>.ctx`, the text that unit reads before it (each includer up to the line that includes the
# next, from clang's own -H order). Nothing of ours is changed; out/ is not kept in git.
#   python3 deps/clangd_context.py   (deps/compile_commands.sh runs it, after it writes the units' entries)
import json, os, re, subprocess

root = os.getcwd()
units = json.load(open('compile_commands.json'))
units = [u for u in units if not u['file'].endswith('.h')]
units.sort(key=lambda u: u['file'] != 'library/motolii.mm')   # (the library's own unit first: most headers are its)
own = set(subprocess.run(['git', 'ls-files', '*.h'], capture_output=True, text=True).stdout.split())
own = {f for f in own if not f.startswith('third_party/')}
done, entries = set(), []


def rel(p):
    p = os.path.normpath(p if os.path.isabs(p) else os.path.join(root, p))
    return os.path.relpath(p, root)


def include_line(text, child):
    # the first line of `text` that includes `child` (as engine-rooted "a/b.h", or by its name alone)
    for n, line in enumerate(text.split('\n')):
        m = re.match(r'\s*#\s*include\s*"([^"]+)"', line)
        if m and (m.group(1) == child or os.path.basename(m.group(1)) == os.path.basename(child)):
            return n
    return None


for u in units:
    args = [a for a in u['arguments'][1:] if a not in ('-c', u['file'])]
    lang = ['-x', 'objective-c++'] if u['file'].endswith('.mm') else ['-x', 'c++']
    h = subprocess.run(['clang++', '-fsyntax-only', '-H', *lang, *args, u['file']], capture_output=True, text=True, cwd=root).stderr
    chain = [u['file']]   # (the includers of the line now read, outermost first)
    for line in h.split('\n'):
        m = re.match(r'^(\.+) (.+)$', line)
        if not m: continue
        depth, path = len(m.group(1)), rel(m.group(2))
        chain = chain[:depth] + [path]
        if path not in own or path in done: continue
        done.add(path)
        parts = []
        for outer, inner in zip(chain[:-1], chain[1:]):
            text = open(os.path.join(root, outer), encoding='utf-8', errors='replace').read()
            n = include_line(text, inner)
            if n is None: parts = None; break
            parts.append(f'#line 1 "{outer}"\n' + '\n'.join(text.split('\n')[:n]) + '\n')
        if parts is None: continue
        ctx = os.path.join('out', 'clangd', path + '.ctx')
        os.makedirs(os.path.dirname(ctx), exist_ok=True)
        open(ctx, 'w').write(''.join(parts))
        entries.append({'directory': root, 'file': path, 'arguments': ['clang++', *lang, *args, '-include', ctx, '-c', path]})

json.dump(json.load(open('compile_commands.json')) + entries, open('compile_commands.json', 'w'), indent=1)
print(f'clangd: {len(entries)} headers given the context of the unit that reads them (out/clangd/)')
