# Roadmap — Domain & Context Architecture Refactor

**Status:** In progress; see `PROGRESS.md` for the current responsibility.

## Parent objective

Refactor Project Hoomans into an MCP-friendly domain architecture that preserves useful fine-grained modules while making domain ownership, public APIs, dependency direction, persistence, UI, composition and agent retrieval boundaries explicit.

The completed result must reduce redundancy and change-local context without changing established gameplay behavior or SP/MP authority.

The full P0-P8 roadmap is the completion boundary. A phase, analyzer score improvement, file split, file merge, or green focused test is not completion of the parent goal.

After each accepted chunk, update `PROGRESS.md` and continue automatically to the next mandatory chunk.

---

## P0 — Fresh architecture and MCP context baseline

### P0A — Establish fresh repository/graph truth

Required:

- verify branch/HEAD/status/upstream before edits;
- refresh or regenerate available Codebase MCP/code graph and architecture-audit evidence against the current HEAD;
- distinguish maintained runtime code, tooling, tests, generated data and declarative assets;
- capture current domain/import/cycle/composition evidence;
- identify which checked-in analyzer findings are stale, current, false-positive or duplicate manifestations of the same cycle;
- record the current full developer-side test baseline rather than assuming historical 783/978-era counts;
- do not alter production architecture yet.

Gate:

A fresh baseline exists and every later architecture claim can be compared to current evidence rather than the old refactor log.

### P0B — Establish representative retrieval probes

Create a bounded probe matrix covering at least:

- Inventory transfer validation;
- Tasking claim/lease eligibility;
- Conversation lifecycle/outcome;
- one persisted domain field;
- one UI query/result presentation;
- Presence materialization decision;
- one networking command/payload route.

For each probe, use Codebase MCP or the repository graph to record:

- public entry path(s);
- maintained implementation files required to understand the behavior;
- foreign domain dependencies;
- dependency hops/cycle involvement;
- affected tests;
- approximate source lines/bytes in the minimal evidence set.

Gate:

The job has a repeatable “change-local context” baseline. File count alone is not used as the context metric.

---

## P1 — Standard domain contract and architecture enforcement

### P1A — Define domain inventory and ownership map

Required:

- classify the real product domains; do not equate every analyzer folder with a bounded context;
- map each maintained production path to a logical domain and runtime layer;
- identify canonical owners for mutable state;
- classify existing public facades, deep imports and internal seams;
- identify genuine cross-domain cycles versus same-domain implementation cycles.

Gate:

Each high-pressure area has an explicit owner and intended public boundary.

### P1B — Add enforceable dependency rules

Introduce the smallest repository-owned validation needed to detect:

- foreign imports into another domain's `Internal` implementation;
- domain -> UI dependencies;
- UI -> persistence-internal dependencies;
- new cross-domain cycles;
- composition roots depending on leaf implementation files where a public domain entry exists;
- duplicate/competing public authorities.

Do not require every domain to adopt every optional Commands/Queries/Events file.

Gate:

New architecture regressions are machine-detectable without hard-coding arbitrary file-size limits.

### P1C — Add MCP-context diagnostics

Extend repository diagnostics/tooling, or add a small bounded companion report, to preserve the P0 probe evidence and compare it after migrations.

This must not require agents to index the entire repository into prompt context.

Gate:

A refactor can demonstrate whether it improved or worsened retrieval locality.

---

## P2 — Pilot domain migration: Inventory + Supply + Provision

Use Inventory with Supply/Provision as the first proof because it already has clear state authority, cross-domain consumers, persistence/network boundaries and good tests.

### P2A — Freeze public behavior and ownership

Required:

- identify the canonical Inventory public facade;
- map mutations, queries, physical adapter, persistence, equipment and network responsibilities;
- map Supply/Provision's legitimate dependencies on Inventory;
- identify deep imports and duplicate/compatibility seams;
- preserve current inventory atomicity and rollback behavior.

