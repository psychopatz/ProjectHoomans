"""Real-worker regressions for grounded backstory conversations."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.providers.pnc.tests.worker_reuse import WarmWorkerTestMixin


class PersonalDialogueKnowledgeDisclosureGatesTests(WarmWorkerTestMixin, unittest.TestCase):
    @staticmethod
    def scenario(
        familiarity: int = 80,
        language: str = "EN",
        social_style: str | None = None,
    ) -> dict:
        return merge(
            DEFAULT_SCENARIO,
            {
                "npc": {
                    "npcID": "npc-h3-grounded",
                    "identitySeed": 90210,
                    "identity": {"seed": 90210},
                    "tacticalClass": "colonist",
                    "relationship": {"familiarity": familiarity},
                    "personality": (
                        {"socialStyle": social_style}
                        if social_style is not None
                        else {}
                    ),
                },
                "runtime": {"language": language},
            },
        )

    @staticmethod
    def final_text(turn: dict) -> str:
        messages = turn["observation"].get("authoritativeMessages", [])
        if messages:
            return str(messages[-1].get("text") or "")
        return ""

    @staticmethod
    def translation_keys(turn: dict) -> set[str]:
        return {
            str(lookup.get("key"))
            for lookup in turn.get("translation", {}).get("lookups", [])
            if lookup.get("key")
        }

    def test_player_scoped_knowledge_bootstrap_survives_reload(self) -> None:
        player_a = self.scenario()
        player_a["player"]["characterUUID"] = "char_h3_a"
        player_a["player"]["displayName"] = "Player A"
        player_b = self.scenario()
        player_b["player"]["characterUUID"] = "char_h3_b"
        player_b["player"]["displayName"] = "Player B"

        with self.warm_worker(player_a) as worker:
            disclosed = worker.input("what was your old job")
            knowledge_a = disclosed["contextAfter"]["knowledge"]
            self.assertEqual(knowledge_a["npcID"], "npc-h3-grounded")

            worker.configure(player_b)
            worker.knowledge_bootstrap("bootstrap-player-b")
            self.assertIsNone(
                worker.snapshot()["context"].get("knowledge"),
                "player B received player A's private dossier fact",
            )

            worker.configure(player_a)
            worker.knowledge_bootstrap("bootstrap-player-a-reload")
            reloaded = worker.snapshot()["context"].get("knowledge")

        self.assertIsNotNone(reloaded)
        self.assertEqual(reloaded["characterUUID"], "char_h3_a")
        self.assertEqual(reloaded["npcID"], "npc-h3-grounded")
        self.assertEqual(reloaded["categories"], knowledge_a["categories"])

if __name__ == "__main__":
    unittest.main()
