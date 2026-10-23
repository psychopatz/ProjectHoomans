"""P13F machine-readable CLI parity against a real offline save."""

from __future__ import annotations

import json
from hashlib import sha256
import os
from pathlib import Path
import subprocess
import sys
import unittest


REPOSITORY = Path(__file__).resolve().parents[3]
SAVE = Path(
    "/home/psychopatz/Zomboid/Saves/Apocalypse/"
    "2026-10-14_13-57-03/global_mod_data.bin"
)
PLAYER = "char_1791957489838_240087"
NPC = "npcAdamBloom_48G5"


class CLIP13FTests(unittest.TestCase):
    def run_cli(self, *arguments: str) -> list[dict]:
        environment = dict(os.environ)
        environment["XDG_STATE_HOME"] = "/tmp/projecthoomans-p13f-cli-state"
        completed = subprocess.run(
            [sys.executable, "-m", "tools.semantic_harness", *arguments, "--jsonl"],
            cwd=REPOSITORY,
            env=environment,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            completed.returncode,
            0,
            msg=f"CLI failed: {completed.stderr}\n{completed.stdout[:1000]}",
        )
        return [
            json.loads(line)
            for line in completed.stdout.splitlines()
            if line.strip()
        ]

    def test_discovery_and_saved_world_queries_are_machine_readable(self) -> None:
        rows = self.run_cli("--discover-saves")
        catalog = next(row for row in rows if row.get("type") == "saved_world_catalog")
        self.assertGreaterEqual(len(catalog["catalog"]), 2)
        self.assertTrue(any(row.get("status") == "rejected" for row in catalog["rejected"]))

        players = self.run_cli("--list-players", "--save", str(SAVE))[0]
        self.assertEqual(players["type"], "saved_players")
        self.assertTrue(any(row["id"] == PLAYER for row in players["players"]))

        factions = self.run_cli("--list-factions", "--save", str(SAVE))[0]
        self.assertEqual(factions["type"], "saved_factions")
        self.assertTrue(any(NPC in row.get("memberIDs", []) for row in factions["factions"]))

        communities = self.run_cli("--list-communities", "--save", str(SAVE))[0]
        self.assertEqual(communities["type"], "saved_communities")
        self.assertTrue(communities["communities"])

        search = self.run_cli(
            "--search-npcs", "Adam", "--save", str(SAVE)
        )[0]
        self.assertEqual(search["npcs"][0]["id"], NPC)

    def test_saved_pair_actions_diff_reset_and_source_hash(self) -> None:
        before_hash = sha256(SAVE.read_bytes()).hexdigest()
        rows = self.run_cli(
            "--save", str(SAVE),
            "--player", PLAYER,
            "--npc", NPC,
            "--inspect-inventories",
            "--gift", "Base.Bandage",
            "--working-world-diff",
        )
        loaded = next(row for row in rows if row.get("type") == "saved_pair_loaded")
        self.assertEqual(loaded["source"], "SAVE")
        inspection = next(row for row in rows if row.get("type") == "actor_inspection")
        self.assertGreaterEqual(
            len(inspection["inventories"]["player"]["items"]), 1
        )
        diff = next(
            row for row in rows
            if row.get("schema") == "semantic.harness_working_world.diff.v1"
        )
        self.assertTrue(diff["changed"])
        self.assertTrue(any("inventory" in patch["path"] for patch in diff["patches"]))
        self.assertEqual(before_hash, sha256(SAVE.read_bytes()).hexdigest())

        reloaded = self.run_cli(
            "--save", str(SAVE),
            "--player", PLAYER,
            "--npc", NPC,
            "--reload-save",
            "--inspect-player",
        )
        reloaded_pair = next(
            row for row in reloaded if row.get("type") == "saved_pair_loaded"
        )
        self.assertEqual(reloaded_pair["source"], "SAVE")

        reset_rows = self.run_cli(
            "--save", str(SAVE),
            "--player", PLAYER,
            "--npc", NPC,
            "--gift", "Base.Bandage",
            "--reset-world",
            "--working-world-diff",
            "--inspect-relationship",
        )
        reset = next(row for row in reset_rows if row.get("type") == "reset_world")
        self.assertEqual(reset["source"], "SAVE")
        reset_diff = next(
            row for row in reset_rows
            if row.get("schema") == "semantic.harness_working_world.diff.v1"
        )
        self.assertFalse(reset_diff["changed"])
        self.assertEqual(before_hash, sha256(SAVE.read_bytes()).hexdigest())

    def test_talk_proposal_and_recruitment_commands_reuse_worker(self) -> None:
        talk_rows = self.run_cli(
            "--save", str(SAVE),
            "--player", PLAYER,
            "--npc", NPC,
            "--talk-start", "current",
            "--talk-utterance", "hello",
        )
        self.assertTrue(any(isinstance(row.get("start"), dict) for row in talk_rows))

        proposal_rows = self.run_cli(
            "--save", str(SAVE),
            "--player", PLAYER,
            "--npc", NPC,
            "--propose",
        )
        proposal = next(
            row for row in proposal_rows if row.get("type") == "relationship_proposal"
        )
        self.assertEqual(
            proposal["response"].get("action"),
            "RELATIONSHIP_PROPOSAL",
        )

        recruitment_rows = self.run_cli(
            "--save", str(SAVE),
            "--player", PLAYER,
            "--npc", NPC,
            "--recruit",
        )
        recruitment = next(
            row for row in recruitment_rows if row.get("type") == "recruitment"
        )
        self.assertEqual(
            recruitment["response"].get("result", {})
            .get("actionResult", {})
            .get("action"),
            "RECRUIT",
        )


if __name__ == "__main__":
    unittest.main()
