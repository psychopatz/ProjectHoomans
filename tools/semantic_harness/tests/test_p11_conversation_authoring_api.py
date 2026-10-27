"""P11G/P11H shared Conversation authoring service and CLI contracts."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import unittest

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


REPOSITORY = Path(__file__).resolve().parents[3]


class ConversationAuthoringAPITests(unittest.TestCase):
    def _cli(self, *arguments: str) -> dict:
        completed = subprocess.run(
            [
                sys.executable,
                "-m",
                "tools.semantic_harness",
                "--no-gui",
                "--jsonl",
                *arguments,
            ],
            cwd=REPOSITORY,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)
        return json.loads(completed.stdout.strip().splitlines()[-1])

    def test_cli_and_gui_service_share_bounded_content_inspection(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        service_report = service.inspect_dialogue_variants(
            "phrase.semantic.command.player.follow"
        )
        cli_report = self._cli(
            "--conversation-variants",
            "phrase.semantic.command.player.follow",
        )
        self.assertTrue(service_report["ok"])
        self.assertTrue(cli_report["ok"])
        self.assertEqual(cli_report["semanticTemplateID"], service_report["semanticTemplateID"])
        self.assertEqual(cli_report["variants"], service_report["variants"])

    def test_cli_preview_is_effect_free_and_ui_authority_is_locked(self) -> None:
        service = SemanticLabAuthoringService(
            repository=REPOSITORY,
            runtime_root=REPOSITORY,
        )
        item = service.load_dialogue_content("phrase.semantic.command.player.follow")
        report = self._cli(
            "--conversation-operation", "duplicate_variant",
            "--conversation-content-id", item["id"],
            "--conversation-style", "neutral",
            "--conversation-index", "0",
            "--conversation-target-index", "1",
            "--conversation-source-fingerprint", item["sourceFingerprint"],
        )
        self.assertTrue(report["ok"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["writes"], [])

        locked = self._cli(
            "--conversation-ui-operation", "update_node",
            "--conversation-ui-node", "conversation.choice:question.weather",
        )
        self.assertTrue(locked["ok"])
        self.assertEqual(locked["writes"], [])

    def test_cli_validation_is_machine_readable_and_effect_free(self) -> None:
        content = self._cli("--conversation-validate", "content")
        ui = self._cli("--conversation-validate", "ui")
        self.assertTrue(content["ok"])
        self.assertTrue(ui["ok"])
        self.assertGreater(content["phraseFamilyCount"], 0)
        self.assertGreater(ui["nodeCount"], 0)
        self.assertTrue(content["effectFree"])
        self.assertTrue(ui["effectFree"])
        self.assertEqual(content["writes"], [])
        self.assertEqual(ui["writes"], [])


if __name__ == "__main__":
    unittest.main()
