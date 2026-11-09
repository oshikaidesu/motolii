#!/bin/zsh
# Which of our files the build reads, as the compiler says it and not as anyone remembers it: the build scripts are
# edit.sh and gpu/build.sh and every script of ours they call, on and on (gpu/build.sh adds gpu/CMakeLists.txt to
# Filament's build: MOTOLII_PROBE_DIR); each .cpp/.mm of ours one names is a unit, and clang++ -MM (clang.llvm.org/docs/
# ClangCommandLineReference.html#dependency-file-generation) lists every header it reads, with the flags of
# compile_commands.json (deps/compile_commands.sh writes it when missing). Nothing is built; no lock.
#   ./deps/files_in_build.sh           the list, by folder, as markdown
#   ./deps/files_in_build.sh --write   that list put into README.md between its two "files_in_build.sh" marks
cd "$(dirname "$0")/.."
[ -f compile_commands.json ] || ./deps/compile_commands.sh > /dev/null || exit 1
python3 - "$1" <<'PY'
import json, os, re, subprocess, sys
from collections import defaultdict
own = set(subprocess.run(['git', 'ls-files'], capture_output=True, text=True).stdout.split())
own = {f for f in own if not f.startswith('third_party/')}
def said(path):   # (a script's lines, its comments left out)
    return '\n'.join(l.split(' #')[0] for l in open(path).read().splitlines() if not l.lstrip().startswith('#'))
def names(text, f):
    return re.search(r'(?<![\w/])(\./|\$PWD/)?' + re.escape(f) + r'(?![\w.])', text)
scripts, todo = [], ['edit.sh', 'gpu/build.sh']
while todo:
    s = todo.pop()
    if s in scripts: continue
    scripts.append(s)
    todo += [f for f in own if f.endswith('.sh') and names(said(s), f)]
    if 'MOTOLII_PROBE_DIR' in said(s): scripts.append('gpu/CMakeLists.txt')
named = '\n'.join(said(s) for s in scripts)
# (gpu/filament_webgpu.sh builds ${RENDER_SRC:-entry/$n.mm}, $n the name its caller gives it: `filament_webgpu.sh motolii`)
for src in re.findall(r'RENDER_SRC:-([\w/]+)\$n\.mm', named):
    named += ''.join(f'\n{src}{n}.mm' for n in re.findall(r'filament_webgpu\.sh (\w+)', named))
units = sorted(f for f in own if f.endswith(('.cpp', '.mm')) and (names(named, f) or
               f.startswith('gpu/') and re.search(r'(?<![\w/])' + re.escape(f[4:]) + r'(?![\w.])', said('gpu/CMakeLists.txt'))))
args = {u['file']: [a for a in u['arguments'][1:] if a not in ('-c', u['file'])] for u in json.load(open('compile_commands.json'))}
read = set()
for u in units:
    out = subprocess.run(['clang++', '-MM', '-MG', '-Wno-everything', *args.get(u, ['-std=c++20', '-I.']), u],
                         capture_output=True, text=True).stdout
    read |= {f for f in (os.path.relpath(os.path.normpath(f)) for f in out.replace('\\\n', ' ').split()[1:]) if f in own}
read |= set(units)
by = defaultdict(list)
for f in sorted(read):
    by[f.split('/')[0] if f.count('/') == 1 else '/'.join(f.split('/')[:2])].append(f.rsplit('/', 1)[1])
code = {f for f in own if f.endswith(('.h', '.cpp', '.mm'))}
lines = [f'{len(read)} files of ours ({len(units)} units and the headers they read), of the {len(code)} .h/.cpp/.mm'
         f' git keeps here outside third_party/. Scripts followed: ' + '、'.join(f'`{s}`' for s in sorted(scripts)) +
         '. Made by `./deps/files_in_build.sh --write`.', '']
lines += [f'- `{d}/` ({len(fs)}): ' + '、'.join(f'`{f}`' for f in fs) for d, fs in sorted(by.items())]
left = sorted(code - read)
if left:
    lines += ['', f'Not read by the build ({len(left)}): ' + '、'.join(f'`{f}`' for f in left)]
text = '\n'.join(lines)
if sys.argv[1] != '--write':
    print(text); sys.exit()
readme = open('README.md').read()
mark = re.compile(r'(<!-- files_in_build.sh -->\n).*?(<!-- /files_in_build.sh -->)', re.S)
if not mark.search(readme):
    sys.exit('README.md has no <!-- files_in_build.sh --> ... <!-- /files_in_build.sh --> marks')
open('README.md', 'w').write(mark.sub(lambda m: m.group(1) + text + '\n' + m.group(2), readme))
print(f'README.md: {len(read)} files')
PY
