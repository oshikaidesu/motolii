#!/usr/bin/env python3
# Every definition of ours at namespace scope, so that a step which only moves code can show it changed none.
# One line each, tab-separated: kind, name, file, linkage, and a hash of the body with its comments taken out.
#   function      linkage static, inline, template or external; the hash is of the body alone
#   type          a struct, class, union or enum with a body, a typedef, a using alias
#   variable      linkage static, const (the object itself), inline or external; the hash leaves the first words
#                 static, inline, extern, const and constexpr out, which change what compiles and not what runs
#   macro         a #define (an include guard is not listed)
#   declaration   a prototype or an extern variable: a name said here and defined elsewhere
# The parser is not ours: ast-grep (tree-sitter's C++ grammar) with the project file .githooks/sgconfig.yml, which
# reads .h and .mm as C++. Nothing is compiled, so a commit can be read as well as the checkout.
#
#   python3 engine/tools/function_census.py                 the census, then "#" lines of counts
#   python3 engine/tools/function_census.py --diff HEAD     the checkout against that commit. Listed and passed: a
#       definition in another file, another linkage, default arguments now in a declaration. Listed and failed (exit
#       status 1): a body or a signature that changed, a definition gone, a new one, a name newly defined twice
#   python3 engine/tools/function_census.py --diff HEAD --renames map.txt
#       the same after each "old<TAB>new" line of map.txt is applied to the commit's text: a declared rename
import hashlib, json, os, re, subprocess, sys, tempfile
from collections import Counter, defaultdict, namedtuple

ROOT = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))
CONFIG = os.path.join(os.path.dirname(ROOT), '.githooks', 'sgconfig.yml')
Item = namedtuple('Item', 'kind name file linkage line signature hash')

# (at namespace scope: in no function body and no class body)
OUTSIDE = 'not: {inside: {any: [{kind: compound_statement}, {kind: field_declaration_list}], stopBy: end}}'
RULES = {
    'function': 'kind: function_definition\n' + OUTSIDE,
    'body': 'kind: compound_statement\ninside: {kind: function_definition, field: body}',
    'name': 'any: [{kind: identifier}, {kind: qualified_identifier}, {kind: field_identifier}, {kind: operator_name}, {kind: destructor_name},'
            ' {kind: template_function}]\ninside: {kind: function_declarator, field: declarator}',
    'template': 'kind: template_declaration\n' + OUTSIDE,
    'type': 'any: [{kind: struct_specifier}, {kind: class_specifier}, {kind: union_specifier}, {kind: enum_specifier}]\n'
            'has: {field: body, any: [{kind: field_declaration_list}, {kind: enumerator_list}]}\n'
            'not: {inside: {any: [{kind: compound_statement}, {kind: field_declaration_list}, {kind: declaration}, {kind: type_definition},'
            ' {kind: function_definition}, {kind: alias_declaration}], stopBy: end}}',
    'alias': 'any: [{kind: type_definition}, {kind: alias_declaration}]\n' + OUTSIDE,
    'declaration': 'kind: declaration\n' + OUTSIDE,
    # (a declaration whose declarator is a function's, not a pointer to one: `void (*hook)(int);` is a variable)
    'prototype': 'kind: declaration\nhas:\n  field: declarator\n  any:\n'
                 '    - {kind: function_declarator, not: {has: {field: declarator, kind: parenthesized_declarator}}}\n'
                 '    - {kind: pointer_declarator, has: {kind: function_declarator, stopBy: end}}\n'
                 '    - {kind: reference_declarator, has: {kind: function_declarator, stopBy: end}}\n' + OUTSIDE,
    'macro': 'any: [{kind: preproc_def}, {kind: preproc_function_def}]\n' + OUTSIDE,
    # (each name a declaration declares: `static long asked = 0, late = 0;` has two)
    'declared': 'kind: identifier\ninside: {field: declarator, any: [{kind: declaration}, {kind: init_declarator}, {kind: array_declarator},'
                ' {kind: pointer_declarator}, {kind: reference_declarator}]}\n'
                'not: {inside: {any: [{kind: compound_statement}, {kind: field_declaration_list}, {kind: parameter_list}], stopBy: end}}',
    'comment': 'kind: comment',
}


