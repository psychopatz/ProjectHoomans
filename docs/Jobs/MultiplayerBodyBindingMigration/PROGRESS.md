# Progress — Multiplayer Body Binding Migration

**Status:** M10 restart-shell recovery implemented and developer-validated; renewed native SP/MP restart acceptance pending.
**Branch:** existing main only.
**Planning anchor:** 2a24bc59d36c845af51097642c55180434680cb7.
**Current phase:** Native restart-shell acceptance handoff.
**Parent objective:** M0-M9 complete migration to explicit MP body binding plus pre-virtualization live-human carrier retirement, with SP preserved; native husk convergence remains to be verified by the user.

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

- M0-M8 are implemented historical prerequisites and remain regression constraints.
- M0-M9 developer work is implemented and validated. M9 selected the engine-proven pre-virtualization retirement path rather than an unsupported detached-shell bridge.
- **Only renewed native SP/MP acceptance remains mandatory.** Persistent old shells after abstraction/rematerialization, chunk streaming, restart or reconnect are still a hard failure and reopen the owning lifecycle gate.

## Current non-goals

- replacing IsoZombie with IsoSurvivor without a separately proven need;
- rewriting Registry/Presence/BodyLifecycle wholesale;
- role-specific companion-only MP binding;
- copying Project A-Life implementation;
- native-game automation;
- Workshop publication.

## Completion rule

Do not mark complete after M0, a working binding prototype, or a passing focused suite.

Developer completion requires all M0-M9 gates plus final full-suite/static/compiler evidence. That developer gate is now met by commit `e1a90335`; parent acceptance still requires renewed native SP/MP proof.

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

## M8 audit corrections — lease and unbind ordering

- Audit found two incarnation gaps: old physical shell receipts could be reused after another shell became canonical, and optional Core provider projection could overwrite an active MP bodyLease. Weak active-record/shell receipts now require intact local identity; provider ownership is projected separately as coreProviderLease on MP. SP provider behavior remains unchanged. Added regression for earlier/recycled object receipts and provider projection preserving physical lease.
- Audit found unbind-before-remove could discard the only exact local shell reference. Repeated server unbind publications now preserve the exact predecessor; clients retire only that matching predecessor. Old-incarnation unbind cannot release a different current incarnation. A missing/detached LIVE shell during Presence grace publishes no premature unbind. Ordering regressions pass.
- Deprecated the obsolete roster online-ID identity index to an empty compatibility hook, eliminating its redundant roster scan and false early-admission comment. Canonical binding is the only client managed-body admission. True-zombie reanimation also clears PNC_MPBound.
- Added fixed-size server/client diagnostic counters and last-reason views without per-tick logging, per-NPC persistent telemetry or new persistence roots.
- Full isolated Lua: 968/968 (6.85s). Focused binding/provider/network/client: 22/22. All 6 changed runtime files pass installed-PZ Kahlua compilation. git diff --check clean. Current graph metadata remains stale/untracked for these paths; direct source is evidence.
- **Outstanding before developer completion:** final classification of retained carrier/outfit/population startup adoption/cleanup against identity invariants; complete gameplay consumer/interest-exit audit; evidence matrix and static budget/persistence checks; final all-changed-runtime compiler/static verification and clean-worktree full-suite acceptance. A green suite does not close these audit gaps. Continue automatically.

## M8 final developer acceptance — 2026-10-30

- Closed remaining outfit+position actor-attribution and arbitrary-outfit cleanup paths. Startup actor adoption now requires UUID or exact population identity; positively learned PNC carriers remain disposable-orphan cleanup evidence, not actor identity. Updated fixtures distinguish strong provenance from ordinary outfit coincidence.
- Interest exit/record removal now releases local cache immediately without deleting a live server shell. Old proof cannot rebind; fresh interest-enter proof restores presentation. Full post-bind ownership/cache tags clear only for an exact owned receipt.
- MP player-hit reports must match the current runtime lease, shell lease and online ID; online-ID-only reports fail closed. Valid MP reports retain damage behavior.
- Added behavioral 10,000-input cache stress, TTL drain, no-scan/no-new-ModData source checks, A-Life dependency guard and actual descriptor payload estimation.
- Final source validation: 969/969 full Lua tests (6.81s); 220/220 complete focused body/presence/husk/restart/replica/network/player-damage/movement/combat/infection/corpse/reanimation/follow set. All 25 runtime files changed since e3614241 compile under installed-PZ Kahlua and pass static Kahlua ERROR checks. git diff --check clean.
- Requirement-by-requirement developer evidence is in DEVELOPER_ACCEPTANCE.md; roadmap status updated. Remaining work is the user-owned native checklist, including real visual precursor, multiplayer streaming and death/reanimation behavior. No native game was launched or Workshop content published.
- Anonymous historical saves remain fail-closed: position/outfit/gender/ownership alone cannot safely reclaim an old shell. Current identifiable shells retain lifecycle/lease/population evidence.
- Next mandatory action belongs to native user acceptance. Any contradictory native result reopens its corresponding implementation gate. No further developer implementation gap is known after this audit.


