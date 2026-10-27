"""P11E acceptance for domain-owned automatic-flow semantic IDs."""

from __future__ import annotations

from pathlib import Path
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class SemanticTaxonomyP11ETests(unittest.TestCase):
    def test_loaded_automatic_pools_use_domain_ids_and_keep_provenance(self):
        expected = {
            "semantic.command.follow.queued": {
                "workflowKind": "simple_command",
                "actionID": "FOLLOW",
            },
            "semantic.task.consume.active": {
                "workflowKind": "parameterized_task",
                "actionID": "CONSUME",
            },
            "semantic.gift.pending": {
                "workflowKind": "multi_stage_gift",
                "actionID": "GIFT",
            },
        }
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            listing = worker.flow_catalog()["responsePoolCatalog"]
            ids = {row["id"] for row in listing}
            self.assertFalse(any(
                pool_id.startswith("semantic." + "generated.")
                for pool_id in ids
            ))
            for pool_id, metadata in expected.items():
                detail = worker.response_pool_detail(pool_id, limit=1)
                self.assertTrue(detail["ok"], detail)
                provenance = detail["provenance"]
                self.assertEqual(provenance["origin"], "automatic_flow")
                self.assertEqual(provenance["workflowKind"],
                                 metadata["workflowKind"])
                self.assertEqual(provenance["actionID"], metadata["actionID"])
                self.assertIsInstance(provenance["templateVersion"], int)
                self.assertTrue(provenance["templateFingerprint"])

    def test_production_lua_contains_no_generated_semantic_taxonomy_prefix(self):
        root = Path(__file__).resolve().parents[3]
        lua_root = root / "Contents/mods/ProjectHoomans"
        legacy_prefix = "semantic." + "generated."
        offenders = []
        for path in lua_root.rglob("*.lua"):
            if legacy_prefix in path.read_text(encoding="utf-8"):
                offenders.append(path.relative_to(root).as_posix())
        self.assertEqual(offenders, [])

    def test_follow_and_task_dispatch_still_select_domain_pools(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            follow = worker.input("Follow me")
            task = worker.input("Wait at the campfire")

        self.assertTrue(follow["result"]["flow"]["generated"])
        self.assertTrue(task["result"]["flow"]["generated"])
        self.assertTrue(
            follow["result"]["flow"]["responsePool"]
            .startswith("semantic.command.")
        )
        self.assertTrue(
            task["result"]["flow"]["responsePool"]
            .startswith("semantic.task.")
        )
        self.assertEqual(follow["transport"][0]["payload"]["commandID"],
                         "follow")
        self.assertEqual(task["transport"][0]["payload"]["action"],
                         "WAIT_AT")


if __name__ == "__main__":
    unittest.main()
