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

## M2 server descriptor checkpoint

- Added canonical shared `PNC_MultiplayerBodyBinding` seam. Server descriptors validate current Registry shell, live Presence/alive state, matching UUID/bodyKind/bodyLease, attachment where exposed, and signed-short nonnegative integer online ID. Client/server object identity is never inferred from position/outfit.
- Binding descriptors carry protocol/session/publication revision, npcId/incarnation/onlineId, bind/unbind operation and exact predecessor when replaced/invalidated. A weak record-keyed receipt cache is transient, not persisted; publication revision orders transport updates and is not a second incarnation token.
- Detailed and presence/combat payloads include the descriptor through existing interested-client routing. Global roster summaries remain unchanged. SP Build returns nil.
- Server regression covers valid/idempotent binding, replacement predecessor, invalid online IDs, mismatched UUID, death/abstract rejection, shell loss/unbind and SP separation. Network-scale fixture now provides Core.GenerateID for session issuance.
- Full isolated Lua suite: 965/965. Installed PZ Kahlua compiler: all three changed/new runtime files pass. git diff --check clean.
- Next mandatory chunk: M3 client bounded reconciliation; M4 consumer routing. M2 exact explicit removal delivery and full lifecycle publication remain integration work under M5/M7, not accepted yet.

## M3 bounded client reconciler checkpoint

- Added client half of the canonical seam (`NewClient`) with message-first/replica-first reconciliation, immutable tuple copies, publication/session freshness validation, idempotent duplicate handling, exact online-ID ownership conflict rejection, weak body references, capped actor/observed entries, TTL expiration, scalar retirement watermark, and explicit reset.
- Reused online ID on a different observed engine object clears local presentation via callback and requires a fresh authoritative publication before rebinding. No engine deletion, Registry mutation, persistence, or full-world scan exists in this module.
- Revised server publication semantics: every Build emits a fresh session revision while retaining the same incarnation for the same shell. This is required to recover safely after client TTL expiration without replaying old proof; duplicate delivered messages remain idempotent.
- Client tests cover both arrival orders, duplicate presentation count, replacement release, stale/reordered packets, conflicting identity, ID recycling, reaffirmation, pending TTL, expired replay, session locking/reset, unbind and capacity.
- Focused MP body/network/presence/replica: 130/130. Full suite: 966/966. Installed-PZ Kahlua compilation: both changed/new runtime files pass. Static Kahlua ERROR scan: zero. git diff --check clean.
- Read-only A-Life comparison inspected ShellAdapter identity stamps, Watchdog identity validation, AIFence death/generation handling, Animations explicit onlineId+UID+generation publication, AnimationClient bounded pending/weak observations, Executor shell identity/death handling. Reference graph is stale; direct bounded source excerpts used. No reference code was edited/copied/imported.
- New migration files are not tracked by the graph generation; implementation/source tests are direct evidence, not graph completeness.
- **Next mandatory chunk: M4 runtime integration.** The new client reconciler is deliberately not wired yet. Route accepted snapshot ingestion, OnZombieUpdate observation, session reset and ClientPresenceSync resolution through it; remove MP UUID/outfit fallback paths. Then finish M5–M8. The migration is not operationally complete.

## M4 runtime integration checkpoint

- Accepted network snapshots now feed the canonical reconciler after existing stale-snapshot rejection. Client zombie-update observation supplies exact online IDs, and connection disconnect/game-start/Lua-reset hooks clear transient binding state. Installed 42.22 LuaEventManager declares OnDisconnect; baseline freshness checked, no game launched.
- ClientPresenceSync resolves MP bodies only through validated current binding. Its MP refresh now performs only a 250ms-gated bounded reconciler sweep; SP retains local indexes/scanning. Remote presentation cannot fall through to UUID/outfit/online-ID indexes when binding is absent. Per-zombie clothing/bandage maintenance is also binding-gated.
- Core.IsManagedNPCBody now requires canonical client binding on pure clients. Raw client ModData, saved animation variables and roster online-ID hints no longer classify an unbound replica as a managed NPC. SP/server classification remains unchanged.
- Post-bind cache stamping updates compatibility indexes. Exact-cache unbind clears owned identity/PNC animation flags and requests native movement release. Registry remains untouched.
- Removed unsafe MP legacy cleanup admission: anonymous online-ID removal and UUID-census duplicate pruning now fail closed. Exact incarnation-based removal delivery is mandatory next (M5); these checks are not a substitute for implementing it.
- Updated cleanup regression to exercise actual accepted snapshot ingestion -> binding -> public body resolver, pre-bind rejection, stale snapshot rejection, no MP census, legacy removal rejection, connection reset and movement release. Updated budget fixture to provide canonical resolver; Core regression proves hints fail closed.
- Full suite: 966/966 (8.28s), focused integration set: 10/10 after final resolver online-ID guard. Installed-PZ Kahlua compiler: all 7 changed/new runtime files pass. git diff --check clean.
- Next mandatory chunk: M5 server lifecycle exact bind/unbind/remove delivery, replacement/stream loss handling and husk migration; then M6 multi-client/combat/movement, M7 death/infection, M8 final audit. Initial M4 routing passes developer regressions; complete migration acceptance remains outstanding.

