# Progress — Project Hoomans Portable Social State Adoption

**Status:** ACCEPTED (READY FOR USER LIVE TEST) — H0-H8 accepted under parent P0-P12.
**Parent:** PsychopatzCore Docs/portable_social_state/.
**Current participant phase:** H8 accepted under parent P12 (9/9 participant phases complete).
**Participant completion:** H0-H8 accepted under parent P0-P12.

## Verified progress

- H0-H8 remain source and test verified (H7 committed at `90fd69fb41ade486f26b181c09482b6015e9c463`; H8 verified after Core P11 and P12).
- Hoomans correctly consumes Core target keys, retention and provenance fields, compiled SocialPolicy definitions and foreign Core memories through semantic evidence.
- H7 single-persistence Core social authority implemented: `PNC_Persistence_CoreSocial` and `PNC_RelationshipRepository.SerializeRecord` persist only PNC-owned extensions (`authority == "core"`, `morale`, `moraleBaseline`, `conduct` without derived `scores`, `relationshipExtensions` with `bond`, `interactionRevision`, `lastInteractionAt`, `interactionJournal`) while Core `actor.social` is the sole persisted generic relationship/memory authority.
- Ephemeral combined runtime views (`EnsureRuntimeView`, `FromCoreSocial`, `SyncFromCore`) hydrate generic approval, respect, familiarity, baselines, states, memories, cooldowns, and saturation from Core on load/access; generic mutations sync once to Core (`SyncToCore` with `changeSpec` support) and refresh the runtime view.
- Versioned one-time legacy migration (`core_social_single_authority` v1) imports older pre-P10 PNC generic saves into Core once, prevents duplicate re-migration, and writes the `authority == "core"` envelope on subsequent saves.
- H8 final regression verified after Core P11 (`407d7d8982944ad78fea815694ed82e7f16daf86`) and Core P12 native player-identity safety:
  - Scoped Hoomans social/conduct/semantic-evidence/convergence suite: `26/26` PASS (1.30s).
  - Full Hoomans Lua suite: `1,065/1,070` PASS — 0 portable-social/relationship/conduct/semantic regressions (failures are only the 4 pre-existing unrelated baselines `pnc_animation_scene_debug_routes_smoke`, `pnc_context_debug_smoke`, `pnc_population_director_smoke`, `pz_custom_translation_manager_smoke` plus 1 unrelated concurrent dirty test `pnc_starting_companion_ui_interaction_smoke`).
  - Kahlua verification: `0` errors on all 9 modified Hoomans production Lua files.
  - Parent Core `core_lua`: `66/66` PASS (including `psychopatz_social_single_persistence_authority_smoke` exercising DTAbstract -> DTHoomans -> DTAbstract + Hoomans extensions + SemanticEvidence + Conduct + SocialEvents); `reconcile.py --check` clean; DynamicTrading `DT6`: `90/90` PASS.

## Immediate Next Chunk

All H0-H8 participant milestones are complete under parent P0-P12; ready for user live playtesting.

Do not touch the unrelated dirty NPC authoring or portrait work.
