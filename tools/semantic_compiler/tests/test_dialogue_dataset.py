from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from tools.semantic_compiler.compiler import (
    CompileError,
    compile_dialogue_dataset,
    load_dialogue_dataset,
    render_dialogue_lua,
    render_dialogue_translation,
)


class DialogueDatasetCompilerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.source = load_dialogue_dataset(
            REPOSITORY / "tools/semantic_compiler/common_interactions.json"
        )

    def test_reviewed_needs_promise_mapping_is_compact_and_localized(self) -> None:
        compiled = compile_dialogue_dataset(self.source)
        pattern = next(
            item for item in compiled["patterns"]
            if item["id"] == "pnc.dataset.promise.needs.i_ll_pick_some_up"
        )
        self.assertEqual(pattern["emit"]["intent"], "PROMISE")
        self.assertEqual(pattern["emit"]["subject"], "NEEDS")
        self.assertEqual(pattern["metadata"]["mapping"]["canonicalConcept"], "FETCH")
        self.assertEqual(pattern["metadata"]["mapping"]["dialogueState"], "NEEDS_PROPOSAL")
        self.assertNotIn("i won't pick some up", json.dumps(pattern))

        pool = next(
            item for item in compiled["responsePools"]
            if item["id"] == "semantic.question.needs.proposal"
        )
        variant = next(
            item for item in pool["variants"]
            if item["id"] == "semantic.question.needs.proposal.dataset.thirst"
        )
        self.assertEqual(variant["plan"]["dialogueAct"], "PROMISE_ACKNOWLEDGEMENT")
        self.assertEqual(
            compiled["translations"]["EN"][variant["templateID"]],
            variant["fallback"],
        )
        self.assertIn(variant["templateID"], compiled["translations"]["TL"])
        self.assertEqual(
            render_dialogue_translation(compiled, "EN"),
            render_dialogue_translation(compiled, "EN"),
        )
        self.assertIn("DatasetNeedsPromiseThirst", render_dialogue_lua(compiled))

    def test_negative_examples_cannot_become_runtime_patterns(self) -> None:
        invalid = copy.deepcopy(self.source)
        invalid["patterns"][0]["negatives"] = [
            invalid["patterns"][1]["utterance"]
        ]
        with self.assertRaisesRegex(CompileError, "collides.*negative|negative.*collides"):
            compile_dialogue_dataset(invalid)

    def test_promise_mapping_requires_review_and_canonical_sources(self) -> None:
        invalid = copy.deepcopy(self.source)
        promise = invalid["patterns"][0]
        promise["reviewed"] = False
        with self.assertRaisesRegex(CompileError, "requires reviewed canonical mapping"):
            compile_dialogue_dataset(invalid)


REPOSITORY = Path(__file__).resolve().parents[3]


if __name__ == "__main__":
    unittest.main()
