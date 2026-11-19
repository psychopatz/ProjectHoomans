# Progress — Project Hoomans Portable Social State Adoption

**Status:** ACTIVE — H7 accepted under parent P10; H8 pending.
**Parent:** PsychopatzCore Docs/portable_social_state/.
**Current participant phase:** H8 under parent P12.
**Participant completion:** H0-H7 accepted; H8 pending.

## Verified progress

- H0-H7 remain source and test verified (H0-H6 committed historical milestones; H7 accepted under parent P10).
- Hoomans correctly consumes Core target keys, retention and provenance fields, compiled SocialPolicy definitions and foreign Core memories through semantic evidence.
- H7 single-persistence Core social authority implemented: `PNC_Persistence_CoreSocial` and `PNC_RelationshipRepository.SerializeRecord` persist only PNC-owned extensions (`authority == "core"`, `morale`, `moraleBaseline`, `conduct` without derived `scores`, `relationshipExtensions` with `bond`, `interactionRevision`, `lastInteractionAt`, `interactionJournal`) while Core `actor.social` is the sole persisted generic relationship/memory authority.
- Ephemeral combined runtime views (`EnsureRuntimeView`, `FromCoreSocial`, `SyncFromCore`) hydrate generic approval, respect, familiarity, baselines, states, memories, cooldowns, and saturation from Core on load/access; generic mutations sync once to Core (`SyncToCore` with `changeSpec` support) and refresh the runtime view.
- Versioned one-time legacy migration (`core_social_single_authority` v1) imports older pre-P10 PNC generic saves into Core once, prevents duplicate re-migration, and writes the `authority == "core"` envelope on subsequent saves.
- Verified 17/17 Hoomans convergence/social/persistence smoke tests, `pnc_portable_social_convergence_smoke` (PASS), Core `core_lua` 66/66 (including cross-repo `psychopatz_social_single_persistence_authority_smoke`), and 0 Kahlua errors across all 9 modified Hoomans production Lua files.

## Immediate Next Chunk

Await Core P11 completion, then execute H8 final regression under parent P12 across Hoomans social, conduct, semantic evidence, reconnect alias, combined DTAbstract/DTHoomans continuity, and the full Hoomans Lua test sweep.

Do not touch the unrelated dirty NPC authoring or portrait work.
