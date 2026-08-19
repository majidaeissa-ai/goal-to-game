#!/usr/bin/env python3
"""Local evidence sink for the Goal-to-Game Roblox Studio verifier.

Binds only to 127.0.0.1. A random token is printed at startup; configure the Studio plugin with it.
Every accepted artifact is hashed into ledger.jsonl.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import re
import secrets
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

MAX_JSON = 12 * 1024 * 1024
SAFE_NAME = re.compile(r"^[A-Za-z0-9_.-]{1,100}$")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class Sink:
    def __init__(self, out: Path, token: str):
        self.out = out.resolve()
        self.token = token
        self.out.mkdir(parents=True, exist_ok=True)
        (self.out / "captures").mkdir(exist_ok=True)
        (self.out / "records").mkdir(exist_ok=True)
        self.ledger = self.out / "ledger.jsonl"

    def store(self, category: str, name: str, data: bytes, media_type: str) -> dict:
        if not SAFE_NAME.fullmatch(name):
            raise ValueError("unsafe artifact name")
        if category not in {"captures", "records"}:
            raise ValueError("unsafe category")
        path = (self.out / category / name).resolve()
        if self.out not in path.parents:
            raise ValueError("path escape")
        path.write_bytes(data)
        entry = {
            "schema": "goal-to-game-roblox-evidence-v1",
            "time_unix": time.time(),
            "category": category,
            "name": name,
            "relative_path": str(path.relative_to(self.out)).replace("\\", "/"),
            "bytes": len(data),
            "media_type": media_type,
            "sha256": sha256(data),
        }
        with self.ledger.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(entry, sort_keys=True) + "\n")
        return entry


def make_handler(sink: Sink):
    class Handler(BaseHTTPRequestHandler):
        server_version = "GoalToGameEvidence/1"

        def _json(self, status: int, payload: dict):
            raw = json.dumps(payload, separators=(",", ":")).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def do_GET(self):
            if self.path == "/health":
                self._json(200, {"ok": True, "schema": "goal-to-game-roblox-evidence-v1"})
            else:
                self._json(404, {"ok": False})

        def do_POST(self):
            if self.headers.get("X-GoalToGame-Token") != sink.token:
                self._json(403, {"ok": False, "error": "bad token"})
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                length = -1
            if length < 1 or length > MAX_JSON:
                self._json(413, {"ok": False, "error": "payload size"})
                return
            try:
                body = self.rfile.read(length)
                obj = json.loads(body)
            except Exception:
                self._json(400, {"ok": False, "error": "invalid JSON"})
                return

            try:
                if self.path == "/v1/record":
                    name = obj["name"]
                    record = obj["record"]
                    raw = json.dumps(record, indent=2, sort_keys=True).encode()
                    entry = sink.store("records", name + ".json", raw, "application/json")
                elif self.path == "/v1/capture":
                    name = obj["name"]
                    fmt = str(obj.get("format", "PNG")).upper()
                    if fmt != "PNG":
                        raise ValueError("only PNG capture payloads are accepted")
                    raw = base64.b64decode(obj["base64"], validate=True)
                    if not raw.startswith(b"\x89PNG\r\n\x1a\n"):
                        raise ValueError("payload is not PNG")
                    entry = sink.store("captures", name + ".png", raw, "image/png")
                else:
                    self._json(404, {"ok": False})
                    return
            except (KeyError, ValueError, TypeError) as exc:
                self._json(400, {"ok": False, "error": str(exc)})
                return

            self._json(201, {"ok": True, "artifact": entry})

        def log_message(self, fmt, *args):
            print("[collector] " + (fmt % args))

    return Handler


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument("--port", type=int, default=43119)
    ap.add_argument("--token", default=None, help="optional fixed token; default is random")
    args = ap.parse_args()

    token = args.token or secrets.token_urlsafe(24)
    sink = Sink(args.output, token)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(sink))
    print(f"Collector: http://127.0.0.1:{args.port}")
    print(f"Session token: {token}")
    print(f"Output: {sink.out}")
    print("Keep this terminal open while running the Studio verifier.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
