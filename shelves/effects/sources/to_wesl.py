#!/usr/bin/env python3
"""Convert Motolii .wgsl files from // --track@/--check@ header comments to
WESL-style (@range/@toggle/@color/@group/@label/@auto) struct attributes."""

import glob
import os
import re
import sys

BUILTINS = {
    "time", "frame", "aspect", "resolution", "width", "height",
    "frameRect", "passRect", "passindex", "screen", "layer",
    "duration", "isf_rate", "history_head", "history_count",
}


def human_label(name: str) -> str:
    out = []
    for i, c in enumerate(name):
        if c == "_":
            if out and out[-1] != " ":
                out.append(" ")
            continue
        if i > 0 and c.isupper() and name[i - 1].islower() and out and out[-1] != " ":
            out.append(" ")
        out.append(c.upper() if (not out or out[-1] == " ") else c)
    return "".join(out) or name


def fmt_num(s: str) -> str:
    v = float(s)
    if v == int(v) and abs(v) < 1e9:
        return str(int(v))
    return f"{v:g}"


def vec_dim(ftype: str) -> int:
    if ftype.startswith("vec2"):
        return 2
    if ftype.startswith("vec3"):
        return 3
    if ftype.startswith("vec4"):
        return 4
    return 1


def convert_file(path: str) -> bool:
    src = open(path, encoding="utf-8").read()
    um = re.search(r"var\s*<\s*uniform\s*>\s+\w+\s*:\s*(\w+)", src)
    if not um:
        return False
    struct_name = um.group(1)
    sm = re.search(r"(struct\s+" + re.escape(struct_name) + r"\s*\{)([^}]*)(\})", src, re.S)
    if not sm:
        return False

    # Parse leading // header block.
    lines = src.splitlines(keepends=True)
    head_end = 0
    while head_end < len(lines):
        l = lines[head_end]
        if l.startswith("//") or (l.strip() == "" and head_end > 0):
            head_end += 1
        else:
            break

    header_lines = lines[:head_end]
    rest_text = "".join(lines[head_end:])

    # Collect field names & types from the uniform struct.
    body = sm.group(2)
    field_matches = list(re.finditer(r"(\w+)\s*:\s*([\w<>]+)", body))
    fields = {m.group(1): m.group(2) for m in field_matches}

    # Parse --track@, --check@, --group in header.
    group = ""
    scalar_params = {}  # field_name -> dict
    vec_params = {}     # base_name -> {comp: dict}
    consumed_line_idx = set()

    for idx, raw in enumerate(header_lines):
        line = raw.rstrip("\r\n")
        gm = re.match(r"^//\s*--group(?::([^,\r]*))?", line)
        if gm:
            group = (gm.group(1) or "").strip()
            consumed_line_idx.add(idx)
            continue
        pm = re.match(r"^//\s*--(track|check)@(\w+):(.*)$", line)
        if not pm:
            continue
        kind, pname, rest = pm.group(1), pm.group(2), pm.group(3)
        parts = [p.strip() for p in rest.split(",")]
        label = parts[0]
        if kind == "track":
            if len(parts) < 4:
                continue
            low, high, usual = parts[1], parts[2], parts[3]
            step = parts[4] if len(parts) >= 5 and parts[4] else "0.01"
            info = dict(kind="track", label=label, low=low, high=high, usual=usual, step=step, group=group, idx=idx)
        else:
            usual = parts[1] if len(parts) >= 2 and parts[1] else "0"
            info = dict(kind="check", label=label, usual=usual, group=group, idx=idx)

        if pname in fields:
            scalar_params[pname] = info
            consumed_line_idx.add(idx)
        else:
            bm = re.match(r"^(.+)_([xyzw])$", pname)
            if bm and bm.group(1) in fields:
                vec_params.setdefault(bm.group(1), {})[bm.group(2)] = info

    if not scalar_params and not vec_params:
        return False

    # Verify which vec_params have complete components and can be converted cleanly.
    convertible_vecs = {}
    for base, comps in vec_params.items():
        dim = vec_dim(fields[base])
        need = "xyzw"[:dim]
        if all(c in comps for c in need):
            items = [comps[c] for c in need]
            if all(it["kind"] == "track" for it in items):
                rngs = {(float(it["low"]), float(it["high"]), float(it["step"])) for it in items}
                grps = {it["group"] for it in items}
                if len(rngs) == 1 and len(grps) == 1:
                    convertible_vecs[base] = items
                    for it in items:
                        consumed_line_idx.add(it["idx"])

    # Drop consumed header lines; keep non-param directives (--label, --about, --tag, --pass, --spill, --picture, etc.).
    new_header_lines = [l for i, l in enumerate(header_lines) if i not in consumed_line_idx]

    # Rebuild the uniform struct body with WESL attributes.
    # Re-locate the struct in rest_text.
    sm2 = re.search(r"(struct\s+" + re.escape(struct_name) + r"\s*\{)([^}]*)(\})", rest_text, re.S)
    if not sm2:
        return False

    new_body_lines = ["\n"]
    cur_group = ""
    for m in re.finditer(r"(\w+)\s*:\s*([\w<>]+)", sm2.group(2)):
        fname, ftype = m.group(1), m.group(2)
        if fname in scalar_params:
            p = scalar_params[fname]
            if p["group"] != cur_group:
                cur_group = p["group"]
                new_body_lines.append(f'  @group("{cur_group}")\n' if cur_group else "  @group()\n")
            if p["label"] != human_label(fname):
                esc = p["label"].replace('"', '\\"')
                new_body_lines.append(f'  @label("{esc}")\n')
            if p["kind"] == "track":
                attr = f"@range({fmt_num(p['low'])}, {fmt_num(p['high'])}, {fmt_num(p['step'])}, {fmt_num(p['usual'])})"
            else:
                attr = f"@toggle({fmt_num(p['usual'])})"
            new_body_lines.append(f"  {attr:<28} {fname}: {ftype},\n")
        elif fname in convertible_vecs:
            items = convertible_vecs[fname]
            grp = items[0]["group"]
            if grp != cur_group:
                cur_group = grp
                new_body_lines.append(f'  @group("{cur_group}")\n' if cur_group else "  @group()\n")
            dim = len(items)
            low, high, step = float(items[0]["low"]), float(items[0]["high"]), float(items[0]["step"])
            labels = [it["label"] for it in items]
            rgba_suffixes = [" R", " G", " B", " A"][:dim]
            xyzw_suffixes = [" X", " Y", " Z", " W"][:dim]
            is_color = (
                dim in (3, 4)
                and low == 0.0
                and high == 1.0
                and abs(step - 0.01) < 1e-6
                and all(lbl.endswith(suf) for lbl, suf in zip(labels, rgba_suffixes))
                and len({lbl[:-2] for lbl in labels}) == 1
            )
            if is_color:
                base_label = labels[0][:-2]
                if base_label != human_label(fname):
                    esc = base_label.replace('"', '\\"')
                    new_body_lines.append(f'  @label("{esc}")\n')
                vals = ", ".join(fmt_num(it["usual"]) for it in items)
                attr = f"@color({vals})"
            else:
                if all(lbl.endswith(suf) for lbl, suf in zip(labels, xyzw_suffixes)) and len({lbl[:-2] for lbl in labels}) == 1:
                    base_label = labels[0][:-2]
                else:
                    base_label = re.sub(r"\s+[XYZWxyzwRGBA]$", "", labels[0])
                if base_label != human_label(fname):
                    esc = base_label.replace('"', '\\"')
                    new_body_lines.append(f'  @label("{esc}")\n')
                vals = ", ".join(fmt_num(it["usual"]) for it in items)
                attr = f"@range({fmt_num(items[0]['low'])}, {fmt_num(items[0]['high'])}, {fmt_num(items[0]['step'])}, {vals})"
            new_body_lines.append(f"  {attr:<28} {fname}: {ftype},\n")
        else:
            is_auto = fname in BUILTINS or fname.startswith("isf_other_")
            prefix = "@auto " if is_auto else ""
            new_body_lines.append(f"  {prefix}{fname}: {ftype},\n")

    new_rest = rest_text[:sm2.start()] + sm2.group(1) + "".join(new_body_lines) + sm2.group(3) + rest_text[sm2.end():]
    new_src = "".join(new_header_lines) + new_rest
    if new_src == src:
        return False
    open(path, "w", encoding="utf-8").write(new_src)
    return True


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    files = sorted(glob.glob(os.path.join(root, "**", "*.wgsl"), recursive=True))
    changed = 0
    for f in files:
        if convert_file(f):
            changed += 1
    print(f"Converted {changed} / {len(files)} .wgsl files to WESL attributes.")


if __name__ == "__main__":
    main()
