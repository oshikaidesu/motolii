#!/usr/bin/env python3
# Edits a new document at random through edit.sh and, after every step, checks what the app would hold of it
# (docs/app/BRIDGE.md): that the parts kept are what making the snapshot whole gives (`snapshot check`), and that the
# parts handed over one read at a time add up to the whole. A step that breaks either is a failure, with no crash
# needed. The steps come from a seed alone, so a failure is found again by its seed; it is then cut down to the fewest
# steps that still fail and written to out/random_edits/ as calls edit.sh reads.
#   tools/random_edits.py [--seed N] [--steps N] [--runs N]    from engine/; run by ../random_edits_check.sh
#   tools/random_edits.py --replay out/random_edits/seed_7.calls
import argparse, json, os, random, subprocess, sys

ENGINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ENGINE, 'out', 'random_edits')
NUMBERS = [('x', -500, 500), ('y', -500, 500), ('z', -200, 200), ('rotate', -360, 360), ('scale_x', 0, 3),
           ('scale_y', 0, 3), ('opacity', 0, 1), ('anchor_x', -50, 50), ('start', 0, 4), ('duration', 0.2, 6),
           ('visible', 0, 1), ('solo', 0, 1), ('lock', 0, 1), ('clip', 0, 1), ('copies', 1, 6), ('speed', 0.25, 4)]
EFFECTS = ['Diagonal Blur', 'Dilate-Fast', 'Blur (Sashimono)']


def steps_of(seed, count):
    """The steps of one run: each a list of calls that belong together (a drag, one undo step)."""
    r = random.Random(seed)
    made, live, steps = 0, [], []

    def one(layer=None):
        t = layer if layer is not None else r.choice(live)
        kind = r.choices(['set', 'set', 'set', 'key', 'say', 'effect', 'easing'], [5, 5, 5, 4, 3, 1, 2])[0]
        name, low, high = r.choice(NUMBERS)
        number = round(r.uniform(low, high), 3) if high - low > 1 else r.choice([low, high])
        at = r.choice([0.5, 1, 1.5, 2, 3])
        if kind == 'set':
            return f'set {t} {name} {number}'
        if kind == 'key':
            return f'key {t} {name} {at} {number}'
        if kind == 'easing':
            return f'easing {t} {name} {at} {r.choice(["Linear", "Hold", "Bezier 0.2 0 0.8 1", "Bounce"])}'
        if kind == 'effect':
            return f'effect {t} {r.choice(EFFECTS)}'
        return r.choice([f'say {t} name Layer{r.randrange(9)}', f'say {t} blend {r.choice(["add", "multiply", "screen"])}',
                         f'say {t} fill {r.choice(["ff3355", "glass", "22aaff"])}', f'set {t} parent {r.choice(live + [0])}'])

    for _ in range(count):
        kind = r.choices(['add', 'remove', 'one', 'undo', 'redo', 'at', 'drag', 'together', 'stage'],
                         [4 if len(live) < 12 else 1, 2, 30, 8, 4, 3, 6, 3, 1])[0]
        if kind == 'add' or not live:
            made += 1
            live.append(made)
            steps.append([f'add solid {r.choice(["cube", "ring", "gem"])}'])
        elif kind == 'remove':
            steps.append([f'remove {live.pop(r.randrange(len(live)))}'])
        elif kind == 'one':
            steps.append([one()])
        elif kind in ('undo', 'redo'):
            steps.append([kind])
        elif kind == 'at':
            steps.append([f'at {r.choice([0, 0.5, 1, 2, 3.5])}'])
        elif kind == 'stage':
            steps.append([f'set 0 bpm {r.choice([0, 90, 120])}'])
        elif kind == 'together':
            steps.append(['together on'] + [one() for _ in range(r.randrange(2, 5))] + ['together off'])
        else:   # a drag: held, followed while it goes, kept or given up
            t, (name, low, high) = r.choice(live), r.choice(NUMBERS[:7])
            by = r.choice(['place', 'bar', name])
            steps.append([f'drag_start {t}']
                         + [f'drag_update {by} {round(r.uniform(low, high), 2)} {round(r.uniform(-50, 50), 2)}'
                            for _ in range(r.randrange(1, 5))]
                         + [f'drag_end {r.choice([1, 1, 0])}'])
    return steps


def calls_of(steps):
    """The calls of a run: every step followed by what the app is handed and by the check.

    Not inside a step: the engine makes the snapshot once, when an undo step ends."""
    calls = ['snapshot', 'snapshot check']
    for step in steps:
        calls += step + ['snapshot', 'snapshot check']
    return calls + ['snapshot whole']


def merged(held, parts):
    """As the app's `merged` (app/lib/bridge/snapshot_parts.dart): the parts put in, a null part gone."""
    return {k: v for k, v in {**held, **parts}.items() if v is not None}


