"""S3 declarative codeblock round-trip contracts."""

from __future__ import annotations

from pathlib import Path
import json
import tempfile
import unittest

from tools.semantic_harness.codebuilder.codeblocks import (
    codeblocks_to_flow,
    flow_to_codeblocks,
    validate_codeblock_document,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]


class CodeBlockRoundTripTests(unittest.TestCase):
    def test_generated_flow_round_trips_typed_result_edges_and_lua_validation(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
            follow = next(
                flow for flow in catalog["flows"]
                if flow["id"] == "pnc.generated.simple_command.pnc.companion.follow"
            )
            known_ids = {flow["id"] for flow in catalog["flows"]}
            document = flow_to_codeblocks(
                follow,
                nested_flows=[{"flowID": "greeting", "entry": "await_thanks"}],
            )
            self.assertEqual(document["schema"], "semantic.codeblocks.v1")
            self.assertTrue(any(edge["type"] == "result" for edge in document["connections"]))
            validated = validate_codeblock_document(document, known_flow_ids=known_ids)
            self.assertTrue(validated["valid"], validated)

            result = codeblocks_to_flow(
                document,
                base_flow=follow,
                known_flow_ids=known_ids,
            )
            self.assertTrue(result["valid"], result)
            self.assertEqual(result["flow"]["nodes"], follow["nodes"])
            production_validation = worker.validate_flow(result["flow"])

        self.assertTrue(production_validation["valid"], production_validation)
        self.assertEqual(result["nestedFlows"], [{"flowID": "greeting", "entry": "await_thanks"}])
        self.assertEqual(result["writes"], [])

    def test_authored_flow_round_trips_special_targets_and_connections(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
        greeting = next(flow for flow in catalog["flows"] if flow["id"] == "greeting")
        document = flow_to_codeblocks(greeting)
        self.assertTrue(
            any(edge["to"] == "suspend" for edge in document["connections"])
        )
        result = codeblocks_to_flow(
            document,
            base_flow=greeting,
            known_flow_ids={flow["id"] for flow in catalog["flows"]},
        )
        self.assertTrue(result["valid"], result)
        self.assertEqual(result["flow"]["nodes"], greeting["nodes"])

    def test_invalid_typed_edge_and_nested_reference_fail_without_writes(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            catalog = worker.flow_catalog()
        greeting = next(flow for flow in catalog["flows"] if flow["id"] == "greeting")
        document = flow_to_codeblocks(greeting)
        document["connections"][0]["type"] = "result"
        document["nestedFlows"] = [{"flowID": "missing_flow"}]
        report = validate_codeblock_document(
            document,
            known_flow_ids={flow["id"] for flow in catalog["flows"]},
        )
        self.assertFalse(report["valid"])
        self.assertTrue(any("type mismatch" in item["message"] for item in report["diagnostics"]))
        self.assertTrue(any("unknown nested flow" in item["message"] for item in report["diagnostics"]))
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["writes"], [])

    def test_headless_service_validates_saved_codeblock_source(self) -> None:
        service = SemanticLabAuthoringService(repository=REPOSITORY)
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            greeting = next(flow for flow in worker.flow_catalog()["flows"] if flow["id"] == "greeting")
        document = flow_to_codeblocks(greeting)
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "codeblocks.json"
            source.write_text(json.dumps(document), encoding="utf-8")
            report = service.validate_codeblock_source(source)
        self.assertTrue(report["valid"], report)
        self.assertEqual(report["writes"], [])


if __name__ == "__main__":
    unittest.main()
