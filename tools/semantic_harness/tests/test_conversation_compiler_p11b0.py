"""P11B0 modular Conversation source/compiler acceptance tests."""

from __future__ import annotations

import copy
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_MAX_SHARD_BYTES,
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    conversation_translation_bundles,
    render_conversation_runtime_plan,
)
from tools.semantic_harness.codebuilder.build import _write_conversation_translation_manifest
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


REPOSITORY = Path(__file__).resolve().parents[3]


class ConversationCompilerP11B0Tests(unittest.TestCase):
    def test_manifest_merge_and_fingerprints_are_bounded(self) -> None:
        model = compile_conversation_sources(REPOSITORY)
        source_documents = model["_source_documents"]
        expected_families = sum(
            len(document.get("phraseFamilies", []))
            for path, document in source_documents.items()
            if path.startswith("content/")
        )
        expected_patterns = sum(
            len(document.get("patterns", []))
            for path, document in source_documents.items()
            if path.startswith("patterns/")
        )
        expected_pools = sum(
            len(document.get("responsePools", []))
            for path, document in source_documents.items()
            if path.startswith("flows/")
        )
        expected_ui = sum(
            len(document.get("suggestions", []))
            for path, document in source_documents.items()
            if path.startswith("ui/")
        )
        self.assertEqual(
            len(model["content"]["phraseFamilies"]),
            expected_families,
        )
        self.assertEqual(len(model["dialogue"]["patterns"]), expected_patterns)
        self.assertEqual(
            len(model["dialogue"]["responsePools"]),
            expected_pools,
        )
        self.assertGreaterEqual(len(model["semantic"]["flows"]), 1)
        self.assertEqual(len(model["ui"]), expected_ui)
        self.assertEqual(len(model["shards"]), len(source_documents))
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
            social_path = repository / CONVERSATION_SOURCE_RELATIVE / "content/social/emotes.json"
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
            before["locations"]["phrase.semantic.emote.player.clap"]["sourceShard"],
            after["locations"]["phrase.semantic.emote.player.clap"]["sourceShard"],
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
            other_path = repository / CONVERSATION_SOURCE_RELATIVE / "content/social/tool_replies.json"
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

    def test_generation_plan_has_no_whole_model_snapshot(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        report = service.preview_dataset_generation("common_dialogue")
        self.assertTrue(report["ok"], report)
        paths = report["generatedPaths"]
        self.assertTrue(paths)
        self.assertFalse(
            any("ConversationSnapshot" in path for path in paths),
            paths,
        )
        self.assertFalse(
            any(
                "tools/semantic_harness/codebuilder/generated/conversation"
                in path
                for path in paths
            ),
            paths,
        )


    def test_third_locale_is_discovered_without_code_whitelist(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            shutil.copytree(
                REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                repository / CONVERSATION_SOURCE_RELATIVE,
            )
            greeting_path = (
                repository
                / CONVERSATION_SOURCE_RELATIVE
                / "content/greeting.json"
            )
            greeting = json.loads(greeting_path.read_text(encoding="utf-8"))
            phrase = greeting["phraseFamilies"][0]["styles"]["neutral"][0]
            phrase["translations"]["XX"] = "Synthetic locale text."
            greeting_path.write_text(
                json.dumps(
                    greeting,
                    ensure_ascii=False,
                    indent=2,
                    sort_keys=True,
                ) + "\n",
                encoding="utf-8",
            )
            model = compile_conversation_sources(
                repository,
                runtime_root=REPOSITORY,
            )
            bundles = conversation_translation_bundles(model)
            self.assertIn("XX", bundles)
            self.assertTrue(any(bundles["XX"].values()))

            translation_root = repository / "translation"
            for language in ("EN", "XX"):
                path = translation_root / language / "Conversation/Test.json"
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("{}\n", encoding="utf-8")
            manifest_path = _write_conversation_translation_manifest(
                translation_root
            )
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(sorted(manifest["languages"]), ["EN", "XX"])
            self.assertEqual(
                manifest["languages"]["XX"],
                ["XX/Conversation/Test.json"],
            )


if __name__ == "__main__":
    unittest.main()
