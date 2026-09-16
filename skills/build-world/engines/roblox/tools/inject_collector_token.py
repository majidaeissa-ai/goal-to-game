#!/usr/bin/env python3
"""Generate an ignored runtime verifier copy with a collector token."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

PLACEHOLDER_DECLARATION = (
    'local TOKEN_PLACEHOLDER = "REPLACE_WITH_COLLECTOR_SESSION_TOKEN"'
)
ASSIGNMENT = re.compile(
    r"^local TOKEN = .*? -- GOAL_TO_GAME_TOKEN_ASSIGNMENT$", re.MULTILINE
)
TRACKED_PLUGIN = Path(__file__).resolve().parents[1] / "plugin" / "GoalToGameVerifier.plugin.lua"
DEFAULT_OUTPUT = (
    Path(__file__).resolve().parents[5]
    / ".roblox-evidence-runtime"
    / "GoalToGameVerifier.session.lua"
)


def inject_token(source: str, token: str) -> str:
    if not token or "\n" in token or "\r" in token:
        raise ValueError("token must be a non-empty single-line string")
    if source.count(PLACEHOLDER_DECLARATION) != 1:
        raise ValueError("plugin safety placeholder declaration is missing or ambiguous")
    replacement = f"local TOKEN = {json.dumps(token)} -- GOAL_TO_GAME_TOKEN_ASSIGNMENT"
    updated, count = ASSIGNMENT.subn(lambda _match: replacement, source)
    if count != 1:
        raise ValueError("plugin token assignment marker is missing or ambiguous")
    if PLACEHOLDER_DECLARATION not in updated:
        raise AssertionError("token injection changed the safety placeholder")
    if "assert(TOKEN ~= TOKEN_PLACEHOLDER" not in updated:
        raise AssertionError("plugin token safety assertion is missing")
    return updated


def write_runtime_plugin(template: Path, output: Path, token: str) -> Path:
    template = template.resolve()
    output = output.resolve()
    if output == template or output == TRACKED_PLUGIN.resolve():
        raise ValueError("output must not overwrite the tracked plugin source")
    source = template.read_text(encoding="utf-8")
    configured = inject_token(source, token)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(configured, encoding="utf-8")
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("token", help="session token printed by evidence_collector.py")
    parser.add_argument("--template", type=Path, default=TRACKED_PLUGIN)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    write_runtime_plugin(args.template, args.output, args.token)
    print("Generated token-configured runtime plugin copy.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