def git(*a):
    return subprocess.run(['git', *a], capture_output=True, text=True, cwd=ROOT).stdout


def own_files(commit=None):
    listed = git('ls-tree', '-r', '--name-only', commit, '.') if commit else git('ls-files', '-co', '--exclude-standard')
    return sorted(f for f in listed.split('\n') if f.endswith(('.h', '.cpp', '.mm')) and not f.startswith(('third_party/', 'out/'))
                  and (commit or os.path.exists(os.path.join(ROOT, f))))


def scan(rules, files, folder=ROOT):
    # every node of `files` (paths from `folder`) that a rule matches: {file: {rule: [(first byte, byte after the last)]}}
    text = '\n---\n'.join(f'id: {name}\nlanguage: cpp\nseverity: hint\nrule:\n' + re.sub('^', '  ', rule, flags=re.M) for name, rule in rules.items())
    try:
        said = subprocess.run(['ast-grep', 'scan', '-c', CONFIG, '--inline-rules', text, '--json=stream', *files], capture_output=True, text=True, cwd=folder)
    except FileNotFoundError:
        sys.exit('ast-grep is not installed: brew bundle (the Brewfile names it), or npm install --global @ast-grep/cli')
    if said.returncode: sys.exit(said.stderr)
    found = defaultdict(lambda: defaultdict(list))
    for line in said.stdout.splitlines():
        match = json.loads(line)
        found[match['file']][match['ruleId']].append((match['range']['byteOffset']['start'], match['range']['byteOffset']['end']))
    return found


def digest(text):
    return hashlib.sha1(text.encode()).hexdigest()[:12]


def signature(head):   # (the words before the body, without what only says linkage)
    return ' '.join(re.sub(r'\b(static|inline|extern)\b', ' ', head).split())


def without_defaults(signature):   # (each " = value" of the parameter list taken out)
    out, depth, i = [], 0, 0
    while i < len(signature):
        c = signature[i]
        depth += (c in '([{') - (c in ')]}')
        if c == '=' and depth == 1 and signature[i - 1] not in '=!<>' and signature[i + 1:i + 2] != '=':
            inner, quote = 0, ''
            while i < len(signature) and (quote or inner or signature[i] not in ',)'):
                c = signature[i]
                if quote: quote = '' if c == quote else quote
                elif c in '"\'': quote = c
                else: inner += (c in '([{') - (c in ')]}')
                i += 1
            while out and out[-1] == ' ': out.pop()
            continue
        out.append(c); i += 1
    return ''.join(out)


def is_const(text):   # (the object itself, not what it points at: `const char* a` can be assigned to)
    while re.search(r'<[^<>;]*>', text): text = re.sub(r'<[^<>;]*>', '', text)
    words = re.split(r'[={\[;(]', text, maxsplit=1)[0]
    return 'constexpr' in words.split() or 'const' in re.split(r'[*&]', words)[-1].split()


