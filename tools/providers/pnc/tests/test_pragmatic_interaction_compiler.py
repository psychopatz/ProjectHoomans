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
    conversation_translation_catalogs_by_owner,
    render_conversation_runtime_plan,
)


REPOSITORY = Path(__file__).resolve().parents[4]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"


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
                "behavior.scene_excursion_home",
                "behavior.scene_post_combat_clear",
                "behavior.scene_excursion_preparing",
                "behavior.scene_excursion_returning",
                "behavior.scene_task_work_completed",
                "behavior.scene_horde_reply_steady",
                "behavior.scene_excursion_acknowledge",
                "behavior.scene_news_followup_answer",
                "behavior.scene_excursion_failed",
                "behavior.scene_horde_reply_cautious",
                "behavior.scene_grounded_news_share",
                "behavior.scene_news_followup",
                "behavior.scene_task_work_assigned",
                "behavior.scene_horde_prompt",
                "behavior.scene_horde_reply_brave",
                "behavior.scene_excursion_departing",
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
            "beat/social/conflict/argument_escalation.json",
        )
        self.assertEqual(
            model["locations"]["behavior.warn"]["sourceShard"],
            "behavior/social/conflict/warn.json",
        )
        for record in [*model["beats"], *model["behaviors"]]:
            self.assertIn(record["domain"], {"social", "scene"})
            self.assertNotIn("translations", record)
            self.assertNotIn("labelKey", record)
            self.assertNotIn("descriptionKey", record)

        for language in ("EN", "TL"):
            self.assertTrue(
                all(
                    "Director" not in owner_catalogs.get(language, {})
                    for owner_catalogs in conversation_translation_catalogs_by_owner(
                        model
                    ).values()
                )
            )

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
                CORE_REPOSITORY / CONVERSATION_SOURCE_RELATIVE,
                repository / CONVERSATION_SOURCE_RELATIVE,
            )
            path = (
                repository
                / CONVERSATION_SOURCE_RELATIVE
                / "beat/social/conflict/argument_escalation.json"
            )
            document = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(document.get("candidates"), dict):
                document["candidates"]["behavior.missing"] = 1
            else:
                document["candidates"][0]["behavior"] = "behavior.missing"
            path.write_text(
                json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True)
                + "\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(Exception, "unknown behavior"):
                compile_conversation_sources(
                    repository,
                    runtime_root=REPOSITORY,
                    package_repositories={
                        "PsychopatzCore": repository,
                        "ProjectHoomans": REPOSITORY,
                        "DTCommon": CORE_REPOSITORY.parent / "DynamicTrading",
                    },
                )

    def test_source_root_discovers_new_behavior_without_manifest_edit(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            source_root = repository / CONVERSATION_SOURCE_RELATIVE
            shutil.copytree(CORE_REPOSITORY / CONVERSATION_SOURCE_RELATIVE, source_root)
            manifest_path = source_root / "manifest.json"
            manifest_before = manifest_path.read_bytes()
            sample = json.loads(
                (source_root / "behavior/social/conflict/warn.json").read_text(
                    encoding="utf-8"
                )
            )
            sample["id"] = "behavior.discovery_probe"
            sample["act"] = "DISCOVERY_PROBE"
            (source_root / "behavior/social/conflict/discovery_probe.json").write_text(
                json.dumps(sample, ensure_ascii=False, indent=2, sort_keys=True)
                + "\n",
                encoding="utf-8",
            )

            model = compile_conversation_sources(
                repository,
                runtime_root=REPOSITORY,
                package_repositories={
                    "PsychopatzCore": repository,
                    "ProjectHoomans": REPOSITORY,
                    "DTCommon": CORE_REPOSITORY.parent / "DynamicTrading",
                },
            )
            self.assertIn(
                "behavior.discovery_probe",
                {row["id"] for row in model["behaviors"]},
            )
            self.assertEqual(manifest_path.read_bytes(), manifest_before)
            self.assertEqual(
                model["locations"]["behavior.discovery_probe"]["sourceShard"],
                "behavior/social/conflict/discovery_probe.json",
            )

    def test_dialogue_content_locale_discovery_remains_data_driven(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            source_root = repository / CONVERSATION_SOURCE_RELATIVE
            shutil.copytree(CORE_REPOSITORY / CONVERSATION_SOURCE_RELATIVE, source_root)
            tr_en_path = (
                source_root
                / "translations/EN/dialogue/core_text_social_departure/departure_confirmed.json"
            )
            tr_xx_path = (
                source_root
                / "translations/XX/dialogue/core_text_social_departure/departure_confirmed.json"
            )
            tr_xx_path.parent.mkdir(parents=True, exist_ok=True)
            tr_doc = json.loads(tr_en_path.read_text(encoding="utf-8"))
            tr_doc["locale"] = "XX"
            for key in list(tr_doc.get("entries") or {}):
                if key.startswith("textRows."):
                    tr_doc["entries"][key] = "Synthetic interaction wording."
            tr_xx_path.write_text(
                json.dumps(tr_doc, ensure_ascii=False, indent=2, sort_keys=True)
                + "\n",
                encoding="utf-8",
            )
            model = compile_conversation_sources(
                repository,
                runtime_root=REPOSITORY,
            )
            catalogs = conversation_translation_catalogs_by_owner(model)
            self.assertTrue(
                any("XX" in owner_catalogs for owner_catalogs in catalogs.values())
            )
            self.assertTrue(
                any(
                    "Text/social/departure/response" in owner_catalogs.get("XX", {})
                    for owner_catalogs in catalogs.values()
                )
            )
            self.assertTrue(
                any(
                    "departure.confirmed"
                    in owner_catalogs.get("XX", {}).get("Text/social/departure/response", {})
                    for owner_catalogs in catalogs.values()
                )
            )


if __name__ == "__main__":
    unittest.main()
