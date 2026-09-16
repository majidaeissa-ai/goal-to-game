#!/usr/bin/env python3
"""Validate provenance and completeness of a Roblox Studio evidence run."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

PLACEHOLDER = re.compile(r"(replace|placeholder|todo|pending|example\.com)", re.I)


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def good_public_url(value: object, host_hint: str | None = None) -> bool:
    if not isinstance(value, str) or PLACEHOLDER.search(value):
        return False
    p = urlparse(value)
    if p.scheme != "https" or not p.netloc:
        return False
    return host_hint is None or host_hint in p.netloc.lower()


def load_ledger(root: Path) -> tuple[list[dict], list[str]]:
    ledger = root / "ledger.jsonl"
    if not ledger.exists():
        return [], ["missing ledger.jsonl"]
    entries, errors = [], []
    for n, line in enumerate(ledger.read_text(encoding="utf-8").splitlines(), 1):
        try:
            e = json.loads(line)
            rel = e["relative_path"]
            p = (root / rel).resolve()
            if root.resolve() not in p.parents:
                errors.append(f"ledger line {n}: path escapes root")
                continue
            if not p.is_file():
                errors.append(f"ledger line {n}: missing {rel}")
                continue
            if digest(p) != e.get("sha256"):
                errors.append(f"ledger line {n}: SHA mismatch for {rel}")
                continue
            entries.append(e)
        except Exception as exc:
            errors.append(f"ledger line {n}: {exc}")
    return entries, errors


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("root", type=Path)
    ap.add_argument("--require-views", nargs="*", default=["front", "rear", "left", "right", "top", "gameplay"])
    ap.add_argument("--submission", type=Path, default=None,
                    help="optional final submission.json with public URLs/performance")
    args = ap.parse_args()
    root = args.root.resolve()
    entries, errors = load_ledger(root)

    capture_names = {Path(e["relative_path"]).stem for e in entries if e["category"] == "captures"}
    for view in args.require_views:
        if view not in capture_names:
            errors.append(f"missing captured view: {view}")

    audit_path = root / "records" / "studio-audit.json"
    if not audit_path.exists():
        errors.append("missing records/studio-audit.json")
    else:
        try:
            audit = json.loads(audit_path.read_text(encoding="utf-8"))
            assets = audit.get("assets", [])
            if not assets:
                errors.append("studio audit contains no GoalToGame assets")
            meshparts = sum((a.get("meshPartCount", 0) for a in assets), 0)
            if meshparts < 1:
                errors.append("studio audit contains no MeshParts")
            if audit.get("errors"):
                errors.extend(f"studio audit: {x}" for x in audit["errors"])
        except Exception as exc:
            errors.append(f"invalid studio audit: {exc}")

    if args.submission:
        try:
            s = json.loads(args.submission.read_text(encoding="utf-8"))
            games = s.get("games", [])
            if len(games) < 2:
                errors.append("submission requires two games")
            genres = {str(g.get("genre", "")).strip().lower() for g in games if g.get("genre")}
            if len(genres) < 2:
                errors.append("games must use different genres")
            if not any(g.get("movingPartEvidence") for g in games):
                errors.append("at least one game requires moving-part evidence")
            for i, g in enumerate(games):
                if not good_public_url(g.get("playableUrl"), "roblox.com"):
                    errors.append(f"game {i}: invalid Roblox playableUrl")
                if not good_public_url(g.get("videoUrl")):
                    errors.append(f"game {i}: invalid videoUrl")
                perf = g.get("performance", {})
                for key in ("desktop", "mobileViewport"):
                    fps = perf.get(key, {}).get("averageFps")
                    if not isinstance(fps, (int, float)) or isinstance(fps, bool) or not math.isfinite(fps) or fps < 30:
                        errors.append(f"game {i}: {key} averageFps must be >= 30")
        except Exception as exc:
            errors.append(f"invalid submission file: {exc}")

    if errors:
        for e in errors:
            print("ERROR:", e, file=sys.stderr)
        return 1

    print(f"OK: {len(entries)} ledgered artifacts verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
