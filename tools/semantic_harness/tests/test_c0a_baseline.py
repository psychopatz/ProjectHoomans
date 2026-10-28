"""Historical C0A evidence checks.

C0A snapshots characterize the pre-C1 worker. Later accepted phases must not
rewrite that evidence to match new behavior.
"""

from __future__ import annotations

import json
from pathlib import Path
import unittest

from tools.semantic_harness.c0a_baseline import capture_storage


REPOSITORY = Path(__file__).resolve().parents[3]
REPORT_ROOT = REPOSITORY / "tools/semantic_harness/reports/c0a"
FIXTURE_ROOT = REPOSITORY / "tools/semantic_harness/fixtures/c0a"


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


class C0AHistoricalEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls.semantic = read_json(REPORT_ROOT / "semantic_current.json")
        cls.multi_turn = read_json(REPORT_ROOT / "multi_turn_current.json")
        cls.suggestions = read_json(REPORT_ROOT / "suggestions_current.json")
        cls.realization = read_json(
            REPORT_ROOT / "reply_realization_current.json"
        )
        cls.storage = read_json(REPORT_ROOT / "storage_topology_current.json")

    def test_semantic_snapshot_is_historical_worker_evidence(self) -> None:
        self.assertEqual(len(self.semantic["cases"]), 23)
        self.assertTrue(all(
            case["currentSemantic"]["selected"].get(
                "provenance", {}
            ).get("provider") == "lua"
            for case in self.semantic["cases"]
            if case["currentSemantic"]["selected"]
        ))

    def test_expected_semantics_are_separate_from_historical_results(self) -> None:
        fixture = read_json(FIXTURE_ROOT / "semantic_corpus.json")
        current_ids = {case["id"] for case in self.semantic["cases"]}
        self.assertEqual(
            current_ids,
            {case["id"] for case in fixture["cases"]},
        )
        self.assertTrue(all(
            "expectedSemantic" not in case
            for case in self.semantic["cases"]
        ))
        self.assertTrue(all(
            "expectedSemantic" in case for case in fixture["cases"]
        ))

    def test_historical_mutation_safety_failure_remains_recorded(self) -> None:
        by_id = {case["id"]: case for case in self.semantic["cases"]}
        self.assertTrue(
            by_id["malformed_mutating_request_tail_typo"]["authority"][
                "attempted"
            ]
        )
        command = by_id["malformed_mutating_request_tail_typo"][
            "authority"
        ]["transportCommands"][0]["command"]
        self.assertEqual(command, "SemanticTaskRequest")

        # This snapshot is intentionally not a current-worker assertion.
        # C1+ live safety belongs in phase-specific regression tests.
        self.assertTrue(
            by_id["valid_mutating_request_control"]["authority"]["attempted"]
        )

    def test_multi_turn_snapshot_preserves_c0a_context_gap(self) -> None:
        scenarios = {
            scenario["id"]: scenario
            for scenario in self.multi_turn["scenarios"]
        }
        npc_question = scenarios[
            "npc_question_player_not_really"
        ]["turns"]
        self.assertEqual(
            npc_question[1]["currentSemantic"]["selected"]["intent"],
            "DISAGREE",
        )
        self.assertEqual(
            npc_question[1]["contextBefore"]["dialogue"][
                "pendingFollowUp"
            ]["flowID"],
            "greeting",
        )
        self.assertEqual(
            npc_question[1]["contextResolution"]["flowReason"],
            "cancel",
        )

    def test_suggestion_snapshot_preserves_typed_click_baseline(self) -> None:
        time_case = next(
            case
            for case in self.suggestions["cases"]
            if case["id"] == "time_reply_with_click"
        )
        self.assertEqual(
            time_case["click"]["typedFrameKind"],
            "semantic_click_frame",
        )
        self.assertEqual(
            time_case["click"]["turnEvidence"]["selected"][
                "provenance"
            ]["pattern"],
            "pnc.question.time",
        )

    def test_reply_realization_snapshot_preserves_authored_baseline(self) -> None:
        by_id = {
            case["id"]: case for case in self.realization["cases"]
        }
        self.assertEqual(
            by_id["retaliation_mirror"]["current"]["response"][
                "templateID"
            ],
            "semantic.interaction.argument.retaliate",
        )
        self.assertTrue(
            by_id["retaliation_mirror"]["current"]["evidence"][
                "messagePhraseFamilies"
            ]
        )
        self.assertEqual(
            by_id["ask_back_follow_up"]["current"]["evidence"][
                "planTurnCount"
            ],
            2,
        )

    def test_storage_snapshot_preserves_pre_c5_topology(self) -> None:
        overflow_names = {
            Path(item["module"]).name
            for item in self.storage["generated"]["numericOverflowShards"]
        }
        self.assertTrue(
            {"SocialPart02", "SocialPart03", "SocialPart04"}.issubset(
                overflow_names
            )
        )
        self.assertTrue(
            {"CommandPart02", "QuestionPart02"}.issubset(overflow_names)
        )
        opaque_names = {
            Path(item["module"]).name
            for item in self.storage["generated"]["opaqueNamedShards"]
        }
        self.assertEqual(opaque_names, {"Massive", "Sgd"})

    def test_storage_capture_remains_observer_only(self) -> None:
        paths = [
            REPOSITORY
            / "tools/semantic_harness/codebuilder/sources/conversation/"
            "manifest.json",
            REPOSITORY
            / "tools/semantic_harness/codebuilder/sources/conversation/"
            "content/social/reactions.json",
            REPOSITORY
            / "Contents/mods/ProjectHoomans/common/media/lua/shared/"
            "PNC/Semantics/Generated/Conversation/Content/Social/Reactions.lua",
            REPOSITORY
            / "Contents/mods/ProjectHoomans/common/media/lua/shared/"
            "PNC/Semantics/Generated/Conversation/Registry.lua",
        ]
        before = {path: path.read_bytes() for path in paths}
        capture_storage()
        self.assertEqual(
            before,
            {path: path.read_bytes() for path in paths},
        )

    def test_projection_source_is_observer_only(self) -> None:
        source = (
            REPOSITORY / "tools/semantic_harness/c0a_baseline.py"
        ).read_text(encoding="utf-8")
        self.assertIn("LuaSemanticWorker", source)
        self.assertIn("production Lua worker", source)
        self.assertNotIn("PsychopatzSemanticParser", source)
        self.assertNotIn("PsychopatzSemanticNormalizer", source)


if __name__ == "__main__":
    unittest.main()
