import importlib.util
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parents[1]
TOOLS = HERE / "tools"


def load(name):
    spec = importlib.util.spec_from_file_location(name, TOOLS / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class EvidenceTests(unittest.TestCase):
    def test_runtime_plugin_generation_preserves_tracked_source(self):
        injector = load("inject_collector_token")
        tracked = HERE / "plugin" / "GoalToGameVerifier.plugin.lua"
        original = tracked.read_bytes()
        with tempfile.TemporaryDirectory() as td:
            output = Path(td) / "GoalToGameVerifier.session.lua"
            injector.write_runtime_plugin(tracked, output, 'session-"token')
            generated = output.read_text(encoding="utf-8")
            self.assertIn(
                'local TOKEN = "session-\\\"token" -- GOAL_TO_GAME_TOKEN_ASSIGNMENT', generated
            )
            self.assertIn(injector.PLACEHOLDER_DECLARATION, generated)
            self.assertIn("assert(TOKEN ~= TOKEN_PLACEHOLDER", generated)
        self.assertEqual(original, tracked.read_bytes())

    def test_runtime_plugin_refuses_tracked_source_as_output(self):
        injector = load("inject_collector_token")
        tracked = HERE / "plugin" / "GoalToGameVerifier.plugin.lua"
        original = tracked.read_bytes()
        with self.assertRaisesRegex(ValueError, "must not overwrite"):
            injector.write_runtime_plugin(tracked, tracked, "session-token")
        self.assertEqual(original, tracked.read_bytes())

    def test_token_injection_rejects_invalid_token(self):
        injector = load("inject_collector_token")
        plugin = (HERE / "plugin" / "GoalToGameVerifier.plugin.lua").read_text(encoding="utf-8")
        for token in ("", "line1\nline2"):
            with self.subTest(token=token), self.assertRaises(ValueError):
                injector.inject_token(plugin, token)

    def test_documentation_makes_studio_mcp_primary_and_keeps_six_views(self):
        guide = (HERE.parent / "roblox.md").read_text(encoding="utf-8")
        self.assertIn("Roblox Studio MCP is the primary", guide)
        for tool in (
            "list_roblox_studios",
            "get_studio_state",
            "search_game_tree",
            "inspect_instance",
            "execute_luau",
            "screen_capture",
        ):
            self.assertIn(f"`{tool}`", guide)
        for view in ("front", "rear", "left", "right", "top", "gameplay"):
            self.assertIn(f"`{view}`", guide)

    def test_plugin_records_audit_before_screenshot_capability_probe(self):
        plugin = (HERE / "plugin" / "GoalToGameVerifier.plugin.lua").read_text(encoding="utf-8")
        run = plugin[plugin.index("local function run()") :]
        self.assertLess(run.index('name = "studio-audit"'), run.index("CanCaptureScreenshot"))

    def test_plugin_has_explicit_capture_stage_diagnostics(self):
        plugin = (HERE / "plugin" / "GoalToGameVerifier.plugin.lua").read_text(encoding="utf-8")
        for stage in (
            "audit",
            "collector-record",
            "CanCaptureScreenshot",
            "RequestScreenshotPermissionAsync",
            "CaptureScreenshot",
            "GetBuffer",
            "Base64Encode",
            "collector-capture",
        ):
            self.assertIn(f'"{stage}"', plugin)

    def test_capture_screenshot_callback_is_closed_with_end(self):
        plugin = (HERE / "plugin" / "GoalToGameVerifier.plugin.lua").read_text(encoding="utf-8")
        capture = plugin[plugin.index('stageCall("CaptureScreenshot", function()') :]
        capture = capture[: capture.index("local errors")]
        self.assertIn("        })\n    end)", capture)
        self.assertNotIn("        })\n    })", capture)

    def test_sink_hashes_written_artifact(self):
        c = load("evidence_collector")
        with tempfile.TemporaryDirectory() as td:
            sink = c.Sink(Path(td), "x")
            e = sink.store("records", "x.json", b"{}", "application/json")
            self.assertEqual(e["sha256"], c.sha256(b"{}"))
            self.assertTrue((Path(td) / "ledger.jsonl").exists())

    def test_sink_rejects_path_escape(self):
        c = load("evidence_collector")
        with tempfile.TemporaryDirectory() as td:
            sink = c.Sink(Path(td), "x")
            with self.assertRaises(ValueError):
                sink.store("records", "../evil.json", b"x", "text/plain")

    def test_public_url_rejects_placeholders(self):
        v = load("validate_evidence")
        self.assertFalse(v.good_public_url("https://example.com/replace-with-game"))
        self.assertTrue(v.good_public_url("https://www.roblox.com/games/123/test", "roblox.com"))


if __name__ == "__main__":
    unittest.main()
