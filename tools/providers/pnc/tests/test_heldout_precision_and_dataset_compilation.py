"""Dataset compilation and held-out precision acceptance for the production Lua worker."""

from __future__ import annotations

from pathlib import Path
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.codebuilder.c7f_holdout import (
    HOLDOUT_PATH,
    load_c7f_holdout,
    score_c7f_holdout,
)
from tools.semantic_harness.codebuilder.dialogue_dataset import compile_dialogue_dataset
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService

HOOMANS_ROOT = Path(__file__).resolve().parents[4]
CORE_ROOT = HOOMANS_ROOT.parent / "psychopatzCore"
DT_ROOT = HOOMANS_ROOT.parent / "DynamicTrading"


class HeldoutPrecisionAndDatasetCompilationTests(unittest.TestCase):
    def test_common_patterns_compile_and_heldout_worker_scores_perfect(self) -> None:
        service = SemanticLabAuthoringService(
            repository=CORE_ROOT,
            runtime_root=CORE_ROOT,
            core_repository=CORE_ROOT,
            dynamic_trading_repository=DT_ROOT if DT_ROOT.is_dir() else None,
        )
        source = service.load_dataset_document("common_patterns")
        compiled = compile_dialogue_dataset(source)
        pattern = next(
            item
            for item in compiled["patterns"]
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
        report = service.preview_dataset_generation("common_patterns")
        self.assertTrue(report["ok"], report)
        self.assertTrue(report["previewOnly"])
        self.assertEqual(report["writes"], [])

        holdout = load_c7f_holdout(HOLDOUT_PATH)
        cases = holdout["cases"]
        turns = []
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            for case in cases:
                worker.reset_working_world()
                for setup in case.get("setup", []):
                    worker.input(setup)
                turns.append(worker.input(case["utterance"]))

        scored = score_c7f_holdout(cases, turns)
        self.assertEqual(scored["caseCount"], len(cases))
        self.assertEqual(scored["precision"], 1.0)
        self.assertEqual(scored["recall"], 1.0)
        self.assertEqual(scored["falseExecutableDispatch"], 0)
        self.assertTrue(all(row["semanticMatch"] for row in scored["cases"]))


if __name__ == "__main__":
    unittest.main()
