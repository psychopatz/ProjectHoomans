"""C7F reviewed-data precision/recall on the production Lua worker."""

from __future__ import annotations

from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.c7f_holdout import (
    HOLDOUT_PATH,
    load_c7f_holdout,
    score_c7f_holdout,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.codebuilder.dialogue_dataset import (
    compile_dialogue_dataset,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]

class C7FDatasetPrecisionTests(unittest.TestCase):
    def test_codebuilder_compiles_reviewed_concept_match_and_new_patterns(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        source = service.load_dataset_document("common_dialogue")
        compiled = compile_dialogue_dataset(source)
        pattern = next(
            item for item in compiled["patterns"]
            if item["id"] == "pnc.dataset.massive.weather.what_is_the_weather_like"
        )
        self.assertEqual(
            pattern["match"],
            [
                {"kind": "concept", "id": "WEATHER"},
                {"kind": "literal", "value": "like"},
            ],
        )
        self.assertTrue(
            any(
                item["id"] == "pnc.dataset.massive.weather.is_it_still_snowing"
                for item in compiled["patterns"]
            )
        )
        report = service.preview_dataset_generation("common_dialogue")
        self.assertTrue(report["ok"], report)
        self.assertEqual(report["summary"]["patterns"], 47)
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["writes"], [])
        self.assertTrue(report["generatedArtifactDiffs"])

    def test_heldout_reviewed_sources_measure_real_worker_precision_recall(self) -> None:
        document = load_c7f_holdout(HOLDOUT_PATH)
        cases = document["cases"]
        turns = []
        for case in cases:
            with self.subTest(case=case["id"]):
                with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
                    for setup in case.get("setup", []):
                        worker.input(setup)
                    turns.append(worker.input(case["utterance"]))

        report = score_c7f_holdout(cases, turns)
        self.assertEqual(report["caseCount"], len(cases))
        self.assertEqual(report["truePositive"], 9)
        self.assertEqual(report["falsePositive"], 0)
        self.assertEqual(report["falseNegative"], 0)
        self.assertEqual(report["precision"], 1.0)
        self.assertEqual(report["recall"], 1.0)
        self.assertEqual(report["falseExecutableDispatch"], 0)
        self.assertEqual(report["falseExecutableDispatchRate"], 0.0)
        self.assertTrue(all(row["semanticMatch"] for row in report["cases"]))
        self.assertTrue(all(not row["effects"] for row in report["cases"]))


if __name__ == "__main__":
    unittest.main()
