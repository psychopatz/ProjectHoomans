"""Recovery acceptance: behaviors use ordinary Dialogue Content."""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    conversation_translation_catalogs_by_owner,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker


REPOSITORY = Path(__file__).resolve().parents[4]
CORE_REPOSITORY = REPOSITORY.parent / "psychopatzCore"


class InteractionDialogueContentEditingContractTests(unittest.TestCase):
    def test_behaviors_reference_dialogue_content_not_response_pools(self) -> None:
        model = compile_conversation_sources(REPOSITORY)
        behaviors = {item["id"]: item for item in model["behaviors"]}
        self.assertEqual(
            behaviors["behavior.warn"]["outputs"]["speech"]["contentTemplateID"],
            "social.hostile_boundary",
        )
        self.assertEqual(
            behaviors["behavior.retaliate_verbally"]["outputs"]["speech"]["contentTemplateID"],
            "interaction.argument.retaliate",
        )
        self.assertEqual(
            behaviors["behavior.deescalate"]["outputs"]["speech"]["contentTemplateID"],
            "interaction.argument.deescalate",
        )
        self.assertEqual(
            behaviors["behavior.challenge"]["outputs"]["speech"]["contentTemplateID"],
            "interaction.first_contact.challenge",
        )
        for behavior in behaviors.values():
            self.assertNotIn("responsePool", behavior)
            self.assertNotIn("contentTemplateID", behavior)
            self.assertNotIn("dialogueAct", behavior)

        director_pools = [
            item["id"]
            for item in model["dialogue"].get("responsePools", [])
            if str(item.get("id") or "").startswith("semantic.director.")
        ]
        self.assertEqual(director_pools, [])

        templates = {
            item["id"]
            for item in model["psdlRuntimePlans"]
        }
        for template in (
            "interaction.argument.retaliate",
            "interaction.argument.deescalate",
            "interaction.first_contact.challenge",
        ):
            self.assertIn(template, templates)

        retaliate_plan = next(
            item
            for item in model["psdlRuntimePlans"]
            if item["id"] == "interaction.argument.retaliate"
        )
        self.assertEqual(retaliate_plan["owner"], "ProjectHoomans")
        self.assertTrue(
            any(
                role.get("translations", {}).get("EN")
                and role.get("translations", {}).get("TL")
                for role in retaliate_plan.get("textRoles", [])
            )
        )

    def test_existing_dialogue_content_authoring_edits_interaction_wording(self) -> None:
        from tools.semantic_harness.tests.convo_engine_test_support import (
            _setup_three_repo_workspace,
        )

        with tempfile.TemporaryDirectory() as directory:
            repos = _setup_three_repo_workspace(Path(directory))
            service = SemanticLabAuthoringService(
                repos["core"],
                runtime_root=repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            core_manifest_path = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
            )
            core_manifest = json.loads(
                core_manifest_path.read_text(encoding="utf-8")
            )
            core_manifest["externalSourceRoots"] = [
                {
                    "path": "adopters/hoomans/dialogue",
                    "kind": "convo_engine",
                    "domain": "general",
                    "order": 3011,
                    "owner": "ProjectHoomans",
                    "sourcePath": "tools/providers/pnc/codebuilder/sources/conversation/dialogue",
                    "domainFromSubdir": True,
                }
            ]
            core_manifest_path.write_text(
                json.dumps(core_manifest, indent=2) + "\n",
                encoding="utf-8",
            )
            source_dir_rel = (
                "tools/providers/pnc/codebuilder/sources/conversation/"
                "dialogue/social_interaction_argument"
            )
            shutil.copytree(
                REPOSITORY / source_dir_rel,
                repos["hoomans"] / source_dir_rel,
                dirs_exist_ok=True,
            )
            dest_path = (
                repos["hoomans"] / source_dir_rel / "interaction_argument_retaliate.json"
            )

            got = service.dispatch_operation(
                "convo.get", {"target": "interaction.argument.retaliate"}
            )
            self.assertTrue(got["found"], got)
            preview_doc = service.preview_convo_engine_document(
                got["document"], source_path=dest_path
            )
            compiled_variants = preview_doc["compiled"]["records"][0]["payload"]["say"]["realizations"]["1"]["variants"]
            doc = deepcopy(got["document"])
            doc["say"] = {
                "variants": [
                    {"id": v["id"], "text": deepcopy(v["text"])}
                    for v in compiled_variants
                ]
            }
            doc["say"]["variants"][0]["text"]["EN"][0] = (
                "You are really pushing me now."
            )
            doc["say"]["variants"][0]["text"]["TL"][0] = (
                "Talagang sinusubok mo ako ngayon."
            )
            preview = service.edit_convo_engine_family(
                dest_path,
                {"say": doc["say"]},
                expected_source_fingerprint=got["sourceFingerprint"],
                write=False,
            )
            self.assertTrue(preview["ok"], preview)
            written = service.edit_convo_engine_family(
                dest_path,
                {"say": doc["say"]},
                expected_source_fingerprint=got["sourceFingerprint"],
                write=True,
            )
            self.assertTrue(written["ok"], written)
            refreshed = service.dispatch_operation(
                "convo.get", {"target": "interaction.argument.retaliate"}
            )
            self.assertEqual(
                refreshed["document"]["say"]["variants"][0]["text"]["EN"][0],
                "You are really pushing me now.",
            )
            self.assertEqual(
                refreshed["document"]["say"]["variants"][0]["text"]["TL"][0],
                "Talagang sinusubok mo ako ngayon.",
            )
            built = service.dispatch_operation("convo.build.apply", {})
            self.assertTrue(built["ok"], built)
            target_paths = [
                Path(path)
                for path in built.get("writes", [])
                if "SocialInteractionArgument" in str(path)
                and str(path).endswith(".lua")
            ]
            self.assertTrue(target_paths, built.get("writes"))
            generated_module = "\n".join(
                path.read_text(encoding="utf-8") for path in target_paths
            )
            self.assertIn("You are really pushing me now.", generated_module)
            self.assertIn("Talagang sinusubok mo ako ngayon.", generated_module)

    def test_real_worker_uses_one_response_authority_and_content_realization(self) -> None:
        scenario = deepcopy(DEFAULT_SCENARIO)
        scenario["npc"]["personality"] = {
            "aggression": 0.95,
            "confidence": 0.85,
            "forgiveness": 0.8,
        }
        with LuaSemanticWorker(scenario) as worker:
            result = worker.input("fuck ypuuuu")

        decision = result["result"]["decision"]
        interaction = decision["interactionPlan"]
        self.assertEqual(
            interaction["behaviorID"],
            "behavior.retaliate_verbally",
        )
        self.assertEqual(
            interaction["contentTemplateID"],
            "interaction.argument.retaliate",
        )
        self.assertEqual(
            decision["response"]["sourcePoolID"],
            "semantic.hostile_remark",
        )
        self.assertEqual(
            decision["response"]["plan"]["dialogueAct"],
            "RETALIATE_VERBALLY",
        )
        self.assertEqual(
            decision["response"]["plan"]["turns"][0]["segments"][0]["templateID"],
            "interaction.argument.retaliate",
        )
        visible = result["observation"]["response"]
        self.assertEqual(
            visible["semanticTemplateID"],
            "interaction.argument.retaliate",
        )
        self.assertTrue(visible["text"])
        self.assertNotEqual(visible.get("selectionSource"), "director")


if __name__ == "__main__":
    unittest.main()
