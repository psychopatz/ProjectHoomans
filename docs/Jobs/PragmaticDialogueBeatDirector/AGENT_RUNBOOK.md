# Agent Runbook — Pragmatic Interaction Director Recovery

Use this runbook only for the job in this directory.

## Read order

Read root `AGENTS.md`, then:

1. `README.md`;
2. `AUDIT.md`;
3. `ARCHITECTURE.md`;
4. this runbook;
5. `ROADMAP.md`;
6. `HARNESS_ACCEPTANCE.md`;
7. `PROGRESS.md` last.

## Critical recovery rule

The current uncommitted director/Beat Studio implementation is an experimental
prototype.

Do **not**:

- continue the old P7/P8 roadmap;
- commit it wholesale;
- assume green prototype tests mean the architecture is accepted;
- preserve a file/API merely because it already exists.

Start from R0 in `PROGRESS.md`.

## Preserve behavior, not accidental architecture

Protected outcomes include:

- recognized typoed hostility remains understood;
- grounded actor context can change reaction;
- multi-interaction situations can transition naturally;
- state remains bounded;
- the harness can explain decisions.

You may replace the implementation underneath those outcomes.

## Single-authority rules

Never create a second:

- NLU parser;
- conversation/context authority;
- response planner;
- dialogue-content authority;
- translation system;
- gameplay-effect authority.

The interaction director ends at semantic behavior/InteractionPlan.

Speech continues through existing ResponsePlan + Dialogue Content.

## Content rules

All first-party wording is ordinary Dialogue Content.

Do not introduce director-specific content pools or translation buckets.

Structural situation/behavior definitions may reference canonical content IDs.

Use the existing Dialogue Content authoring workflow for text changes.

## Generic interaction rules

The target is not dialogue-only.

All architecture must be evaluated for reuse by:

- player ↔ NPC;
- NPC ↔ NPC;
- multi-NPC scenes;
- emotes;
- ambient flavor;
- gossip;
- world events;
- third-party actors.

If a design only works cleanly for player text conversations, it is not the
accepted abstraction.

## NPC-generated semantics

Do not generate English for an NPC and parse it again internally.

Pass semantic acts/facts/topics directly between interaction participants.

Realize text only for presentation.

## Adapter/provider discipline

Interaction definitions consume bounded semantic projections.

They must not read arbitrary private subsystem state.

Project Hoomans and third-party NPCs may provide different backing data but
should project into common normalized semantics/capabilities.

Unknown stays unknown.

## Performance discipline

No:

- all-NPC/all-beat per-frame loops;
- unbounded nearby-pair combinatorics;
- whole-catalog scans per stimulus;
- unbounded transcripts;
- unbounded scene memory.

Use:

- typed event/stimulus wakeups;
- generated indexes;
- candidate caps;
- scene caps;
- turn caps;
- cooldowns;
- simulation LOD;
- semantic-memory promotion only for meaningful outcomes.

## Source/compiler discipline

Prefer small modular authoring shards.

Avoid giant catch-all `social.json`, `Director.json`, or equivalent files.

Prefer deterministic compiler-side discovery of approved source roots.

Generated runtime still uses explicit deterministic manifests/indexes.

Generated files are never hand-authored.

## Harness discipline

The final workbench is integrated.

Structural interaction editing should link to the existing Dialogue Content
editor for wording.

Python presents and edits bounded source definitions. It must not implement a
parallel interaction engine.

All decision truth comes from the real Lua worker/production providers.

Harness-only overrides must be visibly marked and never count as natural
acceptance.

## Validation cadence

For every accepted recovery slice:

- focused Python tests;
- focused Lua tests;
- real-worker semantic cases;
- negative/ambiguous cases;
- compiler tests where canonical source changes;
- deterministic second generation;
- source/generated diff review;
- `git diff --check`;
- no source-save mutation.

Performance slices must include instrumentation, not only functional tests.

## Git discipline

Use existing `main` only.

The current worktree is intentionally dirty from the prototype.

Before modifying it:

- inspect status;
- preserve unrelated work;
- never reset/rebase/stash/discard uncertain changes;
- stage/commit only coherent accepted recovery slices;
- do not push unless explicitly authorized;
- do not publish Workshop content;
- do not launch native PZ for ordinary developer acceptance.

## Documentation

`PROGRESS.md` is the current truth.

After each accepted R-phase/chunk:

- record actual evidence;
- update the immediate next chunk;
- continue automatically under an autonomous `/goal`.

Do not put job progress into root `AGENTS.md`.