### P2B — Refine the capsule

Allowed operations include both:

- **split** cohesive responsibilities when MCP retrieval/testability improves; and
- **merge** artificial providers that always travel together and add no independent contract.

Foreign consumers must migrate to the public Inventory contract.

Do not perform broad folder moves before the seam is proven.

### P2C — Validate the pilot against context metrics

Required:

- focused Inventory/Supply/Provision tests;
- relevant persistence/network/equipment tests;
- full suite;
- changed runtime Kahlua/static verification as required by repository practice;
- dependency validation;
- P0 retrieval probes rerun for the pilot.

Gate:

Behavior is preserved, foreign implementation imports are reduced/eliminated for the pilot, and the representative Inventory evidence set is measurably more local or no worse with a documented architectural gain.

The accepted pilot becomes the migration template. If it fails to improve local comprehensibility, revise the contract before broader rollout.

---

## P3 — Composition roots depend on domains

### P3A — Domain registration seams

For migrated domains, provide a small runtime registration/composition seam where needed:

```text
Domain.RegisterShared
Domain.RegisterServer
Domain.RegisterClient
```

or an equivalent minimal API appropriate to PZ load semantics.

Do not invent lifecycle ceremony where plain ordered `require` is safer.

### P3B — Reduce leaf knowledge

Migrate server/client/shared composition roots away from direct knowledge of internal providers when an accepted domain entry can preserve the same load order.

Keep engine/order-sensitive initialization explicit.

### P3C — Prove load-order equivalence

Gate:

- composition/bootstrap tests pass;
- current required PZ load order is preserved;
- composition root foreign fan-out is domain-oriented;
- no new cyclic registration mechanism is introduced;
- representative bootstrap context is smaller and easier to navigate.

---

## P4 — Persistence ownership and cycle inversion

Persistence currently participates in high-value cross-domain cycles and therefore becomes a dedicated phase.

### P4A — Classify persistence responsibilities

Map:

- coordinator/lifecycle;
- schema ownership;
- serializers/deserializers;
- migration;
- UI/debug consumers;
- conversation/knowledge dependencies.

### P4B — Move schema meaning behind domain repositories

Target:

```text
Persistence Coordinator
    -> Domain.Repository
```

not foreign implementation mutation.

Do not duplicate state to break a dependency.

### P4C — Remove persistence-driven domain/UI callbacks

Deserialization and persistence operations should return/commit state through owned seams. UI refresh and conversation behavior react later through normal domain/application paths.

Gate:

Real Conversation/Persistence/UI/Knowledge/WorldDiscovery persistence cycles are eliminated or reduced to a separately justified runtime composition relation; save/load behavior and migration compatibility remain intact.

---

## P5 — Conversation and Semantics domain-capsule migration

Conversation and Semantics are the largest context-heavy logical areas and must be migrated deliberately rather than flattened into one facade.

### P5A — Define stable subdomains

At minimum audit whether the durable boundaries are:

```text
Conversation
  Lifecycle
  Authority
  Presentation

Semantics
  NLU / interpretation
  Dialogue policy/flow
  Social
  Response realization
  Observatory/diagnostics
```

Use actual current ownership to confirm or revise this list.

### P5B — Establish public subdomain entry seams

Consumers should not need to search hundreds of files to discover the supported interaction surface.

Preserve the current semantic IR, dialogue authority, generated suggestions, social director, observatory and LLM integration contracts unless evidence requires a compatible migration.

### P5C — Consolidate/split based on retrieval meaning

- keep semantically useful catalogs/providers fine-grained;
- merge provider chains that have no independent change reason;
- separate generated/declarative data from orchestration where useful;
- retire obsolete compatibility aliases after callers migrate.

### P5D — Break cross-domain cycles

Prioritize cycles involving Conversation, UI, Persistence, Knowledge, WorldDiscovery and Colony.

Gate:

