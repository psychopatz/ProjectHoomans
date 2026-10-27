"""P11D acceptance for the canonical Conversation UI registry."""

from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.codebuilder.conversation_ui import (
    UI_REGISTRY_SCHEMA,
    compile_conversation_ui,
    conversation_ui_source_path_from_manifest,
    load_conversation_ui_source,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


REPOSITORY = Path(__file__).resolve().parents[3]
MANIFEST = (
    REPOSITORY
    / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
)


class ConversationUIRegistryP11DTests(unittest.TestCase):
    def test_manifest_declares_one_bounded_ui_registry(self) -> None:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        descriptor = manifest["conversationUI"]
        self.assertEqual(descriptor["schema"], UI_REGISTRY_SCHEMA)
        path = conversation_ui_source_path_from_manifest(MANIFEST)
        self.assertTrue(path.is_file())
        compiled = compile_conversation_ui(load_conversation_ui_source(path))
        self.assertEqual(compiled["schema"], UI_REGISTRY_SCHEMA)
        self.assertEqual(len(compiled["nodes"]), 12)

    def test_whats_up_membership_is_declarative_and_provider_locked(self) -> None:
        path = conversation_ui_source_path_from_manifest(MANIFEST)
        document = load_conversation_ui_source(path)
        compiled = compile_conversation_ui(document)
        by_id = {node["id"]: node for node in compiled["nodes"]}
        root = by_id["conversation.landing"]
        self.assertEqual(
            root["children"],
            [{"nodeID": "conversation.landing:whats_up", "order": 10}],
        )
        hub = by_id["conversation.hub:whats_up"]
        child_ids = [child["nodeID"] for child in hub["children"]]
        self.assertEqual(
            child_ids,
            [
                "conversation.choice:question.wellbeing",
                "conversation.choice:question.needs",
                "conversation.choice:question.health",
                "conversation.choice:question.identity",
                "conversation.choice:question.activity",
                "conversation.choice:question.time",
                "conversation.choice:question.date",
                "conversation.choice:question.gossip",
                "conversation.choice:question.weather",
            ],
        )
        for node in by_id.values():
            provider = node.get("providerRef")
            if provider:
                self.assertTrue(provider["locked"])
                self.assertNotIn("eligibility", node)
                self.assertNotIn("effects", node)
            self.assertNotIn("labelTranslations", node)
            self.assertNotIn("choiceTranslations", node)

    def test_shared_service_supports_effect_free_ui_edits_and_stale_guards(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source_root = MANIFEST.parent
            target_root = root / "tools/semantic_harness/codebuilder/sources/conversation"
            target_root.mkdir(parents=True)
            for source in source_root.glob("*.json"):
                (target_root / source.name).write_bytes(source.read_bytes())
            shard_root = target_root / "shards"
            shard_root.mkdir()
            for source in (source_root / "shards").glob("*.json"):
                (shard_root / source.name).write_bytes(source.read_bytes())

            service = SemanticLabAuthoringService(repository=root, runtime_root=root)
            inspected = service.inspect_conversation_ui("conversation.hub:whats_up")
            self.assertTrue(inspected["ok"])
            fingerprint = inspected["sourceFingerprint"]

            preview = service.preview_conversation_ui_operation(
                "reorder_child",
                parentID="conversation.hub:whats_up",
                childID="conversation.choice:question.weather",
                order=5,
                expected_source_fingerprint=fingerprint,
            )
            self.assertTrue(preview["ok"])
            self.assertTrue(preview["previewOnly"])
            self.assertTrue(preview["effectFree"])
            self.assertEqual(preview["writes"], [])
            after_preview = service.inspect_conversation_ui(
                "conversation.choice:question.weather"
            )
            self.assertEqual(after_preview["nodes"][0]["order"], 80)

            written = service.write_conversation_ui_operation(
                "reorder_child",
                parentID="conversation.hub:whats_up",
                childID="conversation.choice:question.weather",
                order=5,
                expected_source_fingerprint=fingerprint,
            )
            self.assertTrue(written["ok"])
            self.assertEqual(len(written["writes"]), 1)

            stale = service.preview_conversation_ui_operation(
                "reorder_child",
                parentID="conversation.hub:whats_up",
                childID="conversation.choice:question.weather",
                order=15,
                expected_source_fingerprint=fingerprint,
            )
            self.assertFalse(stale["ok"])
            self.assertTrue(stale["stale"])
            self.assertEqual(stale["writes"], [])

            locked = service.preview_conversation_ui_operation(
                "update_node",
                nodeID="conversation.choice:question.weather",
                providerRef={"id": "not.allowed"},
            )
            self.assertFalse(locked["ok"])
            self.assertTrue(locked["effectFree"])


if __name__ == "__main__":
    unittest.main()
