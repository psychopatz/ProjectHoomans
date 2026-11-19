# Progress — Lightweight NPC Runtime

## Current state

**PLAN READY — implementation not started.**

The 2026-11-20 new-save audit established a credible runtime/architecture problem set, but the current performance timing was collected with deep PsychopatzProfiler performance wrappers active. The first implementation phase must establish a clean profiler-OFF baseline and make profiler overhead safe before individual AI timings are used for optimization decisions.

Verified source findings that do not depend on timing accuracy:

- server startup and generated-view refresh bulk-call `HydrateCoreActors()`;
- bulk hydration creates full Hoomans records for Core actors that may remain abstract;
- Core actor projection places the Core appearance envelope in `record.appearance`;
- the Hoomans serializer rejects non-`schemaVersion == 2` appearance tables;
- nil record serialization leaves the record dirty;
- `PersistenceCoordinator.Commit()` reaches `Registry.FlushDirty()` and `GlobalModData.save()`;
- `FlushDirty()` performs broad save-snapshot discovery;
- many mutation events still fall back to full `Network.BuildSnapshot()`;
- performance capture installs deep Project Hoomans wrappers while the `performance` section is active.

## Accepted dependencies

Do not reopen:

- Compact Survivor World S0-S11 canonical ownership and compact Core actor persistence;
- NPCReplicationScaling P1-P4 portrait/roster protocol acceptance;
- Core actor lifecycle/provider/GC ownership.

This job corrects Hoomans runtime adoption so it actually obeys those accepted contracts during ordinary play.

## Next Chunk

**L0 — establish a clean profiler-OFF baseline and make deep profiler capture explicit/bounded.**

Immediate evidence required:

1. current source/config path that enables persisted performance capture;
2. tests proving profiler OFF restores/no-ops every ProjectHoomans deep wrapper;
3. identical synthetic/runtime-harness workload with OFF vs current deep capture, clearly separated;
4. coarse top-level sampling design/implementation if needed so later phases can measure server/persistence/network cost without wrapping hot helpers;
5. updated `PROGRESS.md`/`HANDOFF.md` and local accepted-phase commits before L1.
