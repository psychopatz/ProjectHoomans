"""Developer P7 bounds/side-effect verification against the *real Lua worker*.

Keep environmental performance numbers reported, not brittle timing asserts.
No native PZ, persistent save or fixture source is modified by these tests.
"""
from __future__ import annotations

from hashlib import sha256
import json
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.activity import ActivityLog
from tools.semantic_harness.runtime.process import HarnessError
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class ObservatoryP7ScaleTests(unittest.TestCase):
    def test_catalog_paging_exhaustive_worker_registry_no_duplication(self):
        with tempfile.TemporaryDirectory(prefix="pnc-observatory-p7-") as temp:
            with LuaSemanticWorker(
                DEFAULT_SCENARIO,
                activity_log=ActivityLog(path=Path(temp) / "activity.jsonl", client="p7"),
            ) as worker:
                rows = []
                offset = 0
                while True:
                    page = worker.response_pool_list(offset=offset, limit=32)
                    self.assertEqual(page["schemaVersion"], 1)
                    self.assertEqual(page["offset"], offset)
                    self.assertLessEqual(len(page["pools"]), 32)
                    self.assertLess(len(json.dumps(page)), 32 * 1024)
                    rows.extend(page["pools"])
                    offset += len(page["pools"])
                    if not page["hasMore"]:
                        break
                self.assertEqual(len(rows), page["total"])
                self.assertEqual(len(rows), len({row["id"] for row in rows}))
                self.assertGreater(len(rows), 0)

                # A read-only request must never accidentally omit auto-generated
                # pools until FLOW_CATALOG happens to be called first.
                original_count = len(rows)
                full = worker.flow_catalog()
                second = worker.response_pool_list(limit=32)
                self.assertEqual(original_count, len(full["responsePoolCatalog"]))
                self.assertEqual(original_count, second["total"])
                self.assertEqual(page["registryRevision"],
                                 second["registryRevision"])
                revision = page["registryRevision"]
                for row in rows:
                    detail = worker.response_pool_detail(row["id"], limit=16)
                    self.assertEqual(detail["variantCount"], row["variantCount"])
                    self.assertEqual(detail["registryRevision"], revision)
                    self.assertLessEqual(len(detail["variants"]), 16)
                    self.assertEqual(detail["hasMore"],
                                     detail["variantCount"] > 16)
                    self.assertLess(len(json.dumps(detail)), 32 * 1024)
                    self.assertTrue(detail["contentFingerprint"].startswith("catalog-v1:"))

    def test_repeated_inspection_is_read_only_across_actor_state_and_source(self):
        root = Path(__file__).resolve().parents[3]
        watched = [
            root / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticDialogueResponseCatalog_Selection.lua",
            root / "Contents/mods/ProjectHoomans/common/media/translation/TL/Conversation/Semantic/GeneratedTaskCommands.json",
        ]
        hashes = lambda: [sha256(path.read_bytes()).hexdigest() for path in watched]
        before_files = hashes()
        with tempfile.TemporaryDirectory(prefix="pnc-observatory-p7-") as temp:
            with LuaSemanticWorker(
                DEFAULT_SCENARIO,
                activity_log=ActivityLog(path=Path(temp) / "activity.jsonl", client="p7"),
            ) as worker:
                before = worker.inspect_actor_state()
                first = None
                for index in range(270):
                    result = worker.explain_response_selection(
                        "semantic.flow.greeting.opening",
                        {"npcID": "p7-inspection-only",
                         "worldContext": {"weather": {"raining": True}}},
                        "fixed-salt",
                    )
                    if first is None:
                        first = result
                    self.assertEqual(result["selectedID"], first["selectedID"])
                    self.assertFalse(result["rotated"])
                after = worker.inspect_actor_state()
                for envelope in (before, after):
                    envelope.pop("id", None)
                    envelope.pop("protocolVersion", None)
                self.assertEqual(before, after)
        self.assertEqual(before_files, hashes())

    def test_worker_survives_invalid_bounded_queries(self):
        with tempfile.TemporaryDirectory(prefix="pnc-observatory-p7-") as temp:
            with LuaSemanticWorker(
                DEFAULT_SCENARIO,
                activity_log=ActivityLog(path=Path(temp) / "activity.jsonl", client="p7"),
            ) as worker:
                for query in (
                    lambda: worker.response_pool_list(limit=65),
                    lambda: worker.response_pool_list(offset=-1),
                    lambda: worker.response_pool_detail("nonexistent.response.pool"),
                    lambda: worker.response_pool_detail(
                        "semantic.flow.greeting.opening", limit=17),
                ):
                    with self.assertRaises(HarnessError):
                        query()
                normal = worker.response_pool_detail(
                    "semantic.flow.greeting.opening", limit=2)
                self.assertTrue(normal["ok"])
                self.assertEqual(len(normal["variants"]), 2)


if __name__ == "__main__":
    unittest.main()
