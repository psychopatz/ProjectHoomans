# Progress — Semantic Harness Core Migration

**Status:** IN PROGRESS

**Primary repository:** ProjectHoomans (`main`)

**Participant repositories:** PsychopatzCore (`main`), DynamicTrading (`main`)

## Contract

PsychopatzCore owns provider-neutral protocol, process/session lifecycle,
scenario document mechanics, bounded projections/state, launch metadata,
provider/profile composition, reusable CodeBuilder contracts, and generic
tests. Project Hoomans, DTAbstract, and DTHoomans own adapters, gameplay
policy, provider data, optional integrations, and materialization policy.

Materialization is a capability: Hoomans/DTHoomans may be physical; DTAbstract
is abstract and never requires a physical NPC.

## Accepted phases

### P0–P2-D — Core contracts and profile bootstrap

Core protocol, worker kernel, scenario/state/session contracts, provider
registry, semantic execution schema, optional repository layout, and profile
loader are established. DynamicTrading declares DTCommon/DTAbstract/DTHoomans
through Core without importing Hoomans or moving merchant policy.

### P3-A — activity boundary

Core owns the bounded activity stream. Hoomans callers were migrated through a
compatibility checkpoint before later direct-import cleanup.

### P3-B — runtime discovery

Core owns numeric runtime selection and Lua executable probing. Hoomans retains
only repository/DT-specific discovery and `HarnessConfig` policy.

### P3-C — worker client configuration

Core `WorkerLaunchSpec` consumes validated profile metadata and emits neutral
`SEMANTIC_HARNESS_*` launch metadata. Hoomans constructs that spec with local
repository/runtime/worker policy. Hoomans process/protocol/session facades
were deleted after all callers moved to Core.

Commits: Core `6c7742f`; Hoomans `f0dec26`.

### P3-D — handshake and projection facades

Core owns the shared Lua launch-metadata parser. Core and Hoomans workers
advertise the same profile/provider/materialization envelope. Hoomans activity
and state facades were deleted; scenario policy remains Hoomans-owned.

Commits: Core `c77998c`; Hoomans `a8f71f0` plus handoff metadata `71ab971`.

### P3-E — optional provider matrix

Hoomans advertises DTCommon/DTHoomans only when the optional DT runtime is
discovered. DTAbstract and DTHoomans selections both round-trip through Core
`WorkerLaunchSpec` with abstract/physical modes preserved.

Commits: DynamicTrading `b819197`; Hoomans `f6aab93`.

### P4-A — import-zero cleanup

The remaining pure Hoomans CodeBuilder naming/translation facades and duplicate
generic protocol/activity/session/catalog tests were removed. Hoomans runtime
and Lua files left in place are policy-bearing adapters or physical-worker
integration, not duplicate Core engines.

Commit: Hoomans `5f303cf`.

## P4-B audit result

The ownership inventory is recorded in `P4B_OWNERSHIP_AUDIT.md`:

- Core has 31 Python, 11 Lua, and 12 test modules; it has no adopter imports.
- Hoomans has 19 runtime adapters, 23 policy-bearing CodeBuilder modules, 95
  provider worker Lua modules, 86 UI modules, and 211 adopter tests.
- DynamicTrading has two Python manifest/adapter modules, three Lua adapters,
  and four provider-matrix tests.
- Deleted Hoomans Core-only paths are absent.

Developer-side gates are green: Core 36 tests, Hoomans focused P4-A boundary
suite 26 tests, DynamicTrading matrix 4 tests plus Lua adapter smoke.

## P4-E — Core high-level worker façade

Core now owns `semantic_harness.worker.SemanticWorker` for process startup,
source snapshots, working-world state, reset/reload/restart, and generic
request/status/capability access. Hoomans `LuaSemanticWorker` subclasses it;
Hoomans retains only scenario policy, fixture provenance, save-backed bounded
side requests, and provider-specific operation spokes. Core gained two focused
worker tests and now passes 38 semantic-harness tests. Hoomans' focused worker
runtime slice passed 16 tests. Commits: Core `1e37bc8`; Hoomans `28e7afd`.

## P4-F — engine projection ownership audit

Core now owns offline engine fixtures, health normalization, item-script
catalog parsing, bounded live-profiler projection, and native Build 42 player
decoding. Hoomans retains only thin adapters for PNC identity matching and
Project Hoomans profiler namespaces; its remaining runtime files are
Hoomans-specific save, scenario, physical-worker, authoring, and knowledge
policy. Core's generic projection modules contain no adopter identifiers.
Developer-side gates: Core 43 tests passed; Hoomans engine-projection/worker
slice 23 tests passed with environment-dependent skips. Commit: pending phase
boundary.

## Next chunk

**P5 — cross-provider acceptance.** Run Core-only, Hoomans, DTAbstract, and
DTHoomans import/load and shared-contract matrices, then hand off the native
SP/MP acceptance matrix. Native acceptance remains user-owned.

## Known residuals

The broad Hoomans harness retains three pre-existing catalog/translation
failures: false-name response disclosure, Tagalog identity translation, and
Tagalog identity/self-reflection catalog use. They are outside Core ownership
and are not migration import failures.

Native Project Zomboid SP/MP behavior is not claimed by these tests.

## P4-D result

Core now exposes idempotent `Actors.Ensure`/`Registry:Ensure` for adopter-owned
stable actor IDs. Hoomans adopts new and existing records through that seam,
keeps affiliation mutations synchronized, and performs an additive repair for
partially migrated factions, locations, communities, and groups in dependency
order. Existing canonical Core records are preserved.

Validation: Core actor smoke, Hoomans actor-adoption smoke, SurvivorWorld
adapter smoke, social mutation smoke, semantic diagnostics smoke, Lua syntax,
and PZ Kahlua verification pass. Native console evidence identified the
original `core_actor_not_found` and `survivor_world_group_faction_missing`
failures; a fresh native run is still required.

Commits: pending this phase boundary.

## Next chunk

**P4-C — user-owned native acceptance handoff after P4-D.** Run the explicit SP/MP matrix:
restart persistence, optional-mod enable/disable combinations, nearby physical
DTHoomans materialization, DTAbstract abstract traversal, and cross-provider
conversation/trade interaction. Keep the parent goal active until that gate is
verified or explicitly handed back as the remaining user-owned acceptance.
