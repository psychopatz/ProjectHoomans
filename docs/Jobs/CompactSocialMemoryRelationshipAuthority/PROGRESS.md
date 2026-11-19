# Progress — Project Hoomans Portable Social State Adoption

**Status:** IN PROGRESS participant work.
**Parent:** PsychopatzCore Docs/portable_social_state/.
**Current participant phase:** H5 accepted (`P7`); advancing to H6 (`P9` scale and final acceptance).
**Participant completion:** 6/7 phases accepted (H0, H1, H2, H3, H4, H5).

## Verified progress

- **H0 (Accepted):** Full H0 inventory recorded in `AUDIT.md`; baseline smoke suites green.
- **H1/H2 (Accepted):** Reconciled `PNC_EntityRef.lua` (supports `actor:*` and colon `npc:*` while preserving strict 3-segment `player:*`), `PNC_RelationshipTypes_Public.lua` (preserves portable `retentionClass`/`salience`/`consolidationKey`/`count`/`sourceMode`/`confidence`), `PNC_Persistence_CoreSocial.lua` (promotes generic `baselineApproval`, `baselineRespect`, `state`, `previousState`, `cooldowns`, `saturation`, `lastEvaluatedAt` to first-class Core relationship fields, merges `recentEventIDs`, preserves foreign deltas/memories), `PNC_RelationshipMath.lua` (delegates memory strength to Core lazy decay), and `PNC_RelationshipService_Context.lua` (refreshes stale Hoomans snapshots when Core revision advances).
- **H3 (Accepted):** Authored `tools/providers/pnc/codebuilder/sources/social_policy/` (`hoomans.social_policy`) and synchronized `PNC_SocialEventDefinitions.lua` from compiled `PNC/SocialPolicy/Registry.lua`.
- **H4 (Accepted):** Updated `PNC_RelationshipService_Queries.lua` (`QuerySemanticEvidence`) to surface both Hoomans and foreign Core SocialPolicy memories (with provenance/confidence/count) through Unified Semantic Evidence.
- **H5 (Accepted):** Verified MP server authority enforcement, replay idempotency, player `onlineID` reconnect alias migration (`MigrateAliases`), `DTAbstract -> DTHoomans -> DTAbstract` materialization/dematerialization social continuity (`PNC.Persistence.CoreSocial.SyncToCore`), and private `actor.social` omission in client projections via Core `tests/psychopatz_social_mp_continuity_matrix_smoke.lua` (`63/63` Core Lua suites passing) alongside `24/24` Hoomans tests.

## Immediate Next Chunk

Execute **H6** (`P9` scale stress, determinism verification, and final participant acceptance).

## Acceptance

Hoomans H0-H6 is participant completion only. Parent completion requires Core P0-P9 including DynamicTrading/DTAbstract adoption.
