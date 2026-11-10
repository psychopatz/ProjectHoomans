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

## Known residuals

The broad Hoomans harness retains three pre-existing catalog/translation
failures: false-name response disclosure, Tagalog identity translation, and
Tagalog identity/self-reflection catalog use. They are outside Core ownership
and are not migration import failures.

Native Project Zomboid SP/MP behavior is not claimed by these tests.

## Next chunk

**P4-C — user-owned native acceptance handoff.** Run the explicit SP/MP matrix:
restart persistence, optional-mod enable/disable combinations, nearby physical
DTHoomans materialization, DTAbstract abstract traversal, and cross-provider
conversation/trade interaction. Keep the parent goal active until that gate is
verified or explicitly handed back as the remaining user-owned acceptance.
