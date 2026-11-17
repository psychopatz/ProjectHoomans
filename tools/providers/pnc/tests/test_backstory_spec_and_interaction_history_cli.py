"""Backstory interaction-spec compilation and CLI interaction-history inspection tests."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import unittest

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.providers.pnc.tests.worker_reuse import WarmWorkerTestMixin
from tools.semantic_harness.codebuilder.interaction_spec import (
    compile_interaction_spec,
    graph_block,
    graph_connection,
)
from tools.semantic_harness.entrypoints.cli import _parser, cli
from tools.semantic_harness.inspection.conversation_inspector import (
    build_conversation_inspector,
)

HOOMANS_ROOT = Path(__file__).resolve().parents[4]
CORE_ROOT = HOOMANS_ROOT.parent / "psychopatzCore"


class BackstorySpecAndInteractionHistoryCliTests(WarmWorkerTestMixin, unittest.TestCase):
    def test_real_worker_backstory_navigation_and_cli_inspect_interaction_history(self) -> None:
        backstory_spec = {
            "schema": "semantic.interaction_spec.v1",
            "id": "pnc.lab.former_job",
            "owner": "SemanticLab",
            "blocks": [
                graph_block(
                    "trigger",
                    "language.trigger",
                    parameters={
                        "utterance": "what did you do before all this",
                        "negativeUtterance": "do not talk about before",
                        "frame": {"intent": "QUESTION", "speechAct": "QUESTION"},
                    },
                ),
                graph_block(
                    "backstory",
                    "language.backstory_subject",
                    parameters={
                        "backstoryKind": "former_job",
                        "factProvider": "npc_backstory",
                        "topicID": "backstory.former_job",
                        "disclosure": "server_authorized",
                    },
                ),
                graph_block(
                    "fact",
                    "memory.backstory_fact",
                    parameters={
                        "providerID": "npc_backstory",
                        "subject": "NPC_BACKSTORY",
                        "authority": "server",
                        "immutable": True,
                        "privacy": "private",
                    },
                ),
                graph_block(
                    "response",
                    "dialogue_responses.response_pool",
                    parameters={
                        "poolID": "semantic.lab.former_job",
                        "variants": [{
                            "id": "answered",
                            "key": "UI_PNC_Conversation_Semantic_LabFormerJob",
                            "translations": {
                                "EN": "I worked as %1 before all this.",
                                "TL": "Nagtrabaho ako bilang %1 bago ito.",
                            },
                        }],
                    },
                ),
            ],
            "connections": [
                graph_connection("trigger", "backstory", "semantic"),
                graph_connection("backstory", "fact", "fact"),
                graph_connection("fact", "response", "response"),
            ],
        }
        base_doc = {
            "schemaVersion": 1,
            "source": {
                "name": "ConvoEngine Fixture",
                "version": "1",
                "contentLicense": "first_party",
                "references": [{
                    "name": "ConvoEngine Fixture",
                    "url": "https://example.invalid/fixture",
                    "use": "unit_test_fixture",
                    "license": "first_party",
                    "reviewedOn": "2026-11-16",
                    "version": "1",
                    "contentLicense": "first_party",
                    "importStatus": {"imported": 1},
                }],
            },
            "patterns": [],
            "responsePools": [],
        }
        compiled_spec = compile_interaction_spec(backstory_spec, base_doc)
        self.assertTrue(compiled_spec["ok"], compiled_spec)

        scenario = merge(DEFAULT_SCENARIO, {})
        with self.warm_worker(scenario) as worker:
            backstory = worker.input("what did you do before all this")
            follow = worker.input("follow me")
            self.assertTrue(backstory["accepted"])
            self.assertTrue(follow["accepted"])
            inspector = build_conversation_inspector(follow)
            self.assertEqual(inspector["source"], "real_lua_worker")

        args = _parser().parse_args([
            "--no-gui",
            "--preset",
            "pnc",
            "--core-repository",
            str(CORE_ROOT),
            "--repository",
            str(HOOMANS_ROOT),
            "--inspect-interaction-history",
            "--jsonl",
        ])
        out = io.StringIO()
        with redirect_stdout(out):
            rc = cli(args)
        self.assertEqual(rc, 0)
        lines = [json.loads(line) for line in out.getvalue().splitlines() if line.strip()]
        history_record = next(row for row in lines if row.get("type") == "actor_inspection")
        self.assertIn("interactionHistory", history_record)


if __name__ == "__main__":
    unittest.main()
