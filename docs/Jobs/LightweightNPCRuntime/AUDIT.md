# Runtime Audit — 2026-11-20

## Evidence status

This audit combines live runtime evidence from the user's new save with exact current source inspection. Runtime timing values collected while PsychopatzProfiler `performance` capture was enabled are **diagnostic**, not a clean normal-play benchmark, because the capture installs deep function wrappers on hot paths.

Observed repository checkpoints at documentation time:

- ProjectHoomans `main`: `8dfa86e16a16bace054dbb02ff72a56a3b51d706`
- psychopatzCore `main`: `57f09b7043f071193c0c4fbf397af528ea93e826`

Re-verify branch/HEAD/worktree before implementation; these hashes are evidence, not permanent assumptions.

## Live new-save observations

Approximate captured state:

| Metric | Observation |
| --- | ---: |
| Core/Hoomans NPC records | 32 |
| live Hoomans bodies | 6 |
| loaded ordinary zombies | about 63-66 |
| players | 1 |
| average FPS during profiled capture | about 18 |
| `ProjectHoomans.Server.Update` average | about 32.3 ms |
| `ProjectHoomans.Server.Update` peak | 602 ms |
| dirty Hoomans NPC records | 32 |

Selected profiler counts during the capture:

| Marker | Calls | Diagnostic note |
| --- | ---: | --- |
| `Server.Update` | 726 | deeply instrumented |
| `NPC.FollowOwner.Tick` | 786 | self cost contaminated by wrapper overhead |
| `NPC.Stamina` | 641 | remeasure after profiler OFF |
| `Network.Snapshot.Full` | 200 | real structural concern |
| `Network.Snapshot.PresenceDelta` | 1,524 | expected high-frequency lightweight path |
| `NPC.Decision` | 1,729 | remeasure after profiler OFF |
| `NPC.Materialize` | 33 | investigate promotion/materialization churn |
| `Persistence.NPCRecords` | 27 | real retry/commit concern |

Project Hoomans exposed 106 profiler timer metrics and approximately 78,173 wrapped timer calls in the snapshot. The shared profiler wrapper performs clock reads, bookkeeping, stack operations, and protected invocation around wrapped functions. Normal-play performance conclusions must therefore use an OFF-mode control run.

## Finding A — eager Core actor hydration defeats compact abstraction

`PNC_Server_Lifecycle.OnServerStarted()` calls `PNC.Persistence.CoreProvider.HydrateCoreActors(PsychopatzCore)`. `PNC_CoreSurvivorWorldAdapter.refreshGeneratedViews()` calls the same bulk hydrator after generated-view refresh.

`HydrateCoreActors()` iterates the entire Core actor registry. Missing actors are converted through `PNC.Types.NewRecord()` and inserted with `PNC.Registry.AddRecord()`.

A full PNC record initializes Hoomans-specific runtime/social/traits/lifecycle state. `AddRecord()` also schedules/indexes persistent records. This means the server pays Hoomans-side memory/scheduler/spatial/persistence costs for actors that are still abstract in the canonical Core world.

This conflicts with the accepted Compact Survivor World invariant: a canonical abstract actor is not a full Hoomans NPC without a body.

## Finding B — Core appearance and legacy Hoomans serializer disagree

Core-backed record projection assigns the canonical Core appearance envelope to `record.appearance`. Core appearance uses its provider-neutral envelope (`policySchemaVersion`, `policy`, `resolved`, `contract`).

`PNC.Persistence.SerializeRecord()` still treats `record.appearance` as the old Hoomans appearance policy and rejects any table whose `schemaVersion` is not 2. The runtime emitted repeated `PNC persistence produced no payload for record id=...` warnings.

`Registry.FlushDirty()` does not clear a record after a nil serialization result. Therefore a Core-backed record can remain dirty indefinitely and be retried on later flushes.

This must be fixed by ownership cutover, not by converting Core appearance back into a duplicate legacy Hoomans appearance schema.

## Finding C — logical commits synchronously perform broad persistence work

`PersistenceCoordinator.Commit()` saves many repositories, calls `PNC.Registry.FlushDirty()`, then calls `GlobalModData.save()`.

`Registry.FlushDirty()` first runs live-position refresh and `Internal.MarkSnapshotChanges()`. `MarkSnapshotChanges()` walks every persistent Hoomans record and compares compact position/stamina save snapshots.

A small knowledge/social/starting-companion logical mutation can therefore reach broad NPC scanning, dirty serialization and a global ModData flush. Logical state commits and physical persistence flushes are too tightly coupled.

## Finding D — full snapshot is the default for many mutation events

The network path already has a lean periodic presence delta and a combat-damage delta. However many explicit mutation events still use the generic record payload path and fall through to `Network.BuildSnapshot()`.

Examples include attack lifecycle, weapon restore/reload, wounds, treatment, medical-care state, animation scenes and position recovery. The full snapshot rebuilds unrelated domains such as appearance, skills, inventory summaries, wounds/treatment and other detail state.

The accepted portrait replication job remains valid; this is a broader runtime-domain replication issue.

## Finding E — profiler configuration can become part of the workload

Project Hoomans installs deep performance wrappers whenever the profiler `performance` section is enabled. BASIC performance capture still installs the deep wrappers; DETAILED adds richer retention/history behavior.

Normal play must not carry this cost accidentally. A future profiler mode should sample only coarse top-level boundaries unless an explicitly time-bounded deep capture is requested.

## Finding F — cadence/budget tuning is secondary until authority defects are fixed

The world census already shares one zombie-list traversal, body audit and startup cleanup already contain internal throttles, and the scheduler already has LOD/budget concepts. These mechanisms should be preserved and measured.

After lazy promotion and persistence/network fixes, remeasure with profiling OFF before changing follow AI, stamina, world-census cadence, body audits or combat algorithms. Any activity-sensitive cadence improvement must preserve an urgent wake path for threats, materialization, damage and interaction.