def items_of(path, source, found, renamed=lambda text: text):
    comments = sorted(found['comment'])

    def clean(a, b):   # (the text from a to b without comments, trailing blanks and empty lines)
        parts, at = [], a
        for start, end in comments:
            if a <= start and end <= b and start >= at: parts.append(source[at:start]); at = end
        text = b''.join(parts + [source[at:b]]).decode('utf-8', 'replace')
        return renamed('\n'.join(line.rstrip() for line in text.split('\n') if line.strip()))

    def outer(a, b):   # (from `template <...>` on, when it is a template)
        return min([start for start, end in found['template'] if start <= a and b <= end], default=a)

    def function_name(a, b):
        named = [n for n in sorted(found['name']) if a <= n[0] and n[1] <= b]
        return renamed(' '.join(source[named[0][0]:named[0][1]].decode().split())) if named else ''

    def variable_names(a, b):
        return renamed(','.join(source[start:end].decode() for start, end in sorted(found['declared']) if a <= start and end <= b))

    def line(a):
        return source.count(b'\n', 0, a) + 1

    items = []
    for a, b in found['function']:
        body = min([(start, end) for start, end in found['body'] if a <= start and end == b], default=(b, b))
        head = clean(outer(a, b), body[0])
        words = set(re.findall(r'\b(static|inline|constexpr)\b', head))
        linkage = 'static' if 'static' in words else 'template' if outer(a, b) != a else 'inline' if words else 'external'
        items.append(Item('function', function_name(a, body[0]), path, linkage, line(a), signature(head), digest(clean(*body))))
    for a, b in found['type'] + found['alias']:
        text = clean(outer(a, b), b)
        if text.startswith('typedef'):   # (its name is the last word: `typedef struct { ... } Name;`)
            name = re.findall(r'\w+', text)[-1]
        else:
            name = re.search(r'\b(?:struct|class|union|enum(?:\s+(?:class|struct))?|using)\s+(\w+)', text)
            name = name.group(1) if name else ''
        items.append(Item('type', name, path, '-', line(a), '', digest(text)))
    prototypes = set(found['prototype'])
    for a, b in found['declaration']:
        text = clean(outer(a, b), b)
        said = signature(text)
        if (a, b) in prototypes:
            items.append(Item('declaration', function_name(a, b), path, '-', line(a), said.rstrip('; '), digest(said)))
        elif re.match(r'\s*extern\b(?!\s*")', text) and '=' not in text:
            items.append(Item('declaration', variable_names(a, b), path, '-', line(a), said.rstrip('; '), digest(said)))
        else:
            first = re.match(r'(\s*\b(static|inline|extern|const|constexpr)\b)*\s*', text)
            words = first.group().split()
            linkage = 'inline' if 'inline' in words else 'const' if is_const(text) else 'static' if 'static' in words else 'external'
            items.append(Item('variable', variable_names(a, b), path, linkage, line(a), '', digest(text[first.end():])))
    for a, b in found['macro']:
        # (the grammar reads a comment after a #define as part of its value: cut from a // that is in no string)
        text = '\n'.join(re.match(r'((?:[^"\'/]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|/(?!/))*)', line).group(1).rstrip() for line in clean(a, b).split('\n'))
        name, value = re.match(r'\s*#\s*define\s+(\w+)(.*)', text, re.S).groups()
        if value.strip() or not name.endswith(('_H', '_H_')):
            items.append(Item('macro', name, path, '-', line(a), '', digest(text)))
    return sorted(items, key=lambda item: item.line)


def census(commit=None, renamed=lambda text: text):
    files = own_files(commit)

    def read(folder):
        found = scan(RULES, files, folder)
        return [item for f in files for item in items_of(f, open(os.path.join(folder, f), 'rb').read(), found[f], renamed)]
    if not commit: return read(ROOT)
    with tempfile.TemporaryDirectory() as folder:   # (the commit's files, put where ast-grep can open them)
        packed = subprocess.run(['git', 'archive', commit, '--', *files], capture_output=True, cwd=ROOT).stdout
        subprocess.run(['tar', '-x', '-C', folder], input=packed, check=True)
        return read(folder)


def renames(path):
    pairs = [line.split('\t') for line in open(path).read().splitlines() if line and not line.startswith('#')]

    def renamed(text):
        for old, new in pairs:   # (a whole name: `d.acting` is not found in `d.acting_now`)
            text = re.sub((r'(?<!\w)' if old[0].isalnum() or old[0] == '_' else '') + re.escape(old) + (r'(?!\w)' if old[-1].isalnum() or old[-1] == '_' else ''),
                          lambda m: new, text)
        return text
    return renamed


