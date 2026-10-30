# Architecture — Domain & Context Architecture Refactor

## 1. Architectural objective

Project Hoomans should be organized so that a human or coding agent can understand a subsystem's ownership, public contract, dependencies, persistence behavior and failure boundaries without reading unrelated subsystems.

The design is optimized for both runtime containment and Codebase MCP retrieval.

The governing rule is:

> **Fine-grained internally, coarse-grained externally.**

A domain may contain many focused implementation modules. Foreign domains should see a small stable public surface.

## 2. Runtime layers are not domains

Project Zomboid's `shared`, `server` and `client` trees remain deployment/runtime layers.

They do not define business ownership.

For example:

```text
Inventory
├── shared contract/model
├── server authority/persistence
└── client presentation/adapter
```

is one logical Inventory domain spanning runtime layers.

The refactor must not create duplicated client/server “versions” of the same domain rule.

## 3. Domain capsule model

A substantial domain should expose one obvious public entry seam.

Conceptually:

```text
Inventory/
├── PNC_Inventory.lua        public facade / registration seam
├── Commands.lua             mutations requested by consumers
├── Queries.lua              read-only access
├── Events.lua               facts the domain publishes
├── Domain.lua               cohesive rules/state when useful
├── Repository.lua           persistence adapter when useful
├── PZAdapter.lua            engine boundary when useful
├── Diagnostics.lua          optional read-only inspection
└── Internal/...             private implementation only when needed
```

This is a responsibility vocabulary, not a required folder/file checklist.

A small domain can be:

```text
Travel/
├── PNC_Travel.lua
├── Runtime.lua
└── Repository.lua
```

Do not create empty architectural ceremony.

## 4. Public versus internal surface

Foreign domains should begin from the owning domain's public facade or explicit public contract.

Preferred:

```lua
local Inventory = require("PNC/Inventory/PNC_Inventory")

Inventory.Queries.Get(...)
Inventory.Commands.Transfer(...)
```

Avoid:

```lua
require("PNC/Inventory/PNC_Inventory_Mutations_Delta")
require("PNC/Inventory/Internal/...")
```

unless the caller is part of the same domain capsule.

A foreign import into another domain's `Internal` path is an architecture violation unless a documented temporary migration exception exists.

## 5. Commands, queries and events

The vocabulary remains semantic:

- **Command** — request the owning domain to perform a mutation.
- **Query** — ask the owning domain for read-only information.
- **Event** — announce a fact that already happened.

Do not use events as disguised commands.

Do not require all intra-domain calls to go through a bus. Direct functions are preferred within a cohesive domain.

Cross-domain events are appropriate when multiple independent consumers react to a fact and the publisher does not need to know them.

## 6. State ownership

Every important mutable state should have one authoritative owner.

For a migrated state, the architecture should be able to answer:

```text
Owner:
Writers:
Readers:
Persistence:
Networking:
Presentation:
```

Foreign domains do not mutate the owner's tables directly.

If two domains both appear to own the same mutable state, the migration must resolve the ownership ambiguity rather than add another synchronization layer.

## 7. Persistence boundary

Persistence coordinates *when* durable state is saved/loaded. Domain repositories own *what* their schema means.

Target:

```text
Persistence Coordinator
    ├── Inventory.Repository
    ├── Factions.Repository
    ├── Conversation.Repository
    └── Settlement.Repository
```

Persistence must not depend on UI.

Domain deserialization must not trigger presentation behavior.

Repositories should return/accept domain-shaped data through explicit seams rather than reaching into foreign implementation tables.

## 8. Presentation/UI boundary

UI is a consumer.

Target:

```text
Window / Panel
      |
      v
ViewModel / Presenter
      |
      +--> Queries
      +--> Commands
```

UI may own rendering, local interaction state and presentation formatting.

UI should not own authoritative business rules, persistence schemas, server mutation logic, or foreign-domain tables.

Deleting a UI window should not delete the gameplay rule it presents.

## 9. Composition boundary

Composition roots are allowed to know many domains because wiring is their responsibility.

They should increasingly know domain entry/registration seams rather than every implementation provider.

Target:

```text
ServerComposition
    ├── Inventory.RegisterServer(...)
    ├── Conversation.RegisterServer(...)
    ├── Tasking.RegisterServer(...)
    └── Factions.RegisterServer(...)
```

not:

```text
ServerComposition
    ├── Inventory provider A
    ├── Inventory provider B
    ├── Inventory provider C
    ├── Conversation provider A
    └── ...
```

The current PZ load order is behaviorally significant. Registration abstractions must preserve proven ordering until tests establish an equivalent boundary.

## 10. Decomposition policy

Splitting is encouraged when at least one of these is true:

1. the extracted module owns a distinct responsibility;
2. it has independent callers;
3. it is independently testable;
4. it is independently reusable;
5. it crosses a runtime/authority/persistence/engine boundary;
6. it materially improves Codebase MCP retrieval precision for common changes;
7. it isolates generated/declarative data from runtime logic;
8. it reduces a meaningful responsibility-density problem.

Do **not** split solely because a file crossed an arbitrary line threshold.

A large-function finding is triage evidence, not an extraction command.

## 11. Consolidation policy

Merging is encouraged when evidence shows modules:

1. always load together;
2. have one owner;
3. have the same reason to change;
4. have no independent callers;
5. have no independent test seam;
6. mostly exchange private state through artificial `Internal` dependency tables;
7. must all be retrieved by Codebase MCP to understand one operation.

