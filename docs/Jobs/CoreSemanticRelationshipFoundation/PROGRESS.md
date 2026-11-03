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

### Next Chunk — P20A

1. recheck all three repository states;
2. inspect Hoomans excursion public payload normalization and DTHoomans FAILED handling;
3. replace truthiness-based timestamp checks with numeric lifecycle comparisons;
4. add focused regressions for:
   - failure before departure;
   - failure after departure with `completedAt = 0`;
   - failure while visiting/returning;
   - retry/new PREPARING after failure;
5. preserve the accepted happy-path travel behavior;
6. run DT focused/full tests and affected Hoomans integration tests;
7. update PROGRESS and commit coherent changes;
8. continue automatically to P20B reconstructed-persistence acceptance.

P20A gate: FAILED/cancelled travel never fabricates an incorrect home/current state.

## Parent goal status

**IN PROGRESS.**

Do not return to READY FOR USER LIVE TEST until P20A-P20C pass.
