#!/usr/bin/env python3
"""Compile challenges/ into the layout the box reads: challenges.json + c/<id>/{setup.sh,check.sh,files/}."""
import hashlib
import json
import shutil
import sys
import tomllib
from pathlib import Path

TRACKS = ["linux", "networking", "servers", "ctf"]
TYPES = {"flag", "check", "questions"}


def sha256(text):
    return hashlib.sha256(text.strip().lower().encode()).hexdigest()


def load(folder, track):
    meta = tomllib.loads((folder / "challenge.toml").read_text())
    cid = f"{track}-{folder.name}"
    kind = meta.get("type", "flag")
    if kind not in TYPES:
        sys.exit(f"{cid}: unknown type {kind!r}")
    for field in ("title", "story", "learned"):
        if not meta.get(field):
            sys.exit(f"{cid}: missing {field}")
    if len(meta.get("hints", [])) != 3:
        sys.exit(f"{cid}: needs exactly 3 hints")
    if not (folder / "setup.sh").exists():
        sys.exit(f"{cid}: missing setup.sh")
    if kind == "check" and not (folder / "check.sh").exists():
        sys.exit(f"{cid}: type check needs check.sh")
    questions = [
        {"prompt": q["prompt"], "sha256": [sha256(a) for a in q["answers"]]}
        for q in meta.get("questions", [])
    ]
    if kind == "questions" and not questions:
        sys.exit(f"{cid}: type questions needs [[questions]]")
    return {
        "id": cid,
        "track": track,
        "title": meta["title"],
        "difficulty": meta.get("difficulty", 1),
        "root": meta.get("root", False),
        "type": kind,
        "story": meta["story"].strip(),
        "hints": meta["hints"],
        "learned": meta["learned"].strip(),
        "questions": questions,
    }


def build(src, out):
    out.mkdir(parents=True, exist_ok=True)
    shutil.rmtree(out / "c", ignore_errors=True)
    challenges = []
    for track in TRACKS:
        for folder in sorted(p for p in (src / track).iterdir() if p.is_dir()):
            info = load(folder, track)
            dest = out / "c" / info["id"]
            dest.mkdir(parents=True)
            for name in ("setup.sh", "check.sh"):
                if (folder / name).exists():
                    shutil.copy(folder / name, dest / name)
                    (dest / name).chmod(0o755)
            if (folder / "files").is_dir():
                shutil.copytree(folder / "files", dest / "files")
            challenges.append(info)
    (out / "challenges.json").write_text(json.dumps(challenges, indent=1))
    return challenges


if __name__ == "__main__":
    src = Path(sys.argv[1] if len(sys.argv) > 1 else "challenges")
    out = Path(sys.argv[2] if len(sys.argv) > 2 else "build/lab")
    for c in build(src, out):
        print(f"{c['id']:32} {c['type']:9} {c['title']}")
