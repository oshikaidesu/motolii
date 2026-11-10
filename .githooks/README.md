# .githooks

Optional git hooks. Enable them once per clone:

```bash
git config core.hooksPath .githooks
```

| File | What it does |
|---|---|
| [pre-commit](pre-commit) | Runs [format_check.py](format_check.py): refuses a commit whose staged Dart files are not as `dart format` leaves them. Skipped when `dart` is not on the PATH. |
| [path_check.py](path_check.py) | Not a hook: a step of [checks.yml](../.github/workflows/checks.yml). Fails when a shelf file or one of our Markdown files names a path that does not exist. [path_check_allow.txt](path_check_allow.txt) lists the paths that are fetched or built later. By hand: `python3 .githooks/path_check.py --all`. |

Formatting, static analysis and tests run in CI on every push and pull request.
