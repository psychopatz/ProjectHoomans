"""C7G full conversational acceptance on the production Lua worker."""

from __future__ import annotations

from copy import deepcopy
import statistics
import time
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def grounded_scenario(*, language: str = "EN", provider: bool = False) -> dict:
    return merge(
        DEFAULT_SCENARIO,
        {
            "npc": {
                "residence": {"label": "Riverside Camp"},
                "healthState": "injured",
                "needs": {"thirst": 0.9},
                "conditionStats": {},
                "knowledge": {
                    "topics": {
                        "radio tower": {
                            "known": True,
                            "answer": "It is north of here.",
                        }
                    }
                },
                "personality": {"socialStyle": "friendly"},
                "traits": {"friendly": True},
            },
            "runtime": {
                "language": language,
                "llmEnabled": provider,
                "providerAvailable": provider,
            },
        },
    )


class ConversationalCompetenceC7GTests(unittest.TestCase):
    @staticmethod
    def message_text(turn: dict) -> str:
        payload = turn["messages"][-1]["payload"]
        if isinstance(payload, dict):
            return str(payload.get("text") or payload.get("fallback") or "")
        return str(payload or "")

    @staticmethod
    def assert_no_effects(turn: dict) -> None:
        assert turn["accepted"], turn.get("reason")
        assert turn["result"]["decision"]["route"] == "deterministic"
        assert turn["result"].get("actionResult") is None
        assert turn["transport"] == []
        assert turn["toolCalls"] == []
        assert turn["llmCalls"] == 0

    def test_sustained_grounded_dialogue_preserves_context_and_authority(self) -> None:
        script = (
            "where do you live exactly",
            "what about it",
            "tell me more",
            "are you okay",
            "what about your health",
            "do you need anything",
            "how many",
            "i'll get some",
            "what is the weather",
            "okay",
            "do you know about the radio tower",
            "tell me more",
            "i like your jacket",
            "did you hear someone got bitten",
        )
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                with LuaSemanticWorker(grounded_scenario(language=language)) as worker:
                    turns = [worker.input(text) for text in script]
                    before_preview = worker.snapshot()
                    preview = worker.preview("wait here")
                    after_preview = worker.snapshot()
                    action = worker.input("wait here")

                for turn in turns:
                    self.assertTrue(turn["messages"], turn)
                    self.assertTrue(self.message_text(turn), turn)
                    self.assertEqual(turn["translation"]["language"], language)
                    self.assertEqual(turn["llmCalls"], 0)

                residence, reference, continuation = turns[:3]
                self.assertEqual(
                    residence["result"]["ir"]["subject"], "NPC_RESIDENCE"
                )
                self.assertIn("Riverside Camp", self.message_text(residence))
                self.assertEqual(
                    reference["result"]["ir"]["target"]["concept"],
                    "NPC_RESIDENCE",
                )
                self.assertIn("Riverside Camp", self.message_text(reference))
                self.assertEqual(
                    continuation["result"]["decision"]["response"][
                        "selectionSource"
                    ],
                    "conversation_context",
                )

                self.assertEqual(
                    turns[3]["result"]["ir"]["subject"], "WELLBEING"
                )
                self.assertEqual(
                    turns[4]["result"]["ir"]["subject"], "NPC_HEALTH_STATE"
                )
                self.assertEqual(
                    turns[6]["result"]["ir"]["subject"], "QUANTITY"
                )
                self.assertEqual(turns[7]["result"]["ir"]["intent"], "PROMISE")
                self.assertEqual(
                    turns[8]["result"]["ir"]["subject"], "WEATHER"
                )
                self.assertEqual(
                    turns[9]["result"]["ir"]["extensions"][
                        "contextualFollowUp"
                    ]["status"],
                    "matched",
                )
                self.assertEqual(
                    turns[10]["result"]["ir"]["subject"], "NPC_KNOWLEDGE"
                )
                self.assertEqual(
                    turns[11]["result"]["decision"]["response"][
                        "selectionSource"
                    ],
                    "conversation_context",
                )
                self.assertEqual(turns[13]["result"]["ir"]["intent"], "GOSSIP")

                for turn in turns:
                    self.assert_no_effects(turn)

                self.assertTrue(preview["accepted"], preview.get("reason"))
                self.assertEqual(preview["result"]["ir"]["action"], "STAY")
                self.assertEqual(preview["messages"], [])
                self.assertEqual(preview["transport"], [])
                self.assertEqual(preview["toolCalls"], [])
                self.assertEqual(
                    {key: value for key, value in before_preview.items() if key != "id"},
                    {key: value for key, value in after_preview.items() if key != "id"},
                )
                self.assertEqual(action["result"]["ir"]["action"], "STAY")
                self.assertTrue(action["result"]["actionResult"]["accepted"])
                self.assertEqual(len(action["transport"]), 1)
                self.assertEqual(
                    action["result"]["actionResult"]["capabilityID"],
                    "pnc:companion.stay",
                )

    def test_personality_changes_tone_without_changing_grounding_or_authority(self) -> None:
        friendly = grounded_scenario()
        withdrawn = grounded_scenario()
        withdrawn["npc"]["personality"] = {"socialStyle": "withdrawn"}
        withdrawn["npc"]["traits"] = ["reserved"]

        with LuaSemanticWorker(friendly) as friendly_worker:
            friendly_turn = friendly_worker.input("are you okay")
        with LuaSemanticWorker(withdrawn) as withdrawn_worker:
            withdrawn_turn = withdrawn_worker.input("are you okay")

        for turn in (friendly_turn, withdrawn_turn):
            self.assertEqual(turn["result"]["ir"]["subject"], "WELLBEING")
            self.assertEqual(
                turn["result"]["decision"]["response"]["plan"]["groundedFactRefs"],
                ["npc.healthState"],
            )
            self.assert_no_effects(turn)
        friendly_plan = friendly_turn["result"]["decision"]["response"]["plan"]
        withdrawn_plan = withdrawn_turn["result"]["decision"]["response"]["plan"]
        self.assertEqual(friendly_plan["personalityStyle"], "friendly")
        self.assertEqual(withdrawn_plan["personalityStyle"], "withdrawn")
        self.assertNotEqual(friendly_plan["tone"], withdrawn_plan["tone"])
        self.assertNotEqual(
            friendly_turn["result"]["decision"]["response"]["templateID"],
            withdrawn_turn["result"]["decision"]["response"]["templateID"],
        )
        self.assertNotEqual(self.message_text(friendly_turn), self.message_text(withdrawn_turn))

    def test_participant_scoped_memory_does_not_cross_contaminate(self) -> None:
        alpha = grounded_scenario()
        bravo = grounded_scenario()
        alpha["player"]["characterUUID"] = "char_alpha"
        alpha["npc"]["npcID"] = "npc_alpha"
        bravo["player"]["characterUUID"] = "char_bravo"
        bravo["npc"]["npcID"] = "npc_bravo"
        bravo["npc"]["residence"] = {"label": "Oak Cabin"}

        with (
            LuaSemanticWorker(alpha) as alpha_worker,
            LuaSemanticWorker(bravo) as bravo_worker,
        ):
            alpha_worker.input("where do you live exactly")
            bravo_worker.input("where do you live exactly")
            alpha_follow_up = alpha_worker.input("what about it")
            bravo_follow_up = bravo_worker.input("what about it")

        self.assertIn("Riverside Camp", self.message_text(alpha_follow_up))
        self.assertNotIn("Oak Cabin", self.message_text(alpha_follow_up))
        self.assertIn("Oak Cabin", self.message_text(bravo_follow_up))
        self.assertNotIn("Riverside Camp", self.message_text(bravo_follow_up))
        for turn, key in (
            (alpha_follow_up, "char_alpha|npc_alpha"),
            (bravo_follow_up, "char_bravo|npc_bravo"),
        ):
            self.assertIn(
                key.split("|")[0],
                [participant["id"] for participant in turn["contextAfter"]["state"]["participants"]],
            )
            self.assertIn(
                key.split("|")[1],
                [participant["id"] for participant in turn["contextAfter"]["state"]["participants"]],
            )
            self.assert_no_effects(turn)

    def test_optional_provider_matches_the_same_long_dialogue_without_authority(self) -> None:
        script = (
            "where do you live exactly",
            "what about it",
            "tell me more",
            "are you okay",
            "what about your health",
            "do you know about the radio tower",
            "i like your outfit",
            "did you hear someone got bitten",
        )
        turns: dict[str, list[dict]] = {}
        for label, enabled in (("offline", False), ("provider", True)):
            with LuaSemanticWorker(grounded_scenario(provider=enabled)) as worker:
                turns[label] = [worker.input(text) for text in script]

        for offline, provider in zip(turns["offline"], turns["provider"]):
            self.assertEqual(offline["result"]["ir"], provider["result"]["ir"])
            self.assertEqual(
                offline["result"]["decision"]["response"],
                provider["result"]["decision"]["response"],
            )
            self.assertEqual(offline["contextAfter"]["dialogue"], provider["contextAfter"]["dialogue"])
            self.assertEqual(offline["messages"], provider["messages"])
            self.assertEqual(offline["transport"], provider["transport"])
            self.assertEqual(offline["toolCalls"], provider["toolCalls"])
            self.assertEqual(offline["llmCalls"], 0)
            self.assertEqual(provider["llmCalls"], 0)

    def test_long_dialogue_turn_latency_and_context_remain_bounded(self) -> None:
        script = (
            "where do you live exactly",
            "what about it",
            "tell me more",
            "are you okay",
            "what about your health",
            "do you need anything",
            "how many",
            "i'll get some",
            "what is the weather",
            "okay",
            "do you know about the radio tower",
            "tell me more",
        )
        samples: list[float] = []
        with LuaSemanticWorker(grounded_scenario()) as worker:
            for phrase in script:
                started = time.perf_counter()
                turn = worker.input(phrase)
                samples.append(time.perf_counter() - started)
                self.assertTrue(turn["accepted"], turn.get("reason"))
            snapshot = worker.snapshot()

        p95 = sorted(samples)[max(0, int(len(samples) * 0.95) - 1)]
        self.assertLessEqual(p95, 1.0)
        # This is wall-clock JSONL IPC through a disposable Lua process.  The
        # full suite can schedule other workers at the same time, so retain a
        # meaningful sub-third-second mean budget without turning scheduler
        # contention into a product failure.  The p95 bound above remains the
        # tighter outlier guard.
        self.assertLessEqual(statistics.fmean(samples), 0.30)
        dialogue = snapshot["context"]["dialogue"]
        self.assertLessEqual(len(dialogue["recentTurns"]), 12)
        self.assertLessEqual(len(dialogue["mentions"]), 32)
        self.assertLessEqual(len(dialogue["focus"]), 8)


if __name__ == "__main__":
    unittest.main()
