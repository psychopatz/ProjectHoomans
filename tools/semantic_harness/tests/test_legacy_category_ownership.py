"""Semantic Lab coverage for the first legacy-category ownership slice."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class LegacyCategoryOwnershipTests(unittest.TestCase):
    def test_worker_loads_the_shared_ownership_manifest(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.open_conversation()
            snapshot = worker.snapshot()

        self.assertIn(
            "PNC/Semantics/PNC_SemanticConversationCategoryOwnership.lua",
            snapshot["loadedModules"],
        )

    def test_root_projection_exposes_compatibility_metadata_for_first_slice(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            opened = worker.open_conversation()
            landing = next(
                row
                for row in opened["presentation"]["responseChannel"]["rows"]
                if row["id"] == "conversation.landing:whats_up"
            )
            activated = worker.suggestion_click(landing["frame"])

        self.assertTrue(activated["accepted"], activated.get("reason"))
        candidates = {
            row["id"]: row
            for row in activated["observation"]["suggestions"]["candidates"]
        }
        for category, topic in (
            ("wellbeing", "wellbeing"),
            ("small_talk", "small_talk"),
            ("ask_about", "ask_about"),
        ):
            with self.subTest(category=category):
                frame = candidates[
                    f"conversation.root:menu:projecthoomans:{category}"
                ]["frame"]
                extensions = frame["extensions"]
                self.assertEqual(
                    extensions["semanticOwner"],
                    f"projecthoomans.semantic.{topic}",
                )
                self.assertTrue(extensions["legacyRegistry"])
                self.assertEqual(
                    extensions["migrationPhase"],
                    "legacy_registry_projection",
                )
                self.assertEqual(
                    extensions["authority"], "conversation_registry"
                )


if __name__ == "__main__":
    unittest.main()
