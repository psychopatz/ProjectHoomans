from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import json
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
    conversation_discovery_index,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
PROVIDER = "projecthoomans.generated_affordances"


def generated_rows(turn: dict) -> list[dict]:
    return [
        row
        for row in turn["observation"]["suggestions"]["candidates"]
        if row.get("providerID") == PROVIDER
    ]


class CoherentConversationC6C7Tests(unittest.TestCase):
    def test_hostility_generates_semantically_diverse_affordances_and_keeps_authored(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turn = worker.input("fuckyouuuu")

        rows = generated_rows(turn)
        self.assertEqual(
            [row["strategy"] for row in rows],
            ["APOLOGIZE", "CHALLENGE", "DISMISS", "ASK_WHY"],
        )
        self.assertEqual(len({row["strategy"] for row in rows}), len(rows))
        self.assertLessEqual(len(rows), 6)
        self.assertEqual(
            {row["stance"] for row in rows},
            {"POSITIVE", "NEGATIVE", "NEUTRAL"},
        )
        for row in rows:
            self.assertEqual(row["origin"], "GENERATED")
            self.assertEqual(row["frame"]["kind"], "semantic_click_frame")
            dynamic = row["frame"]["extensions"]["dynamicAffordance"]
            self.assertEqual(dynamic["origin"], "GENERATED")
            self.assertEqual(dynamic["strategy"], row["strategy"])
            self.assertEqual(dynamic["stance"], row["stance"])
            self.assertTrue(row["display"]["utterance"])

        ids = {
            row["id"]
            for row in turn["observation"]["suggestions"]["candidates"]
        }
        self.assertIn("conversation.root:menu:goodbye", ids)
        self.assertIn("social.check_in", ids)

    def test_trait_lane_uses_player_trait_only_and_exposes_bounded_provenance(self) -> None:
        player_trait = deepcopy(DEFAULT_SCENARIO)
        player_trait["player"]["traits"] = ["Brave"]
        with LuaSemanticWorker(player_trait) as worker:
            brave = worker.input("fuckyouuuu")

        call_bluff = next(
            row for row in generated_rows(brave)
            if row["strategy"] == "CALL_BLUFF"
        )
        self.assertEqual(call_bluff["contextReason"], "player_trait:Brave")
        serialized = json.dumps(call_bluff, sort_keys=True)
        self.assertNotIn("npcTraits", serialized)
        self.assertNotIn("aggression", serialized)
        self.assertNotIn("forgiveness", serialized)

        npc_trait_only = deepcopy(DEFAULT_SCENARIO)
        npc_trait_only["npc"]["traits"] = ["Brave"]
        with LuaSemanticWorker(npc_trait_only) as worker:
            npc_only = worker.input("fuckyouuuu")
        self.assertNotIn(
            "CALL_BLUFF",
            {row["strategy"] for row in generated_rows(npc_only)},
        )

    def test_generated_affordance_follows_current_pending_question(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            greeting = worker.input("hello")

        rows = generated_rows(greeting)
        self.assertEqual(
            [row["strategy"] for row in rows],
            ["WELLBEING_POSITIVE", "WELLBEING_NEUTRAL", "WELLBEING_NEGATIVE"],
        )
        self.assertFalse(
            {"APOLOGIZE", "CHALLENGE", "DISMISS", "ASK_WHY"}
            & {row["strategy"] for row in rows}
        )
        for row in rows:
            reply_to = row["frame"]["extensions"]["discourseFrame"]["replyTo"]
            self.assertEqual(reply_to["kind"], "pending_interaction")
            self.assertEqual(reply_to["flowID"], "greeting")

    def test_generated_click_and_typed_apology_converge_downstream(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            hostile = worker.input("fuckyouuuu")
            apology = next(
                row for row in generated_rows(hostile)
                if row["strategy"] == "APOLOGIZE"
            )
            clicked = worker.suggestion_click(apology["frame"])

        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.input("fuckyouuuu")
            typed = worker.input("sorry")

        click_ir = clicked["result"]["ir"]
        typed_ir = typed["result"]["ir"]
        self.assertEqual(
            (click_ir["intent"], click_ir["speechAct"]),
            (typed_ir["intent"], typed_ir["speechAct"]),
        )
        self.assertEqual(
            clicked["result"]["decision"]["branch"],
            typed["result"]["decision"]["branch"],
        )
        self.assertEqual(
            clicked["observation"]["director"]["entered"]["id"],
            "beat.reconciliation",
        )
        self.assertEqual(
            typed["observation"]["director"]["entered"]["id"],
            "beat.reconciliation",
        )
        self.assertEqual(
            click_ir["provenance"]["parser"],
            "semantic_click_frame",
        )
        self.assertEqual(
            typed_ir["provenance"]["parser"],
            "deterministic",
        )

    def test_generated_buttons_are_locale_realizations_not_nlu_inputs(self) -> None:
        surfaces: dict[str, dict[str, str]] = {}
        for language in ("EN", "TL"):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario["runtime"]["language"] = language
            with LuaSemanticWorker(scenario) as worker:
                turn = worker.input("fuckyouuuu")
            surfaces[language] = {
                row["strategy"]: row["display"]["utterance"]
                for row in generated_rows(turn)
            }

        self.assertEqual(set(surfaces["EN"]), set(surfaces["TL"]))
        self.assertEqual(surfaces["EN"]["APOLOGIZE"], "I'm sorry.")
        self.assertEqual(surfaces["TL"]["APOLOGIZE"], "pasensya na.")
        self.assertNotEqual(
            surfaces["EN"]["ASK_WHY"],
            surfaces["TL"]["ASK_WHY"],
        )

    def test_runtime_retaliation_uses_canonical_microplan_en_and_tl(self) -> None:
        expected = {
            "EN": ("fuck you too.", "construction.en.social.mirror_retort"),
            "TL": ("Putang ina mo rin.", "construction.tl.social.mirror_retort"),
        }
        for language, (text, construction) in expected.items():
            with self.subTest(language=language):
                scenario = deepcopy(DEFAULT_SCENARIO)
                scenario["runtime"]["language"] = language
                scenario["npc"]["personalityOverride"] = True
                scenario["npc"]["personality"] = {
                    "aggression": 0.95,
                    "confidence": 0.85,
                    "forgiveness": 0.8,
                }
                with LuaSemanticWorker(scenario) as worker:
                    turn = worker.input("fuckyouuuu")

                self.assertEqual(
                    turn["observation"]["interactionPlan"]["behaviorID"],
                    "behavior.retaliate_verbally",
                )
                canonical = turn["result"]["decision"]["response"]
                self.assertEqual(
                    canonical["templateID"],
                    "semantic.interaction.argument.retaliate",
                )
                self.assertEqual(canonical["fallback"], "Watch your mouth.")

                payload = turn["messages"][0]["payload"]
                self.assertEqual(payload["text"], text)
                self.assertEqual(
                    payload["realizationFamily"],
                    "utterance_plan",
                )
                self.assertEqual(
                    payload["realizationVariant"],
                    construction,
                )
                self.assertNotIn("uuu", payload["text"].lower())
                self.assertEqual(
                    payload["semanticTemplateID"],
                    "semantic.interaction.argument.retaliate",
                )

    def test_unsupported_microplan_falls_back_to_dialogue_content(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            turn = worker.input("fuckyouuuu")
        payload = turn["messages"][0]["payload"]
        self.assertNotEqual(payload.get("realizationFamily"), "utterance_plan")
        self.assertTrue(payload["text"])

    def test_realization_records_are_compiler_owned_and_routable(self) -> None:
        model = compile_conversation_sources(REPOSITORY)
        modules, reports = render_conversation_runtime_plan(model)
        index = conversation_discovery_index(model, reports)

        self.assertTrue(modules)
        self.assertEqual(
            index["construction.en.social.mirror_retort"]["source"],
            "realization/social/constructions_en.json",
        )
        self.assertEqual(
            index["construction.en.social.mirror_retort"]["generated"],
            [
                "PNC/Semantics/Generated/Conversation/"
                "Realization/Social/ConstructionsEn"
            ],
        )
        self.assertEqual(
            index["construction.tl.social.mirror_retort"]["source"],
            "realization/social/constructions_tl.json",
        )
        self.assertEqual(
            index["lexeme.social.profanity.fuck"]["source"],
            "realization/social/lexemes.json",
        )


if __name__ == "__main__":
    unittest.main()
