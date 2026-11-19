#!/bin/zsh
# Edits new documents at random with the engine as built and fails at the first step where what the app would hold
# of the document is not the document (tools/random_edits.py; docs/TESTING.md). The same seeds give the same steps.
#   ./engine/random_edits_check.sh                       3 runs of 200 steps, seeds 1 to 3
#   SEED=40 STEPS=1000 RUNS=10 ./engine/random_edits_check.sh
cd "$(dirname "$0")"
./build.sh >&2 || exit 1
exec python3 tools/random_edits.py --seed ${SEED:-1} --steps ${STEPS:-200} --runs ${RUNS:-3}
