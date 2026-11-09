#!/usr/bin/env python3
# Is every staged Dart file as `dart format` leaves it? A contributor's editor formats on save (dart.dev/tools/dart-format),
# so a file left unformatted turns their one-line change into a whole-file diff. The staged text is checked (not the disk),
# at the width app/analysis_options.yaml gives (formatter: page_width:, found through --stdin-name).
# No `dart` on PATH: skipped with a word, not refused. Run by the pre-commit hook after layout_check.py; or by hand.
import shutil, subprocess, sys

dart = shutil.which('dart')
staged = [p for p in subprocess.run(['git', 'diff', '--cached', '--name-only', '-z', '--diff-filter=ACMR'], capture_output=True)
          .stdout.decode('utf-8', 'replace').split('\0') if p.startswith('app/') and p.endswith('.dart')]
if not staged:
    sys.exit(0)
if dart is None:
    print('format check skipped: no dart on PATH (Flutter puts it in its bin/)', file=sys.stderr)
    sys.exit(0)

bad = []
for path in staged:
    text = subprocess.run(['git', 'show', f':{path}'], capture_output=True).stdout
    run = subprocess.run([dart, 'format', '-o', 'none', '--set-exit-if-changed', f'--stdin-name={path}'], input=text, capture_output=True)
    if run.returncode != 0:
        bad.append(path)

if bad:
    print('format check refused this commit (rule: Dart as `dart format` leaves it; .githooks/README.md):\n  ' + '\n  '.join(bad)
          + '\n  fix:  (cd app && dart format ' + ' '.join(p[len('app/'):] for p in bad) + ') && git add ' + ' '.join(bad),
          file=sys.stderr)
    sys.exit(1)
