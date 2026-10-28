"""C5 source-owned Conversation storage/context-health acceptance."""

from __future__ import annotations

import json
import re
import shutil
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.build import write_conversation_output
from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_MAX_INDEX_BYTES,
    CONVERSATION_MAX_RECORDS_PER_SHARD,
    CONVERSATION_MAX_SHARD_BYTES,
    CONVERSATION_MAX_SOURCE_BYTES,
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    conversation_affected_closure,
    conversation_context_health,
    conversation_discovery_index,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.codebuilder.lexicon_compiler import CompileError
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


REPOSITORY = Path(__file__).resolve().parents[3]


class ConversationContextHealthC5Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.model = compile_conversation_sources(REPOSITORY)
        cls.modules, cls.reports = render_conversation_runtime_plan(cls.model)
        cls.health = conversation_context_health(cls.model, cls.reports)

    def test_source_owned_plan_has_no_numeric_or_opaque_runtime_shards(self) -> None:
        self.assertEqual(self.health["status"], "pass", self.health["errors"])
        self.assertEqual(self.health["errors"], [])
        self.assertEqual(self.health["numericShardViolations"], [])
        self.assertEqual(self.health["opaqueShardViolations"], [])
        self.assertEqual(self.health["missingOwnership"], [])

        data_reports = [
            row for row in self.reports
            if row["kind"] not in {"Index", "IndexRegistry"}
        ]
        self.assertTrue(data_reports)
        self.assertTrue(all(
            int(row["bytes"]) <= CONVERSATION_MAX_SHARD_BYTES
            for row in data_reports
        ))
        self.assertTrue(all(
            int(row["recordCount"]) <= CONVERSATION_MAX_RECORDS_PER_SHARD
            for row in data_reports
        ))
        self.assertFalse(any(
            re.search(r"Part\d+$", row["module"])
            for row in data_reports
        ))
        self.assertFalse(any(
            row["module"].rsplit("/", 1)[-1] in {"Massive", "Sgd"}
            for row in data_reports
        ))

    def test_source_hard_budget_is_green_after_semantic_split(self) -> None:
        self.assertTrue(self.health["largestSources"])
        self.assertLessEqual(
            max(int(row["bytes"]) for row in self.health["largestSources"]),
            CONVERSATION_MAX_SOURCE_BYTES,
        )
        largest = self.health["largestSources"][0]
        self.assertEqual(
            largest["path"],
            "content/social/emotes/reply.json",
        )

    def test_generated_paths_explain_canonical_ownership(self) -> None:
        modules = {row["module"]: row for row in self.reports}
        expected = {
            "PNC/Semantics/Generated/Conversation/Content/Command/Lifecycle/Camp":
                "content/command/lifecycle/camp.json",
            "PNC/Semantics/Generated/Conversation/Content/Social/ToolReplies/Hostile":
                "content/social/tool_replies/hostile.json",
            "PNC/Semantics/Generated/Conversation/Content/Task/Lifecycle/Eat":
                "content/task/lifecycle/eat.json",
            "PNC/Semantics/Generated/Conversation/Patterns/Common/GreetingWhatsUp":
                "patterns/common/greeting_whats_up.json",
            "PNC/Semantics/Generated/Conversation/Behaviors/Social/RetaliateVerbally":
                "behaviors/social/retaliate_verbally.json",
            "PNC/Semantics/Generated/Conversation/Beats/Social/ArgumentEscalation":
                "beats/social/argument_escalation.json",
        }
        for module, source in expected.items():
            with self.subTest(module=module):
                self.assertIn(module, modules)
                self.assertEqual(modules[module]["sourceShard"], source)

    def test_recursive_source_roots_remove_split_files_from_manifest_catalog(self) -> None:
        manifest = self.model["manifest"]
        explicit_paths = {
            row["path"] for row in manifest["shards"]
        }
        self.assertNotIn(
            "content/command/lifecycle/camp.json",
            explicit_paths,
        )
        self.assertIn(
            "content/command/lifecycle/camp.json",
            self.model["_source_documents"],
        )
        roots = {row["path"] for row in manifest["sourceRoots"]}
        self.assertIn("content/command/lifecycle", roots)
        self.assertIn("content/social/tool_replies", roots)
        self.assertIn("content/task/tool_replies", roots)

        second = compile_conversation_sources(REPOSITORY)
        self.assertEqual(
            list(self.model["_source_documents"]),
            list(second["_source_documents"]),
        )

    def test_discovery_index_is_pointer_only_bounded_and_routable(self) -> None:
        index = conversation_discovery_index(self.model, self.reports)
        row = index["behavior.retaliate_verbally"]
        self.assertEqual(
            row["source"],
            "behaviors/social/retaliate_verbally.json",
        )
        self.assertEqual(
            row["generated"],
            [
                "PNC/Semantics/Generated/Conversation/"
                "Behaviors/Social/RetaliateVerbally"
            ],
        )
        self.assertIn("beat.argument_escalation", row["dependents"])
        allowed = {
            "id", "kind", "domain", "source", "generated",
            "related", "dependents",
        }
        self.assertTrue(all(set(entry) <= allowed for entry in index.values()))
        index_reports = [
            row for row in self.reports
            if row["kind"] in {"Index", "IndexRegistry"}
        ]
        self.assertTrue(index_reports)
        self.assertTrue(all(
            int(row["bytes"]) <= CONVERSATION_MAX_INDEX_BYTES
            for row in index_reports
        ))

    def test_affected_closure_stays_bounded_and_useful(self) -> None:
        closure = conversation_affected_closure(
            self.model,
            self.reports,
            "behavior.retaliate_verbally",
        )
        self.assertIsNotNone(closure)
        assert closure is not None
        self.assertIn("beat.argument_escalation", closure["closureIDs"])
        self.assertIn(
            "behaviors/social/retaliate_verbally.json",
            closure["sources"],
        )
        self.assertIn(
            "PNC/Semantics/Generated/Conversation/"
            "Behaviors/Social/RetaliateVerbally",
            closure["generated"],
        )
        self.assertFalse(closure["truncated"])
        self.assertLessEqual(len(closure["closureIDs"]), 24)

    def test_authoring_service_exposes_health_and_closure(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        health = service.conversation_context_health()
        self.assertEqual(health["status"], "pass", health["errors"])
        row = service.conversation_discovery_record(
            "behavior.retaliate_verbally"
        )
        self.assertIsNotNone(row)
        assert row is not None
        self.assertEqual(
            row["source"],
            "behaviors/social/retaliate_verbally.json",
        )
        closure = service.conversation_affected_closure(
            "behavior.retaliate_verbally"
        )
        self.assertIsNotNone(closure)
        assert closure is not None
        self.assertIn("beat.argument_escalation", closure["closureIDs"])

    def test_writer_refuses_hard_source_budget_before_generation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            shutil.copytree(
                REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                repository / CONVERSATION_SOURCE_RELATIVE,
            )
            path = (
                repository
                / CONVERSATION_SOURCE_RELATIVE
                / "content/social/emotes/reply.json"
            )
            document = json.loads(path.read_text(encoding="utf-8"))
            # JSON whitespace is semantically inert but still consumes source
            # context. It is enough to prove the hard source budget is enforced
            # before generated output is touched.
            path.write_text(
                json.dumps(document, indent=2, sort_keys=True)
                + (" " * (CONVERSATION_MAX_SOURCE_BYTES + 64))
                + "\n",
                encoding="utf-8",
            )
            model = compile_conversation_sources(
                repository,
                runtime_root=REPOSITORY,
            )
            with self.assertRaisesRegex(
                CompileError,
                "context-health hard violations",
            ):
                write_conversation_output(repository, model)
            generated = (
                repository
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/"
                "PNC/Semantics/Generated/Conversation"
            )
            self.assertFalse(generated.exists())


if __name__ == "__main__":
    unittest.main()
