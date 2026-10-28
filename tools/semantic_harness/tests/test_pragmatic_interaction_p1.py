"""Structural compiler acceptance for the pragmatic interaction recovery."""

from __future__ import annotations

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    conversation_translation_bundles,
    render_conversation_runtime_plan,
)


REPOSITORY = Path(__file__).resolve().parents[3]


class PragmaticInteractionCompilerTests(unittest.TestCase):
    def test_beats_and_behaviors_compile_as_modular_structural_records(self) -> None:
        model = compile_conversation_sources(REPOSITORY)
        self.assertEqual(
            {item["id"] for item in model["behaviors"]},
            {
                "behavior.warn",
                "behavior.retaliate_verbally",
                "behavior.deescalate",
                "behavior.end_conversation",
                "behavior.reconcile",
                "behavior.challenge",
                "behavior.acknowledge_thanks",
                "behavior.ask_memory_followup",
                "behavior.acknowledge_memory",
                "behavior.acknowledge_news",
                "behavior.world_event_warn",
                "behavior.clarify_context",
                "behavior.acknowledge_reply",
                "behavior.acknowledge_repair",
            },
        )
        self.assertEqual(
            {item["id"] for item in model["beats"]},
            {
                "beat.suspicious_first_contact",
                "beat.argument_escalation",
                "beat.reconciliation",
            },
        )
        self.assertEqual(
            model["locations"]["beat.argument_escalation"]["sourceShard"],
            "beats/social/argument_escalation.json",
        )
        self.assertEqual(
            model["locations"]["behavior.warn"]["sourceShard"],
            "behaviors/social/warn.json",
        )
        for record in [*model["beats"], *model["behaviors"]]:
            self.assertEqual(record["domain"], "social")
            self.assertNotIn("translations", record)
            self.assertNotIn("labelKey", record)
            self.assertNotIn("descriptionKey", record)

        bundles = conversation_translation_bundles(model)
        for language in ("EN", "TL"):
            self.assertNotIn("Director", bundles[language])

        _modules, reports = render_conversation_runtime_plan(model)
        self.assertTrue(
            any(
                row["kind"] == "Beats" and row["domain"] == "social"
                for row in reports
            )
        )
        self.assertTrue(
            any(
                row["kind"] == "Behaviors" and row["domain"] == "social"
                for row in reports
            )
        )

    def test_unknown_behavior_reference_is_rejected_at_compile_time(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            shutil.copytree(
                REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                repository / CONVERSATION_SOURCE_RELATIVE,
            )
            path = (
                repository
                / CONVERSATION_SOURCE_RELATIVE
                / "beats/social/argument_escalation.json"
            )
            document = json.loads(path.read_text(encoding="utf-8"))
            document["beats"][0]["candidates"][0]["behavior"] = "behavior.missing"
            path.write_text(
                json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True)
                + "\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(Exception, "unknown behavior"):
                compile_conversation_sources(repository, runtime_root=REPOSITORY)

    def test_source_root_discovers_new_behavior_without_manifest_edit(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            source_root = repository / CONVERSATION_SOURCE_RELATIVE
            shutil.copytree(REPOSITORY / CONVERSATION_SOURCE_RELATIVE, source_root)
            manifest_path = source_root / "manifest.json"
            manifest_before = manifest_path.read_bytes()
            sample = json.loads(
                (source_root / "behaviors/social/warn.json").read_text(
                    encoding="utf-8"
                )
            )
            sample["behaviors"][0]["id"] = "behavior.discovery_probe"
            sample["behaviors"][0]["act"] = "DISCOVERY_PROBE"
            (source_root / "behaviors/social/discovery_probe.json").write_text(
                json.dumps(sample, ensure_ascii=False, indent=2, sort_keys=True)
                + "\n",
                encoding="utf-8",
            )

            model = compile_conversation_sources(
                repository,
                runtime_root=REPOSITORY,
            )
            self.assertIn(
                "behavior.discovery_probe",
                {row["id"] for row in model["behaviors"]},
            )
            self.assertEqual(manifest_path.read_bytes(), manifest_before)
            self.assertEqual(
                model["locations"]["behavior.discovery_probe"]["sourceShard"],
                "behaviors/social/discovery_probe.json",
            )

    def test_dialogue_content_locale_discovery_remains_data_driven(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            source_root = repository / CONVERSATION_SOURCE_RELATIVE
            shutil.copytree(REPOSITORY / CONVERSATION_SOURCE_RELATIVE, source_root)
            path = (
                source_root
                / "content/social/interaction/argument_retaliate.json"
            )
            document = json.loads(path.read_text(encoding="utf-8"))
            document["phraseFamilies"][0]["styles"]["neutral"][0][
                "translations"
            ]["XX"] = "Synthetic interaction wording."
            path.write_text(
                json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True)
                + "\n",
                encoding="utf-8",
            )
            model = compile_conversation_sources(
                repository,
                runtime_root=REPOSITORY,
            )
            bundles = conversation_translation_bundles(model)
            self.assertIn("XX", bundles)
            self.assertIn("Social", bundles["XX"])
            self.assertIn(
                "UI_PNC_Conversation_Content_"
                "SemanticInteractionArgumentRetaliateNeutral01",
                bundles["XX"]["Social"],
            )


if __name__ == "__main__":
    unittest.main()
