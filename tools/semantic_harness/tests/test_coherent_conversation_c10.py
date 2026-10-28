from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.inspection.conversation_inspector import (
    build_conversation_inspector,
)
from tools.semantic_harness.inspection.rendering import conversation_first
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.testing.conversation_fuzz import (
    DEFAULT_CASES,
    run_mutation_matrix,
)


PROVIDER = "projecthoomans.generated_affordances"


class CoherentConversationC10Tests(unittest.TestCase):
    def test_bounded_mutation_matrix_uses_real_worker_and_preserves_action_safety(self) -> None:
        report = run_mutation_matrix()
        self.assertEqual(report["caseCount"], len(DEFAULT_CASES))
        self.assertEqual(report["failedCount"], 0, report)
        self.assertEqual(report["passedCount"], len(DEFAULT_CASES))
        self.assertLessEqual(report["caseCount"], 32)

        rows = {row["id"]: row for row in report["rows"]}
        self.assertTrue(rows["compact_hostility"]["actual"]["recovered"])
        self.assertTrue(rows["elongated_compact_hostility"]["actual"]["recovered"])
        self.assertTrue(rows["safe_social_typo"]["actual"]["fuzzy"])
        self.assertEqual(
            rows["safe_fuzzy_movement"]["actual"]["action"],
            "FOLLOW",
        )
        unsafe = rows["unsafe_item_typo"]["actual"]
        self.assertEqual(unsafe["branch"], "ASK_CLARIFICATION")
        self.assertEqual(unsafe["riskReason"], "unresolved_action_reference")
        self.assertEqual(unsafe["transportCount"], 0)
        self.assertEqual(
            rows["self_state_intensifier"]["actual"]["subject"],
            "HUNGER",
        )

    def test_inspector_exposes_complete_bounded_chain_with_storage_and_conduct(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["personalityOverride"] = True
        scenario["npc"]["personality"] = {
            "aggression": 0.95,
            "confidence": 0.85,
            "forgiveness": 0.8,
        }
        with LuaSemanticWorker(scenario) as worker:
            turn = worker.input("fuckyouuuu")

        view = build_conversation_inspector(turn)
        self.assertTrue(view["surface"]["recovered"])
        self.assertTrue(view["candidateSelection"]["rows"])
        self.assertEqual(
            view["discourse"]["frame"]["semantic"]["intent"],
            "INSULT",
        )
        self.assertGreaterEqual(view["affordances"]["generatedCount"], 4)
        self.assertTrue(view["dialogueDirector"]["committed"])
        self.assertEqual(
            view["interactionPlan"]["behaviorID"],
            "behavior.retaliate_verbally",
        )

        realization = view["realization"]
        self.assertEqual(
            realization["presentation"]["realizationFamily"],
            "utterance_plan",
        )
        self.assertEqual(
            realization["utteranceRealization"]["constructionID"],
            "construction.en.social.mirror_retort",
        )
        self.assertEqual(
            realization["utterancePlan"]["strategy"],
            "MIRROR",
        )

        storage = view["storagePointers"]
        self.assertEqual(storage["contextHealth"]["status"], "pass")
        resolved = {
            row["id"]: row
            for row in storage["records"]
            if row.get("resolved")
        }
        self.assertEqual(
            resolved["behavior.retaliate_verbally"]["source"],
            "behaviors/social/retaliate_verbally.json",
        )
        self.assertEqual(
            resolved["construction.en.social.mirror_retort"]["source"],
            "realization/social/constructions_en.json",
        )

        social = view["socialEffect"]
        self.assertTrue(social["present"])
        self.assertTrue(social["interaction"]["understood"])
        self.assertEqual(
            social["reaction"]["behaviorID"],
            "behavior.retaliate_verbally",
        )
        self.assertTrue(social["relationshipEffect"]["accepted"])
        self.assertEqual(
            social["conductMemory"]["status"],
            "persisted",
        )
        self.assertEqual(
            social["conductMemory"]["persisted"],
            1,
        )

        rendered = conversation_first(view)
        for heading in (
            "SURFACE + RECOVERY",
            "CANDIDATE SELECTION",
            "DISCOURSE FRAME",
            "DYNAMIC AFFORDANCES",
            "UTTERANCE REALIZATION",
            "STORAGE OWNERSHIP",
            "SOCIAL EFFECT + CONDUCT MEMORY",
        ):
            self.assertIn(heading, rendered)

    def test_inspector_explains_selected_generated_button_without_reparse(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opening = worker.input("hello")
            choice = next(
                row
                for row in opening["observation"]["suggestions"]["candidates"]
                if row.get("providerID") == PROVIDER
                and row.get("strategy") == "WELLBEING_POSITIVE"
            )
            clicked = worker.suggestion_click(choice["frame"])

        view = build_conversation_inspector(clicked)
        selected = view["affordances"]["selectedSemanticFrame"]
        self.assertEqual(selected["candidateID"], "generated.wellbeing_positive")
        self.assertEqual(selected["providerID"], PROVIDER)
        self.assertEqual(selected["intent"], "INFORM")
        self.assertEqual(selected["subject"], "WELLBEING")
        self.assertEqual(
            selected["realizedPlayerUtterance"],
            "I'm doing pretty good.",
        )
        self.assertEqual(
            selected["dynamicAffordance"]["strategy"],
            "WELLBEING_POSITIVE",
        )
        self.assertEqual(
            selected["discourseFrame"]["replyTo"]["kind"],
            "pending_interaction",
        )
        self.assertEqual(
            clicked["result"]["ir"]["provenance"]["parser"],
            "semantic_click_frame",
        )


if __name__ == "__main__":
    unittest.main()
