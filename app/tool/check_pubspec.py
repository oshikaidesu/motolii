#!/usr/bin/env python3
# Rule for app/pubspec.yaml: only the packages in tool/pubspec_allow.txt may be depended on, and every allowed name
# must still be in use. Chromium's DEPS and Bazel's visibility, as plain text: deny by default, the list beside the code
# so a diff is the review. Only the maker changes the allow list.
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(HERE)
pub = open(os.path.join(APP, 'pubspec.yaml')).read()
allow_lines = open(os.path.join(HERE, 'pubspec_allow.txt')).readlines()
allowed = {m.group(1) for line in allow_lines
           if (m := re.match(r'([a-z_][a-z0-9_]*)\b', line.split('#', 1)[0].strip()))}

names = set()
for section in ('dependencies', 'dev_dependencies'):
    m = re.search(rf'^{section}:\n((?:[ \t].*\n|\n)*)', pub, re.M)
    if not m:
        continue
    names |= set(re.findall(r'^  ([a-z_][a-z0-9_]*):', m.group(1), re.M))

unknown = sorted(names - allowed)
unused = sorted(allowed - names)
if unknown:
    print('check_pubspec: pubspec.yaml depends on packages that tool/pubspec_allow.txt does not name:')
    for n in unknown:
        print(f'  {n}')
    print('If this is wanted, ask the maker to add it to tool/pubspec_allow.txt.')
if unused:
    print('check_pubspec: tool/pubspec_allow.txt names packages pubspec.yaml no longer uses; take them out:')
    for n in unused:
        print(f'  {n}')
if unknown or unused:
    sys.exit(1)
print(f'check_pubspec: {len(allowed)} allowed, all accounted for.')
