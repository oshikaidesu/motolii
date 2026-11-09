#!/usr/bin/env python3
# A commit's subject is at most 72 characters (characters, not bytes: a Japanese subject counts as many as it reads).
# The subject is what git-commit(1) DISCUSSION calls the title, "the text up to the first blank line", used
# throughout git (`git log --oneline`, the Subject: of git-format-patch); that page advises 50 or fewer. 72 is where
# GitHub cuts a title with "…" (github.com/orgs/community/discussions/12450). One subject here was 1120 characters.
#   subject_check.py MESSAGE_FILE   the commit-msg hook (.githooks/commit-msg): the message being written
#   subject_check.py --range A..B   CI (.github/workflows/checks.yml): every commit of a pull request or a push
#                                   made since this rule came in
import subprocess, sys

LIMIT = 72
HOW = ('Keep the first line to what changed, in at most 72 characters; after one blank line, write the problem,'
       ' the fix and the source in the body.')


def title(message):
    """git's title: lines up to the first blank line, joined by spaces; comment lines and what follows the
    `git commit -v` scissors are not part of the message."""
    lines = []
    for line in message.split('\n'):
        if line.startswith('# ------------------------ >8'):
            break
        if line.startswith('#'):
            continue
        if not line.strip():
            if lines:
                break
            continue
        lines.append(line.strip())
    return ' '.join(lines)


if sys.argv[1:2] == ['--range']:
    log = subprocess.run(['git', 'log', '--format=%h%x00%s', sys.argv[2]], capture_output=True, check=True).stdout
    subjects = [line.split('\0', 1) for line in log.decode('utf-8', 'replace').splitlines()]
    # a commit made before this rule (its tree has no subject_check.py) is not judged by it: history is not rewritten
    has = subprocess.run(['git', 'cat-file', '--batch-check'], capture_output=True, check=True,
                         input=''.join(f'{h}:.githooks/subject_check.py\n' for h, _ in subjects).encode()).stdout
    subjects = [hs for hs, found in zip(subjects, has.decode().splitlines()) if not found.endswith('missing')]
    fix = 'Reword them (git rebase -i, `reword`) and push again.'
else:
    with open(sys.argv[1], encoding='utf-8', errors='replace') as f:
        subjects = [('this commit', title(f.read()))]
    fix = f'Your message is kept: git commit -e -F {sys.argv[1]}'

bad = [f'{at}: {len(s)} characters: {s[:80]}…' for at, s in subjects if len(s) > LIMIT]
if bad:
    print('subject check refused (rule: a subject of 72 characters at most; .githooks/README.md):\n  ' + '\n  '.join(bad) + f'\n{HOW}\n{fix}',
          file=sys.stderr)
    sys.exit(1)
