"""F4 end-to-end acceptance through CodeBuilder, generated assets, and Lua."""

from __future__ import annotations

import hashlib
from pathlib import Path
import shutil
import tempfile
import unittest

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.tests.test_interaction_spec import backstory_spec
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[3]
BACKSTORY_BLOCKS = [
    "language.trigger",
    "language.backstory_subject",
    "memory.backstory_fact",
    "dialogue_responses.response_pool",
]


def _worker_scenario(
    *, character_uuid: str = "char-f4-a", language: str = "EN"
) -> dict:
    return merge(
        DEFAULT_SCENARIO,
        {
            "player": {"characterUUID": character_uuid},
            "npc": {
                "npcID": "npc-f4-generated",
                "identitySeed": 90210,
                "identity": {"seed": 90210},
                "tacticalClass": "colonist",
                "relationship": {"familiarity": 80},
            },
            "runtime": {"language": language},
        },
    )


def _hometown_spec() -> dict:
    spec = backstory_spec(
        spec_id="pnc.lab.generated.hometown",
        utterance="tell me about your hometown",
        kind="hometown",
        pool_id="semantic.lab.generated.hometown",
        key="UI_PNC_Conversation_Semantic_LabGeneratedHometown",
        english="I grew up in %1.",
        tagalog="Lumaki ako sa %1.",
    )
    spec["blocks"][0]["parameters"]["negativeUtterance"] = (
        "do not ask about my hometown"
    )
    return spec


