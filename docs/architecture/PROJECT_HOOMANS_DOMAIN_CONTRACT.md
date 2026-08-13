# Project Hoomans Domain Contract

This is the migration convention for substantial Project Hoomans domains. It
describes boundaries; it is not mandatory boilerplate. Existing stable modules
adopt it only when their active migration chunk benefits from doing so.

## Domain Definition

A domain is a cohesive owner of gameplay state, policy, or capability. The
`shared`, `server`, and `client` folders are runtime layers, not domain
boundaries. One domain may have code in all three layers.

Before changing a domain, record the following in its entry file or a short
contract document:

- **Owns:** mutable state and invariants controlled by the domain.
- **Writers:** services or handlers allowed to mutate that state.
- **Commands:** requests for authoritative work and their result contract.
- **Queries:** read-only answers supplied to callers.
- **Events:** facts published after successful state transitions.
- **Persistence:** schema, migration, validation, and serialization owner.
- **Network:** authority, validation, request, and replication boundaries.
- **Lifecycle:** registration, start, tick, reset, load, and stop behavior.
- **Diagnostics:** bounded, safe inspection and failure reporting.
- **Dependencies:** public capabilities consumed from other domains.

Omit categories that genuinely do not exist. Never create empty `Commands`,
`Queries`, `Events`, or `Internal` tables merely to match this document.

## Public Entry Point

A substantial multi-file domain should have one canonical public entry point,
normally its existing `PNC.<Domain>` table and established require path. The
entry point may initialize shared state and require focused implementation
modules in explicit order.

External callers use the public domain table. Implementation modules may share
`PNC.<Domain>.Internal`, but other domains must not require or mutate that
internal table without a documented transitional exception.

Keep existing public method names during migration. Commands and queries may be
grouped into `Domain.Commands` and `Domain.Queries` only when the distinction
improves the real API; a stable direct method such as `Inventory.Serialize`
does not need a compatibility-breaking rename.

## PZ/Kahlua Load-Order Constraint

Preserve the existing `00_*Init.lua` bootstrap pattern independently in the
shared, server, and client runtime roots. These files are deliberate
early-loading composition anchors. Do not remove, rename, or replace them
without an explicit compatibility plan and startup validation.

Do not rely on alphabetical filename order to establish dependencies between
ordinary implementation modules. The intended loading chain is:

```text
PZ runtime layer
  → 00_*Init.lua early-loading anchor
  → explicit composition root
  → canonical domain entry points
  → internal modules in deterministic require(...) order
```

The `00_*Init.lua` anchors should remain thin. They may select and invoke the
appropriate composition root, but domain behavior, persistence work, command
handling, and runtime simulation do not belong in the anchors themselves.

Each substantial multi-file domain should similarly expose one canonical entry
file. That entry file explicitly loads its internal modules in dependency order
with ordered `require(...)` calls. Implementation modules must not assume that
their filenames happen to sort before their dependencies.

Any bootstrap or load-order refactor must preserve existing runtime-layer
initialization timing, event-registration timing, optional/lazy integrations,
and nil-safe loading behavior. Validate startup in all three supported modes:

- single-player;
- hosted multiplayer;
- dedicated server.

A bootstrap chunk is incomplete until those startup checks pass or an
environment limitation is recorded honestly in the refactor ledger.

## Commands, Queries, and Events

- A **command** requests work from exactly one responsible handler. It may
  return success, failure, and a reason. Network messages are adapters into a
  command; they are not the domain operation itself.
- A **query** reads data without authoritative mutation. Return copied,
  immutable, or presentation-safe data where exposing owned tables would let a
  caller bypass invariants.
- An **event** announces a fact after it happened. Publishers do not require a
  listener result. Events must not hide request/response control flow or serve
  as RPC.

Only publish semantically useful transitions. Recurring systems must not emit
per-tick event noise when a threshold, dirty flag, revision, or coalesced event
can represent the same fact.

## Runtime Layers and Authority

- **Shared:** contracts, pure rules, serialization-safe types, and code that is
  valid in every runtime in which PZ loads it.
- **Server:** authoritative mutations, validation, persistence coordination,
  simulation, and command handlers.
- **Client:** presentation, local input, view-model state, requests, and
  replicated-state application.

Do not move a module between these roots merely to make a folder look more
domain-oriented. Preserve the current `isClient`/`isServer` guards, the
`00_*Init.lua` anchors, and deterministic ordered requires until
runtime-equivalent behavior is demonstrated.

SP follows the same authority direction as MP. A client-facing action requests
work; the authority validates and mutates; replication or a response updates
presentation. Client UI must not directly mutate canonical NPC, inventory,
faction, settlement, health, or persistence state.

## Persistence

The persistence coordinator owns when a save is committed. A persistent domain
owns its schema, normalization, validation, migration, serialization, and dirty
state. It must preserve existing ModData keys and accepted older schemas unless
an explicit, tested migration changes them.

Save failures at an integrity boundary must remain visible and retryable.
Optional presentation or diagnostics may degrade, but persistence must never
report success after a failed authoritative write.

## Lifecycle and Failure Boundaries

Use protected calls where errors cross a subsystem or PZ runtime boundary:
module lifecycle, event subscribers, network handlers, persistence operations,
and optional integrations. Log or return enough context to diagnose failure;
never silently swallow it.

Do not wrap ordinary helpers in `pcall`. Invariant, authority, and persistence
errors should fail clearly when continuing would pretend that state is valid.

## Performance Contract

Recurring work must have an explicit cadence or bound. Preserve current
scheduler budgets, spatial indexes, dirty tracking, interest sets, queues, and
lazy hydration. Avoid repeated full-state scans, unbounded queues, and new
indirection in hot paths without measured justification.

Pathing, Presence, Combat, Needs, Supply, and Director changes require an
explicit statement of tick/work-budget impact.

## Dependency Direction

A caller depends on another domain's public capability, not its owned storage.
Cross-domain mutation should follow:

```text
caller → command/application service → owning domain mutation
```

Cross-domain reads should follow:

```text
caller → owning domain query → copied/safe result
```

The composition roots may know which modules exist and in what order they
start. They must not absorb gameplay policy. PsychopatzCore may provide generic
mechanisms, but Project Hoomans policy remains in Project Hoomans.

## Migration and Compatibility

For each production chunk:

1. Identify owned state, current writers, callers, entry points, persistence,
   authority, and affected tests.
2. State the public and wire/save contracts that cannot change.
3. Introduce or clarify one boundary while retaining compatibility shims when
   needed.
4. Validate syntax/static rules, affected smoke tests, SP, MP authority, save
   compatibility, load order, and performance in proportion to the change.
5. Remove compatibility paths only in a later chunk with direct evidence that
   no caller still uses them.

Prefer a public entry point plus one to five relevant implementation files for
a normal change. Avoid both domain monoliths and one-function nano-files. Large
file splitting is deliberately deferred until a later dedicated decoupling
pass; early chunks should establish ownership and contracts without structural
churn.

## Pilot Interpretation

The proposed pilot dependency is provisional:

```text
Needs → Provision → Supply query → Inventory command
```

Needs should own need state, Provision provisioning policy/orchestration,
Supply availability/indexing, and Inventory inventory mutation where targeted
source inspection confirms those boundaries. Deviations must be recorded when
the current behavior demonstrates a different owner.
