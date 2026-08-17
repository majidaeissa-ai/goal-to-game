#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read_preserving_newlines(path: Path) -> tuple[str, str]:
    raw = path.read_bytes()
    newline = "\r\n" if b"\r\n" in raw else "\n"
    text = raw.decode("utf-8").replace("\r\n", "\n")
    return text, newline


def write_preserving_newlines(path: Path, text: str, newline: str) -> None:
    if newline != "\n":
        text = text.replace("\n", newline)
    path.write_bytes(text.encode("utf-8"))


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        print(f"already patched: {label}")
        return text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected anchor once, found {count}")
    print(f"patched: {label}")
    return text.replace(old, new, 1)


def patch(path: Path, changes: list[tuple[str, str, str]]) -> None:
    text, newline = read_preserving_newlines(path)
    for old, new, label in changes:
        text = replace_once(text, old, new, label)
    write_preserving_newlines(path, text, newline)


roblox_setup = r'''### Roblox Studio Installation

Roblox Studio is the source of truth for import, playtesting, screenshots, and publishing.
Use **Rojo** for reproducible source-to-place builds and **Python 3** for the local evidence collector.

#### Windows PowerShell

Install Roblox Studio from the official Roblox Creator site, then install Rojo through Rokit:

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
rokit init
rokit add rojo-rbx/rojo@7.6.1
python --version
rojo --version
```

#### macOS

Install Roblox Studio from the official Roblox Creator site, then:

```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
rokit init
rokit add rojo-rbx/rojo@7.6.1
python3 --version
rojo --version
```

#### Linux / WSL

Roblox Studio is not supported natively here. Linux/WSL can prepare source and run Python
validation, but the import/playtest/publish/evidence gate must run in Roblox Studio on a Windows
or macOS host.

```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
rokit init
rokit add rojo-rbx/rojo@7.6.1
python3 --version
rojo --version
```

**Hard stop:** if Roblox Studio is unavailable on Windows/macOS, stop before claiming the game has
been imported, visually verified, performance-tested, or published.

For the evidence bridge, start the collector in the project root before running the Studio plugin:

```bash
python skills/goal-to-game/engines/roblox/tools/evidence_collector.py \
  --output evidence/roblox-run
```

The Studio plugin talks only to `127.0.0.1`. Studio may prompt once for permission for that local
address. Never expose the collector on a public network interface.

'''

patch(
    ROOT / "README.md",
    [
        (
            "Goal to Game currently supports **Unity** and **Three.js**.",
            "Goal to Game currently supports **Unity**, **Three.js**, and **Roblox Studio**.",
            "README engine list",
        ),
        (
            "describe the game and name the engine (three.js or Unity):",
            "describe the game and name the engine (three.js, Unity, or Roblox Studio):",
            "README prompt engine list",
        ),
    ],
)

patch(
    ROOT / "skills/goal-to-game/SKILL.md",
    [
        (
            "description: Generates polished, fully playable 3D game prototypes in Unity or three.js, with high quality (.glb) meshes generated through the Thrixel API. Use when the user wants to make a game, build a playable prototype, or generate 3D assets.",
            "description: Generates polished, fully playable 3D game prototypes in Unity, three.js, or Roblox Studio, with high quality (.glb) meshes generated through the Thrixel API. Use when the user wants to make a game, build a playable prototype, or generate 3D assets.",
            "SKILL frontmatter engines",
        ),
        (
            "- **three.js**: run the capture tooling and show the frames, and give them the dev-server URL\n  so they can play it themselves.\n- **Unity**: make sure the scene opens and plays, and say exactly what to press.\n",
            "- **three.js**: run the capture tooling and show the frames, and give them the dev-server URL\n  so they can play it themselves.\n- **Unity**: make sure the scene opens and plays, and say exactly what to press.\n- **Roblox Studio**: run the Studio verification plugin, preserve the evidence bundle, and give the\n  user the playable place or published URL.\n",
            "SKILL out-of-cubes Roblox presentation",
        ),
        (
            "- **Unity** → [engines/unity.md](engines/unity.md)\n- **three.js / web** → [engines/threejs/threejs.md](engines/threejs/threejs.md)\n",
            "- **Unity** → [engines/unity.md](engines/unity.md)\n- **three.js / web** → [engines/threejs/threejs.md](engines/threejs/threejs.md)\n- **Roblox Studio / Roblox** → [engines/roblox.md](engines/roblox.md)\n",
            "SKILL target engine list",
        ),
    ],
)

setup_path = ROOT / "skills/goal-to-game/SetupAndInstallationFlow.md"
setup_text, setup_newline = read_preserving_newlines(setup_path)
if "### Roblox Studio Installation" not in setup_text:
    anchor = "### Unity Installation\n"
    if setup_text.count(anchor) != 1:
        raise RuntimeError("Setup flow: Unity installation anchor not found exactly once")
    setup_text = setup_text.replace(anchor, roblox_setup + anchor, 1)
    write_preserving_newlines(setup_path, setup_text, setup_newline)
    print("patched: Setup Roblox toolchain")
else:
    print("already patched: Setup Roblox toolchain")

gitignore = ROOT / ".gitignore"
git_text, git_newline = read_preserving_newlines(gitignore)
if ".roblox-evidence-runtime/" not in git_text.splitlines():
    if git_text and not git_text.endswith("\n"):
        git_text += "\n"
    git_text += ".roblox-evidence-runtime/\n"
    write_preserving_newlines(gitignore, git_text, git_newline)
    print("patched: .gitignore runtime evidence state")
else:
    print("already patched: .gitignore runtime evidence state")

# This helper is intentionally temporary; its deletion becomes part of the integration commit.
Path(__file__).unlink()
print("done: integration files patched; temporary helper removed")
