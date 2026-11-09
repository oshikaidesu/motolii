#!/usr/bin/env python3
# One rule for every Inspector card: a card is what the engine declares (engine/document/card_table.h, sent by
# motolii_cards, written as a WGSL uniform struct by app/lib/workspace/workspace_cards.dart) and drawn by the one
# ValuesCard (app/lib/inspector/inspector_card.dart), as an effect is. A card drawn by hand next to it is a second
# path: its values named in Dart, its ranges made up (AGENTS.md principles 2 and 3). This refuses that second path.
#   card_check.py              what is staged (the index): the pre-commit hook
#   card_check.py --all        the commit checked out (HEAD): CI, .github/workflows/checks.yml
#   card_check.py --rev REV    another commit (`--rev main`: what main still holds)
# rule 1: a value's key written as a string in Dart ('v_shadow_distance'), anywhere in app/lib
# rule 2: a value's bare name written as a string in Dart ('intensity'), in app/lib/inspector
import re, subprocess, sys

TABLE = 'engine/document/card_table.h'
CARD = re.compile(r'\{\s*"([^"]+)",\s*"([^"]*)"')   # (with or without the space clang-format puts after the brace)   # {"Drop Shadow", "shadow shadow_distance ...", ...}
# The words of the declaration's own form, not values: the @unit words workspace_cards.dart writes for a value that is
# not a number ('numbers', 'colours', 'words', 'file'), and the sub-fields of a point or a size (param_infer.dart).
FORM_WORDS = {'numbers', 'colours', 'words', 'file', 'x', 'y', 'z'}
# Files that may hold value names because they read declarations, they do not write cards. One line each, with why.
READERS = {
    # the word lists that guess a field's control from its name, for any effect's struct (ISF and Shadertoy names
    # alike): the effects' path itself, the one every card now goes through
    'app/lib/inspector/controls/param_infer.dart',
}
# Debt: a value name a host still reads by hand, not a card. (path, the string, why); the line goes once it is moved.
OWED = {
    # the host turns a Speed change into time_stretch round the playhead (After Effects' Time Stretch); the engine's
    # own say of `speed` should do that, then this goes
    ('app/lib/workspace/inspector_feed/values.dart', 'v_speed'),
}
COMMENT = re.compile(r'//[^\n]*|/\*.*?\*/', re.S)
STRING = re.compile(r"""r?'((?:[^'\\\n]|\\.)*)'|r?"((?:[^"\\\n]|\\.)*)\"""")
SAY = 'declare it like an effect; the inspector reads it'


def git(*a, data=None):
    return subprocess.run(['git', *a], input=data, capture_output=True).stdout


if sys.argv[1:2] == ['--all']:
    rev = 'HEAD'
elif sys.argv[1:2] == ['--rev'] and len(sys.argv) > 2:
    rev = sys.argv[2]
else:
    rev = ''   # the index
listing = git('ls-tree', '-r', '--name-only', '-z', rev) if rev else git('ls-files', '--cached', '-z')
files = [p for p in listing.decode().split('\0') if p.startswith('app/lib/') and p.endswith('.dart')]


def read(paths):
    """Each path's text at `rev` (or in the index), by one `git cat-file --batch`."""
    out = git('cat-file', '--batch', data=''.join(f'{rev}:{p}\n' for p in paths).encode())
    texts, at = {}, 0
    for p in paths:
        head_end = out.index(b'\n', at)
        head = out[at:head_end].split()
        if head[-1] == b'missing':
            at = head_end + 1
            continue
        size = int(head[2])
        texts[p] = out[head_end + 1:head_end + 1 + size].decode('utf-8', 'replace')
        at = head_end + 1 + size + 1
    return texts


texts = read([TABLE] + files)
names = {n for _, said in CARD.findall(texts.get(TABLE, '')) for n in said.split()}
if not names:
    print(f'card check: {TABLE} has no cards at {rev or "the index"}; nothing to check against', file=sys.stderr)
    sys.exit(0)

bad = []
for p in files:
    if p not in texts:
        continue
    code = COMMENT.sub(lambda m: '\n' * m.group(0).count('\n'), texts[p])   # (comments may name values; lines kept)
    line = lambda at: code.count('\n', 0, at) + 1
    for m in STRING.finditer(code):
        word = m.group(1) if m.group(1) is not None else m.group(2)
        if (p, word) in OWED:
            continue
        if word.startswith('v_') and word[2:] in names:
            bad.append(f"rule 1: {p}:{line(m.start())}: '{word}' is a value's key written in Dart; {SAY}")
        elif p.startswith('app/lib/inspector/') and p not in READERS and word in names and word not in FORM_WORDS:
            bad.append(f"rule 2: {p}:{line(m.start())}: '{word}' is a value's name written in Dart; {SAY}")

if bad:
    print('card check refused this commit (rule: one card rule, .githooks/README.md):\n  ' + '\n  '.join(bad), file=sys.stderr)
    sys.exit(1)
