"""Verification tests for dialogue anti-duplication, seeded exploration, and phrase pool utilization."""

from __future__ import annotations

from copy import deepcopy
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.testing.sweep_quality import ALLOWED_SHORT_WORDS, QualityAnalyzer


class DialogueAntiDuplicationTests(unittest.TestCase):
    def test_unseeded_initial_turn_preserves_canonical_variant(self) -> None:
        """Prove that default unseeded turns select canonical variant 1 for test parity."""
        scenario = deepcopy(DEFAULT_SCENARIO)
        with LuaSemanticWorker(scenario) as worker:
            rec = worker.input("hello")
            p = rec["messages"][0]["payload"]
            self.assertEqual(p.get("phraseAntiRepeatReason"), "initial_canonical")
            self.assertEqual(p.get("phraseID"), "phrase.semantic.flow.greeting.opening.default.neutral.01")

    def test_seeded_initial_turn_rotates_across_pool(self) -> None:
        """Prove that passing distinct phrase salts across workers selects diverse variants."""
        selected_phrases: set[str] = set()
        for i in range(5):
            scenario = deepcopy(DEFAULT_SCENARIO)
            scenario.setdefault("runtime", {})["phraseSalt"] = f"case_test_salt_{i * 7}"
            with LuaSemanticWorker(scenario) as worker:
                rec = worker.input("hello")
                p = rec["messages"][0]["payload"]
                self.assertEqual(p.get("phraseAntiRepeatReason"), "initial_seeded")
                selected_phrases.add(p.get("phraseID"))

        # Must sample more than 1 variant across 5 distinct case seeds
        self.assertGreater(len(selected_phrases), 1)

    def test_recruitment_rejection_expanded_pool(self) -> None:
        """Prove that recruitment rejection supports 10 variants in categories.json."""
        import json
        from pathlib import Path

        repo_root = Path(__file__).resolve().parents[4]
        en_cat = json.loads(
            (repo_root / "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/Bundles/system/shared/categories.json").read_text(encoding="utf-8")
        )
        tl_cat = json.loads(
            (repo_root / "Contents/mods/ProjectHoomans/common/media/translation/TL/Conversation/Bundles/system/shared/categories.json").read_text(encoding="utf-8")
        )

        for i in range(1, 11):
            key = f"response.recruit.reject.relationship.{i}"
            self.assertIn(key, en_cat, f"Missing EN key {key}")
            self.assertIn(key, tl_cat, f"Missing TL key {key}")
            self.assertTrue(len(en_cat[key]) > 10)
            self.assertTrue(len(tl_cat[key]) > 10)

    def test_allowed_short_words_includes_farewells(self) -> None:
        """Prove that natural short farewells like 'you too.' are permitted."""
        analyzer = QualityAnalyzer()
        for word in ("you too.", "You too.", "ingat.", "kayo rin."):
            row = {
                "output": {"finalText": word},
                "trigger": {},
                "semanticPath": {},
            }
            flags = analyzer.analyze_row(row)
            self.assertFalse(
                any(f.name == "ONE_WORD_RESPONSE" for f in flags),
                f"Valid short farewell '{word}' was falsely flagged as ONE_WORD_RESPONSE",
            )


if __name__ == "__main__":
    unittest.main()
