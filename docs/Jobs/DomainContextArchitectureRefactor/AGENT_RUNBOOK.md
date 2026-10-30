# Agent Runbook — Domain & Context Architecture Refactor

## Read order

Read root `AGENTS.md`, then this job in this order:

1. `README.md`
2. `AUDIT.md`
3. `ARCHITECTURE.md`
4. `ROADMAP.md`
5. `ACCEPTANCE.md`
6. `PROGRESS.md` last

Use current code, Codebase MCP graph evidence, tests, runtime artifacts and current analyzer output over historical refactor prose.

The giant historical refactor logs are not required reading unless a specific migration seam needs provenance.

## Parent objective

Implement the complete P0-P8 Domain & Context Architecture Refactor.

The parent objective is the completion boundary.

A phase/chunk passing does not finish the job.

After each accepted chunk:

1. update `PROGRESS.md`;
2. choose the next mandatory documented chunk;
3. continue automatically.

Do not ask for another `/goal` merely because one phase passes.

## Core operating principle

> **Fine-grained internally, coarse-grained externally.**

Do not optimize for minimum file count.

Do not optimize for maximum splitting.

Optimize for bounded ownership and MCP retrieval locality.

## Codebase MCP workflow

Before changing a domain:

1. identify the public entry/facade;
2. query callers and inbound foreign dependencies;
3. query outbound dependencies;
4. query relevant cycle participation;
5. identify affected tests;
6. inspect only the smallest source slice needed to establish the real contract;
7. record the pre-change retrieval/context evidence for the representative probe when applicable.

After changing the domain:

1. repeat caller/dependency queries;
2. rerun affected-test discovery;
3. compare the retrieval set;
4. verify no new foreign deep imports/cycles were introduced;
5. record evidence in `PROGRESS.md`.

Do not load entire domains into context merely because Codebase MCP can find them.

## Split policy

A split is justified when it creates a meaningful responsibility boundary, improves independent testability/reuse, isolates runtime/authority/persistence/engine concerns, separates generated/declarative data, or materially improves MCP retrieval precision.

Do not create a new provider merely to lower line count.

## Consolidation policy

A merge is justified when files always load together, share one owner/change reason, have no independent callers/test seam, or force an agent to retrieve several artificial fragments to understand one operation.

Do not merge useful Commands/Queries/Mutations/Repository/Adapter/Presentation/Diagnostics modules merely because they are short.

## Domain boundary policy

Foreign domains must use public seams.

Treat imports into another domain's `Internal` implementation as migration debt unless explicitly documented.

Do not create a generic service locator to hide dependencies.

Do not event-bus ordinary direct intra-domain calls.

## Runtime-layer policy

`shared`, `server`, and `client` are runtime layers, not separate business domains.

Preserve existing authority.

Do not move server-authoritative policy client-side for convenience.

## Composition policy

Composition roots may know many domains.

They should not progressively own gameplay logic or become a hidden service locator.

Preserve proven PZ require/load order until an equivalent domain registration seam is validated.

## Persistence policy

The persistence coordinator owns lifecycle timing.

Each domain owns the meaning of its persisted schema through a repository/adapter seam.

Do not duplicate canonical state to break a cycle.

Do not make deserialization call UI/presentation behavior.

## UI policy

UI owns presentation and local interaction state.

Move gameplay/persistence/network authority out of UI when encountered.

Preserve UX while changing authority ownership.

## Active Multiplayer Body Binding work

The repository currently contains recent Multiplayer Body Binding Migration commits and remains ahead of `origin/main`.

This architecture refactor must preserve that work.

Before operating on Presence, PresenceSync, BodyLifecycle, Networking or related composition paths:

- inspect the current MultiplayerBodyBindingMigration job;
- preserve M9-M12 authority/lifecycle contracts;
- do not reinterpret a recent body-binding seam as redundant architecture without evidence;
- do not disturb user-owned native acceptance requirements.

## Generated/debug assets

Do not treat giant generated/debug catalogs as ordinary monolith findings.

Verify generator/source ownership first.

If generated data is split, do it for loading, generation, retrieval or maintenance reasons, not because raw bytes look large.

## Validation cadence

After each coherent chunk:

- Codebase MCP callers/dependencies/affected tests;
- focused tests for the owning domain;
- architecture/dependency checks;
- Lua syntax and Kahlua verification where relevant;
- `git diff --check`;
- update `PROGRESS.md`;
- continue automatically.

Before phase acceptance, rerun the relevant retrieval probe(s).

Before parent completion:

- current full Lua suite;
- mandatory focused matrices;
- refreshed architecture/dependency report;
- final P0-vs-final retrieval probe comparison;
- changed-runtime installed-PZ/Kahlua validation according to repository practice;
- static performance/persistence audit;
- final Git status/diff review.

## Git policy

Existing `main` only.

Before edits and commits verify:

- branch and HEAD;
- local status;
- upstream divergence;
- concurrent/unrelated edits.

Preserve unrelated work.

Never reset, destructive-rebase, blind-pull, auto-stash/discard, or create another branch.

Commit coherent accepted chunks.

Do not push/publish unless explicitly authorized by the active user request/repository policy.

## Documentation policy

This job directory owns current refactor truth.

Do not append phase progress to:

- `docs/architecture/PROJECT_HOOMANS_REFACTOR.md`
- `docs/architecture/PROJECT_HOOMANS_MONOLITH_REFACTOR_2026-09.md`
- root `AGENTS.md`

unless a truly durable repository-wide policy changes.

`PROGRESS.md` must remain current-state-only. Replace stale next-chunk text rather than accumulating a diary.

## Stop conditions

Stop only for:

- complete P0-P8 developer-side acceptance;
- genuine unsafe concurrent-work conflict;
- unavailable required tool/runtime capability with no accepted fallback;
- a real architecture/scope conflict requiring user choice;
- an explicit user-owned native acceptance gate after all implementable work is complete.

Do not stop because:

- a phase passed;
- a file was split/merged;
- architecture score improved;
- focused tests passed;
- one cycle was removed.

If evidence disproves a design, revise the smallest owning phase and continue.
