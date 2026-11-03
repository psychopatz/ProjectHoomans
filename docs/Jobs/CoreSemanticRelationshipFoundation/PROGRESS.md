# Progress — Core Semantic & Relationship Foundation

**State:** IN PROGRESS — fifth production-path audit invalidated the P18-P19 READY FOR USER LIVE TEST closeout.

## Current repository snapshot at fifth audit

- `psychopatzCore`: `main @ c62262c`, 11 commits ahead of `origin/main`, clean.
- `DynamicTrading`: `main @ 89c349ce`, 11 commits ahead of `origin/main`, clean.
- `ProjectHoomans`: `main @ fc68c285`, 23 commits ahead of `origin/main`, clean.

Important Git-history correction: the former tracked `DTHoomans_Conversation.lua` semantic-hub working-tree edit is now committed in Dynamic Trading commit `be9e8e10`. It is not an outstanding local modification.

Recheck actual state before every write.

## Independently retained accepted work

- P8B shared-social integrity.
- P9 semantic pack lifecycle.
- P10 Hoomans semantic schema/gates.
- P14 production capability isolation.
- complete required DT parser coverage.
- bounded uncertainty and fact-backed WorldKnowledge route/news behavior.
- P16 authoritative issuance registry.
- **P18 accepted:** exact forged PNC mirror -> Core resolves first -> Hoomans validates second attack no longer bootstraps authority.
- P19 canonical travel policy, TalkService consumption and human-facing place-presentation seam.
- P19 happy-path PREPARING/OUTBOUND/VISITING/RETURNING_HOME/AT_HOME integration.
- production Hoomans community resolver independently resolves machine ID to `community.name` and suppresses unknown machine IDs.
- Dynamic Trading full runner: `43/43`.
- Hoomans broad runner: `982/987`, same five documented older baseline failures.
- changed Lua syntax and repository diff checks pass.

## Acceptance-invalidating finding 1 — FAILED-after-departure is wrong

Project Hoomans public excursion status normalizes timestamps to numeric `0`.

Current DTHoomans FAILED logic uses:

`payload.departedAt ~= nil and not payload.completedAt`.

Lua treats numeric `0` as truthy, so `not 0` is false.

Independent reproduction through the production handler:

Before FAILED:
- current settlement: nil/offsite;
- origin: `community_home_123`;
- destination: `community_dest_789`.

FAILED payload:
- `departedAt = 12`;
- `completedAt = 0`.

After current handler:
- current settlement incorrectly becomes `community_home_123`;
- destination is cleared;
- the state behaves like a failure before departure.

This is a real product defect and violates the P19 failure/cancelled lifecycle requirement.

## Acceptance-invalidating finding 2 — trader persistence proof reuses the same object

The current matrix and standalone semantic test store the trader record in a simulated storage table, clear one local variable, then retrieve that same table/object from the same backing storage.

WorldKnowledge does exercise its real `Save/Load` path, but trader-record reconstruction from persisted state is not proven.

P20 must reconstruct a fresh storage/runtime view from a snapshot/deep copy and assert the reloaded trader record is a distinct object while preserving canonical policy fields and dialogue behavior.

## Current phase

**P20 — Failure-state correctness and reconstructed persistence acceptance.**

### P20A — COMPLETE (accepted)

1. Rechecked repository states: Dynamic Trading clean at `89c349ce`, Core clean at `c62262c`, Hoomans clean at `aaa3e41d`.
2. Inspected Hoomans excursion public status normalization (`departedAt = excursion.departedAt`, `completedAt = excursion.completedAt`) and DTHoomans `OnExcursion` FAILED handling.
3. Replaced truthiness check `payload.departedAt ~= nil and not payload.completedAt` with numeric lifecycle semantics: `departedAt = tonumber(payload.departedAt) or 0`, `completedAt = tonumber(payload.completedAt) or 0`, `hasDeparted = departedAt > 0`, `hasCompleted = completedAt > 0`, `hasVisited = visitedAt > 0`, `isReturning = returnStartedAt > 0`.
4. Added production-handler regressions in `dt_m10d_resident_excursion_smoke.lua` covering:
   - Case 1: FAILED before departure (PREPARING -> FAILED) keeps trader at home, clears destination, keeps trader available (`STATUS_READY`).
   - Case 2: FAILED after departure (OUTBOUND -> FAILED with `departedAt > 0, completedAt = 0`) does NOT fabricate current settlement as home (stays `nil`), clears destination, keeps origin as home, sets availability to away. Also explicitly reproduced and verified the fifth-audit direct payload probe (`departedAt = 12, completedAt = 0`).
   - Case 3: FAILED while visiting (VISITING -> FAILED) retains last authoritative visited location as current settlement, clears destination, stays away.
   - Case 4: FAILED while returning home (RETURNING_HOME -> FAILED before completion) keeps current settlement `nil` (in transit, not home), retains visited community as origin, clears destination, stays away.
   - Case 5: Retry after FAILED (`Retry` -> `PREPARING`) resets origin and current to home, receives fresh destination, and verifies previous failed destination does not leak.
   - Case 6: Happy path regression (`PREPARING -> OUTBOUND -> VISITING -> RETURNING_HOME -> AT_HOME`) completes fully, restores home context and availability.
5. In ProjectHoomans `PNC_CommunityExcursionService.lua`, ensured `departedAt`, `visitedAt`, `returnStartedAt`, and `completedAt` are cleanly reset to 0 upon entering `PREPARING` for a new excursion.
6. Validation:
   - Dynamic Trading: `43/43` PASS.
   - Project Hoomans: `982/987` PASS (identical 5 known baseline failures preserved).
   - Changed Lua syntax verified with `luac5.3 -p`.
   - `git diff --check` passes cleanly.
   - Committed DT changes in `f61f0ac5`.

### Next Chunk — P20B (Reconstructed trader-record persistence acceptance)

1. Strengthen headless trader-record persistence proof.
2. In `dt_standalone_semantic_story_smoke.lua` and `pnc_real_cross_adopter_hotplug_matrix_smoke.lua`:
   - Establish trader state through production owners (home, current, origin, destination, route/news knowledge).
   - Obtain real DT storage representation.
   - Produce a persisted snapshot/deep copy representing Global ModData.
   - Tear down/reset TalkService sessions, local trader references, runtime cache, Core WorldKnowledge in-memory state.
   - Reconstruct fresh storage table from the persisted snapshot and reinitialize DT storage.
   - Retrieve reloaded trader record and assert `reloadedTrader ~= originalTrader` (distinct object identity) while canonical persisted fields match.
   - Call `WorldKnowledge.Load()` against reconstructed storage.
   - Re-open `TalkService` and verify: destination, origin, settlement, route, news queries.
   - Assert human names resolve, fact/evidence IDs survive, machine IDs do not leak, bounded uncertainty preserved.
   - Cover failed/offsite state reload (does not become falsely home) and completed AT_HOME state reload (stale destination does not reappear).

## Parent goal status

**IN PROGRESS.**

Do not return to READY FOR USER LIVE TEST until P20A-P20C pass.
