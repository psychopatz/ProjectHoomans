"""tests for bounded batch execution, manifest management, and resume logic."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.testing.sweep_batch import (
    MANIFEST_SCHEMA_V1,
    StaleFingerprintError,
    SweepBatch,
    SweepBatchExecutor,
    SweepExecutionCancelled,
    SweepManifest,
    split_plan_into_batches,
)
from tools.semantic_harness.testing.sweep_dimensions import extract_dimension_inventory
from tools.semantic_harness.testing.sweep_planner import CoveragePlan, CoveragePlanner, PlannedCase


class SweepBatchTests(unittest.TestCase):
    def setUp(self) -> None:
        self.mock_control_catalog = {
            "controls": [
                {
                    "id": "relationship.approval",
                    "path": "npc.standing.approval",
                    "label": "Approval",
                    "valueType": "number",
                    "control": "slider",
                    "min": -100.0,
                    "max": 100.0,
                    "workbenchPanel": "Relationship",
                },
                {
                    "id": "runtime.language",
                    "path": "runtime.language",
                    "label": "Language",
                    "valueType": "enum",
                    "control": "combobox",
                    "options": ["EN", "TL"],
                    "workbenchPanel": "World",
                },
            ]
        }
        self.inventory = extract_dimension_inventory(control_catalog=self.mock_control_catalog)
        self.planner = CoveragePlanner(self.inventory, sweep_id="batch_test_sweep")

    def test_split_plan_into_bounded_batches(self) -> None:
        # Create a synthetic plan with 150 cases
        cases = [
            PlannedCase(
                case_id=f"case_{i}",
                sweep_id="test",
                strategy="smoke",
                surface="scenario.utterance:hello",
                parameters={},
            )
            for i in range(150)
        ]
        plan = CoveragePlan(
            sweep_id="test",
            strategy="smoke",
            plan_digest="abc",
            catalog_fingerprint="fingerprint1",
            cases=cases,
            total_cases=150,
            estimated_batches=3,
            batch_size=64,
        )

        batches = split_plan_into_batches(plan, batch_size=64)
        self.assertEqual(len(batches), 3)
        self.assertEqual(batches[0].cases_count, 64)
        self.assertEqual(batches[1].cases_count, 64)
        self.assertEqual(batches[2].cases_count, 22)
        self.assertEqual(batches[0].batch_id, "batch-0000")
        self.assertEqual(batches[1].batch_id, "batch-0001")
        self.assertEqual(batches[2].batch_id, "batch-0002")

    def test_manifest_serialization_and_atomic_save(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            batches = [
                SweepBatch(batch_id="batch-0000", sweep_id="test", case_ids=["c1", "c2"], cases_count=2)
            ]
            manifest = SweepManifest(
                sweep_id="test",
                strategy="smoke",
                plan_digest="digest123",
                catalog_fingerprint="fp123",
                total_cases=2,
                batch_size=64,
                batches=batches,
                artifact_directory=tmpdir,
            )
            p = manifest.save(tmpdir)
            self.assertTrue(p.exists())

            loaded = SweepManifest.load(p)
            self.assertEqual(loaded.schema, MANIFEST_SCHEMA_V1)
            self.assertEqual(loaded.sweep_id, "test")
            self.assertEqual(loaded.catalog_fingerprint, "fp123")
            self.assertEqual(len(loaded.batches), 1)
            self.assertEqual(loaded.batches[0].case_ids, ["c1", "c2"])

    def test_stale_fingerprint_rejection(self) -> None:
        manifest = SweepManifest(
            sweep_id="test",
            strategy="smoke",
            plan_digest="d",
            catalog_fingerprint="original_fingerprint",
            total_cases=1,
            batch_size=64,
            batches=[],
        )
        # Identical fingerprint passes
        manifest.validate_catalog_fingerprint("original_fingerprint")

        # Changed fingerprint raises StaleFingerprintError
        with self.assertRaises(StaleFingerprintError) as ctx:
            manifest.validate_catalog_fingerprint("new_incompatible_fingerprint")
        self.assertIn("production catalog fingerprint changed", str(ctx.exception))

    def test_cancellation_and_resumption(self) -> None:
        """Verify that cancelling a batch marks it CANCELLED, and subsequent resume finishes cases."""
        with tempfile.TemporaryDirectory() as tmpdir:
            plan = self.planner.plan_smoke(
                surfaces=("scenario.utterance:hello",),
                languages=("EN", "TL"),
            )
            executor = SweepBatchExecutor(
                plan,
                self.inventory,
                artifact_dir=tmpdir,
                worker_factory=LuaSemanticWorker,
                batch_size=64,
            )
            # Cancel immediately before execution
            with self.assertRaises(SweepExecutionCancelled):
                executor.execute_next_batch(is_cancelled=lambda: True)

            self.assertEqual(executor.manifest.status, "CANCELLED")
            self.assertEqual(executor.manifest.batches[0].status, "CANCELLED")

            # Resuming should pick up the CANCELLED batch and complete it
            resume_executor = SweepBatchExecutor(
                plan,
                self.inventory,
                artifact_dir=tmpdir,
                worker_factory=LuaSemanticWorker,
                batch_size=64,
            )
            resumed_batch = resume_executor.execute_next_batch()
            self.assertIsNotNone(resumed_batch)
            self.assertEqual(resumed_batch.status, "COMPLETED")
            self.assertEqual(resumed_batch.completed_cases, 2)
            self.assertEqual(resume_executor.manifest.status, "COMPLETED")

            # Ensure both cases executed without duplicate case executions
            rows = list(resume_executor.iter_evidence_rows())
            executed_case_ids = set(r["identity"]["caseID"] for r in rows)
            self.assertEqual(len(executed_case_ids), 2)
            self.assertGreaterEqual(len(rows), 2)

    def test_stale_root_choice_detected_as_invalid_surface(self) -> None:
        """Verify that attempting to execute a stale root choice marks batch as COMPLETED_WITH_INVALID_SURFACE."""
        with tempfile.TemporaryDirectory() as tmpdir:
            plan = self.planner.plan_smoke(
                surfaces=("scenario.rootChoice:wellbeing",),
                languages=("EN",),
            )
            executor = SweepBatchExecutor(
                plan,
                self.inventory,
                artifact_dir=tmpdir,
                worker_factory=LuaSemanticWorker,
                batch_size=64,
            )
            batch = executor.execute_next_batch()
            self.assertIsNotNone(batch)
            self.assertEqual(batch.status, "COMPLETED_WITH_INVALID_SURFACE")
            self.assertGreaterEqual(batch.invalid_surface_cases, 1)

            rows = list(executor.iter_evidence_rows())
            self.assertEqual(len(rows), 1)
            row = rows[0]
            self.assertEqual(row["identity"]["surfaceStatus"], "INVALID_SURFACE")
            flags = [f["name"] for f in row["quality"]["flags"]]
            self.assertIn("INVALID_SURFACE", flags)

    def test_real_lua_batch_execution_and_resume(self) -> None:
        """Integration with real LuaSemanticWorker running 2 cases and testing resume."""
        with tempfile.TemporaryDirectory() as tmpdir:
            plan = self.planner.plan_smoke(
                surfaces=("scenario.rootChoice:ask_name",),
                languages=("EN", "TL"),
            )
            self.assertEqual(plan.total_cases, 2)

            # First run: execute batch-0000
            executor = SweepBatchExecutor(
                plan,
                self.inventory,
                artifact_dir=tmpdir,
                worker_factory=LuaSemanticWorker,
                batch_size=64,
            )
            batch = executor.execute_next_batch()
            self.assertIsNotNone(batch)
            self.assertEqual(batch.status, "COMPLETED")
            self.assertEqual(batch.completed_cases, 2)
            self.assertEqual(executor.manifest.status, "COMPLETED")

            # Verify evidence.jsonl contents
            evidence_rows = list(executor.iter_evidence_rows())
            self.assertGreaterEqual(len(evidence_rows), 2)
            for row in evidence_rows:
                self.assertEqual(row["schema"], "pnc.semantic-dialogue-quality-evidence.v1")
                self.assertIsNotNone(row["output"]["finalText"])
                self.assertEqual(row["identity"]["surfaceStatus"], "MATCHED")

            # Test resume: creating a new executor pointing to the same directory
            # should see batch already completed and return None
            resume_executor = SweepBatchExecutor(
                plan,
                self.inventory,
                artifact_dir=tmpdir,
                worker_factory=LuaSemanticWorker,
                batch_size=64,
            )
            next_batch = resume_executor.execute_next_batch()
            self.assertIsNone(next_batch)


if __name__ == "__main__":
    unittest.main()