Conversation/Semantics have obvious bounded public surfaces, no foreign deep implementation imports in migrated paths, no unresolved unjustified cycles through UI/Persistence, semantic regression suites stay green, and representative conversation probes retrieve materially less unrelated source.

---

## P6 — UI becomes presentation-only

### P6A — Classify UI responsibilities

Separate:

- rendering/widgets;
- local presentation state;
- view models/presenters;
- command submission;
- domain queries;
- debug-only inspection.

Identify authoritative gameplay/persistence/network logic that leaked into UI.

### P6B — Migrate authority out of windows/panels

Move authoritative behavior to the owning domain without changing UI behavior.

UI communicates through domain queries/commands and bounded transport adapters.

### P6C — Remove UI/persistence mixing

Close the analyzer-reported UI/persistence mixing and similar direct schema manipulation.

Gate:

UI may be large and finely decomposed, but it is no longer an owner of authoritative gameplay or persistence state; deleting a window would not remove its business rule.

---

## P7 — Remaining high-value domains and global cycle cleanup

Apply the proven P2-P6 method by pressure and context payoff, not by raw file size.

Mandatory review set includes:

- Colony / Settlement / Production;
- Social;
- Factions;
- Pathing / Presence / PresenceSync;
- Tasking;
- Networking;
- Director;
- Facilities/Needs/World where cycle or ownership evidence remains.

For each selected domain:

1. establish owner/public seam;
2. query callers/dependencies/affected tests with Codebase MCP;
3. split or consolidate only with semantic evidence;
4. migrate foreign callers;
5. remove obsolete migration seams;
6. run focused + required broad validation;
7. rerun relevant retrieval probes/architecture diagnostics.

Gate:

No unresolved high-confidence cross-domain cycle remains in maintained production code without an explicit architecture justification. Foreign-domain `Internal` imports are eliminated from mandatory migrated domains.

---

## P8 — Migration cleanup, documentation compression and final acceptance

### P8A — Compatibility cleanup

Classify every retained compatibility path as:

- permanent public API;
- external integration requirement;
- legacy-save migration;
- or temporary.

Temporary paths must be removed before completion.

### P8B — Documentation cleanup

Required:

- do not append new history to the giant old refactor logs;
- produce/update one concise current architecture navigation document if needed;
- keep domain contracts short;
- keep root `AGENTS.md` durable and lean;
- archive/history stays discoverable through Git and historical documents, not required read order;
- PROGRESS remains current-state-only.

### P8C — Final architecture/context comparison

Compare final state to P0:

- domain/public surfaces;
- foreign deep imports;
- cross-domain cycles;
- composition leaf knowledge;
- representative retrieval probe files/bytes/hops;
- test discovery;
- active documentation context;
- performance/persistence footprint.

File count may rise or fall. It is not a pass/fail target.

### P8D — Final developer acceptance

Required:

- all mandatory architecture gates pass;
- full current test suite passes or any pre-existing baseline failure is proved unchanged and explicitly accepted;
- focused migration matrices pass;
- changed runtime Lua passes required installed-PZ/Kahlua verification;
- dependency/context validation passes;
- no new unbounded hot-path work or persistent duplication;
- `git diff --check` passes;
- clean/coherent worktree after intended commits;
- no Workshop publication;
- native PZ testing is performed only if explicitly assigned.

Gate:

Project Hoomans is domain-oriented, MCP-retrievable, behavior-preserving, and current architecture can be understood without reading the historical 240-chunk migration log.

---

## Completion rule

Do not mark this parent goal complete because:

- one large module was split;
- one provider tree was merged;
- architecture health score increased;
- a cycle count decreased;
- the pilot passed;
- a phase passed;
- file count decreased.

Completion requires the P0-P8 product outcome and the final acceptance in `ACCEPTANCE.md`.

If only optional future cleanup remains, mark the job maintenance-ready rather than inventing more refactor work.
