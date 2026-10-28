from __future__ import annotations

import copy
import unittest

from tools.semantic_harness.codebuilder.lexicon_compiler import CompileError
from tools.semantic_harness.codebuilder.semantic_definition_compiler import (
    compile_semantic_definitions,
    render_semantic_lua_shards,
    render_semantic_manifest,
)


class SemanticAuthoringCompilerTests(unittest.TestCase):
    def source(self) -> dict:
        return {
            "schema": "pnc.semantic_authoring.v1",
            "source": {"owner": "ProjectHoomans", "version": "1"},
            "definitions": [{
                "id": "pnc.test.follow",
                "capability": "pnc:companion.follow",
                "utterances": {
                    "positives": ["keep close behind me"],
                    "negatives": ["don't keep close behind me"],
                },
                "emit": {
                    "intent": "REQUEST",
                    "speechAct": "REQUEST",
                    "action": "FOLLOW",
                },
                "flow": {
                    "id": "pnc.test.follow.flow",
                    "initial": "accepted",
                    "triggers": [{
                        "intent": "REQUEST",
                        "speechAct": "REQUEST",
                        "action": "FOLLOW",
                    }],
                    "nodes": {
                        "accepted": {
                            "terminal": True,
                            "responsePool": "semantic.test.follow",
                        },
                    },
                },
                "responses": {
                    "poolID": "semantic.test.follow",
                    "variants": [{
                        "id": "accepted",
                        "key": "UI_PNC_Conversation_Semantic_TestFollow",
                        "translations": {
                            "EN": "Okay, I will follow.",
                            "TL": "Sige, susunod ako.",
                        },
                    }],
                },
            }],
        }

    def test_semantic_definition_is_deterministic_and_modular(self) -> None:
        compiled = compile_semantic_definitions(
            self.source(), {"pnc:companion.follow"}, set()
        )
        self.assertEqual(len(compiled["patterns"]), 1)
        self.assertEqual(len(compiled["flows"]), 1)
        self.assertEqual(compiled["patterns"][0]["emit"]["action"], "FOLLOW")
        first = render_semantic_lua_shards(compiled, "PNC/Semantics/Test")
        second = render_semantic_lua_shards(compiled, "PNC/Semantics/Test")
        self.assertEqual(first, second)
        manifest = render_semantic_manifest(
            compiled,
            ["PNC/Semantics/Test_Patterns_01"],
            ["PNC/Semantics/Test_Flows_01"],
            ["PNC/Semantics/Test_Responses_01"],
            {"EN": ["EN/Generated.json"], "TL": ["TL/Generated.json"]},
        )
        self.assertEqual(manifest, render_semantic_manifest(
            compiled,
            ["PNC/Semantics/Test_Patterns_01"],
            ["PNC/Semantics/Test_Flows_01"],
            ["PNC/Semantics/Test_Responses_01"],
            {"EN": ["EN/Generated.json"], "TL": ["TL/Generated.json"]},
        ))

    def test_semantic_definition_rejects_capability_and_recognition_collisions(self) -> None:
        invalid = self.source()
        invalid["definitions"][0]["capability"] = "pnc:missing.action"
        with self.assertRaisesRegex(CompileError, "unregistered capability"):
            compile_semantic_definitions(invalid, {"pnc:companion.follow"}, set())

        invalid = self.source()
        with self.assertRaisesRegex(CompileError, "registered utterance"):
            compile_semantic_definitions(
                invalid, {"pnc:companion.follow"}, {"keep close behind me"}
            )

        invalid = self.source()
        duplicate = copy.deepcopy(invalid["definitions"][0])
        duplicate["id"] = "pnc.test.follow_duplicate"
        duplicate["flow"]["id"] = "pnc.test.follow_duplicate.flow"
        duplicate["responses"]["poolID"] = "semantic.test.follow_duplicate"
        duplicate["flow"]["nodes"]["accepted"]["responsePool"] = (
            "semantic.test.follow_duplicate"
        )
        invalid["definitions"].append(duplicate)
        with self.assertRaisesRegex(CompileError, "semantic utterance collision"):
            compile_semantic_definitions(invalid, {"pnc:companion.follow"}, set())


if __name__ == "__main__":
    unittest.main()
