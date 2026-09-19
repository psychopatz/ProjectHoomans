"""Entry-point, CLI, and settings draft contract tests."""

from __future__ import annotations

from contextlib import redirect_stdout
from copy import deepcopy
import io
import json
import subprocess
import sys
import unittest
from unittest.mock import patch

from tools.semantic_harness import app
import tools.semantic_harness.cli as cli_module
from tools.semantic_harness.cli import _parser, cli
from tools.semantic_harness.rendering import pretty
from tools.semantic_harness.runner import HarnessRun
from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.settings_dialog import collect_scenario_settings


def settings_values() -> dict[str, object]:
    return {
        "runtime.mode": "multiplayer",
        "runtime.language": "TL",
        "runtime.llmEnabled": True,
        "runtime.providerAvailable": False,
        "world.hunger": "0.3",
        "world.thirst": "0.5",
        "world.fatigue": "0.2",
        "world.stress": "0.1",
        "world.boredom": "0",
        "world.panic": "0",
        "world.timeOfDay": "14.5",
        "world.worldAgeHours": "50.5",
        "world.weather": "rain",
        "player.characterUUID": "char_patrick",
        "player.forename": "Patrick",
        "player.surname": "Patz",
        "player.displayName": "Patrick Patz",
        "player.inventory": json.dumps(DEFAULT_SCENARIO["player"]["inventory"]),
        "npc.npcID": "npc_mara",
        "npc.forename": "Mara",
        "npc.surname": "Vale",
        "npc.identityState": "unknown",
        "npc.relationshipState": "Member",
        "npc.traits": json.dumps(["friendly"]),
        "npc.personality": json.dumps({"reserved": False}),
        "npc.inventory": json.dumps(DEFAULT_SCENARIO["npc"]["inventory"]),
        "relationship.approval": "3",
        "relationship.respect": "2",
        "relationship.familiarity": "4",
        "relationship.revision": "8",
        "relationship.identityTrust": "trusted",
        "conversation.topic": "items",
        "conversation.token": "settings-contract",
        "runtime.commandResponses": json.dumps(DEFAULT_SCENARIO["runtime"]["commandResponses"]),
        "runtime.nativeTranslations": json.dumps({"UI_Test_Key": "test"}),
    }


class AppEntryTests(unittest.TestCase):
    def test_main_routes_cli_and_doctor_arguments(self) -> None:
        with patch.object(app, "install_shutdown_handler"), patch.object(app, "cli", return_value=7) as run_cli:
            self.assertEqual(app.main(["--cli", "--input", "hello"]), 7)
        run_cli.assert_called_once()

        with (
            patch.object(app, "install_shutdown_handler"),
            patch.object(app, "run_doctor", return_value=4) as run_doctor,
            patch.object(app, "cli") as run_cli,
        ):
            self.assertEqual(app.main(["--doctor-json", "--cli"]), 4)
        run_doctor.assert_called_once()
        run_cli.assert_not_called()

    def test_cli_case_output_and_conflict_exit_code(self) -> None:
        report = HarnessRun(case_id="identity", conflicts=[{"kind": "duplicate"}])
        arguments = _parser().parse_args(["--case", "identity.json", "--jsonl"])
        output = io.StringIO()
        with (
            patch("tools.semantic_harness.cli.load_case", return_value=object()),
            patch("tools.semantic_harness.cli.run_case", return_value=report),
            redirect_stdout(output),
        ):
            self.assertEqual(cli(arguments), 3)
        record = json.loads(output.getvalue())
        self.assertEqual(record["type"], "harness_run")
        self.assertEqual(record["caseID"], "identity")
        self.assertEqual(record["conflicts"][0]["kind"], "duplicate")

    def test_interactive_audit_uses_incremental_ledger(self) -> None:
        arguments = _parser().parse_args(["--cli", "--interactive", "--audit", "--jsonl"])
        output = io.StringIO()
        with (
            patch.object(cli_module.sys, "stdin", io.StringIO("first\nsecond\n")),
            patch("tools.semantic_harness.cli.LuaSemanticWorker") as worker_type,
            patch("tools.semantic_harness.cli.ConflictLedger") as ledger_type,
            redirect_stdout(output),
        ):
            worker = worker_type.return_value.__enter__.return_value
            worker.input.side_effect = [{"turn": 1}, {"turn": 2}]
            ledger_type.return_value.report.return_value = []

            self.assertEqual(cli(arguments), 0)

        ledger_type.return_value.add.assert_any_call({"turn": 1})
        ledger_type.return_value.add.assert_any_call({"turn": 2})
        self.assertEqual(ledger_type.return_value.add.call_count, 2)
        self.assertEqual(ledger_type.return_value.report.call_count, 1)
        self.assertEqual(len(output.getvalue().splitlines()), 3)

    def test_parser_preserves_cli_defaults_and_flags(self) -> None:
        arguments = _parser().parse_args(["--cli", "--language", "TL", "--input", "hello"])
        self.assertTrue(arguments.no_gui)
        self.assertEqual(arguments.language, "TL")
        self.assertEqual(arguments.input, ["hello"])
        self.assertEqual(arguments.timeout, 5.0)
        self.assertIn("Tkinter chat UI and CLI", _parser().description)

    def test_importing_entrypoint_does_not_import_tkinter(self) -> None:
        result = subprocess.run(
            [
                sys.executable,
                "-c",
                "import sys; import tools.semantic_harness.app; print('tkinter' in sys.modules)",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "False")


class ScenarioSettingsContractTests(unittest.TestCase):
    def test_collection_copies_and_validates_complete_settings(self) -> None:
        draft = merge({}, DEFAULT_SCENARIO)
        draft["extension"] = {"keep": True}
        original = deepcopy(draft)

        updated = collect_scenario_settings(draft, settings_values())

        self.assertEqual(draft, original)
        self.assertIsNot(updated, draft)
        self.assertEqual(updated["extension"], {"keep": True})
        self.assertEqual(updated["runtime"]["language"], "TL")
        self.assertEqual(updated["world"]["hunger"], 0.3)
        self.assertEqual(updated["npc"]["traits"], ["friendly"])
        self.assertEqual(updated["npc"]["relationship"]["revision"], 8)
        self.assertEqual(updated["conversation"]["token"], "settings-contract")

    def test_collection_reports_invalid_numbers_and_json_shapes(self) -> None:
        values = settings_values()
        values["world.hunger"] = "hungry"
        with self.assertRaisesRegex(ValueError, "world.hunger must be a number"):
            collect_scenario_settings(merge({}, DEFAULT_SCENARIO), values)

        values = settings_values()
        values["player.inventory"] = "[]"
        with self.assertRaisesRegex(ValueError, "player.inventory must be a JSON object"):
            collect_scenario_settings(merge({}, DEFAULT_SCENARIO), values)

        values = settings_values()
        values["runtime.nativeTranslations"] = "{"
        with self.assertRaisesRegex(ValueError, "runtime.nativeTranslations must contain valid JSON"):
            collect_scenario_settings(merge({}, DEFAULT_SCENARIO), values)


if __name__ == "__main__":
    unittest.main()
