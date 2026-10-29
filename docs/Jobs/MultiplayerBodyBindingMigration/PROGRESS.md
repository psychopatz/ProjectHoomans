# Progress — Multiplayer Body Binding Migration

**Status:** PLANNED — implementation not started.
**Branch:** existing main only.
**Planning anchor:** 2a24bc59d36c845af51097642c55180434680cb7.
**Current phase:** M0 — restore/freeze SP baseline and engine-ground the MP identity contract.
**Parent objective:** M0-M8 complete migration to explicit MP body binding, with SP preserved and full developer-side acceptance.

## Verified starting evidence

- User reports the latest MP-oriented body changes regressed single-player while the multiplayer zombie-first/NPC-later symptom persists.
- Installed PZ 42.22 Java inspection shows an MP client can create a fresh local IsoZombie for an unknown vanilla zombie online ID; server Lua object/PNC ModData continuity cannot be assumed.
- Current Hoomans already projects liveBodyOnlineID and has Registry, Presence, BodyLifecycle, NetworkSnapshots and ClientPresenceSync seams suitable for a binding protocol.
- 5dbbadc4 added shared early preclaim behavior motivated by MP; this cannot by itself transport PNC identity through the vanilla zombie packet and is the first SP regression boundary to audit.
- Project A-Life independently demonstrates a viable logical actor + disposable IsoZombie shell + explicit onlineId/uid/generation client-reconciliation pattern.
- Current repository worktree was clean at planning time.

## Immediate Next Chunk — M0A

1. Recheck branch/HEAD/status and current native logs.
2. Characterize the SP regression around 5dbbadc4 with focused body factory/presence/restart tests.
3. Establish a pre-5dbbadc4 SP behavioral baseline from Git/code without discarding later unrelated changes.
4. Surgically restore/isolate SP local materialization semantics.
5. Add a regression proving SP body creation does not require MP binding/preclaim.
6. Add/extend a synthetic engine-boundary fixture documenting:
   - server body PNC ModData is not trusted as client replica identity;
   - MP identity must be reconstructed from onlineId + PNC binding.
7. Freeze current liveBodyOnlineID and runtime.bodyLease semantics for M1 audit.
8. Run focused body/presence/restart tests + Kahlua + git diff --check.
9. Update this file and continue automatically to M1.

## Remaining mandatory work

- M1 body-incarnation contract;
- M2 server binding authority;
- M3 client pending/reconciliation;
- M4 ClientPresenceSync migration;
- M5 lifecycle/husk simplification;
- M6 multi-client + movement/combat interoperability;
- M7 death/corpse/infection/reanimation;
- M8 cleanup/full acceptance.

## Current non-goals

- replacing IsoZombie with IsoSurvivor without a separately proven need;
- rewriting Registry/Presence/BodyLifecycle wholesale;
- role-specific companion-only MP binding;
- copying Project A-Life implementation;
- native-game automation;
- Workshop publication.

## Completion rule

Do not mark complete after M0, a working binding prototype, or a passing focused suite.

Developer completion requires all M0-M8 gates plus final full-suite/static/compiler evidence. Native SP/MP remains user-owned final acceptance.