def wrong_in(steps, name):
    """Runs the steps on a new document. Returns None, or what was wrong and how many checks had been made by then
    (the first is of the new document, then one a step)."""
    doc = os.path.join(OUT, name + '.motolii')
    for end in ('', '-wal', '-shm', '-journal'):
        if os.path.exists(doc + end):
            os.remove(doc + end)
    calls = calls_of(steps)
    ran = subprocess.run([os.path.join(ENGINE, 'edit.sh'), doc], input='\n'.join(calls) + '\n', text=True,
                         capture_output=True, timeout=1800)
    document, layers, checks, whole = {}, {}, 0, None
    for line in ran.stdout.splitlines():
        if line.startswith('snapshot '):
            read = json.loads(line.split(' ', 2)[2])
            document = merged(document, read['document'])
            for layer, parts in read['layer'].items():
                layers[layer] = merged(layers.get(layer, {}), parts)
            are = {'0'} | {str(t) for t in document.get('layers', [])}
            layers = {t: of for t, of in layers.items() if t in are}
        elif line.startswith('stale'):
            checks += 1
            if line.strip() != 'stale':
                return f'parts held that making the snapshot whole does not give: {line[6:]}', checks
        elif line.startswith('whole '):
            whole = json.loads(line.split(' ', 2)[2])
        elif line.startswith('FAIL'):
            return line, checks
    wanted = sum(1 for c in calls if c == 'snapshot check')
    if checks != wanted or whole is None:
        return (f'the engine stopped after {checks} of {wanted} checks (exit {ran.returncode}): '
                f'{(ran.stdout + ran.stderr).strip().splitlines()[-1:]}'), checks
    all_document = merged({}, whole['document'])
    are = {'0'} | {str(t) for t in all_document.get('layers', [])}
    all_layers = {t: merged({}, parts) for t, parts in whole['layer'].items() if t in are}
    if document != all_document:
        return 'the document read part by part is not the whole: ' + ', '.join(
            sorted(k for k in document.keys() | all_document.keys() if document.get(k) != all_document.get(k))), checks
    if layers != all_layers:
        return 'the layers read part by part are not the whole: ' + ', '.join(sorted(
            f'{t}/{k}' for t in layers.keys() | all_layers.keys()
            for k in layers.get(t, {}).keys() | all_layers.get(t, {}).keys()
            if layers.get(t, {}).get(k) != all_layers.get(t, {}).get(k))), checks
    return None


def fewest(steps, name, runs):
    """Cuts a failing run down: steps are taken away, a chunk at a time, while it still fails (ddmin)."""
    chunk = max(1, len(steps) // 2)
    while chunk >= 1 and runs > 0:
        at, cut = 0, False
        while at < len(steps) and runs > 0:
            without = steps[:at] + steps[at + chunk:]
            runs -= 1
            if without and wrong_in(without, name):
                steps, cut = without, True
            else:
                at += chunk
        chunk = chunk // 2 if not cut or chunk > 1 else 0
    return steps


def main():
    said = argparse.ArgumentParser()
    said.add_argument('--seed', type=int, default=1)
    said.add_argument('--steps', type=int, default=200)
    said.add_argument('--runs', type=int, default=3, help='runs, each with the next seed')
    said.add_argument('--replay', help='a .calls file written by an earlier failure')
    said = said.parse_args()
    os.makedirs(OUT, exist_ok=True)
    if said.replay:
        # As one step: the checks then come only at its end, wherever its undo steps began and ended.
        steps = [[line for line in open(said.replay).read().splitlines() if line and not line.startswith('snapshot')]]
        wrong = wrong_in(steps, 'replay')
        print(f'{said.replay}: {wrong[0] if wrong else "ok"}')
        return 1 if wrong else 0
    for seed in range(said.seed, said.seed + said.runs):
        steps = steps_of(seed, said.steps)
        wrong = wrong_in(steps, f'seed_{seed}')
        if not wrong:
            print(f'seed {seed}: ok, {said.steps} steps')
            continue
        # Only the steps up to the failure can have caused it.
        steps = fewest(steps[:max(1, wrong[1] - 1)], f'seed_{seed}', 40)
        kept = os.path.join(OUT, f'seed_{seed}.calls')
        open(kept, 'w').write('\n'.join(calls_of(steps)) + '\n')
        print(f'seed {seed}: {wrong_in(steps, f"seed_{seed}")[0]}\n  the fewest steps that fail, {len(steps)}: '
              + ' | '.join(call for step in steps for call in step)
              + f'\n  again: engine/tools/random_edits.py --seed {seed} --steps {said.steps} --runs 1'
              + f'\n  by hand: engine/edit.sh a.motolii < {os.path.relpath(kept, os.path.dirname(ENGINE))}')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
