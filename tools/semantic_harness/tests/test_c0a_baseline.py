"""C0A snapshot checks for the real Project Hoomans semantic worker."""

from __future__ import annotations

import json
from pathlib import Path
import unittest

from tools.semantic_harness.c0a_baseline import (
    capture_multi_turn,
    capture_reply_realization,
    capture_semantic_corpus,
    capture_storage,
    capture_suggestions,
)


REPOSITORY = Path(__file__).resolve().parents[3]
REPORT_ROOT = REPOSITORY / "tools/semantic_harness/reports/c0a"
FIXTURE_ROOT = REPOSITORY / "tools/semantic_harness/fixtures/c0a"


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


class C0ABaselineTests(unittest.TestCase):
    """Characterization assertions; expected semantic labels are not used here."""

    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls.semantic = capture_semantic_corpus()
        cls.multi_turn = capture_multi_turn()
        cls.suggestions = capture_suggestions()
        cls.realization = capture_reply_realization()
        cls.storage = capture_storage()

    def test_semantic_corpus_matches_current_worker_snapshot(self) -> None:
        expected = read_json(REPORT_ROOT / "semantic_current.json")
        self.assertEqual(self.semantic, expected)
        self.assertEqual(len(self.semantic["cases"]), 23)
        self.assertTrue(all(
            case["currentSemantic"]["selected"].get("provenance", {}).get("provider") == "lua"
            for case in self.semantic["cases"]
            if case["currentSemantic"]["selected"]
        ))

    def test_expected_semantics_are_separate_from_current_results(self) -> None:
        fixture = read_json(FIXTURE_ROOT / "semantic_corpus.json")
        current_ids = {case["id"] for case in self.semantic["cases"]}
        self.assertEqual(current_ids, {case["id"] for case in fixture["cases"]})
        self.assertTrue(all("expectedSemantic" not in case for case in self.semantic["cases"]))
        self.assertTrue(all("expectedSemantic" in case for case in fixture["cases"]))

    def test_mutation_safety_controls_remain_observable(self) -> None:
        by_id = {case["id"]: case for case in self.semantic["cases"]}
        for case_id in (
            "compact_fuckyou",
            "compact_fuckyou_elongated",
            "compact_shutthefuckup",
            "compact_youidiot",
            "compact_youreuseless",
            "compact_illkillyou",
            "malformed_mutating_request_typo",
            "malformed_mutating_request_elongated",
        ):
            self.assertFalse(by_id[case_id]["authority"]["attempted"], case_id)
        # Current baseline failure: the tail typo is fuzzy-accepted and reaches
        # the task transport. The fixture's expected safety class remains
        # separate so this assertion characterizes, rather than blesses, it.
        self.assertTrue(by_id["malformed_mutating_request_tail_typo"]["authority"]["attempted"])
        self.assertEqual(
            by_id["malformed_mutating_request_tail_typo"]["authority"]["transportCommands"][0]["command"],
            "SemanticTaskRequest",
        )
        self.assertTrue(by_id["valid_mutating_request_control"]["authority"]["attempted"])
        self.assertEqual(
            by_id["valid_mutating_request_control"]["authority"]["transportCommands"][0]["command"],
            "SemanticTaskRequest",
        )

    def test_multi_turn_context_is_currently_recorded(self) -> None:
        expected = read_json(REPORT_ROOT / "multi_turn_current.json")
        self.assertEqual(self.multi_turn, expected)
        scenarios = {scenario["id"]: scenario for scenario in self.multi_turn["scenarios"]}
        npc_question = scenarios["npc_question_player_not_really"]["turns"]
        self.assertEqual(npc_question[1]["currentSemantic"]["selected"]["intent"], "DISAGREE")
        self.assertEqual(
            npc_question[1]["contextBefore"]["dialogue"]["pendingFollowUp"]["flowID"],
            "greeting",
        )
        self.assertEqual(npc_question[1]["contextResolution"]["flowReason"], "cancel")
        apology = scenarios["hostility_then_apology"]["turns"][1]
        self.assertEqual(apology["currentSemantic"]["selected"]["intent"], "APOLOGIZE")
        self.assertEqual(
            apology["interactionDirector"]["interactionPlan"]["behaviorID"],
            "behavior.reconcile",
        )

    def test_dynamic_suggestions_snapshot_includes_typed_click_path(self) -> None:
        expected = read_json(REPORT_ROOT / "suggestions_current.json")
        self.assertEqual(self.suggestions, expected)
        time_case = next(case for case in self.suggestions["cases"] if case["id"] == "time_reply_with_click")
        self.assertEqual(time_case["click"]["typedFrameKind"], "semantic_click_frame")
        self.assertEqual(time_case["click"]["turnEvidence"]["selected"]["provenance"]["pattern"], "pnc.question.time")
        source_kinds = set(time_case["suggestions"]["diversityObserved"]["sourceKinds"])
        self.assertIn("typed_input", source_kinds)
        greeting_kinds = set(next(
            case for case in self.suggestions["cases"] if case["id"] == "greeting_reply"
        )["suggestions"]["diversityObserved"]["sourceKinds"])
        self.assertIn("active_flow", greeting_kinds)
        self.assertIn("npc_response_plan", greeting_kinds)

    def test_reply_realization_snapshot_exposes_composition_evidence(self) -> None:
        expected = read_json(REPORT_ROOT / "reply_realization_current.json")
        self.assertEqual(self.realization, expected)
        by_id = {case["id"]: case for case in self.realization["cases"]}
        self.assertEqual(
            by_id["retaliation_mirror"]["current"]["response"]["templateID"],
            "semantic.interaction.argument.retaliate",
        )
        self.assertTrue(by_id["retaliation_mirror"]["current"]["evidence"]["messagePhraseFamilies"])
        self.assertEqual(by_id["ask_back_follow_up"]["current"]["evidence"]["planTurnCount"], 2)
        self.assertEqual(by_id["apology_deescalation"]["current"]["selectedIntent"], "APOLOGIZE")

    def test_storage_snapshot_reports_current_overflow_and_reference_state(self) -> None:
        expected = read_json(REPORT_ROOT / "storage_topology_current.json")
        self.assertEqual(self.storage, expected)
        overflow_names = {Path(item["module"]).name for item in self.storage["generated"]["numericOverflowShards"]}
        self.assertTrue({"SocialPart02", "SocialPart03", "SocialPart04"}.issubset(overflow_names))
        self.assertTrue({"CommandPart02", "QuestionPart02"}.issubset(overflow_names))
        opaque_names = {Path(item["module"]).name for item in self.storage["generated"]["opaqueNamedShards"]}
        self.assertEqual(opaque_names, {"Massive", "Sgd"})
        discoverability = self.storage["discoverability"]
        self.assertEqual(discoverability["sourceMissing"], [])
        self.assertEqual(discoverability["unresolvedGeneratedMissing"], [])
        self.assertEqual(discoverability["generatedDefinitionCollisions"], {})
        self.assertEqual(discoverability["referenceFailures"], [])

    def test_capture_does_not_mutate_canonical_or_generated_files(self) -> None:
        paths = [
            REPOSITORY / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json",
            REPOSITORY / "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions.json",
            REPOSITORY / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/Generated/Conversation/Content/SocialPart03.lua",
            REPOSITORY / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/Generated/Conversation/Registry.lua",
        ]
        before = {path: path.read_bytes() for path in paths}
        capture_storage()
        self.assertEqual(before, {path: path.read_bytes() for path in paths})

    def test_projection_is_observer_only(self) -> None:
        source = (REPOSITORY / "tools/semantic_harness/c0a_baseline.py").read_text(encoding="utf-8")
        self.assertIn("LuaSemanticWorker", source)
        self.assertIn("production Lua worker", source)
        self.assertNotIn("PsychopatzSemanticParser", source)
        self.assertNotIn("PsychopatzSemanticNormalizer", source)


if __name__ == "__main__":
    unittest.main()
