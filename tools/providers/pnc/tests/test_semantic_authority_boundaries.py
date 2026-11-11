"""semantic-authority regression guards."""

from __future__ import annotations

from pathlib import Path
import json
import subprocess
import unittest

from tools.semantic_harness.discovery.runtime import discover_newest_runtime


PROJECT = Path(__file__).resolve().parents[4]
LUA = (
    PROJECT
    / "Contents/mods/ProjectHoomans"
    / discover_newest_runtime(PROJECT / "Contents/mods/ProjectHoomans")
    / "media/lua"
)


class SemanticAuthorityBoundaryTests(unittest.TestCase):
    def _production_lua_sources(self) -> list[tuple[Path, str]]:
        definition = LUA / "shared/PNC/Core/Commands/PNC_VanillaEmoteInteractions.lua"
        return [
            (path, path.read_text())
            for path in LUA.rglob("*.lua")
            if path != definition
        ]

    def test_canonical_realization_boundary_returns_plan_and_provenance(self) -> None:
        source = (
            LUA
            / "shared/PNC/Semantics/PNC_SemanticDialogueRealizationAuthority.lua"
        ).read_text()
        self.assertIn("Catalog.Select", source)
        self.assertIn("responsePlan = plan", source)
        self.assertIn("realizationFamily", source)
        self.assertIn("realizationID", source)
        self.assertIn("groundedFactRefs", source)

    def test_greeting_and_emote_no_longer_select_reply_flavor_ids(self) -> None:
        greeting = (
            LUA
            / "server/PNC/Social/PNC_SocialGreetingService_TryGreet.lua"
        ).read_text()
        emote = (
            LUA
            / "server/PNC/Networking/Handlers/"
            "PNC_ServerPlayerEmoteInteractionCommandHandler.lua"
        ).read_text()
        self.assertNotIn("GreetingReplyFlavorID(", greeting)
        self.assertNotIn("ReplyFlavorID(", emote)
        self.assertIn("CompanionSpeech", greeting)
        self.assertIn("ResolveGreeting", greeting)
        self.assertIn('poolID = "semantic.emote.reply"', emote)

    def test_social_context_is_the_only_project_hoomans_context_namespace(self) -> None:
        source = (
            LUA / "shared/PNC/Core/Social/PNC_SemanticSocialContext.lua"
        ).read_text()
        self.assertIn("PNC.Semantics.SocialContext", source)
        self.assertNotIn("PNC.FlavorText", source)
        self.assertNotIn("PNC.FlavorTextConst", source)

    def test_lifecycle_provenance_carries_realization_identity(self) -> None:
        source = (
            LUA / "shared/PNC/Semantics/PNC_SemanticInteractionLifecycle.lua"
        ).read_text()
        self.assertIn("realizationFamily", source)
        self.assertIn("realizationID", source)

    def test_retired_emote_response_helpers_have_no_production_callers(self) -> None:
        forbidden = (
            "Interactions.ReplyFlavorID(",
            "Interactions.GreetingReplyFlavorID(",
            "Interactions.ResolveNPCType(",
            "Interactions.ResolveRelationshipTier(",
            "Interactions.GreetingState(",
        )
        offenders = []
        for path, source in self._production_lua_sources():
            for token in forbidden:
                if token in source:
                    offenders.append(f"{path.relative_to(PROJECT)}: {token}")
        self.assertEqual([], offenders)

    def test_event_reactions_cross_semantic_boundary_before_delivery(self) -> None:
        paths = (
            LUA / "server/PNC/Medical/MedicalCareExecutor/"
            "PNC_MedicalCareExecutor_Supply.lua",
            LUA / "shared/PNC/Core/Presence/PNC_BodyLifecycle/"
            "PNC_BodyLifecycle_CorpseAwareness_Reactions.lua",
            LUA / "client/PNC/Conversation/PNC_SemanticSpeechPresentation_Speech.lua",
            LUA / "client/PNC/Commands/PNC_CompanionCommandPresentation.lua",
        )
        for path in paths:
            source = path.read_text()
            self.assertIn("SocialReactions", source, str(path))
            self.assertIn("responsePlanID", source, str(path))
            self.assertIn("realizationID", source, str(path))

    def test_context_classifiers_are_neutral_providers(self) -> None:
        source = (
            LUA / "shared/PNC/Core/Social/PNC_SemanticSocialContext.lua"
        ).read_text()
        self.assertIn("function SocialContext.ResolveNPCType", source)
        self.assertIn("function SocialContext.ResolveRelationshipTier", source)
        self.assertIn("PNC.Semantics.SocialContext", source)

    def test_representative_reactions_cross_the_same_boundary(self) -> None:
        cases = {
            "greeting": (
                LUA / "server/PNC/Social/PNC_SocialGreetingService_TryGreet.lua",
                ("CompanionSpeech", "ResolveGreeting", "responsePlanID", "realizationID"),
            ),
            "farewell": (
                LUA / "client/PNC/Conversation/PNC_ConversationFarewell.lua",
                ("RealizationAuthority", "semantic.flow.farewell"),
            ),
            "emote": (
                LUA / "server/PNC/Networking/Handlers/"
                "PNC_ServerPlayerEmoteInteractionCommandHandler.lua",
                ("RealizationAuthority", "semantic.emote.reply"),
            ),
            "companion": (
                LUA / "client/PNC/Commands/PNC_CompanionCommandPresentation.lua",
                ("SocialReactions", "responsePlanID", "realizationID"),
            ),
            "combat": (
                LUA / "server/PNC/Social/SocialEventHooks/"
                "PNC_SocialEventHooks_CombatAdapter_Awareness.lua",
                ("SocialReactions", "responsePlanID", "realizationID"),
            ),
            "medical": (
                PROJECT / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Social/SocialEventHooks/"
                "PNC_SocialEventHooks_DownedDistress_Public_Shared.lua",
                ("SocialReactions", "responsePlanID", "realizationID"),
            ),
            "leader_loss": (
                LUA / "server/PNC/Social/SocialEventHooks/"
                "PNC_SocialEventHooks_LeaderLoss.lua",
                ("SocialReactions", "responsePlanID", "realizationID"),
            ),
        }
        for label, (path, tokens) in cases.items():
            source = path.read_text()
            for token in tokens:
                self.assertIn(token, source, f"{label}: {path}")

    def test_renderer_boundary_has_no_contextual_flavor_selection(self) -> None:
        authority = (
            LUA
            / "shared/PNC/Semantics/PNC_SemanticDialogueRealizationAuthority.lua"
        ).read_text()
        reactions = (
            LUA / "shared/PNC/Semantics/PNC_SemanticSocialReaction.lua"
        ).read_text()
        presentation = (
            LUA / "client/PNC/Commands/PNC_CompanionCommandPresentation.lua"
        ).read_text()
        self.assertIn("Catalog.Select", authority)
        self.assertNotIn("Flavor.Resolve", authority)
        self.assertIn("Authority.Resolve", reactions)
        self.assertIn("context.responsePlanID and context.realizationID", presentation)
        self.assertIn("semantic_realization_required", presentation)

    def test_canonical_en_tl_dialogue_content_is_the_only_pnc_wording_catalog(self) -> None:
        root = PROJECT / "Contents/mods/ProjectHoomans/common/media/translation"
        for language in ("EN", "TL"):
            greeting = root / language / "Conversation/Greeting.json"
            social = root / language / "Conversation/Social.json"
            semantic = root / language / "Conversation/Semantic/Responses.json"
            for path in (greeting, social, semantic):
                self.assertTrue(path.exists(), str(path))
                self.assertTrue(json.loads(path.read_text()), str(path))
            self.assertIn(
                "conversation.content.semantic.flow.greeting.opening.default.neutral.01",
                json.loads(greeting.read_text()),
            )
            self.assertIn(
                "conversation.content.semantic.emote.player.thumbsdown.neutral.01",
                json.loads(social.read_text()),
            )
            self.assertIn(
                "UI_PNC_Conversation_Semantic_FlowGreetingOpening",
                json.loads(semantic.read_text()),
            )
            self.assertFalse(list((root / language / "Conversation/Flavor").glob("*.json")))
            self.assertFalse(list((root / language / "Conversation/ToolReplies").glob("*.json")))

    def test_repository_policy_is_durable_and_no_executable_goal_prompt(self) -> None:
        root_policy = (PROJECT / "AGENTS.md").read_text()
        forbidden_goal_state = (
            "ACTIVE SEMANTIC INTERACTION LIFECYCLE GOAL",
            "Current exact Next Chunk",
            "HISTORICAL / SUPERSEDED",
        )
        for token in forbidden_goal_state:
            self.assertNotIn(
                token,
                root_policy,
                "root AGENTS.md must contain durable repository policy, not goal state",
            )
        self.assertIn("Repository instruction-file hygiene", root_policy)
        self.assertIn("docs/Jobs/<Goal>/", root_policy)

        self.assertEqual([], list(PROJECT.rglob("GOAL_PROMPT.md")))
        self.assertEqual([], list(PROJECT.rglob("HISTORICAL_GOAL_PROMPT.md")))
        self.assertFalse(
            (PROJECT / "docs/Jobs/SemanticInteractionLifecycle").exists(),
            "superseded job documentation belongs in Git history, not the active tree",
        )



if __name__ == "__main__":
    unittest.main()
