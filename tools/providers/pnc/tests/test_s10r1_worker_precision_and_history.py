"""Migrated real-worker acceptance for C7F precision, patterns, backstory specs, and interaction history."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.providers.pnc.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.codebuilder.c7f_holdout import (
    HOLDOUT_PATH,
    load_c7f_holdout,
    score_c7f_holdout,
)
from tools.semantic_harness.codebuilder.dialogue_dataset import compile_dialogue_dataset
from tools.semantic_harness.codebuilder.interaction_spec import (
    compile_interaction_spec,
    graph_block,
    graph_connection,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.entrypoints.cli import _parser, cli
from tools.semantic_harness.inspection.conversation_inspector import (
    build_conversation_inspector,
)

HOOMANS_ROOT = Path(__file__).resolve().parents[4]
CORE_ROOT = HOOMANS_ROOT.parent / "psychopatzCore"
DT_ROOT = HOOMANS_ROOT.parent / "DynamicTrading"


class S10R1WorkerPrecisionAndHistoryTests(unittest.TestCase):
    def test_common_patterns_compile_and_heldout_c7f_worker_scores_perfect(self) -> None:
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

    def test_real_worker_backstory_navigation_and_cli_inspect_interaction_history(self) -> None:
        backstory_spec = {
            "schema": "semantic.interaction_spec.v1",
            "id": "pnc.lab.former_job",
            "owner": "SemanticLab",
            "blocks": [
                graph_block(
                    "trigger",
                    "language.trigger",
                    parameters={
                        "utterance": "what did you do before all this",
                        "negativeUtterance": "do not talk about before",
                        "frame": {"intent": "QUESTION", "speechAct": "QUESTION"},
                    },
                ),
                graph_block(
                    "backstory",
                    "language.backstory_subject",
                    parameters={
                        "backstoryKind": "former_job",
                        "factProvider": "npc_backstory",
                        "topicID": "backstory.former_job",
                        "disclosure": "server_authorized",
                    },
                ),
                graph_block(
                    "fact",
                    "memory.backstory_fact",
                    parameters={
                        "providerID": "npc_backstory",
                        "subject": "NPC_BACKSTORY",
                        "authority": "server",
                        "immutable": True,
                        "privacy": "private",
                    },
                ),
                graph_block(
                    "response",
                    "dialogue_responses.response_pool",
                    parameters={
                        "poolID": "semantic.lab.former_job",
                        "variants": [{
                            "id": "answered",
                            "key": "UI_PNC_Conversation_Semantic_LabFormerJob",
                            "translations": {
                                "EN": "I worked as %1 before all this.",
                                "TL": "Nagtrabaho ako bilang %1 bago ito.",
                            },
                        }],
                    },
                ),
            ],
            "connections": [
                graph_connection("trigger", "backstory", "semantic"),
                graph_connection("backstory", "fact", "fact"),
                graph_connection("fact", "response", "response"),
            ],
        }
        base_doc = {
            "schemaVersion": 1,
            "source": {
                "name": "ConvoEngine Fixture",
                "version": "1",
                "contentLicense": "first_party",
                "references": [{
                    "name": "ConvoEngine Fixture",
                    "url": "https://example.invalid/fixture",
                    "use": "unit_test_fixture",
                    "license": "first_party",
                    "reviewedOn": "2026-11-16",
                    "version": "1",
                    "contentLicense": "first_party",
                    "importStatus": {"imported": 1},
                }],
            },
            "patterns": [],
            "responsePools": [],
        }
        compiled_spec = compile_interaction_spec(backstory_spec, base_doc)
        self.assertTrue(compiled_spec["ok"], compiled_spec)

        scenario = merge(DEFAULT_SCENARIO, {})
        with LuaSemanticWorker(scenario) as worker:
            backstory = worker.input("what did you do before all this")
            follow = worker.input("follow me")
            self.assertTrue(backstory["accepted"])
            self.assertTrue(follow["accepted"])
            inspector = build_conversation_inspector(follow)
            self.assertEqual(inspector["source"], "real_lua_worker")

        args = _parser().parse_args([
            "--no-gui",
            "--preset",
            "pnc",
            "--core-repository",
            str(CORE_ROOT),
            "--repository",
            str(HOOMANS_ROOT),
            "--inspect-interaction-history",
            "--jsonl",
        ])
        out = io.StringIO()
        with redirect_stdout(out):
            rc = cli(args)
        self.assertEqual(rc, 0)
        lines = [json.loads(line) for line in out.getvalue().splitlines() if line.strip()]
        history_record = next(row for row in lines if row.get("type") == "actor_inspection")
        self.assertIn("interactionHistory", history_record)


if __name__ == "__main__":
    unittest.main()
