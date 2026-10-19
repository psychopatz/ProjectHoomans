"""R1 canonical typed InteractionSpec composition contracts."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import json
import tempfile
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
    @staticmethod
    def gated_collection() -> dict:
        first = stay_spec()
        first["id"] = "pnc.lab.stay.week"
        first["blocks"].append({"id": "week_fact", "use": "shared.week_fact"})
        first["blocks"].append({
            "id": "week_gate",
            "type": "conditions.gate",
            "parameters": {
                "type": "pnc:fact",
                "factBlockID": "week_fact",
                "operator": ">=",
                "value": 1,
            },
        })
        first["connections"].extend([
            {"from": "week_fact", "to": "week_gate", "type": "fact"},
            {"from": "week_gate", "to": "capability", "type": "gate"},
        ])
        second = deepcopy(first)
        second["id"] = "pnc.lab.remain.week"
        second["blocks"][0]["parameters"]["utterance"] = "remain with me"
        second["blocks"][0]["parameters"]["negativeUtterance"] = "don't remain with me"
        second["blocks"][2]["parameters"]["poolID"] = "semantic.lab.remain.week"
        second["blocks"][2]["parameters"]["variants"][0]["key"] = (
            "UI_PNC_Conversation_Semantic_LabRemainWeekAccepted"
        )
        return {
            "schema": "semantic.interaction_collection.v1",
            "sharedBlocks": [{
                "id": "shared.week_fact",
                "type": "world_facts.engine_fact",
                "parameters": {"factID": "world.time.week"},
            }],
            "interactions": [first, second],
        }

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
        self.assertIn("pnc.lab.stay.flow", report["compiledSummary"]["flowIDs"])
        self.assertIn("semantic.lab.stay", report["compiledSummary"]["responsePoolIDs"])
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

    def test_approved_spec_persists_canonical_source_and_reports_artifact_diffs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            source_path = repository / "tools/semantic_compiler/semantic_definitions.json"
            source_path.parent.mkdir(parents=True)
            source_path.write_text(
                (REPOSITORY / "tools/semantic_compiler/semantic_definitions.json")
                .read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            service = SemanticLabAuthoringService(
                repository=repository,
                runtime_root=REPOSITORY,
            )

            preview = service.preview_interaction_spec(stay_spec())
            self.assertTrue(preview["ok"], preview)
            self.assertEqual(preview["canonicalSourceDiff"]["status"], "changed")
            self.assertTrue(
                any(
                    row["path"].endswith("EN/Conversation/Semantic/Generated.json")
                    and row["status"] == "added"
                    for row in preview["generatedArtifactDiffs"]
                )
            )

            generated = service.generate_interaction_spec(stay_spec(), approved=True)
            self.assertTrue(generated["ok"], generated)
            self.assertTrue(generated["generationApproved"])
            self.assertIn(str(source_path), generated["writes"])
            document = json.loads(source_path.read_text(encoding="utf-8"))
            self.assertIn(
                "pnc.lab.stay",
                [definition["id"] for definition in document["definitions"]],
            )
            self.assertEqual(generated["canonicalSourceDiff"]["status"], "unchanged")
            self.assertTrue(
                all(row["status"] == "unchanged" for row in generated["generatedArtifactDiffs"])
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

    def test_one_shared_world_fact_block_compiles_into_two_flows(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
        report = service.preview_interaction_collection(
            self.gated_collection(),
            production_catalog=catalog,
        )
        self.assertTrue(report["ok"], report)
        self.assertEqual(report["sharedBlockIDs"], ["shared.week_fact"])
        self.assertIn("pnc.lab.stay.week.flow", report["compiledSummary"]["flowIDs"])
        self.assertIn("pnc.lab.remain.week.flow", report["compiledSummary"]["flowIDs"])
        generated = "\n".join(item["source"] for item in report["generatedLua"])
        self.assertGreaterEqual(generated.count("world.time.week"), 2)

    def test_collection_generation_requires_explicit_approval(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        report = service.generate_interaction_collection(
            self.gated_collection(), approved=False,
        )
        self.assertFalse(report["ok"])
        self.assertFalse(report["generationApproved"])
        self.assertEqual(report["writes"], [])


if __name__ == "__main__":
    unittest.main()
