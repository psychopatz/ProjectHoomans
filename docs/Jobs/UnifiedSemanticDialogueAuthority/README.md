# Unified Semantic Dialogue Authority

**Status:** PAUSED / READY TO RESUME.

P0–P10, P11A, and P11B0 are accepted foundation. P11B has completed the
Wellbeing, Needs, Health, and Social Apology wording domains. No agent is
currently running.

## Current steady state

Project Hoomans now uses:

- manifest-backed modular Conversation source shards;
- deterministic CodeBuilder compilation;
- bounded generated runtime shards plus small registry/manifest hubs;
- generated translation bundles by Conversation domain;
- dynamically discovered translation locales with EN as the required fallback;
- pretty, deterministic generated JSON;
- one runtime translation manifest generated from actual locale files.

Generated Lua/JSON is downstream output. Normal implementation work belongs in
CodeBuilder, canonical Conversation shards, and tests.

## Remaining parent goal

Continue P11 only when requested:

1. P11B — finish one first-party wording authority by coherent Conversation
   domain, next candidate: Task Fetch;
2. P11C — refine shard boundaries and retire remaining mixed authoring seams;
3. P11D — canonical Conversation UI Registry;
4. P11E — remove implementation-history taxonomy such as
   `semantic.generated.*` and shorten canonical naming;
5. P11F — one Conversation explorer;
6. P11G — contextual Developer Tools editor;
7. P11H — shared GUI/agent authoring API;
8. P11I — final modular acceptance.

Do not create P12 or expand the parent goal without explicit user approval.

## Minimal read order

For a fresh implementation session read:

1. root `AGENTS.md`;
2. this `README.md`;
3. `ARCHITECTURE.md`;
4. `AGENT_RUNBOOK.md`;
5. `ROADMAP.md`;
6. `PROGRESS.md` **last**.

Completed migration/characterization documents are not part of the normal read
path. Git history is the archive; open historical docs only for a specific
regression investigation.

## Core invariant

> Semantics chooses meaning. Dialogue Content owns first-party wording.
> Conversation UI owns navigation/presentation structure. Gameplay/domain
> systems own facts, eligibility, permissions and effects. Generated artifacts
> are deterministic outputs, never parallel authoring authorities.
