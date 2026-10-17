# Modular Conversation translations — preserved implementation, focus on usability

Project Hoomans already has a `Conversation.json` manifest with **12 EN and 12 TL** files under subsystem folders. The previous 521-key single files were replaced; the historical ledger reports exact key/value/placeholder parity. Do not re-split the catalogs or regenerate a monolith.

PsychopatzCore remote main `44a4d534a9520440070ae7943d7ae9fb848f71ce` now implements manifest registration in `PsychopatzCustomTranslationManager.lua`, including optional `scope.registerSystem(systemName, basePath, manifestPath)`. The older claim that manifest support is missing remotely is stale.

## Developer acceptance (in Semantic Lab)
- Verify actual production Core translator reads the declared manifest and fragment(s), in EN and TL, via its public lookup API.
- Verify identity, wellbeing, one tool response and one new response variation resolve to the expected keys/text, preserving English fallback diagnostics.
- Preserve current `PNC.Translation.GetKey/Get/TrFormat`, EN/TL placeholders/values, compatible legacy Core catalogs and native PZ Translate system.
- Investigate the Trading catalog's missing registration only through an actual observed lookup/consumer before changing it.
- Keep shard authoring straightforward: additions belong to existing subsystem folders and manifest paths; no ever-growing catch-all response JSON or fake Python mapping layer.

## Final user acceptance (NOT a Codex blocker)
Provide a brief EN/TL in-game language-switch/restart and NPC-response checklist with the final handoff. Do **not** demand Steam Workshop publication or a running game from Codex.
