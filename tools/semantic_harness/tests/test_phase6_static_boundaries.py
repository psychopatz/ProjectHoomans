"""Static Phase 6 guards for semantic submission ownership."""

from __future__ import annotations

import re
import unittest
from pathlib import Path


REPOSITORY = Path(__file__).resolve().parents[3]
SEMANTIC_INPUT_ROOT = (
    REPOSITORY
    / "Contents"
    / "mods"
    / "ProjectHoomans"
    / "42.20"
    / "media"
    / "lua"
    / "client"
    / "PNC"
    / "Semantics"
)
SERVER_HANDLER_ROOT = (
    REPOSITORY
    / "Contents"
    / "mods"
    / "ProjectHoomans"
    / "42.20"
    / "media"
    / "lua"
    / "server"
    / "PNC"
    / "Networking"
    / "Handlers"
)
TICK_REGISTRATION = re.compile(r"\bEvents\s*\.\s*OnTick\b|\bOnTick\s*\.\s*Add\b")


class Phase6StaticBoundaryTests(unittest.TestCase):
    def test_semantic_input_modules_have_no_tick_polling_registration(self) -> None:
        paths = sorted(SEMANTIC_INPUT_ROOT.glob("PNC_SemanticDialogueInput*.lua"))
        self.assertTrue(paths, "semantic input modules were not found")
        offenders = [
            str(path.relative_to(REPOSITORY))
            for path in paths
            if TICK_REGISTRATION.search(path.read_text(encoding="utf-8"))
        ]
        self.assertEqual(
            offenders,
            [],
            "semantic dialogue submission must remain request-driven; "
            f"tick registration found in {offenders}",
        )

    def test_semantic_social_server_path_retains_authority_and_lease_gates(self) -> None:
        handler = (
            SERVER_HANDLER_ROOT
            / "PNC_ServerSemanticSocialInteractionCommandHandler_Handle.lua"
        ).read_text(encoding="utf-8")
        apply_event = (
            SERVER_HANDLER_ROOT
            / "PNC_ServerSemanticSocialInteractionCommandHandler_ApplySocialEvent.lua"
        ).read_text(encoding="utf-8")
        for marker in (
            "Core.IsAuthority()",
            "validateLease(player, record, conversationToken)",
            "SocialEvents.Emit({",
        ):
            self.assertIn(marker, handler + apply_event)

    def test_provider_social_server_path_retains_lease_ownership_and_replay_gates(
        self,
    ) -> None:
        admission_lease = (
            SERVER_HANDLER_ROOT
            / "PNC_ServerLLMSocialReactionCommandHandler_AdmissionLease.lua"
        ).read_text(encoding="utf-8")
        for marker in (
            "internal.ValidateLLMRequest",
            "internal.ValidateLease",
            "playerOwnsLease(player, lease)",
            "replayCachedReaction({",
            "lease.consumed == true",
        ):
            self.assertIn(marker, admission_lease)


if __name__ == "__main__":
    unittest.main()