## Native acceptance failure — 2026-10-30

User-owned testing reproduced the persistent NPC husk on both single-player and multiplayer after the M0-M8 developer handoff. This reopens the parent goal.

### Verified engine/lifecycle evidence

Installed Project Zomboid 42.22 Java inspection establishes:

- `LuaManager.addZombiesInOutfit(...)` delegates to `VirtualZombieManager.createRealZombieAlways(...)`.
- `VirtualZombieManager.createRealZombieAlways(...)` constructs/adopts an `IsoZombie`, adds it to live zombie collections, assigns an MP online ID on server, and then calls `ZombiePopulationManager.registerZombie(...)`.
- That registration gives the shell a non-zero native `persistentId` and registers it in PopMan's real-zombie map.
- `IsoZombie.removeFromWorld()` calls `ZombiePopulationManager.releaseZombie(zombie)` before clearing server online identity/world membership.
- PZ's normal chunk virtualization path writes native zombie population data and then uses the same `removeFromWorld()/removeFromSquare()` lifecycle.
- `ZombiePopulationManager.INVALID_PERSISTENT_ID` is `0`; `releaseZombie()` is a no-op when `persistentId == 0`.
- `IsoZombie` is Lua-exposed and has a public `IsoZombie(IsoCell)` constructor, so a transient, non-PopMan carrier is technically plausible but must be proven against world/network admission requirements before production adoption.

Native server logs also showed the same logical NPC IDs materializing again at a distant location with new shell carrier IDs while the former physical husks persisted. This is consistent with logical Presence movement succeeding while the old PopMan-owned carrier survives outside PNC authority.

### Revised root cause

M0-M8 solved cross-network identity/reconciliation but left the physical carrier born through a native population-zombie factory. The shell therefore participates in a lifecycle PNC does not own. A client binding/unbind fix cannot prevent a native population record from later resurfacing as an ordinary zombie, and the SP reproduction proves the defect is below the MP binding layer.

### Initial M9 hypothesis — superseded by later engine evidence

The following was the first post-native-failure hypothesis and is retained only as audit history. The later M9A-M9C checkpoint disproved `persistentId == 0` as sufficient and selected pre-virtualization retirement instead.

1. Build a focused engine-grounded transient-shell prototype/fixture using `IsoZombie.new(getCell())` or the smallest equivalent PNC-owned factory.
2. Reproduce only the required vanilla admission steps for a live shell while deliberately omitting `ZombiePopulationManager.registerZombie()`.
3. Prove the live PNC human invariant `persistentId == 0` in SP and on MP server.
4. Verify MP online-ID allocation/map membership and vanilla replication still function for an unregistered shell; if pure Lua cannot safely establish that contract, introduce the smallest justified bridge rather than falling back to PopMan ownership.
5. Change normal live-human materialization/removal to the proven transient path while preserving M1-M8 incarnation binding.
6. Keep true Knox reanimation on the genuine vanilla zombie lifecycle.
7. Retain HuskLedger/Reaper only as bounded legacy-save migration for previously registered shells; do not add anonymous positional reclamation.
8. Add old-save migration evidence and an explicit diagnostic for any managed live human with `persistentId ~= 0`.
9. Re-run focused/full Lua, installed-PZ compiler/static verification, and then hand back a revised native SP/MP matrix.

**Historical next chunk (superseded):** M9A transient shell construction/admission proof. Later engine evidence selected the pre-virtualization retirement design documented below.


