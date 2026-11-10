#!/usr/bin/env python3
# What the linker would say about the library, found without linking. Nothing is built.
#
# 1. The dry link. clang++ -fsyntax-only reads entry/motolii.mm once more with every function and global variable of
#    ours given internal linkage (#pragma clang attribute push: clang.llvm.org/docs/LanguageExtensions.html
#    #specifying-an-attribute-for-multiple-declarations-pragma-clang-attribute). -Wundefined-internal then names each
#    one the unit uses and never defines: what the link has to find in another input (script.cpp, isf.o, the interop).
#    A name that tools/link_expected.txt does not list is declared and called and defined nowhere: the link error a
#    syntax check cannot see.
#    Others' headers must keep their own linkage, so each one our files include is read before the pragma (taken from
#    clang's -H tree). The ones in LATE cannot be read early; a name declared in another's file is never reported.
# 2. Global objects. -Wglobal-constructors names each namespace-scope object of ours that runs code before main or at
#    exit. Across translation units that order is undefined, so this list may shrink and never grow: a new one is a
#    function-local static instead.
# 3. One unit each. Every .cpp and .mm of ours is read by exactly one unit of the build (tools/files_in_build.sh
#    --units, then clang++ -MM): compiled by itself or #included by the library's unit, never both, never neither.
#
#   python3 engine/tools/check_link.py           "ok" after three lines of counts, or what differs and exit status 1
#   python3 engine/tools/check_link.py --write   link_expected.txt written again when names only moved or went away
import json, os, re, subprocess, sys

ROOT = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))
os.chdir(ROOT)
UNIT = 'entry/motolii.mm'
EXPECTED = 'tools/link_expected.txt'
# (read after a macro of ours, inside extern "C", inside a namespace: the three places a header cannot be read twice)
LATE = ('stb_truetype.h', 'curve_fit_nd.h', 'godot_easing/easing_equations.h')
PRAGMA = '#pragma clang attribute push (__attribute__((internal_linkage)), apply_to = any(function, variable(is_global)))\n'
SAID = re.compile(r"^(.+?):(\d+):(\d+): warning: (?:(?:function|variable) '([^']+)' has internal linkage but is not defined"
                  r"|declaration requires a (global (?:con|de)structor))", re.M)

if not os.path.exists('compile_commands.json'):
    sys.exit('check_link.py: no compile_commands.json: run ./engine/tools/compile_commands.sh once')
COMMANDS = {u['file']: [a for a in u['arguments'][1:] if a not in ('-c', u['file'])] for u in json.load(open('compile_commands.json'))}


def run(*command, **more):
    return subprocess.run(command, capture_output=True, text=True, **more)


def rel(path):
    return os.path.relpath(os.path.realpath(path), ROOT)


def ours(path):   # (in this engine/, and neither fetched nor built)
    return not path.startswith(('..', 'third_party/', 'out/'))


def dry_link():
    flags = ['-x', 'objective-c++', *COMMANDS[UNIT]]
    chain, early = [UNIT], []
    for line in run('clang++', '-E', '-H', '-Wno-everything', *flags, UNIT, '-o', os.devnull).stderr.splitlines():
        m = re.match(r'(\.+) (.+)', line)
        if not m: continue
        chain = chain[:len(m.group(1))] + [m.group(2)]
        if ours(rel(chain[-2])) and not ours(rel(chain[-1])) and chain[-1] not in early and not chain[-1].endswith(LATE):
            early.append(chain[-1])
    # (#import and not #include: Apple's framework headers have no include guard)
    stub = ''.join(f'#import "{os.path.abspath(h)}"\n' for h in early) + PRAGMA + f'#include "{UNIT}"\n#pragma clang attribute pop\n'
    said = run('clang++', '-fsyntax-only', '-Wno-everything', '-Wundefined-internal', '-Wglobal-constructors', *flags, '-', input=stub)
    if said.returncode:
        sys.exit(said.stderr + f'check_link.py: the dry link of {UNIT} does not compile. If ./engine/check_syntax.sh passes, a header of '
                 "another's is now read after a macro or inside a block: add it to LATE in tools/check_link.py")
    found = set()
    for path, line, column, name, kind in SAID.findall(said.stderr):
        path = rel(path)
        if not ours(path): continue
        if kind: name = re.match(r'\w+', open(path).read().splitlines()[int(line) - 1][int(column) - 1:]).group()
        found.add((kind or 'undefined', name, path))
    return found


def one_unit_each():
    units = run('./tools/files_in_build.sh', '--units').stdout.split()
    readers = {f: [] for f in run('git', 'ls-files', '-co', '--exclude-standard', '*.cpp', '*.mm').stdout.split() if ours(f)}
    for unit in units:
        read = run('clang++', '-MM', '-MG', '-Wno-everything', *COMMANDS.get(unit, COMMANDS[UNIT]), unit).stdout
        for f in {rel(f) for f in read.replace('\\\n', ' ').split()[1:]} & readers.keys():
            readers[f].append(unit)
    return len(units), {f: r for f, r in readers.items() if len(r) != 1}


found = dry_link()
lines = open(EXPECTED).read().splitlines()
expected = {tuple(line.split('\t')) for line in lines if line and not line.startswith('#')}
new_names = {f[:2] for f in found} - {e[:2] for e in expected}
if '--write' in sys.argv[1:] and not (new_names and expected):
    open(EXPECTED, 'w').write('\n'.join([line for line in lines if line.startswith('#')] + ['\t'.join(f) for f in sorted(found)]) + '\n')
    expected = found
bad = [f'not in engine/{EXPECTED}: ' + '  '.join(f) for f in sorted(found - expected)]
bad += ['no longer said by clang: ' + '  '.join(e) for e in sorted(expected - found)]
if any(kind == 'undefined' for kind, _ in new_names):
    bad.append(f'A new "undefined" name is used in {UNIT} and defined nowhere in it: the link fails. Define it, or #include the .cpp '
               f'that does. Only if another link input defines it, add its line to engine/{EXPECTED} by hand.')
if any(kind != 'undefined' for kind, _ in new_names):
    bad.append('A new global object: make it a function-local static (its constructor then runs at first use, in a known order).')
if bad and not new_names:
    bad.append(f'Names only moved to another file or went away: python3 engine/tools/check_link.py --write, and commit engine/{EXPECTED}.')
units, wrong = one_unit_each()
bad += [f'{f}: read by {len(r)} units of the build ({", ".join(r) or "none"}), not by exactly one. A .cpp is either named by a build '
        f'script or #included by {UNIT}, not both.' for f, r in sorted(wrong.items())]
print(f'dry link of {UNIT}: {sum(f[0] == "undefined" for f in found)} names left to the other link inputs')
print(f'global objects with a constructor or destructor: {sum(f[0] != "undefined" for f in found)}')
print(f'units of the build: {units}; .cpp and .mm of ours read by exactly one of them: all' + (f' but {len(wrong)}' if wrong else ''))
sys.exit('\n'.join(bad) if bad else print('ok'))
