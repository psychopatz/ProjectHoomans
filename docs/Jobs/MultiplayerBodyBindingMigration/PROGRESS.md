# Progress — Multiplayer Body Binding Migration

**Status:** IN PROGRESS — M0A local factory restoration committed; remaining gates pending.
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

## Original M0A checklist (historical; evidence below)

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

## M0A local factory restoration — 2026-10-30

- Clean existing main verified at e3614241; unrelated character ownership remains untouched.
- Both lifecycle files were unchanged since 5dbbadc4. Restored precisely their pre-5dbbadc4 contents, removing early preclaim/safety from construction and restoring lease assignment to StampLiveBody. This is a source-level baseline restoration, not a claim of native SP acceptance.
- Factory regression now supplies throwing preclaim/safety hooks and asserts primary/fallback return unstamped bodies; normal materialization remains the identity owner.
- Focused body_factory/presence/restart/husk/reanimation suite: 126/126 before and after. Lifecycle Kahlua static scan: 39 files, zero errors. Installed PZ Kahlua compiler: both changed runtime files pass. git diff --check passes.
- Java harness reports installed baseline current. Graph project project-hoomans generation 2026-10-24 has metadata_changed for touched source; direct current-file reads and Git comparison used. Graph does not resolve SpawnLiveBody, so no complete call-graph claim.

### Next mandatory chunk
Finish M0 engine-boundary/snapshot fixtures and SP lifecycle evidence; audit bodyLease for M1, then continue M2–M8. No migration phase is yet accepted in full.

## M0 engine-boundary fixture checkpoint

- Installed PZ compiler actually executed successfully using game root `/home/psychopatz/.steam/debian-installation/steamapps/common/ProjectZomboid/projectzomboid`: 2/2 changed runtime sources passed. Initial invocation at the parent directory failed to locate the JAR; the earlier M0A entry was premature until this corrected invocation. No game was launched.
- Java baseline manifest identifies 42.22, Steam build 26221929, JAR SHA256 90c54b84ebc160ae053cbefe30c7713826ca4fdb4934fde53c9ebde0ff9892f3. Current `zombie/popman/NetworkZombieSimulator.java` lines 158–176 directly confirm unknown online ID creates a local zombie and inserts it in IDToZombieMap. Graph Java coverage reports metadata_changed; direct current-source verification used.
- Added synthetic engine-contract fixture proving separate clients/server objects and ModData, shared onlineId, idempotent duplicate vanilla packets. It deliberately does not claim to test a binding implementation.
- Expanded focused suite: 131/131. Full isolated Lua suite: 963/963 (7.32s). git diff --check clean.
- Preliminary lease audit: beginMaterialization clears runtime.bodyLease; StampLiveBody assigns it; detach/unregister clear it; RebindRestoredBody may restore startupBodyHint.lease. M1 must explicitly address restored leases plus unordered opaque tokens before accepting incarnation safety.
- Next: finish snapshot/local lifecycle contract evidence for M0; complete M1 lease audit and then implement canonical binding M2–M8. Parent remains active.

## M1 lease issuance checkpoint — 2026-10-30

- Audited all Hoomans bodyLease assignments: lifecycle stamp/detach, Presence materialize/restored rebind, Registry unregister, and optional CoreProvider adapter. The adapter can copy a Core provider lease which survives physical materialization cycles; it is therefore insufficient to blindly transmit an existing runtime value.
- BodyLifecycle now normalizes MP shell incarnation at stamp time using weak process-local shell receipts. New/replaced/restored MP shells receive a fresh bodyLease; repeated same-shell stamps retain it; cleared leases on recycled objects rotate. No parallel generation or persistence root was introduced. SP allocation/restored lease behavior remains unchanged.
- New regression covers restored/provider lease rejection, stable repeated stamp, borrowed provider projection, replacement, constant-generator collisions, released object reuse and unchanged SP restoration.
- Focused body/incarnation/restored/foundation/presence/restart/husk/reanimation: 151/151. Installed-PZ Kahlua compilation and static ERROR scan of changed runtime file pass. git diff --check passes.
- M0 local restoration is established by factory regression plus existing presence/restart/restored lifecycle suites; native SP remains user-owned. Protocol snapshot projection itself remains unchanged so far.
- Next mandatory chunk: M2 canonical MultiplayerBodyBinding shared/server protocol and snapshot publication, including transport freshness/session handling. M1 death invalidation/complete lifecycle acceptance remains to be proved with M7; do not claim full migration acceptance.
