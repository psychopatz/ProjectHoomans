"""H2 Semantic Lab authoring and generated grounded-dialogue acceptance."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.codebuilder.authoring import (
    generate_dialogue_source,
    preview_dialogue_source,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
SOURCE = REPOSITORY / (
    "tools/semantic_harness/codebuilder/sources/grounded_personal_dialogue.json"
)


class GroundedPersonalDialogueH2Tests(unittest.TestCase):
    def test_backstory_source_is_typed_and_preview_is_effect_free(self) -> None:
        report = preview_dialogue_source(SOURCE)

        self.assertTrue(report["ok"])
        self.assertTrue(report["previewOnly"])
        self.assertTrue(report["effectFree"])
        self.assertEqual(report["writes"], [])
        self.assertEqual(report["patternCount"], 7)
        self.assertEqual(report["responsePoolCount"], 13)
        self.assertEqual(report["translationCounts"], {"EN": 13, "TL": 13})
        self.assertEqual(
            report["candidateReview"]["summary"],
            {"approved": 7, "rejected": 0, "not_candidate": 13},
        )
        self.assertIn(
            "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
            "PNC_SemanticGroundedPersonalDialogue.lua",
            report["generatedPaths"],
        )
        self.assertIn(
            "Contents/mods/ProjectHoomans/common/media/translation/EN/Conversation/"
            "Semantic/GroundedPersonalDialogue.json",
            report["generatedPaths"],
        )

    def test_generation_is_byte_stable_and_has_en_tl_catalogs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first = generate_dialogue_source(SOURCE, repository=root)
            first_bytes = {
                path: Path(path).read_bytes() for path in first["writes"]
            }
            second = generate_dialogue_source(SOURCE, repository=root)
            second_bytes = {
                path: Path(path).read_bytes() for path in second["writes"]
            }

        self.assertTrue(first["ok"])
        self.assertTrue(first["generationApproved"])
        self.assertEqual(first_bytes, second_bytes)
        self.assertEqual(len(first["writes"]), 6)
        self.assertEqual(
            json.loads(
                first_bytes[
                    next(path for path in first_bytes if path.endswith(
                        "common/media/translation/EN/Conversation/"
                        "Semantic/GroundedPersonalDialogue.json"
                    ))
                ].decode("utf-8")
            )["UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob"],
            "I worked as %1 before all this.",
        )
        self.assertEqual(
            hashlib.sha256(first_bytes[next(iter(first_bytes))]).hexdigest(),
            hashlib.sha256(second_bytes[next(iter(second_bytes))]).hexdigest(),
        )

    def test_worker_loads_generated_patterns_after_fresh_restart(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            before = worker.preview("what was your old job")
            restart = worker.restart()
            after = worker.preview("what was your old job")

        self.assertTrue(restart.get("accepted", True))
        for result in (before, after):
            ir = result["result"]["ir"]
            self.assertEqual(
                ir["provenance"]["pattern"],
                "pnc.backstory.question.former_job.old_job",
            )
            self.assertEqual(ir["subject"], "NPC_BACKSTORY")
            self.assertEqual(ir["extensions"]["factProvider"], "npc_backstory")
            self.assertEqual(ir["extensions"]["topicID"], "backstory.former_job")
            self.assertTrue(result["observation"]["sideEffects"]["none"])
            self.assertEqual(result["transport"], [])

    def test_backstory_provider_contract_rejects_untyped_authoring(self) -> None:
        source = json.loads(SOURCE.read_text(encoding="utf-8"))
        del source["patterns"][0]["emit"]["extensions"]["factProvider"]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / SOURCE.name
            path.write_text(json.dumps(source), encoding="utf-8")
            report = preview_dialogue_source(path)

        self.assertFalse(report["ok"])
        self.assertIn("typed fact provider", report["diagnostics"][0]["message"])


if __name__ == "__main__":
    unittest.main()
