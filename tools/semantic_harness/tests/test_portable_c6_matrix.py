"""C6 portable actor matrix over the real worker and adopter Lua harnesses."""

from __future__ import annotations

from pathlib import Path
import subprocess
import sys
import unittest

from tools.semantic_harness.inspection.conversation_inspector import (
    build_conversation_inspector,
)
from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"
DYNAMIC_TRADING = REPOSITORY.parent / "DynamicTrading"


def _scenario(language: str, character_uuid: str = "c6-player-a") -> dict:
    return merge(
        DEFAULT_SCENARIO,
        {
            "player": {"characterUUID": character_uuid},
            "npc": {"npcID": "c6-mara"},
            "runtime": {"language": language, "llmEnabled": False},
        },
    )


class PortableC6MatrixTests(unittest.TestCase):
    def test_real_worker_dialogue_inspector_restart_and_translation_matrix(self) -> None:
        expected = {
            "EN": {
                "where do you live": "I don't have a confirmed home to tell you about.",
                "why is it so?": "I don't know why that is; I only know what I can confirm.",
                "hello": "Hello. Good to see you.",
                "im fine, how about you": "Doing okay, all things considered.",
            },
            "TL": {
                "hello": "Kumusta. Mabuti at nakita kita.",
                "im fine, how about you": "Okay naman ako, sa lahat ng bagay.",
            },
        }
        for language, phrases in expected.items():
            with self.subTest(language=language):
                with LuaSemanticWorker(_scenario(language)) as worker:
                    for phrase, visible in phrases.items():
                        turn = worker.input(phrase)
                        self.assertTrue(turn["accepted"], turn.get("reason"))
                        self.assertEqual(turn["messages"][0]["payload"]["text"], visible)
                        self.assertEqual(turn["translation"]["language"], language)
                        self.assertEqual(turn["llmCalls"], 0)
                        self.assertEqual(turn["transport"], [])
                        self.assertTrue(turn["observation"]["sideEffects"]["none"])
                        inspector = build_conversation_inspector(turn)
                        self.assertEqual(inspector["source"], "real_lua_worker")
                        self.assertEqual(inspector["visibleResponse"]["text"], visible)
                        self.assertTrue(inspector["finalResponse"]["text"])

                    before = worker.snapshot()
                    self.assertEqual(before["scenario"]["npc"]["npcID"], "c6-mara")
                    restarted = worker.restart()
                    self.assertTrue(restarted["ok"])
                    after = worker.input("hello")
                    self.assertTrue(after["accepted"])
                    self.assertEqual(after["actorConversation"]["actorID"], "c6-mara")

    def test_core_only_and_dynamictrading_adopter_matrix(self) -> None:
        commands = [
            (
                CORE_REPOSITORY,
                [
                    "lua5.3",
                    "tests/psychopatz_npc_acceptance_matrix_smoke.lua",
                ],
            ),
            (
                DYNAMIC_TRADING,
                [
                    sys.executable,
                    "tests/run_tests.py",
                    "dt_provider_hotswap_persistence_smoke",
                    "dt_talk_service_smoke",
                    "dt_trade_access_security_smoke",
                ],
            ),
        ]
        for workdir, command in commands:
            with self.subTest(command=command):
                result = subprocess.run(
                    command,
                    cwd=workdir,
                    capture_output=True,
                    text=True,
                    check=False,
                    timeout=60,
                )
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("PASS", result.stdout)


if __name__ == "__main__":
    unittest.main()
