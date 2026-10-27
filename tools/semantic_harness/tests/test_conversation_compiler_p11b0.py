"""P11B0 modular Conversation source/compiler acceptance tests."""

from __future__ import annotations

import copy
import hashlib
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_MAX_SHARD_BYTES,
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    render_conversation_runtime_plan,
    render_conversation_snapshot,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


REPOSITORY = Path(__file__).resolve().parents[3]


class ConversationCompilerP11B0Tests(unittest.TestCase):
    def test_manifest_merge_and_fingerprints_are_bounded(self) -> None:
        model = compile_conversation_sources(REPOSITORY)
        self.assertEqual(len(model["content"]["phraseFamilies"]), 226)
        self.assertEqual(len(model["dialogue"]["patterns"]), 54)
        self.assertEqual(len(model["dialogue"]["responsePools"]), 26)
        self.assertEqual(len(model["semantic"]["flows"]), 2)
        self.assertEqual(len(model["ui"]), 10)
        self.assertEqual(len(model["shards"]), 13)
        self.assertEqual(len(model["wholeModelFingerprint"]), 64)
        modules, reports = render_conversation_runtime_plan(model)
        self.assertEqual(len(modules), len(reports))
        self.assertTrue(reports)
        self.assertTrue(all(report["bytes"] <= CONVERSATION_MAX_SHARD_BYTES for report in reports))
        self.assertLess(
            len(
                (REPOSITORY / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
                 "Semantics/Generated/Conversation/Registry.lua").read_bytes()
            ),
            64 * 1024,
        )

    def test_moving_a_record_changes_provenance_not_runtime_identity(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            shutil.copytree(
                REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                repository / CONVERSATION_SOURCE_RELATIVE,
            )
            before = compile_conversation_sources(repository)
            greeting_path = repository / CONVERSATION_SOURCE_RELATIVE / "content/greeting.json"
            social_path = repository / CONVERSATION_SOURCE_RELATIVE / "content/social.json"
            greeting = json.loads(greeting_path.read_text(encoding="utf-8"))
            social = json.loads(social_path.read_text(encoding="utf-8"))
            moved = next(
                item for item in social["phraseFamilies"]
                if item["semanticTemplateID"] == "semantic.emote.player.clap"
            )
            social["phraseFamilies"].remove(moved)
            greeting["phraseFamilies"].append(moved)
            greeting_path.write_text(json.dumps(greeting, indent=2, sort_keys=True) + "\n")
            social_path.write_text(json.dumps(social, indent=2, sort_keys=True) + "\n")
            after = compile_conversation_sources(repository)

        def runtime_content(model: dict) -> tuple[object, str]:
            families = []
            for family in model["content"]["phraseFamilies"]:
                families.append({
                    key: value for key, value in family.items()
                    if key not in ("conversationDomain", "sourceShard")
                })
            return families, model["content"]["contentFingerprint"]

        self.assertEqual(runtime_content(before), runtime_content(after))
        self.assertEqual(before["wholeModelFingerprint"], after["wholeModelFingerprint"])
        self.assertNotEqual(
            before["locations"]["semantic.emote.player.clap"]["sourceShard"],
            after["locations"]["semantic.emote.player.clap"]["sourceShard"],
        )

    def test_targeted_service_edit_writes_only_owning_shard(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            shutil.copytree(
                REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                repository / CONVERSATION_SOURCE_RELATIVE,
            )
            service = SemanticLabAuthoringService(
                repository=repository,
                runtime_root=REPOSITORY,
            )
            item = service.load_dialogue_content(
                "phrase.semantic.flow.greeting.opening.default"
            )
            owning_path = repository / CONVERSATION_SOURCE_RELATIVE / "content/greeting.json"
            other_path = repository / CONVERSATION_SOURCE_RELATIVE / "content/social.json"
            before_other = other_path.read_bytes()
            edited = copy.deepcopy(item)
            edited["styles"]["neutral"][0]["translations"]["EN"] = (
                "Hey there. Great to see you."
            )
            report = service.write_dialogue_content_edit(
                item["id"],
                edited,
                expected_source_fingerprint=item["sourceFingerprint"],
            )
            self.assertTrue(report["ok"])
            self.assertNotEqual(owning_path.read_bytes(), b"")
            self.assertEqual(other_path.read_bytes(), before_other)
            self.assertIn(str(owning_path), report["writes"])

    def test_snapshot_is_generated_only_and_deterministic(self) -> None:
        model = compile_conversation_sources(REPOSITORY)
        first = render_conversation_snapshot(model)
        second = render_conversation_snapshot(model)
        self.assertEqual(first, second)
        decoded = json.loads(first)
        self.assertTrue(decoded["generatedOnly"])
        self.assertNotIn("_repository", decoded)
        self.assertEqual(
            hashlib.sha256(first.encode("utf-8")).hexdigest(),
            hashlib.sha256(second.encode("utf-8")).hexdigest(),
        )


if __name__ == "__main__":
    unittest.main()
