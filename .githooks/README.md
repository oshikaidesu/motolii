# .githooks

Optional git hooks. Enable them once per clone:

```bash
git config core.hooksPath .githooks
```

| File | What it does |
|---|---|
| [pre-commit](pre-commit) | Runs [format_check.py](format_check.py), then [import_check.py](import_check.py): refuses a commit whose staged Dart files are not as `dart format` leaves them, or whose imports break the rules. Looks for `dart` on the PATH, then in `~/flutter/bin`; skipped when neither has it. |
| [import_check.py](import_check.py) | In pre-commit and [checks.yml](../.github/workflows/checks.yml). Fails when an app file imports the engine (`package:motolii/bridge/`), `dart:io` or `dart:ffi` outside the places [import_rules.txt](import_rules.txt) allows, or `app/pubspec.yaml` depends on what it does not name. Imports from before the rule are listed there with `!` and counted. Only the maker changes the list: [rules_guard.py](../.claude/hooks/rules_guard.py) asks before Claude Code edits it. By hand: `python3 .githooks/import_check.py --all`. |
| [path_check.py](path_check.py) | Not a hook: a step of [checks.yml](../.github/workflows/checks.yml). Fails when a shelf file or one of our Markdown files names a path that does not exist. [path_check_allow.txt](path_check_allow.txt) lists the paths that are fetched or built later. By hand: `python3 .githooks/path_check.py --all`. |

Formatting, static analysis and tests run in CI on every push and pull request.
