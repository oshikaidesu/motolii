#!/usr/bin/env python3
"""Checks the imports in app/lib against the layering map in app/README.md.

Each folder of app/lib may import only the folders its row of MAY_IMPORT names,
so dependencies run one way: from the panes of the window down to the engine
bridge. The imports that break the map today are listed in layer_debt.txt beside
this script. The check fails on a forbidden import the ledger does not list, and
on a ledger line whose import is gone.

    python3 app/tool/check_layers.py            check the tree
    python3 app/tool/check_layers.py --write    rewrite the ledger from the tree

Flutter checks its own layers the same way (dev/bots/analyze.dart).
"""

import argparse
import pathlib
import posixpath
import re
import sys

TOOL = pathlib.Path(__file__).resolve().parent
LIB = TOOL.parent / 'lib'
LEDGER = TOOL / 'layer_debt.txt'
PACKAGE = 'package:motolii/'

# What each folder of lib/ may import besides itself, as paths from lib/. A name
# ending in .dart is that one file; None is anything. A row covers its
# subfolders, except 'workspace': that row is only the files directly in it (the
# shell), so every folder under workspace/ needs a row of its own.
_STATE = ['bridge', 'storage', 'skin', 'widgets/glyph.dart', 'workspace/easing']
_EDITS = _STATE + ['workspace/state']
_COMMANDS = _EDITS + ['widgets', 'workspace/edits']
_SHELF = _COMMANDS + ['skin/forms', 'workspace/commands']
_INSPECTOR_FEED = _SHELF + ['inspector', 'workspace/shelf']
_PANE = _INSPECTOR_FEED + ['workspace/inspector_feed']
MAY_IMPORT = {
    'bridge': [],
    'storage': [],
    'skin': ['bridge/engine_paths.dart', 'storage'],
    'widgets': ['skin'],
    'skin/forms': ['skin', 'widgets'],
    'inspector': ['skin', 'skin/forms', 'widgets'],
    'workspace/easing': ['bridge'],
    'workspace/state': _STATE,
    'workspace/edits': _EDITS,
    'workspace/commands': _COMMANDS,
    'workspace/shelf': _SHELF,
    'workspace/inspector_feed': _INSPECTOR_FEED,
    'workspace/dock': _PANE,
    'workspace/stage': _PANE,
    'workspace/timeline': _PANE,
    'workspace/tool_panel': _PANE,
    'workspace/top_bar': _PANE,
    'workspace/window': _PANE,
    'workspace': None,
    'panel.dart': None,
    'main.dart': ['bridge', 'workspace'],
}

DIRECTIVE = re.compile(r'''^(?:import|export)\s+(['"])(.+?)\1''', re.MULTILINE)
LEDGER_HEAD = '''\
# Imports in app/lib that the layering map in app/README.md forbids today.
# One per line, importer -> imported, as paths from app/lib. Written by
# `python3 app/tool/check_layers.py --write`. It should only get shorter.
'''


def layer_of(path):
    """Returns the row of MAY_IMPORT a file of lib/ belongs to, or None."""
    folder = posixpath.dirname(path)
    if not folder:
        return path if path in MAY_IMPORT else None
    if folder == 'workspace':
        return folder
    while folder and (folder == 'workspace' or folder not in MAY_IMPORT):
        folder = posixpath.dirname(folder)
    return folder or None


def imports_of(path):
    """Yields the files of lib/ that a Dart file imports or exports."""
    text = (LIB / path).read_text(encoding='utf-8')
    folder = posixpath.dirname(path)
    for match in DIRECTIVE.finditer(text):
        uri = match.group(2)
        if uri.startswith(PACKAGE):
            yield uri[len(PACKAGE):]
        elif ':' not in uri:
            yield posixpath.normpath(posixpath.join(folder, uri))


def allowed(importer, imported):
    """Says whether the map lets one file of lib/ import another."""
    row = layer_of(importer)
    may = MAY_IMPORT[row]
    if may is None:
        return True
    return layer_of(imported) in [row, *may] or imported in may


def forbidden_imports():
    """Returns the forbidden imports in lib/ and the files no row covers."""
    edges, unmapped = set(), []
    for file in sorted(LIB.rglob('*.dart')):
        path = file.relative_to(LIB).as_posix()
        if layer_of(path) is None:
            unmapped.append(path)
            continue
        for imported in imports_of(path):
            if not allowed(path, imported):
                edges.add(f'{path} -> {imported}')
    return edges, unmapped


def read_ledger():
    """Returns the imports layer_debt.txt lists."""
    if not LEDGER.exists():
        return set()
    lines = LEDGER.read_text(encoding='utf-8').splitlines()
    return {line for line in lines if line and not line.startswith('#')}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--write', action='store_true',
                        help='rewrite layer_debt.txt from the tree')
    args = parser.parse_args()

    found, unmapped = forbidden_imports()
    for path in unmapped:
        print(f'lib/{path}: no row of the layering map covers its folder; '
              'add one to MAY_IMPORT and to app/README.md')
    if args.write:
        lines = ''.join(f'{edge}\n' for edge in sorted(found))
        LEDGER.write_text(LEDGER_HEAD + lines, encoding='utf-8')
        print(f'{LEDGER.name}: {len(found)} forbidden imports written')
        return 1 if unmapped else 0

    listed = read_ledger()
    for edge in sorted(found - listed):
        importer, imported = edge.split(' -> ')
        print(f'lib/{importer} imports lib/{imported}, which the row of '
              f'{layer_of(importer)} does not allow (app/README.md)')
    for edge in sorted(listed - found):
        print(f'{LEDGER.name} lists an import that is gone: {edge}; '
              'run this with --write')
    if unmapped or found != listed:
        return 1
    print(f'layers ok: {len(found)} forbidden imports, '
          f'all listed in {LEDGER.name}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
