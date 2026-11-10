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

## Evidence

- Core focused smoke tests: 3 passed.
- Hoomans focused regression tests: 8 passed.
- Dynamic Trading focused regression tests: 12 passed.
- Dynamic Trading pre-hydrated-record hotswap regression: passed.
- Modified production Lua passes `pz-verify`; modified Lua passes `luac -p`.
- `git diff --check` passes in Core, Hoomans, and Dynamic Trading.

## Pending

- Live new-save and restart validation in Project Zomboid.
- Confirm NPC monitor and map hover see hydrated Core actors immediately.
- Confirm `DTAbstract` to `DTHoomans` hotswap materializes the same actor
  without duplicate generation.
- After live evidence, narrow/remove the legacy PNC generation fallback.
