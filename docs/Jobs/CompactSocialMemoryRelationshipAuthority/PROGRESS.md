# Progress — Project Hoomans Portable Social State Adoption

**Status:** READY FOR USER LIVE TEST (Developer H0–H6 / Parent P0–P9 Accepted).
**Parent:** PsychopatzCore Docs/portable_social_state/.
**Current participant phase:** H6 accepted (`P9` complete; awaiting user live SP/MP test).
**Participant completion:** 7/7 phases accepted (H0, H1, H2, H3, H4, H5, H6).

## Verified progress

- **H0 (Accepted):** Full H0 inventory recorded in `AUDIT.md`; baseline smoke suites green.
- **H1/H2 (Accepted):** Reconciled `PNC_EntityRef.lua` (supports `actor:*` and colon `npc:*` while preserving strict 3-segment `player:*`), `PNC_RelationshipTypes_Public.lua` (preserves portable `retentionClass`/`salience`/`consolidationKey`/`count`/`sourceMode`/`confidence`), `PNC_Persistence_CoreSocial.lua` (promotes generic `baselineApproval`, `baselineRespect`, `state`, `previousState`, `cooldowns`, `saturation`, `lastEvaluatedAt` to first-class Core relationship fields, merges `recentEventIDs`, preserves foreign deltas/memories), `PNC_RelationshipMath.lua` (delegates memory strength to Core lazy decay), and `PNC_RelationshipService_Context.lua` (refreshes stale Hoomans snapshots when Core revision advances).
- **H3 (Accepted):** Authored `tools/providers/pnc/codebuilder/sources/social_policy/` (`hoomans.social_policy`) and synchronized `PNC_SocialEventDefinitions.lua` from compiled `PNC/SocialPolicy/Registry.lua`.
- **H4 (Accepted):** Updated `PNC_RelationshipService_Queries.lua` (`QuerySemanticEvidence`) to surface both Hoomans and foreign Core SocialPolicy memories (with provenance/confidence/count) through Unified Semantic Evidence.
- **H5 (Accepted):** Verified MP server authority enforcement, replay idempotency, player `onlineID` reconnect alias migration (`MigrateAliases`), `DTAbstract -> DTHoomans -> DTAbstract` materialization/dematerialization social continuity (`PNC.Persistence.CoreSocial.SyncToCore`), and private `actor.social` omission in client projections via Core `tests/psychopatz_social_mp_continuity_matrix_smoke.lua` (`63/63` Core Lua suites passing) alongside `24/24` Hoomans tests.
- **H6 (Accepted):** Verified scale stress (`1,000` actors, `500` repeated same-pair events, anchor/short/long caps, observer/hearsay bounds, `365d` lazy decay, `RuntimeStore` 30KB chunking) via Core `tests/psychopatz_social_scale_stress_smoke.lua`, standalone convergence test resolution in `tests/pnc_portable_social_convergence_smoke.lua`, `48/48` scoped ProjectHoomans social/relationship/conduct/semantic-evidence suites passing (`0` failures), `pz_verify --kahlua` (`0` errors on all 7 modified Hoomans production Lua files), and CodeBuilder `reconcile.py --check` (`clean=true`). Full 1,070-test ProjectHoomans sweep reported `1,066/1,070` passing with `4` unrelated pre-existing dirty-work failures (`pnc_animation_scene_debug_routes_smoke`, `pnc_context_debug_smoke`, `pnc_population_director_smoke`, `pz_custom_translation_manager_smoke`).

## Immediate Next Chunk

Developer-side **H0–H6** and parent **P0–P9** accepted. Ready for user-driven live SP/MP smoke acceptance.

## Acceptance

Hoomans H0-H6 is participant completion only. Parent completion requires Core P0-P9 including DynamicTrading/DTAbstract adoption.
