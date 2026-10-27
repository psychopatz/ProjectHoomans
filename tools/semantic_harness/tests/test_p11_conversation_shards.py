"""P11C acceptance for manifest-driven Conversation authoring shards."""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tools.semantic_harness.codebuilder.dialogue_content import (
    CONTENT_MANIFEST_SCHEMA,
    compile_dialogue_content,
    load_dialogue_content_manifest,
    load_dialogue_content_source,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


REPOSITORY = Path(__file__).resolve().parents[3]
MANIFEST = (
    REPOSITORY
    / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
)
OLD_MONOLITH = (
    REPOSITORY
    / "tools/semantic_harness/codebuilder/sources/semantic_dialogue_content.json"
)


class P11ConversationShardTests(unittest.TestCase):
    def _temporary_content_service(self, temporary: str) -> SemanticLabAuthoringService:
        root = Path(temporary)
        source_root = MANIFEST.parent
        target_root = root / "tools/semantic_harness/codebuilder/sources/conversation"
        target_root.mkdir(parents=True)
        for source in source_root.glob("*.json"):
            shutil.copy2(source, target_root / source.name)
        shutil.copytree(source_root / "shards", target_root / "shards")
        return SemanticLabAuthoringService(repository=root, runtime_root=root)

    def test_manifest_is_the_only_canonical_content_entrypoint(self) -> None:
        manifest = load_dialogue_content_manifest(MANIFEST)
        self.assertEqual(manifest["schema"], CONTENT_MANIFEST_SCHEMA)
        self.assertGreaterEqual(len(manifest["shards"]), 20)
        self.assertFalse(OLD_MONOLITH.exists())

        shard_ids = [item["id"] for item in manifest["shards"]]
        self.assertEqual(len(shard_ids), len(set(shard_ids)))
        shard_paths = [MANIFEST.parent / item["path"] for item in manifest["shards"]]
        self.assertTrue(all(path.is_file() for path in shard_paths))
        self.assertNotIn("phraseFamilies", manifest)
        self.assertNotIn("patterns", manifest)
        for path in shard_paths:
            shard = json.loads(path.read_text(encoding="utf-8"))
            self.assertNotIn("patterns", shard)
            self.assertNotIn("flows", shard)
            self.assertNotIn("responsePools", shard)

        self.assertTrue(
            (
                REPOSITORY
                / "tools/semantic_harness/codebuilder/sources/semantic_definitions.json"
            ).is_file()
        )

    def test_shards_compile_to_one_global_semantic_id_space(self) -> None:
        source = load_dialogue_content_source(MANIFEST)
        compiled = compile_dialogue_content(source)
        semantic_ids = [
            family["semanticTemplateID"] for family in compiled["phraseFamilies"]
        ]
        phrase_ids = [
            phrase["id"]
            for family in compiled["phraseFamilies"]
            for phrases in family["styles"].values()
            for phrase in phrases
        ]
        self.assertEqual(len(semantic_ids), len(set(semantic_ids)))
        self.assertEqual(len(phrase_ids), len(set(phrase_ids)))
        self.assertEqual(len(compiled["phraseFamilies"]), 550)
        self.assertEqual(len(compiled["playerChoices"]), 12)
        self.assertEqual(len(compiled["runtimeAliases"]), 292)

    def test_authoring_service_reads_and_writes_the_owning_shard(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            service = self._temporary_content_service(temporary)
            shard_root = root / "tools/semantic_harness/codebuilder/sources/conversation/shards"
            item = service.load_dialogue_content(
                "phrase.semantic.command.player.follow"
            )
            edited = json.loads(json.dumps(item, ensure_ascii=False))
            edited["styles"]["neutral"][0]["translations"]["EN"] = (
                "{names}, stay with me."
            )
            edited["styles"]["neutral"][0]["translations"]["TL"] = (
                "{names}, manatili sa akin."
            )
            preview = service.preview_dialogue_content_edit(
                item["id"],
                edited,
                expected_source_fingerprint=item["sourceFingerprint"],
            )
            self.assertTrue(preview["ok"])
            self.assertTrue(preview["effectFree"])
            self.assertEqual(preview["writes"], [])

            report = service.write_dialogue_content_edit(
                item["id"],
                edited,
                expected_source_fingerprint=item["sourceFingerprint"],
            )
            self.assertTrue(report["ok"])
            self.assertTrue(any(path.endswith("commands.json") for path in report["writes"]))
            self.assertFalse((root / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json").read_text().find("stay with me") >= 0)
            commands = json.loads(
                (shard_root / "commands.json").read_text(encoding="utf-8")
            )
            family = next(
                family for family in commands["phraseFamilies"]
                if family["semanticTemplateID"] == "semantic.command.player.follow"
            )
            self.assertEqual(
                family["styles"]["neutral"][0]["translations"]["EN"],
                "{names}, stay with me.",
            )

    def test_structured_variant_operations_share_stale_validation_and_compile(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            service = self._temporary_content_service(temporary)
            item = service.load_dialogue_content(
                "phrase.semantic.command.player.follow"
            )
            before = service.inspect_dialogue_variants(item["id"])
            self.assertTrue(before["ok"])
            self.assertGreaterEqual(before["variantCount"], 1)

            duplicate = service.preview_dialogue_content_operation(
                item["id"],
                "duplicate_variant",
                style="neutral",
                index=0,
                targetIndex=1,
                expected_source_fingerprint=item["sourceFingerprint"],
            )
            self.assertTrue(duplicate["ok"], duplicate)
            self.assertTrue(duplicate["effectFree"])
            self.assertEqual(duplicate["writes"], [])

            stale = service.preview_dialogue_content_operation(
                item["id"],
                "add_variant",
                style="neutral",
                translations={"EN": "stale", "TL": "luma"},
                expected_source_fingerprint="stale-fingerprint",
            )
            self.assertFalse(stale["ok"])
            self.assertTrue(stale["stale"])

            mismatch = service.preview_dialogue_content_operation(
                item["id"],
                "add_variant",
                style="neutral",
                translations={"EN": "{names} stay", "TL": "Manatili"},
                expected_source_fingerprint=item["sourceFingerprint"],
            )
            self.assertFalse(mismatch["ok"])
            self.assertIn("placeholders", mismatch["diagnostics"][0]["message"])

            written = service.write_dialogue_content_operation(
                item["id"],
                "duplicate_variant",
                style="neutral",
                index=0,
                targetIndex=1,
                expected_source_fingerprint=item["sourceFingerprint"],
            )
            self.assertTrue(written["ok"], written)
            self.assertTrue(written["writes"])
            after = service.inspect_dialogue_variants(item["id"])
            self.assertEqual(after["variantCount"], before["variantCount"] + 1)

            deleted = service.write_dialogue_content_operation(
                item["id"],
                "delete_variant",
                style="neutral",
                index=1,
                expected_source_fingerprint=after["sourceFingerprint"],
            )
            self.assertTrue(deleted["ok"], deleted)
            self.assertEqual(
                service.inspect_dialogue_variants(item["id"])["variantCount"],
                before["variantCount"],
            )
            self.assertTrue(service.validate_dialogue_content()["ok"])


if __name__ == "__main__":
    unittest.main()
