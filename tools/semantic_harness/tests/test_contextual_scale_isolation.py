"""C6-A bounded latency and multi-scope isolation on real Lua workers."""

from __future__ import annotations

import statistics
import time
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def scoped_scenario(character: str, npc: str, token: str) -> dict:
    return merge(
        DEFAULT_SCENARIO,
        {
            "player": {"characterUUID": character},
            "npc": {
                "npcID": npc,
                "runtime": {
                    "conversationLease": {
                        "token": token,
                        "playerOnlineID": 1,
                        "playerUsername": character,
                        "startedAt": 1000,
                        "expiresAt": 4000,
                        "maximumDistance": 6,
                        "dangerRadius": 8,
                        "processedConversationRequests": {
                            f"{token}-ack": {
                                "success": True,
                                "npcID": npc,
                                "outcomeID": "promise.accepted",
                            },
                        },
                    },
                },
            },
            "conversation": {"token": token},
        },
    )


class ContextualScaleIsolationTests(unittest.TestCase):
    def test_real_worker_turn_latency_stays_bounded(self) -> None:
        scenario = scoped_scenario("char_perf", "npc_perf", "perf")
        samples: list[float] = []
        with LuaSemanticWorker(scenario) as worker:
            worker.preview("Are you okay?")
            for phrase in (
                "Are you okay?",
                "What happened?",
                "Do you need anything?",
                "How many?",
                "Can we talk about the weather",
                "What is going on with you",
                "I won't pick some up",
                "Which items do you mean",
            ):
                started = time.perf_counter()
                result = worker.preview(phrase)
                samples.append(time.perf_counter() - started)
                self.assertTrue(result["accepted"], result.get("reason"))

        p95 = sorted(samples)[max(0, int(len(samples) * 0.95) - 1)]
        self.assertLessEqual(p95, 1.0)
        self.assertLessEqual(statistics.fmean(samples), 0.25)
        self.assertEqual(len(samples), 8)

    def test_two_player_npc_scopes_keep_context_memory_and_transport_isolated(self) -> None:
        with (
            LuaSemanticWorker(scoped_scenario("char_alpha", "npc_alpha", "alpha")) as alpha,
            LuaSemanticWorker(scoped_scenario("char_bravo", "npc_bravo", "bravo")) as bravo,
        ):
            alpha_question = alpha.input("Are you okay?")
            bravo_question = bravo.input("Are you okay?")
            alpha_follow = alpha.input("Follow me")
            bravo_follow = bravo.input("Follow me")
            alpha_commitment = alpha.commitment(
                {
                    "operation": "record",
                    "npcID": "npc_alpha",
                    "commitmentID": "alpha-bandages",
                    "topic": "medical",
                    "intent": "bring bandages",
                    "sourceFactRefs": ["conversation:alpha-ack"],
                    "acknowledgementRequestID": "alpha-ack",
                }
            )
            bravo_memory = bravo.commitment(
                {"operation": "list", "npcID": "npc_bravo"}
            )

        for turn, key in ((alpha_question, "char_alpha|npc_alpha"), (bravo_question, "char_bravo|npc_bravo")):
            dialogue = turn["contextAfter"]["dialogue"]
            self.assertIn(key, [session["key"] for session in dialogue["flowSessions"]])
            self.assertEqual(dialogue["pendingFollowUp"]["status"], "open")
        self.assertEqual(alpha_follow["dispatchTransport"][0]["payload"]["id"], "npc_alpha")
        self.assertEqual(bravo_follow["dispatchTransport"][0]["payload"]["id"], "npc_bravo")
        self.assertEqual(alpha_commitment["result"]["characterUUID"], "char_alpha")
        self.assertEqual(alpha_commitment["result"]["commitment"]["ownerNPCID"], "npc_alpha")
        self.assertEqual(bravo_memory["commitments"], [])
        self.assertEqual(alpha_follow["llmCalls"], 0)
        self.assertEqual(bravo_follow["llmCalls"], 0)


if __name__ == "__main__":
    unittest.main()
