# Progress

## Completed

- Added the Core server bootstrap hook and wired it into server composition.
- Added Core population provenance bookkeeping for generated plans.
- Added Core `CommitCommunityPlan` and retained `CommitGroupPlan` as public
  generation seams.
- Added Hoomans Core actor hydration into abstract PNC records, including
  identity, position, affiliation, inventory, and lifecycle defaults.
- Routed Hoomans settlement/group generation through Core when the cutover is
  active, with explicit failure handling and a compatibility fallback when
  Core generation is unavailable.
- Preserved Dynamic Trading source behavior; its existing Core group commit
  path now receives the same Core population bookkeeping.
- Added a Dynamic Trading handoff regression proving that a pre-hydrated
  Hoomans record survives `DTAbstract` to `DTHoomans` materialization and
  dematerialization without replacement or temporary-projection metadata.
- Moved SurvivorWorld presence-debug ownership into PsychopatzCore: the
  persisted debug gate, provider registry, session-only original-lease
  rollback, canonical lease synchronization, and bounded diagnostics now have
  one shared implementation.
- Added one gated Core map-debug action that force-materializes the selected
  or tracked actor and releases only a body created by that debug session.
- Added Project Hoomans and DTHoomans provider adapters without duplicating
  the Core debug state; both use their existing physical lifecycle mechanics.
- Repaired startup reconciliation timing and generated-plan faction
  preflight so Core actors are hydrated after PNC registries load and stale
  provider plans are reconciled before commit.

## Evidence

- Core focused smoke tests: 3 passed.
- Hoomans focused regression tests: 8 passed.
- Dynamic Trading focused regression tests: 12 passed.
- Dynamic Trading pre-hydrated-record hotswap regression: passed.
- Core presence coordinator and map-debug smoke tests: passed.
- Hoomans Core provider/generation/authority smoke tests: passed.
- Dynamic Trading provider-runtime and hotswap smoke tests: passed.
- Modified production Lua passes `pz-verify`; modified Lua passes `luac -p`.
- `git diff --check` passes in Core, Hoomans, and Dynamic Trading.

## Pending

- Live new-save and restart validation in Project Zomboid.
- With `PsychopatzCore.SurvivorWorldPresenceOverride` enabled through the
  central Debug Settings UI, use the map action on a fresh-save actor and
  confirm NPC monitor, map hover, and the spawned body share one actor ID.
- Release the debug body and confirm the exact original provider lease is
  restored without touching a normal non-debug body.
- Confirm `DTAbstract` to `DTHoomans` hotswap still materializes the same
  actor without duplicate generation.
- After live evidence, narrow/remove the legacy PNC generation fallback.