Do **not** merge merely because files are short.

Useful fine-grained modules such as Commands, Queries, Mutations, Repository, Adapter, Presentation or Diagnostics may remain small if their semantic boundary is real.

## 12. MCP context-locality model

The architecture analyzer should gain evidence that reflects agent reasoning cost.

For each domain and representative behavior, record where practical:

- public entry-point count;
- foreign implementation imports;
- cross-domain dependency count;
- dependency depth;
- cycle participation;
- internal require edges;
- files needed for a representative change;
- affected-test discovery size;
- duplicate implementation candidates;
- documentation bytes/lines loaded for current-state understanding.

The primary contextual question is:

> How much code must Codebase MCP retrieve before an agent can safely explain or modify one behavior?

No single score should become a mechanical refactor oracle. The evidence should guide human/agent inspection.

## 13. Representative retrieval probes

P0 should establish a small stable probe set spanning architecture types, for example:

- Inventory: change transfer validation.
- Tasking: change claim/lease eligibility.
- Conversation: change one lifecycle outcome.
- Persistence: add/modify one domain field.
- UI: change presentation for one query result.
- Presence: change one materialization decision.
- Networking: change one command/payload boundary.

A probe records the minimal evidence set an agent needs:

```text
public contract
implementation files
foreign dependencies
affected tests
```

Later phases compare against the baseline.

The goal is not “one file per task.” The goal is a bounded, semantically coherent evidence set.

## 14. Domain contract metadata

Each substantial domain should eventually have a concise machine/human-readable contract, either generated or maintained near the domain.

Minimum information:

```text
Domain:
Owns:
Public commands:
Public queries:
Published events:
Depends on:
Persistence:
Runtime layers:
Must not depend on:
Diagnostics:
```

This should remain short. It is orientation metadata, not another architecture essay.

Where feasible, analyzer output should validate the contract against actual imports.

## 15. Dependency direction

Desired high-level direction:

```text
Presentation/UI
      |
      v
Application / public domain API
      |
      v
Domain rules/state
      |
      +--> owned repository adapter
      +--> engine/platform adapter
```

Foreign domains communicate through public contracts, not implementation internals.

Dependency cycles are not automatically forbidden inside one tightly cohesive capsule, but cross-domain cycles require explicit justification and should normally be removed.

## 16. PsychopatzCore boundary

PsychopatzCore owns reusable mechanisms.

Project Hoomans owns Project Hoomans policy.

Good Core candidates:

- event mechanism;
- generic persistence mechanism;
- registries;
- diagnostics/profiling primitives;
- generic state-machine helpers.

Not Core:

- hunger rules;
- faction hostility rules;
- companion command policy;
- settlement trader behavior;
- Project Hoomans dialogue policy.

Do not solve Project Hoomans modularity by moving domain policy into a new Core monolith.

## 17. Networking/authority boundary

Existing server authority remains authoritative unless a separately evidenced change is required.

Network handlers should translate/validate transport and hand off to the owning domain.

Target:

```text
PZ command callback
      |
      v
bounded command router
      |
      v
Domain command/application seam
```

Transport code should not become the owner of gameplay policy.

Client presentation must not become authority because a refactor makes a client implementation easier to reach.

## 18. Performance

Architecture cleanliness must not add hot-path indirection without evidence.

Preserve:

- bounded scans;
- existing scheduler budgets;
- interest routing;
- cache/revision strategies;
- event cadence;
- no per-frame global census;
- no unbounded pending structures.

Do not replace cheap direct intra-domain calls with broad event traffic merely for architectural symmetry.

## 19. Generated and declarative data

Generated/debug catalogs and large declarative datasets should be classified separately from maintained executable architecture.

They may be split for loading, generation, diffability or MCP retrieval reasons, but their raw byte size must not inflate runtime responsibility scoring.

Generated outputs should have a clear source/generator relationship where practical.

## 20. Compatibility and migration seams

A temporary compatibility facade/alias is acceptable only when:

- it protects an existing public/runtime contract during migration;
- its owner is explicit;
- callers to migrate are identifiable;
- retirement criteria are recorded.

Do not preserve shims indefinitely merely because they once made a phase easier.

At final acceptance, every retained compatibility path must be classified as:

- permanent public compatibility;
- legacy-save migration;
- external integration contract;
- or still-temporary and therefore a failed completion gate.

## 21. File movement policy

Do not begin by moving hundreds of files into prettier folders.

Order:

1. establish public seam;
2. migrate callers;
3. enforce ownership/dependency direction;
4. validate behavior;
5. then move/rename when it improves discoverability.

This minimizes Git churn and makes each migration reversible/evidence-based.

## 22. Documentation architecture

Current truth belongs under this job directory while the migration is active.

The giant historical refactor logs remain history and should not receive per-phase updates.

Root `AGENTS.md` remains durable repository policy only.

At final acceptance, current architecture documentation should be concise enough that an agent does not need the historical migration log to understand the repository.

## 23. Non-goals

This job does not intentionally redesign:

- NPC gameplay behavior;
- semantic dialogue content;
- combat balance;
- faction rules;
- inventory semantics;
- body-binding authority;
- save schemas except where a boundary-preserving migration requires a compatible adapter;
- Steam Workshop packaging/publication.

Any necessary behavior change discovered during refactor must be isolated, evidenced and treated as an explicit bug fix rather than silently folded into architecture cleanup.
