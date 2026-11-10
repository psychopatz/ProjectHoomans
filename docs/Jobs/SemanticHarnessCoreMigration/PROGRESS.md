# Progress — Semantic Harness Core Migration

**Status:** IN PROGRESS

**Primary repository:** ProjectHoomans (`main`)

**Participant repositories:** PsychopatzCore (`main`), DynamicTrading (`main`)

## Contract

PsychopatzCore owns provider-neutral protocol, process/session lifecycle,
scenario document mechanics, bounded projections/state, launch metadata,
provider/profile composition, optional-adopter worker loading, reusable
CodeBuilder contracts, and generic tests. Project Hoomans, DTAbstract, and
DTHoomans own adapters, gameplay policy, provider data, optional integrations,
and materialization policy.

Materialization is a provider capability, not a second harness:

- Project Hoomans and DTHoomans may expose `physical` materialization.
- DTAbstract exposes `abstract` operation without requiring physical NPCs.
- All providers use the same Core identity, traversal, conversation, and
  transport contracts.

## Accepted phases

### P0–P2-D — Core contracts and profile bootstrap

Core protocol, worker kernel, scenario/state/session contracts, provider
registry, semantic execution schema, optional repository layout, and profile
loader are established. DynamicTrading declares DTCommon/DTAbstract/DTHoomans
through Core without moving merchant policy into Core.

### P3-A–P3-D — Activity, discovery, launch, and handshake boundaries

Core owns the bounded activity stream, runtime discovery, `WorkerLaunchSpec`,
neutral `SEMANTIC_HARNESS_*` metadata, and shared Lua launch-metadata parsing.
Hoomans process/protocol/session facades and activity duplicates were removed.

Commits include Core `6c7742f` and `c77998c`, plus the corresponding Hoomans
adopter-boundary commits.

### P4-A–P4-D — Test migration and canonical actor adoption

Provider-neutral Hoomans facades/tests were removed after import and focused
behavior gates. Core gained the idempotent actor ensure seam; Hoomans performs
additive actor and SurvivorWorld adoption repair without overwriting canonical
Core records.

### P4-E — Core high-level worker façade

Core owns `semantic_harness.worker.SemanticWorker` for process startup, source
snapshots, working-world state, reset/reload/restart, and generic request,
status, and capability access. Hoomans `LuaSemanticWorker` subclasses it and
retains scenario policy, fixture provenance, save-backed side requests, and
provider-specific operation spokes.

Commits: Core `1e37bc8`; Hoomans `28e7afd`.

### P4-F — Engine projection ownership audit

Core owns offline engine fixtures, health normalization, item-script catalog
parsing, bounded live-profiler projection, and native Build 42 player decoding.
Hoomans retains only thin adapters for PNC identity matching and Project
Hoomans profiler namespaces; its remaining runtime files are save, scenario,
physical-worker, authoring, knowledge, and provider-policy code.

Validation: Core 43 tests passed; Hoomans engine-projection/worker slice 23
tests passed with environment-dependent skips.

Commits: Core `ccecfa5`; Hoomans `329b70bb`.

### P5-A — Cross-provider developer matrix

Core profile/worker/process/registry/layout checks passed 15/15. Hoomans
optional-provider and real-Lua checks passed 8/8. DynamicTrading profile
adapter checks passed 4/4 and its Lua semantic-execution adapter smoke passed.
No native Project Zomboid process was launched.

Commit: Hoomans `0c7296d6`.

### P5-B — Core optional-adopter worker loading

Core now owns `lua/worker/ProviderLoader.lua`. `WorkerLaunchSpec` carries
provider-neutral module-path, module-name, and execution-provider metadata.
The Core worker validates adopter factories, advertises loaded execution
descriptors, and dispatches `SEMANTIC_PROVIDER` operations through the shared
`SemanticExecution` contract. Empty loader metadata preserves the standalone
Core-only worker.

DynamicTrading supplies only `provider_worker_launch_values()`; its actual
DTAbstract and DTHoomans Lua modules load through the Core worker and receive
the same generic operation dispatch. Their materialization modes remain
abstract and physical respectively.

Validation: Core semantic-harness suite 45/45; DynamicTrading provider tests
5/5; Hoomans runtime/provider slice 11/11; DynamicTrading Lua adapter smoke;
direct Lua load checks. Core generic worker files contain no adopter imports.

Commit: pending phase boundary.

## Next chunk

**P5-C — user-owned native SP/MP acceptance.** Exercise restart persistence,
independent Project Hoomans/Dynamic Trading toggles, nearby DTHoomans physical
materialization, DTAbstract abstract traversal, and shared conversation/trade
behavior in real saves. Keep the parent goal active until that gate is verified
or explicitly handed back as the remaining user-owned acceptance.

## Known residuals

The broad Hoomans harness retains three pre-existing catalog/translation
failures: false-name response disclosure, Tagalog identity translation, and
Tagalog identity/self-reflection catalog use. They are outside the Core
migration boundary and are not migration import failures.

The PZ verifier reports `os`/`package` sandbox warnings for the standalone
developer harness Lua worker. Those APIs are already required by the external
JSON-lines harness and are not under `Contents/mods/**/media/`; direct Lua
load/smoke checks pass. Native Project Zomboid SP/MP behavior is not claimed by
developer-side tests.
