"""R1 canonical typed InteractionSpec composition contracts."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]


def stay_spec() -> dict:
    return {
        "schema": "semantic.interaction_spec.v1",
        "id": "pnc.lab.stay",
        "owner": "SemanticLab",
        "blocks": [
            {
                "id": "trigger",
                "type": "language.trigger",
                "parameters": {
                    "utterance": "stay with me",
                    "negativeUtterance": "don't stay with me",
                    "frame": {
                        "intent": "REQUEST",
                        "speechAct": "REQUEST",
                        "action": "STAY",
                    },
                },
            },
            {
                "id": "capability",
                "type": "gameplay_actions.capability",
                "parameters": {
                    "capabilityID": "pnc:companion.stay",
                    "action": "STAY",
                },
            },
            {
                "id": "response",
                "type": "dialogue_responses.response_pool",
                "parameters": {
                    "poolID": "semantic.lab.stay",
                    "variants": [
                        {
                            "id": "accepted",
                            "key": "UI_PNC_Conversation_Semantic_LabStayAccepted",
                            "en": "Okay, I will stay with you.",
                            "tl": "Sige, mananatili ako sa iyo.",
                        },
                    ],
                },
            },
        ],
        "connections": [
            {"from": "trigger", "to": "capability", "type": "semantic"},
            {"from": "capability", "to": "response", "type": "response"},
        ],
    }


class InteractionSpecTests(unittest.TestCase):
    def test_typed_spec_compiles_through_existing_semantic_builder(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
        report = service.preview_interaction_spec(
            stay_spec(), production_catalog=catalog,
        )
        self.assertTrue(report["ok"], report)
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["compiledSummary"]["flowIDs"][-1], "pnc.lab.stay.flow")
        self.assertEqual(report["compiledSummary"]["responsePoolIDs"][-1], "semantic.lab.stay")
        generated = "\n".join(item["source"] for item in report["generatedLua"])
        self.assertIn("stay_with_me", generated)
        self.assertIn('"STAY"', generated)

    def test_modifying_a_block_changes_generated_lua_fingerprint(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        original = service.preview_interaction_spec(stay_spec())
        changed_spec = deepcopy(stay_spec())
        changed_spec["blocks"][2]["parameters"]["variants"][0]["en"] = (
            "Sure, I will stay with you."
        )
        changed = service.preview_interaction_spec(changed_spec)
        self.assertTrue(original["ok"], original)
        self.assertTrue(changed["ok"], changed)
        self.assertNotEqual(
            original["generatedSourceFingerprint"],
            changed["generatedSourceFingerprint"],
        )
        self.assertNotEqual(
            [item["sha256"] for item in original["generatedLua"]],
            [item["sha256"] for item in changed["generatedLua"]],
        )

    def test_wrong_typed_connection_is_rejected_without_writes(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        spec = stay_spec()
        spec["connections"][0]["type"] = "response"
        report = service.preview_interaction_spec(spec)
        self.assertFalse(report["ok"])
        self.assertEqual(report["writes"], [])
        self.assertTrue(any("typed connection" in item["message"] for item in report["diagnostics"]))

    def test_generation_requires_explicit_approval(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        report = service.generate_interaction_spec(stay_spec(), approved=False)
        self.assertFalse(report["ok"])
        self.assertFalse(report["generationApproved"])
        self.assertEqual(report["writes"], [])


if __name__ == "__main__":
    unittest.main()
