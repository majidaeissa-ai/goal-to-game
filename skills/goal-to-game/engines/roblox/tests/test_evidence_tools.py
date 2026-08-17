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
