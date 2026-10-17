"""Contract checks that Semantic Lab exercises the live semantic Lua seam.

The runtime cases in the neighboring tests prove behavior on the real Lua
worker. These checks protect the stronger claim that the worker reaches the
same production entrypoint and fallback modules used by a live conversation,
while keeping native Project Zomboid engine boundaries explicit.
"""

from __future__ import annotations

from pathlib import Path
import re
import unittest


REPOSITORY = Path(__file__).resolve().parents[3]
WORKER = REPOSITORY / "tools/semantic_harness/lua/worker"
LIVE_SEMANTICS = (
    REPOSITORY
    / "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Semantics"
)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


class SemanticLiveParityTests(unittest.TestCase):
    def test_worker_calls_the_live_entrypoint_and_reads_owned_outputs(self) -> None:
        production_modules = read(WORKER / "ProductionModules.lua")
        conversation = read(WORKER / "Conversation.lua")

        self.assertIn(
            'load("ProjectHoomans", "client", '
            '"PNC/Semantics/PNC_SemanticDialogueInput.lua", "semantic_entry")',
            production_modules,
        )
        self.assertIn(
            "PNC.Semantics.DialogueInput.Submit(view, text)",
            conversation,
        )
        self.assertIn(
            "local result = view.lastSemanticDialogueResult",
            conversation,
        )
        self.assertIn(
            "local routedSituation = routedContext and routedContext.dialogueSituation",
            conversation,
        )

    def test_live_entrypoint_keeps_lifecycle_and_core_router_composition(self) -> None:
        entrypoint = read(
            LIVE_SEMANTICS / "PNC_SemanticDialogueInput.lua"
        )

        for required_module in (
            "PsychopatzCore/Semantics/PsychopatzSemanticDialogueRouter",
            "PNC/Semantics/PNC_SemanticDialoguePolicy",
            "PNC/Semantics/PNC_SemanticDialogueResponseCatalog",
            "PNC/Semantics/PNC_SemanticDialogueInput_Context",
            "PNC/Semantics/PNC_SemanticDialogueInput_ProviderFallback",
            "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle",
        ):
            with self.subTest(module=required_module):
                self.assertIn(f'require "{required_module}"', entrypoint)

        self.assertIn(
            "return Internal.SubmitSingle(view, value, part)",
            entrypoint,
        )

    def test_worker_does_not_replace_semantic_modules_with_boundary_stubs(self) -> None:
        production_modules = read(WORKER / "ProductionModules.lua")
        boundary_table = re.search(
            r"local headlessModules = \{(?P<body>.*?)\n    \}",
            production_modules,
            re.DOTALL,
        )
        self.assertIsNotNone(boundary_table)
        boundary_body = boundary_table.group("body")

        self.assertIn("native_ui", boundary_body)
        self.assertNotIn("/Semantics/", boundary_body)
        self.assertNotIn("PsychopatzSemantic", boundary_body)

        self.assertIn(
            'error("unexpected production require failure for "',
            production_modules,
        )

    def test_live_provider_fallback_is_the_worker_provider_boundary(self) -> None:
        provider_fallback = read(
            LIVE_SEMANTICS / "PNC_SemanticDialogueInput_ProviderFallback.lua"
        )

        self.assertIn(
            "integration.Submit(view, value, part)",
            provider_fallback,
        )
        self.assertIn("decision.branch = \"ASK_CLARIFICATION\"", provider_fallback)
        self.assertIn("context.llmAvailable = false", provider_fallback)
        self.assertIn("options.llmEnabled = false", provider_fallback)


if __name__ == "__main__":
    unittest.main()
