#!/usr/bin/env python3
"""Generate SHA-256 manifest for shelves/ and compute delta stats between two manifests."""
import argparse
import hashlib
import json
import os
import sys
from pathlib import Path


def build_manifest(shelves_dir: Path) -> dict:
    files = {}
    total_bytes = 0
    for root, dirs, filenames in os.walk(shelves_dir):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for fname in sorted(filenames):
            if fname.startswith("."):
                continue
            full = Path(root) / fname
            if not full.is_file():
                continue
            rel = full.relative_to(shelves_dir).as_posix()
            data = full.read_bytes()
            files[rel] = {
                "sha256": hashlib.sha256(data).hexdigest(),
                "size": len(data),
            }
            total_bytes += len(data)
    return {
        "version": 1,
        "fileCount": len(files),
        "totalBytes": total_bytes,
        "files": files,
    }


def diff_manifests(old_m: dict, new_m: dict) -> dict:
    old_files = old_m.get("files", {})
    new_files = new_m.get("files", {})
    added, updated, removed = [], [], []
    delta_bytes = 0
    for rel, meta in new_files.items():
        if rel not in old_files:
            added.append(rel)
            delta_bytes += meta["size"]
        elif old_files[rel]["sha256"] != meta["sha256"]:
            updated.append(rel)
            delta_bytes += meta["size"]
    for rel in old_files:
        if rel not in new_files:
            removed.append(rel)
    return {
        "added": sorted(added),
        "updated": sorted(updated),
        "removed": sorted(removed),
        "deltaBytes": delta_bytes,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("shelves_dir", type=Path, help="Path to shelves/ directory")
    ap.add_argument("-o", "--output", type=Path, required=True, help="Output manifest JSON path")
    ap.add_argument("--prev", type=Path, default=None, help="Optional previous manifest to print delta stats")
    args = ap.parse_args()

    manifest = build_manifest(args.shelves_dir)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {args.output} ({manifest['fileCount']} files, {manifest['totalBytes'] / (1024*1024):.1f} MiB)")

    if args.prev and args.prev.exists():
        prev_m = json.loads(args.prev.read_text(encoding="utf-8"))
        d = diff_manifests(prev_m, manifest)
        print(
            f"Delta vs {args.prev.name}: +{len(d['added'])} added, "
            f"~{len(d['updated'])} updated, -{len(d['removed'])} removed "
            f"({d['deltaBytes'] / 1024:.1f} KiB to download)"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
