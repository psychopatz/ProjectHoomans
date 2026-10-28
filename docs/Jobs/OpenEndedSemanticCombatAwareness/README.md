# Open-Ended Semantic Continuation & Combat Awareness

**Status:** DEVELOPER COMPLETE — ready for user native SP/MP verification.
**Foundation:** `docs/Jobs/UnifiedSemanticEvidenceArchitecture/`.

## Objective

Make semantic conversation continuation genuinely open-ended, expose current zombie/combat context through bounded evidence, and make routine zombie-kill reactions immersive without turning every corpse into a relationship/conduct write or an expensive speech-generation event.

This job reuses the existing parser, semantic lifecycle, WorldCensus/SpatialIndex/Perception pipeline, SocialEncounterTracker, and PsychopatzCore ZombieKillDetector. It adds no second world scanner, kill ledger, memory store, dialogue engine, or combat authority.

## Accepted outcome

- generated semantic strategies use bounded session-only recurrence policy; `DOUBLE_DOWN` no longer immediately proposes itself after being clicked;
- typed reaffirmations such as `I mean it` remain valid and are interpreted from discourse context rather than globally hard-coded as hostility;
- current zombie pressure is derived from the existing WorldCensus -> SpatialIndex -> Perception frame and projected as runtime SESSION evidence;
- player and NPC zombie kills converge on `engine:zombie_killed`;
- the legacy Hoomans client kill-audit consumer and `witnessed_player_kill` SocialEvent/relationship/conduct path are retired;
- PsychopatzCore ZombieKillDetector remains the reusable SP/MP authority bridge, with hot-path audit printing disabled by default;
- routine player-kill reactions are ephemeral, spatial-local, capped at two speakers, and globally coalesced for five seconds; kills inside that window do no witness query or presentation work;
- routine NPC self-kills use the same semantic reaction system and bounded speaker cooldown;
- reaction style derives from existing relationship, personality, traits, panic/stress, speech style, health, and current zombie pressure;
- 42 compiler-owned EN/TL kill-reaction families cover witness/killer roles across aggressive, supportive, shaken, brave, reserved, cold, and practical styles;
- kill reactions can expose grounded `What happened?`, `How many are around?`, `Are you okay?`, and `What now?` follow-ups from the same event fact;
- routine kill speech is `memoryEligible=false` and `llmEligible=false`; meaningful protection/shared-survival outcomes remain existing SocialEncounterTracker/SocialEvents persistence boundaries;
- no new ModData root, transcript, routine kill ledger, or zombie-list traversal was introduced.

See ARCHITECTURE.md for ownership and PROGRESS.md for exact acceptance evidence.