class SemanticLabF4AcceptanceTests(unittest.TestCase):
    @staticmethod
    def _isolated_repository(root: Path) -> None:
        """Provide the real mod tree without allowing the test to write it."""

        (root / "Contents" / "mods").mkdir(parents=True)
        shutil.copytree(
            REPOSITORY / "Contents" / "mods" / "ProjectHoomans",
            root / "Contents" / "mods" / "ProjectHoomans",
        )
        (root / "tools" / "semantic_harness" / "codebuilder" / "sources").mkdir(
            parents=True
        )
        shutil.copy2(
            REPOSITORY
            / "tools"
            / "semantic_harness"
            / "codebuilder"
            / "sources"
            / "grounded_personal_dialogue.json",
            root
            / "tools"
            / "semantic_harness"
            / "codebuilder"
            / "sources"
            / "grounded_personal_dialogue.json",
        )
        shutil.copytree(
            REPOSITORY / "tools" / "semantic_harness" / "lua",
            root / "tools" / "semantic_harness" / "lua",
        )
        (root / "tests" / "support").mkdir(parents=True)
        shutil.copy2(
            REPOSITORY / "tests" / "support" / "test.lua",
            root / "tests" / "support" / "test.lua",
        )
        shutil.copy2(
            REPOSITORY / "tests" / "test_config.lua",
            root / "tests" / "test_config.lua",
        )

    @staticmethod
    def _written_bytes(report: dict, root: Path) -> dict[Path, bytes]:
        return {
            Path(path).relative_to(root): Path(path).read_bytes()
            for path in report.get("writes", [])
        }

    @staticmethod
    def _knowledge_kinds(snapshot: dict | None) -> set[str]:
        kinds: set[str] = set()
        for category in (snapshot or {}).get("categories", []):
            for descriptor in category.get("descriptors", []):
                kind = descriptor.get("presentation", {}).get("backstoryKind")
                if kind:
                    kinds.add(str(kind))
        return kinds

    def test_codeblocks_generate_reload_localize_and_isolate_real_dialogue(self) -> None:
        former_job = backstory_spec(
            spec_id="pnc.lab.generated.former_job",
            utterance="tell me about your work history",
            pool_id="semantic.lab.generated.former_job",
            key="UI_PNC_Conversation_Semantic_LabGeneratedFormerJob",
        )
        former_job["blocks"][1]["parameters"][
            "dialogueFollowUp"
        ] = "CONTEXT_REFERENCE"
        hometown = _hometown_spec()

        with tempfile.TemporaryDirectory(prefix="project-hoomans-f4-") as directory:
            root = Path(directory)
            self._isolated_repository(root)
            service = SemanticLabAuthoringService(repository=root, runtime_root=REPOSITORY)

            preview = service.preview_workflow(
                "grounded_personal_dialogue",
                BACKSTORY_BLOCKS,
                interaction_spec=former_job,
            )
            self.assertTrue(preview["ok"], preview)
            self.assertTrue(preview["previewOnly"])
            self.assertTrue(preview["effectFree"])
            self.assertEqual(preview["writes"], [])
            self.assertTrue(preview["sourcePreview"]["generatedPaths"])
            self.assertTrue(
                any(
                    path.endswith(
                        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/Generated/Dialogue/GroundedPersonalDialogue.lua"
                    )
                    for path in preview["sourcePreview"]["generatedPaths"]
                )
            )

            not_approved = service.generate_workflow(
                "grounded_personal_dialogue",
                BACKSTORY_BLOCKS,
                interaction_spec=former_job,
                approved=False,
            )
            self.assertFalse(not_approved["ok"])
            self.assertEqual(not_approved["writes"], [])

            generated_former = service.generate_workflow(
                "grounded_personal_dialogue",
                BACKSTORY_BLOCKS,
                interaction_spec=former_job,
                approved=True,
            )
            self.assertTrue(generated_former["ok"], generated_former)
            self.assertTrue(generated_former["generationApproved"])
            self.assertEqual(generated_former["reloadedBy"], "caller_restart_required")
            self.assertTrue(
                any(path.endswith("EN/Conversation/Semantic/GroundedPersonalDialogue.json")
                    for path in generated_former["writes"])
            )
            self.assertTrue(
                any(path.endswith("TL/Conversation/Semantic/GroundedPersonalDialogue.json")
                    for path in generated_former["writes"])
            )
            first_bytes = self._written_bytes(generated_former, root)

            with LuaSemanticWorker(
                _worker_scenario(),
                repository=root,
                core_repository=REPOSITORY.parent / "psychopatzCore",
            ) as worker:
                first_turn = worker.input("tell me about your work history")
                self.assertEqual(
                    first_turn["result"]["ir"]["provenance"]["pattern"],
                    "pnc.lab.generated.former_job.tell_me_about_your_work_history",
                )
                self.assertEqual(
                    first_turn["messages"][0]["payload"]["text"],
                    "I worked as farmer before all this.",
                )
                self.assertEqual(
                    first_turn["messages"][0]["payload"]["translationKey"],
                    "UI_PNC_Conversation_Semantic_LabGeneratedFormerJob",
                )
                self.assertEqual(
                    first_turn["messages"][0]["payload"]["args"]["content"],
                    "farmer",
                )
                self.assertEqual(
                    first_turn["result"]["ir"]["extensions"]["factProvider"],
                    "npc_backstory",
                )
                self.assertEqual(
                    first_turn["result"]["ir"]["extensions"]["disclosure"],
                    "server_authorized",
                )
                self.assertTrue(first_turn["observation"]["sideEffects"]["actions"])
                self.assertEqual(
                    first_turn["observation"]["sideEffects"]["actions"][0]["name"],
                    "KnowledgeDisclosureRequest",
                )
                self.assertEqual(
                    self._knowledge_kinds(first_turn["contextAfter"]["dossier"]),
                    {"former_job"},
                )

                follow_up = worker.input("where?")
                self.assertEqual(
                    follow_up["result"]["ir"]["provenance"]["pattern"],
                    "pnc.backstory.follow_up.where",
                )
                self.assertNotEqual(
                    follow_up["result"]["decision"]["branch"], "ASK_CLARIFICATION"
                )
                self.assertEqual(
                    follow_up["contextAfter"]["dialogue"]["lastBackstoryKind"],
                    "former_job",
                )

            changed_preview = service.preview_workflow(
                "grounded_personal_dialogue",
                BACKSTORY_BLOCKS,
                interaction_spec=hometown,
            )
            self.assertTrue(changed_preview["ok"], changed_preview)
            self.assertNotEqual(
                preview["sourcePreview"]["generatedSourceFingerprint"],
                changed_preview["sourcePreview"]["generatedSourceFingerprint"],
            )
            self.assertNotEqual(
                preview["sourcePreview"]["compiledSummary"]["patternIDs"],
                changed_preview["sourcePreview"]["compiledSummary"]["patternIDs"],
            )
            generated_hometown = service.generate_workflow(
                "grounded_personal_dialogue",
                BACKSTORY_BLOCKS,
                interaction_spec=hometown,
                approved=True,
            )
            self.assertTrue(generated_hometown["ok"], generated_hometown)
            second_bytes = self._written_bytes(generated_hometown, root)
            self.assertTrue(
                any(
                    "UI_PNC_Conversation_Semantic_LabGeneratedHometown" in data.decode("utf-8")
                    for path, data in second_bytes.items()
                    if path.suffix in {".json", ".lua"}
                )
            )
            generated_hometown_again = service.generate_workflow(
                "grounded_personal_dialogue",
                BACKSTORY_BLOCKS,
                interaction_spec=hometown,
                approved=True,
            )
            self.assertEqual(
                second_bytes,
                self._written_bytes(generated_hometown_again, root),
            )
            self.assertEqual(
                {
                    path: hashlib.sha256(data).hexdigest()
                    for path, data in second_bytes.items()
                },
                {
                    path: hashlib.sha256(data).hexdigest()
                    for path, data in self._written_bytes(generated_hometown_again, root).items()
                },
            )

            player_a = _worker_scenario(character_uuid="char-f4-a")
            player_b = _worker_scenario(character_uuid="char-f4-b")
            with LuaSemanticWorker(
                player_a,
                repository=root,
                core_repository=REPOSITORY.parent / "psychopatzCore",
            ) as worker:
                former_a = worker.input("tell me about your work history")
                knowledge_a = former_a["contextAfter"]["dossier"]
                worker.configure(player_b)
                hometown_b = worker.input("tell me about your hometown")
                knowledge_b = hometown_b["contextAfter"]["dossier"]
                self.assertEqual(self._knowledge_kinds(knowledge_a), {"former_job"})
                self.assertEqual(self._knowledge_kinds(knowledge_b), {"hometown"})
                self.assertTrue(hometown_b["contextAfter"]["pbrainz"]["disclosureFiltered"])
                worker.configure(player_a)
                worker.knowledge_bootstrap("f4-player-a-reload")
                self.assertEqual(
                    self._knowledge_kinds(worker.snapshot()["context"]["knowledge"]),
                    {"former_job"},
                )
                worker.restart()
                reloaded_hometown = worker.input("tell me about your hometown")
                self.assertEqual(
                    reloaded_hometown["result"]["ir"]["provenance"]["pattern"],
                    "pnc.lab.generated.hometown.tell_me_about_your_hometown",
                )

            with LuaSemanticWorker(
                _worker_scenario(language="TL"),
                repository=root,
                core_repository=REPOSITORY.parent / "psychopatzCore",
            ) as worker:
                tagalog = worker.input("tell me about your hometown")
                payload = tagalog["messages"][0]["payload"]
                content = payload["args"]["content"]
                self.assertEqual(payload["text"], f"Lumaki ako sa {content}.")
                self.assertTrue(content)
                self.assertEqual(
                    tagalog["translation"]["language"], "TL"
                )
                self.assertEqual(
                    payload["translationKey"],
                    "UI_PNC_Conversation_Semantic_LabGeneratedHometown",
                )
                response_lookups = [
                    item for item in tagalog["translation"]["lookups"]
                    if item.get("key") == payload["translationKey"]
                ]
                self.assertTrue(response_lookups)
                self.assertFalse(
                    any(item.get("fallbackUsed") for item in response_lookups)
                )

            with LuaSemanticWorker(
                _worker_scenario(),
                repository=root,
                core_repository=REPOSITORY.parent / "psychopatzCore",
            ) as worker:
                empty = worker.knowledge_metrics()
                worker.backstory(90210, npc_id="npc-f4-generated")
                unchanged_after_seed = worker.knowledge_metrics()
            with LuaSemanticWorker(
                _worker_scenario(),
                repository=root,
                core_repository=REPOSITORY.parent / "psychopatzCore",
            ) as worker:
                worker.input("tell me about your work history")
                one_fact = worker.knowledge_metrics()
            with LuaSemanticWorker(
                _worker_scenario(),
                repository=root,
                core_repository=REPOSITORY.parent / "psychopatzCore",
            ) as worker:
                ten_facts = worker.knowledge_metrics(1, 10)

            self.assertEqual(empty["serializedBytes"], 0)
            self.assertEqual(unchanged_after_seed["serializedBytes"], 0)
            self.assertEqual(one_fact["evidenceCount"], 1)
            self.assertEqual(ten_facts["evidenceCount"], 10)
            self.assertGreater(one_fact["serializedBytes"], empty["serializedBytes"])
            self.assertGreater(ten_facts["serializedBytes"], one_fact["serializedBytes"])


if __name__ == "__main__":
    unittest.main()
