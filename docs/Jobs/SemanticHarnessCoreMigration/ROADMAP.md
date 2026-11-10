# Roadmap — Semantic Harness Core Migration

**Parent status:** IN PROGRESS

**Completion boundary:** provider-neutral Semantic Harness execution, runtime,
and tests are owned by PsychopatzCore; Project Hoomans, DTAbstract, and
DTHoomans provide adapters and policy only.

## Contract

Core owns the JSON-lines worker contract, process/session lifecycle, scenario
document model, provider/profile registry, generic projections, and reusable
harness tests. Adopters own gameplay policy, production-module registration,
provider data, and optional runtime integrations.

Materialization is a provider capability, not a second harness:

- Project Hoomans and DTHoomans may expose `physical` materialization.
- DTAbstract exposes `abstract` operation without requiring physical NPCs.
- All providers use the same Core identity, traversal, conversation, and
  transport contracts.

## Phases and gates

### P0 — Baseline and ownership contract

Record the current split, verify repository/worktree state, centralize the
protocol boundary, and establish the migration ledger. Gate: Core protocol
tests and Hoomans worker integration pass; no duplicate protocol remains.

### P1 — Core worker kernel

Move provider-neutral transport, worker session, scenario state, bounded
request handling, lifecycle/restart behavior, and generic projections into
Core. Gate: Core worker can run standalone and Hoomans can consume it through a
provider descriptor without importing Hoomans modules by default.

### P2 — Core semantic execution seams

Move generic conversation/session, interaction routing, identity, relationship,
knowledge, and observation interfaces into Core. Keep provider policy behind
capability callbacks. Gate: Hoomans, DTAbstract, and DTHoomans resolve the same
Core interaction contract with their own provider capabilities. P2-C records
the shared execution descriptor and Dynamic Trading's abstract/physical
profile compositions; P2-D connects those profiles to the Core-owned worker.

### P3 — Provider adapters and materialization

Replace Hoomans/DT duplicated worker bootstrap and DynamicTrading-specific
paths with thin adapters. Make physical materialization an optional
Hoomans/DTHoomans capability and abstract simulation the DTAbstract capability.
Gate: providers can be enabled or disabled independently without missing-
module failures.

### P4 — Test migration and legacy removal

Move provider-neutral tests to Core, retain only provider-specific acceptance
tests in adopters, and delete obsolete Hoomans worker/runtime/test duplicates
after import-zero and behavior gates pass. Gate: no stale duplicate ownership,
Core/adopter suites pass, and the migration ledger is current.

#### P4-D — canonical actor and SurvivorWorld adoption repair

Close the runtime migration seam exposed by restart and native diagnostics:
provider-owned Hoomans records must be idempotently adopted into Core actors,
and partially migrated Hoomans factions, locations, communities, and groups
must be repaired into Core in dependency order. The repair remains additive and
must not overwrite records already canonical in Core.

Gate: Core and Hoomans adoption/world-adapter smokes pass; Core has no Hoomans
imports; affiliation and group synchronization no longer depend on a restart.

### P4-E — Core high-level worker façade

Move the provider-neutral Python worker lifecycle, source snapshot, working
world, reset, reload, and restart mechanics into PsychopatzCore. Adopters may
provide normalization, validation, and bounded source-payload hooks, but may
not reimplement Core process/session/state mechanics.

Gate: Core worker façade tests pass; Hoomans worker/runtime contract tests pass;
Hoomans keeps only provider policy and source adapters; Core imports no adopter.

### P4-F — remaining runtime/test ownership audit

Audit every remaining Hoomans `runtime/` and harness test import. Move any
provider-neutral contract or reusable test into Core, retain Hoomans save,
fixture, production-module, authoring, and physical materialization policy,
and remove only proven obsolete duplicates.

Gate: no provider-neutral duplicate remains in Hoomans; Core-only, Hoomans,
DTAbstract, and DTHoomans import/load tests pass independently.

### P5 — Cross-provider acceptance

Run the shared Core matrix for Core-only, Hoomans, DTAbstract, and DTHoomans
profiles, including abstract traversal, nearby physical materialization,
conversation, persistence/restart, and optional-provider loading. Native game
acceptance remains a separate user-owned gate unless explicitly authorized.

#### P5-B — Core optional-adopter worker loading

Close the executable gap between declarative profile metadata and the Core
worker. Core must load adopter-supplied Lua adapter modules only through
neutral launch metadata, validate the shared `SemanticExecution` contract, and
dispatch generic provider operations without naming Project Hoomans or
Dynamic Trading. DTAbstract and DTHoomans must both run through this loader;
their only harness distinction is abstract versus physical materialization.

Gate: Core standalone worker tests pass without adopters; actual DTAbstract and
DTHoomans modules load through the Core worker and receive the same generic
operation dispatch; Hoomans continues to consume Core lifecycle/process
contracts with optional-provider loading disabled or enabled independently.

#### P5-C — native SP/MP acceptance

After the developer-side loader gate, execute
[`P5C_NATIVE_ACCEPTANCE_RUNBOOK.md`](P5C_NATIVE_ACCEPTANCE_RUNBOOK.md) to
exercise restart persistence, independent Project Hoomans/Dynamic Trading
toggles, nearby DTHoomans physical materialization, DTAbstract abstract
traversal, shared conversation/trade behavior, and native multiplayer authority
in real saves. This remains user-owned unless the user explicitly authorizes
native Project Zomboid operation.

## Required phase discipline

Each accepted phase updates `PROGRESS.md` and `HANDOFF.md`, commits exact
phase-owned paths locally in participant repositories first and the primary
Hoomans repository last, and never pushes or publishes Workshop content.