## M9A-M9C pre-virtualization retirement implementation — 2026-10-30

Native/Java audit refined the original population-detached-shell hypothesis before a production factory swap:

- A manually constructed `IsoZombie` with `persistentId == 0` is **not sufficient** by itself. Installed 42.22 `ZombiePopulationManager.removeChunkFromWorld(IsoChunk)` serializes every ground-level `IsoZombie` in an unloading chunk through native `n_addZombie(...)` before removing it, regardless of the Java-side persistent ID. `IsoMovingObject` also calls `virtualizeZombie()` for pathing/walk-toward zombies that leave loaded world space.
- No Lua pre-chunk-unload event exists before that native population serialization. `ReuseGridsquare` is too late.
- Pure Lua cannot safely build a fully detached MP carrier because `ServerMap`/its zombie map and `NetworkZombiePacker` are not Lua-exposed. Adding a javaagent/launcher dependency would be a larger unsupported deployment change and is not justified while the lifecycle can be closed in Lua.
- Native `libPZPopMan64.so` disassembly distinguishes `n_registerZombie`, `n_addZombie` and `n_releaseZombie` as separate queues. The dangerous virtual-population handoff is `n_addZombie`; proactive PNC `removeFromWorld()` follows the release queue without first issuing `n_addZombie`.

### Implemented engine-proven equivalent

Rather than letting a managed shell reach native virtualization, Presence now owns a hard physical-carrier safety envelope:

- `forceLive` is an embodiment preference only inside `MATERIALIZE_DISTANCE`; it cannot materialize an `IsoZombie` with no nearby player or outside the player-owned live radius.
- `ShouldAbstract` applies a hard envelope **before** force-live and combat-target exceptions. A stale target or follow state cannot hold a physical shell beyond all players.
- `LIVE_BODY_RETIRE_DISTANCE = 40` preserves the existing materialize/abstract hysteresis while staying inside the MP server's minimum 12-chunk loaded grid.
- Local SP/splitscreen additionally checks the actual `IsoChunkMap` tile bounds and retires one chunk (8 tiles) before the edge, covering small/debug chunk maps where a fixed distance alone could be unsafe.
- `RetireUnsafeLiveBodies` performs a 100ms bounded sweep over `Registry.LiveByID` only (already capped by live-body admission). It does not scan world zombies.
- `Server.ProcessRecord` also applies the same cheap fence before behavior/pathing so a due moving follower cannot issue another native route after it crosses the retirement boundary.
- Successful attached-body retirement uses the existing exact lease/body removal path. It does not arm the husk ledger; the ledger/reaper remains only for already-lost/legacy shells.

This specifically closes the native log sequence where a companion remained embodied hundreds of tiles behind the owner, PZ virtualized the old carrier, and PNC later rematerialized the same logical NPC with a new shell.

### Developer evidence

- New `pnc_presence_live_body_envelope_smoke.lua` covers force-live materialization bounds, no-player retirement, combat-target override ordering, small local chunk-map safety, global live-body sweep cadence, and pre-behavior/path server retirement.
- Existing follow-combat regression now requires far stale/combat targets to yield to the hard carrier envelope while preserving near-player protection.
- Existing husk E2E keeps its body-loss grace case inside the live envelope; far/no-player shells are now expected to be proactively retired instead of waiting for loss recovery.
- Focused presence/husk/follow/travel/body-loss suite: **152/152**.
- Full isolated Lua suite: **970/970**.
- Broad body/presence/husk/restart/replica/network/player-damage/movement/combat/infection/corpse/reanimation/follow suite: **221/221**.
- Installed Project Zomboid Kahlua compiler: **5/5 changed runtime Lua files pass**.
- `git diff --check`: clean at this checkpoint.

### Remaining M9 work

- run static Kahlua/error and source-performance guards;
- re-audit death/reanimation and legacy cleanup against the preventive lifecycle (no expected authority change);
- update ROADMAP/ARCHITECTURE acceptance language from the disproven “persistentId zero alone” hypothesis to the engine-proven pre-virtualization retirement equivalent;
- commit coherent implementation/docs;
- hand back the revised native SP/MP matrix. Native confirmation remains mandatory and must test repeated abstraction/rematerialization plus old-location return.


