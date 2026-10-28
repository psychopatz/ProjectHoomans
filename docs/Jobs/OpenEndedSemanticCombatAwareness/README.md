# Open-Ended Semantic Continuation & Combat Awareness

**Status:** DEVELOPER COMPLETE — ready for user native SP/MP verification.
**Foundation:** `docs/Jobs/UnifiedSemanticEvidenceArchitecture/`.

## Objective

Make semantic conversation continuation genuinely open-ended instead of repeatedly proposing the same generated response, and expose nearby zombie pressure plus player/NPC zombie kills through the existing bounded semantic-evidence architecture.

This job does not add another parser, world scanner, memory store, dialogue engine or combat authority.

## Accepted outcome

- generated semantic strategies use bounded session-only recurrence policy;
- `DOUBLE_DOWN` no longer immediately proposes itself after being clicked;
- typed reaffirmations such as `I mean it` remain valid and are interpreted from discourse context rather than globally hard-coded as hostility;
- hostility produces focused repair, de-escalation, escalation and follow-up choices before generic relation rows;
- player realization remains locale-owned and now has multiple deterministic DOUBLE_DOWN constructions;
- current zombie pressure is derived from the existing WorldCensus -> SpatialIndex -> Perception frame and projected as runtime SESSION evidence;
- idle/live NPC sensing runs only on the existing record scheduler/LOD cadence;
- tactical horde thresholds remain gameplay-owned while one canonical classifier owns descriptive semantic bands;
- player and NPC zombie kills converge on `engine:zombie_killed`;
- SocialEncounterTracker remains the kill/encounter aggregation owner;
- player-kill witness discovery uses SpatialIndex first instead of scanning the whole live NPC roster;
- no new ModData root, transcript, routine kill ledger or zombie-list traversal was introduced.

See ARCHITECTURE.md for ownership and PROGRESS.md for exact acceptance evidence.
