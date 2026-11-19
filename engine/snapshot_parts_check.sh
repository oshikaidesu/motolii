#!/bin/zsh
# Checks, with the engine as built, what the app is handed of the document's snapshot (docs/app/BRIDGE.md): everything
# when it has nothing, then only the parts that differ: a number set anew hands over the layer's numbers alone, a word
# its words, nothing done hands over nothing. It edits a new document under out/ through edit.sh's `snapshot` call.
#   ./engine/snapshot_parts_check.sh      prints "ok: 8 snapshots" or what was wrong; exits 0 or 1
set -e -o pipefail
cd "$(dirname "$0")"
mkdir -p out/snapshot_parts_check
doc=$PWD/out/snapshot_parts_check/parts.motolii
rm -f $doc $doc-wal $doc-shm $doc-journal
./edit.sh $doc <<'CALLS' | python3 -c '
import json, sys
shots, things = [], []
for line in sys.stdin:
    if line.startswith("snapshot "):
        shots.append(json.loads(line.split(" ", 2)[2]))
    elif line.startswith("thing "):
        things.append(line.split()[1])
    elif "NOT done" in line or line.startswith(("not a call", "FAIL")):
        sys.exit("a call was refused: " + line.strip())
if len(shots) != 8 or things != ["1"]:
    sys.exit(f"expected 8 snapshots and layer 1, got {len(shots)} and {things}")
numbers = {"lasts", "stretches", "keys", "value", "keyTimes", "keyValues", "keyEasings"}
tables = {"usual", "knows", "easingCurves", "easingNames", "effectNames", "easings"}
wrong = []
def want(n, what, said):
    if not what:
        wrong.append(f"snapshot {n}: {said}; it holds {json.dumps(shots[n])[:400]}")
first, added, set_once, set_again, nothing, named, keyed, undone = shots
want(0, tables <= first["document"].keys() and "layers" in first["document"] and "0" in first["layer"],
     "a reader with nothing is handed the tables, the layers and the stage")
want(1, {"cards", "value", "word"} <= added["layer"].get("1", {}).keys() and 1 in added["document"].get("layers", [])
        and "layers" in added["document"].get("changes", "").split("\n"),
     "a layer that came is handed whole, and said to have come")
want(1, not tables & added["document"].keys(), "the tables are not handed over again when a layer comes")
want(2, abs(set_once["layer"].get("1", {}).get("value", {}).get("x", 0) - 40) < 1e-6, "x set to 40 is in the value part")
again = set_again["layer"].get("1", {})
want(3, abs(again.get("value", {}).get("x", 0) - 80) < 1e-6, "x set to 80 is in the value part")
want(3, again.keys() <= numbers, "a number set anew hands over numbers alone")
want(3, list(set_again["layer"]) == ["1"] and not tables & set_again["document"].keys(),
     "no other layer and no table is handed over for it")
want(4, nothing == {"document": {}, "layer": {}}, "nothing done hands over nothing")
want(5, named["layer"].get("1", {}).get("word", {}).get("name") == "Box", "a word written hands over the words")
want(6, keyed["layer"].get("1", {}).get("keyTimes", {}).get("y") == [1], "a keyframe put hands over its time")
want(7, "keyTimes" in undone["layer"].get("1", {}) and "y" not in undone["layer"]["1"]["keyTimes"],
     "the keyframe undone hands over the key times without it")
print("\n".join(wrong) if wrong else f"ok: {len(shots)} snapshots")
sys.exit(1 if wrong else 0)
'
snapshot
add solid cube
snapshot
set 1 x 40
snapshot
set 1 x 80
snapshot
snapshot
say 1 name Box
snapshot
key 1 y 1 100
snapshot
undo
snapshot
CALLS