## M9F developer acceptance — 2026-10-30

- Implementation committed as `e1a90335 fix: retire npc shells before native virtualization`.
- Engine audit established the production boundary: managed shells became husks when PZ reached native `n_addZombie` virtualization during chunk/out-of-loaded-area handling; proactive attached-body PNC removal uses the distinct release path.
- The proposed `persistentId == 0` detached-shell design was rejected after proving chunk unload can still virtualize any IsoZombie and pure Lua cannot safely complete detached MP ServerMap/packer admission.
- Presence now enforces a hard loaded-space carrier envelope before force-live/combat exceptions, plus a 100ms sweep over the capped live-body registry and a per-record pre-behavior/path fence.
- SP/splitscreen additionally retires one chunk inside actual local IsoChunkMap bounds; MP uses the conservative 40-tile fence within the minimum server loaded range.
- Temporary engine-removal failure now fails closed for AI/pathing: the body remains registered for cleanup retry but is not passed to behavior on that tick.
- Successful attached retirement is confirmed not to arm HuskLedger; reaping remains fallback/legacy recovery.
- Traversal handoff was split into its own module to keep Presence decision files under the project token threshold.
- Final validation: **970/970 full Lua**, **221/221 broad lifecycle/network/combat/death**, **152/152 focused presence/husk/follow/travel/body-loss**, **7/7 installed-PZ Kahlua compile**, **7/7 pz_verify Kahlua ERROR clean**, `git diff --check` clean.
- No native Project Zomboid game was launched and no Workshop content was published.

**Remaining mandatory action:** renewed user-owned native SP and MP acceptance. Repeated abstraction/rematerialization, old-location return, chunk unload/reload, reconnect/relog and restart must show no persistent former NPC shell. Any native husk reproduction reopens M9 despite the green developer suite.


## M10 native restart failure and developer repair — 2026-10-30

Native evidence from /home/psychopatz/Zomboid/Logs/2026-10-30_09-42_DebugLog.txt reopened the restart gate after M9:
- 09:44:18 startup fallback count=10; cleanup removed=0 ordinaryUnknown=6 blockedRecords=5;
- 09:44:22 HuskReaper active with ledgerEntries=48 but unable to prove-match the anonymous restored shells;
- 09:46:24 second startup again completed with removed=0 ordinaryUnknown=4 blockedRecords=4;
- 09:46:38 Carey Carrington was freshly materialized, proving replacement spawn still occurred while the prior anonymous carrier remained unmanaged.

Repository history identified the direct regression: df315d65 had replaced anonymousRehydrateMatch with an unconditional false result, disabling the bounded settle/rebind lane added by 75983f6c.

M10 repairs this without restoring unsafe positional deletion:
- current-save anonymous recovery requires startupRehydrateExpected, bodyHint.wasLive, a saved lease, a saved nonzero engine identity, tight saved position, sex match when available, and the real-frame settle window;
- it is role-agnostic, but anonymous evidence is adoption-only;
- competing anonymous bodies or anonymous plus proven competition is ambiguous and deletes nothing;
- startup keeps the gate open and quarantines the shell until rebind succeeds or remains blocked;
- successful rebind emits PNC startup_rehydrate_rebound npc=<id> reason=<proof> anonymous=<bool>;
- a lifecycle-only live-shell token provides exact identity when the engine preserves object inventory, is excluded from logical inventory, and is stripped before corpse conversion;
- local/SP OnSave retires live carriers before the PNC persistence commit so the subsequent world/PopMan save cannot serialize a live PNC shell;
- dedicated/MP startup reclaim remains mandatory because installed 42.22 server save code snapshots registered real zombies through updateRealZombies plus native n_save and exposes no safe Lua pre-save detach/re-admit seam.

Implementation commit: ada48d24 fix: reclaim anonymous npc shells on restart.

Final developer evidence: 972/972 full, 231/231 broad, 163/163 focused restart/persistence, 14/14 installed-PZ compile, 14/14 static Kahlua ERROR clean, git diff --check clean.

Remaining mandatory action: native SP and MP restart/relog testing. The decisive next-log success signal is PNC startup_rehydrate_rebound before any spawnPrimary for the same NPC. Any ordinaryUnknown/blockedRecords followed by replacement materialization without a rebound reopens M10.
