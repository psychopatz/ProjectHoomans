# P4-E — Core high-level worker façade

## Result

PsychopatzCore now owns the provider-neutral high-level worker lifecycle in
`semantic_harness.worker.SemanticWorker`. The façade owns:

- process construction and startup/cleanup;
- immutable source snapshots and mutable working-world state;
- bounded source installation and adopter payload hooks;
- configure/reset/reload/restart behavior; and
- generic capability/status/request access.

Project Hoomans `LuaSemanticWorker` now subclasses that Core façade. Its
remaining code is an adopter boundary: Hoomans scenario normalization and
validation, fixture provenance, save-backed registry/item side requests, and
the Hoomans conversation/authoring/knowledge/source operation spokes.

## Boundary decision

The presence of `tools/semantic_harness/runtime/` in Project Hoomans is no
longer evidence of a duplicate generic engine. Those modules are intentionally
Hoomans-owned provider policy and source adapters. The generic lifecycle code
removed from `runtime/worker.py` is now tested in Core. No DTCommon, DTAbstract,
or DTHoomans import is introduced into Core.

## Validation

- PsychopatzCore semantic-harness suite: 38 tests passed.
- Project Hoomans worker/runtime contract slice: 16 tests passed.
- Python compilation of the changed Hoomans runtime module passed.
- Native Project Zomboid SP/MP behavior was not launched or claimed.

## Remaining work

The next developer-side slice is an import/ownership audit of the remaining
Hoomans runtime and test package. Move only additional provider-neutral
contracts/tests into Core, keep save and gameplay policy with the adopter, and
delete a Hoomans file only after its callers and focused tests are migrated.
The final gate remains the shared Core/Hoomans/DTAbstract/DTHoomans matrix plus
user-owned native SP/MP acceptance.