## M5 exact removal transport checkpoint

- Canonical Binding.Removal now issues session/revision proof for an explicit npcId/incarnation/onlineId tuple. Legacy packets lacking a lease fail closed on MP servers. Removal uses existing RemoveBody command and current interested clients, replacing the previous unconditional all-player broadcast.
- Normal verified MP BodyLifecycle removal captures shell online ID and lease before engine mutation, publishes exact retirement only after verified removal, then detaches as before. Failed removal retains the lease and emits no retirement. SP does not enter this new publication path.
- Startup and husk removals pass only the removed body's own explicit lease where it is still present; they do not substitute a current NPC lease for an anonymous historical shell. Such shells cannot authorize a client deletion from an online ID/outfit hint.
- Client remove validates session/revision plus the exact currently bound incarnation and online ID; later removal of an old incarnation cannot retire a newer bound shell. Valid removal and authoritative replacement may remove only the previously bound, still-valid local shell. Unknown removals retain a bounded tombstone but cannot delete an unbound engine object.
- Added regressions for legacy refusal, interested-client routing, exact removal, old-incarnation removal with a later publication, duplicate idempotence, stale live resurrection rejection, failed lifecycle removal and capture-before-engine-mutation.
- Focused MP/body/network/husk/startup/restored/replica: 18/18. Full suite: 966/966 (8.19s); final expanded focused fixture also passes. Installed-PZ compiler: all 8 changed runtime files pass. git diff --check clean.
- Existing graph BroadcastBodyRemoval node is stale and bare-name trace fails; current source and literal callsite reads used. No exhaustive graph claim.
- Next mandatory chunk: complete M5 streaming/replacement and legacy heuristic classification/static cleanup, then M6 multi-client roles/combat/movement, M7 corpse/infection exact invalidation, M8 full acceptance. Corpse conversion removal still needs pre-conversion lease capture in M7. No native acceptance is claimed.

## M5 anonymous-identity safety audit

- Removed the zero-ID ledger exception which used saved position, companion ownership and gender to identify/delete a zombie. Closed anonymous startup rehydration which used the same non-identity evidence to adopt a vanilla zombie. Rules now apply equally to companions, neutral NPCs and vehicle reservations.
- This intentionally supersedes unsafe historical-save recovery expectations: a genuinely anonymous old shell cannot be distinguished from an ordinary zombie and is preserved. Local SP constructor/stamping semantics remain intact; this safety correction does not introduce an MP dependency into SP. Native acceptance must distinguish identifiable current shells from unrecoverable anonymous historical saves.
- Updated legacy/restart tests to require protection of zero-ID coincident zombies before/after settle and while companions are canonical. Identifiable restart/population/carrier lanes remain tested separately.
- Full Lua: 966/966 (8.22s). Changed runtime sources compile under installed-PZ Kahlua. git diff --check clean.
- Remaining M5 audit: population/carrier legacy lanes and complete same-session/multi-client convergence. Next implement M6 client-isolation fixture and M7 pre-conversion death retirement; M8 must audit all retained heuristic paths, budgets and persistence before completion.

## M6 multi-client identity fixture checkpoint

- Added a three-client fixture using real server descriptor construction and independent canonical reconciler instances. Covers message-first A, replica-first B, late-interest C, local reconnect without server respawn, client isolation, simulation-owner/movement changes, replacement convergence and stale-incarnation rejection. Repeats the same protocol for companion, neutral, raider and faction roles.
- Focused MP body/replica/streaming/follow/player-damage/combat-target selection: 33/33. This proves protocol/client isolation, not native movement or combat execution; existing focused movement/combat regressions remain part of final acceptance.
- No runtime source changed in this chunk, so no additional changed-runtime compiler invocation is required. git diff --check passes.
- Next mandatory work: M7 pre-conversion corpse lease capture and death/reanimation stale-proof matrix; then complete retained M5 heuristic audit and M8 requirement-by-requirement full acceptance. Parent remains active.

## M7 death-binding integration checkpoint

- Corpse conversion now captures the source shell lease before engine conversion clears/copies ModData and before detach invalidates the runtime lease. The existing-corpse reuse branch also retires the exact source incarnation. Existing corpse inventory/clothing/announcement authority remains unchanged.
- Corpse clothing regression now clears the source lease inside the synthetic engine constructor and requires the removal publication to retain the original lease.
- Added infected/noninfected protocol death matrix using actual server descriptors: death unbind, stale live rejection after corpse/reanimation, late joining client, exact removal and reset/reconstruction from authoritative dead state. This is synthetic identity evidence; actual native corpse/reanimation remains user-owned.
- Focused corpse/death/reanimation/infection/binding: 26/26. Full suite before the final new matrix: 967/967 (8.27s). Installed-PZ Kahlua compilation of changed corpse runtime passes. git diff --check clean.
- Next mandatory chunk: M8 completion audit of every M0–M8 requirement, including retained M5 carrier/population heuristics, connection/interest loss, combat and movement source consumers, diagnostics, static budgets/persistence, complete acceptance matrix and final full isolated suite/compiler checks. Do not mark complete until the audit closes all developer-side gaps.