def twice(items):   # (function names defined more than once, and where)
    by = defaultdict(list)
    for item in items:
        if item.kind == 'function': by[item.name].append(item.file)
    return {name: files for name, files in by.items() if len(files) > 1}


def counts(items):
    kinds, links = Counter(item.kind for item in items), Counter(item.linkage for item in items if item.kind == 'function')
    return (f'{kinds["function"]} functions ({", ".join(f"{links[l]} {l}" for l in ("static", "inline", "template", "external"))}), {kinds["type"]} types, '
            f'{kinds["variable"]} variables, {kinds["macro"]} macros, {kinds["declaration"]} declarations in {len({item.file for item in items})} files')


def differences(old, new):
    # the lines to print and how many of them fail
    lines, failed, moved = [], 0, defaultdict(list)
    was, now = defaultdict(list), defaultdict(list)
    for item in old: was[(item.kind, item.name)].append(item)
    for item in new: now[(item.kind, item.name)].append(item)
    declared = {(item.name, item.signature) for item in new if item.kind == 'declaration'}
    for key in sorted(set(was) | set(now)):
        if key[0] == 'declaration': continue
        left, right, pairs = list(was[key]), list(now[key]), []
        for same in (lambda a, b: (a.hash, a.signature, a.file) == (b.hash, b.signature, b.file), lambda a, b: (a.hash, a.signature) == (b.hash, b.signature),
                     lambda a, b: a.hash == b.hash, lambda a, b: a.file == b.file, lambda a, b: True):
            for a in list(left):
                b = next((b for b in right if same(a, b)), None)
                if b: pairs.append((a, b)); left.remove(a); right.remove(b)
        what = '\t'.join(key)
        for a, b in pairs:
            if a.hash != b.hash:
                lines.append(f'CHANGED\t{what}\t{b.file}:{b.line}\tits body is not what {a.file} held'); failed += 1
            elif a.signature != b.signature and without_defaults(a.signature) == b.signature and (a.name, a.signature) in declared:
                lines.append(f'defaults\t{what}\t{b.file}\tits default arguments are now in its declaration')
            elif a.signature != b.signature:
                lines.append(f'SIGNATURE\t{what}\t{b.file}:{b.line}\twas: {a.signature}\tis: {b.signature}'); failed += 1
            if a.linkage != b.linkage: lines.append(f'linkage\t{what}\t{b.file}\t{a.linkage} -> {b.linkage}')
            if a.file != b.file: moved[(a.file, b.file)].append(a.name)
        lines += [f'GONE\t{what}\t{a.file}' for a in left] + [f'NEW\t{what}\t{b.file}:{b.line}' for b in right]
        failed += len(left) + len(right)
    lines += [f'moved\t{a} -> {b}\t{len(names)}: {" ".join(names)}' for (a, b), names in sorted(moved.items())]
    before = twice(old)
    for name, files in sorted(twice(new).items()):
        if len(files) > len(before.get(name, [])):
            lines.append(f'SAME NAME\tfunction\t{name}\tdefined {len(files)} times: {" ".join(files)}'); failed += 1
    return lines, failed


if __name__ == '__main__':
    args = sys.argv[1:]
    if '--diff' not in args:
        items = census()
        print('\n'.join('\t'.join((item.kind, item.name, item.file, item.linkage, item.hash)) for item in items))
        print('# ' + counts(items))
        print('\n'.join(f'# defined {len(files)} times: {name} ({" ".join(files)})' for name, files in sorted(twice(items).items())))
        sys.exit()
    commit = args[args.index('--diff') + 1]
    old = census(commit, renames(args[args.index('--renames') + 1]) if '--renames' in args else lambda text: text)
    new = census()
    lines, failed = differences(old, new)
    print('\n'.join(lines + [f'{commit}: {counts(old)}', f'now: {counts(new)}']))
    sys.exit(f'{failed} differences that a move does not explain (the lines in capitals)' if failed else print('ok: every body and signature as in ' + commit))
