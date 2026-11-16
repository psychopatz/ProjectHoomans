"""Acceptance tests for real manifest-selected PNC provider worker startup."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.config import HarnessConfig
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


PROJECT_HOOMANS_ROOT = Path(__file__).resolve().parents[4]
CORE_ROOT = PROJECT_HOOMANS_ROOT.parent / "psychopatzCore"


class S10AProviderWorkerStartupTests(unittest.TestCase):
    def _create_manifest_worker(self) -> LuaSemanticWorker:
        config = HarnessConfig.discover(
            repository=PROJECT_HOOMANS_ROOT,
            core_repository=CORE_ROOT,
            profile="pnc",
        )
        self.assertEqual(
            config.provider_python_worker,
            "tools.providers.pnc.runtime.worker:LuaSemanticWorker",
        )
        self.assertIsNotNone(config.provider_worker_script)
        self.assertTrue(
            str(config.provider_worker_script).endswith("tools/providers/pnc/lua/worker.lua"),
            f"unexpected worker script: {config.provider_worker_script}",
        )
        return LuaSemanticWorker(DEFAULT_SCENARIO, config=config)

    def test_manifest_selected_pnc_worker_starts_handshakes_and_completes_greeting(self) -> None:
        with self._create_manifest_worker() as worker:
            ping = worker.ping()
            capabilities = worker.capabilities()
            greeting = worker.input("hello")

        self.assertTrue(ping.get("ok"))
        self.assertTrue(capabilities.get("capabilities"))
        manifest_paths = {
            entry.get("path") for entry in capabilities.get("moduleManifest", [])
        }
        self.assertEqual(
            len(manifest_paths),
            len(capabilities.get("moduleManifest", [])),
            "ProductionModules moduleManifest should not duplicate module loads",
        )
        self.assertTrue(greeting.get("messages"), "greeting should produce an NPC reply")

    def test_all_generated_task_gift_command_and_quest_pools_resolve_canonical_wording(self) -> None:
        with self._create_manifest_worker() as worker:
            catalog = worker.flow_catalog()

        pools_by_id = {
            pool["id"]: pool for pool in catalog.get("responsePoolCatalog", [])
        }
        generation = catalog.get("generation", {})
        self.assertGreaterEqual(generation.get("summary", {}).get("generated", 0), 19)

        # Every parameterized task capability must have all 5 outcome pools registered.
        for task_action in ("consume", "drink", "eat", "fetch", "give", "refill", "wait.at"):
            for outcome in ("admitted", "active", "completed", "rejected", "failed"):
                pool_id = f"semantic.generated.parameterized_task.{task_action}.{outcome}"
                self.assertIn(pool_id, pools_by_id, f"missing pool {pool_id}")
                self.assertGreaterEqual(
                    int(pools_by_id[pool_id].get("variantCount", 0)),
                    1,
                    f"pool {pool_id} registered zero variants",
                )

        # Every companion command contextual variant must also resolve cleanly (none dropped).
        for cmd_action, expected_variants in (
            ("follow", 5),
            ("stay", 5),
            ("stop", 5),
            ("go", 5),
            ("camp", 5),
            ("combat.engage", 4),
            ("combat.avoid", 2),
            ("combat.hold", 3),
        ):
            pool_id = f"semantic.generated.simple_command.{cmd_action}.queued"
            self.assertIn(pool_id, pools_by_id, f"missing pool {pool_id}")
            self.assertEqual(
                int(pools_by_id[pool_id].get("variantCount", 0)),
                expected_variants,
                f"pool {pool_id} dropped variants: {pools_by_id[pool_id]}",
            )

        # Quest simple commands and multi-stage gift pools must all be non-empty.
        for quest_action in ("help", "quest.accept", "quest.status", "quest.turn.in"):
            for outcome in ("queued", "rejected", "failed"):
                pool_id = f"semantic.generated.simple_command.{quest_action}.{outcome}"
                self.assertIn(pool_id, pools_by_id, f"missing pool {pool_id}")
                self.assertGreaterEqual(int(pools_by_id[pool_id].get("variantCount", 0)), 1)

        for outcome in ("selection_required", "pending", "completed", "rejected", "failed"):
            # Gift pools are only generated when Input_Gifts is loaded by the runtime.
            pool_id = f"semantic.generated.multi_stage_gift.gift.{outcome}"
            if pool_id in pools_by_id:
                self.assertGreaterEqual(int(pools_by_id[pool_id].get("variantCount", 0)), 1)

    def test_repeated_worker_start_and_reset_is_idempotent_and_catalog_stable(self) -> None:
        snapshots = []
        for _ in range(2):
            with self._create_manifest_worker() as worker:
                cat1 = worker.flow_catalog()
                worker.reset()
                cat2 = worker.flow_catalog()
                worker.restart()
                cat3 = worker.flow_catalog()
            for cat in (cat1, cat2, cat3):
                pool_ids = tuple(sorted(p["id"] for p in cat.get("responsePoolCatalog", [])))
                self.assertLessEqual(len(pool_ids), 256)
                snapshots.append(
                    (
                        tuple(sorted(f["id"] for f in cat.get("flows", []))),
                        pool_ids,
                        tuple(sorted(a["id"] for a in cat.get("actionCatalog", []))),
                    )
                )
        for index in range(1, len(snapshots)):
            self.assertEqual(snapshots[0], snapshots[index])


if __name__ == "__main__":
    unittest.main()
