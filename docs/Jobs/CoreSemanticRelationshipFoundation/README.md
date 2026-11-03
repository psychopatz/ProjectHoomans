# Core Semantic & Relationship Foundation

**Parent goal:** make PsychopatzCore the reusable semantic/conversation and canonical shared relationship foundation so Dynamic Trading works richly without Project Hoomans, while Project Hoomans remains an additive adopter for deeper NPC-specific dialogue, social policy, and gameplay actions.

This cross-repository goal spans:

- `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
- `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
- `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`

## Current state

**READY FOR USER LIVE TEST.**

All developer-owned P0-P20 implementation and acceptance gates are complete. The final independent audit reverified the previously failing production boundaries, including:

- canonical Core player identity that cannot be bootstrapped from untrusted mirrors;
- non-destructive DT/Hoomans shared relationship writes;
- semantic-pack lifecycle and production capability isolation;
- standalone Dynamic Trading semantic/story/whereabouts behavior;
- actual excursion-derived origin/destination/current settlement state;
- human-facing settlement presentation without leaking machine IDs;
- FAILED excursion behavior for before-departure, after-departure, visiting, returning, and retry;
- reconstructed trader-record persistence using a fresh backing table and distinct Lua objects;
- WorldKnowledge save/load with fact/evidence continuity.

Developer validation at final audit:

- PsychopatzCore focused identity/social/conversation/semantic checks: PASS.
- Dynamic Trading full suite: `43/43` PASS.
- Project Hoomans full suite: `982/987`; the same five documented pre-existing baseline failures remain.
- Changed P20 Lua syntax: PASS under `luac5.3 -p`.
- `git diff --check`: PASS in all three repositories.

The remaining acceptance is user-owned native Project Zomboid SP/MP testing. No native acceptance or Workshop publication is implied by developer completion.

## Product outcome

Core owns canonical actor/player social identity, generic shared relationship state, reusable conversation/semantic mechanisms, and adopter extension envelopes. Core also physically owns generated semantic assets whose canonical CodeBuilder sources declare `PsychopatzCore`, including the reviewed lexicon and generic common parser patterns.

Dynamic Trading owns commercial/trader policy, factual trader state, and its semantic/story pack. It remains functional without Project Hoomans.

Project Hoomans adopts the same Core actors/relationships, contributes Hoomans-owned social extensions and gameplay actions, and can be added/removed/re-added without destructive relationship migration.

See `ARCHITECTURE.md` for durable ownership and invariants.

## Documents

Read only what the task needs:

1. root `AGENTS.md` — repository-wide durable policy;
2. `README.md` — current job state and navigation;
3. `ARCHITECTURE.md` — stable ownership/invariants;
4. `AGENT_RUNBOOK.md` — durable execution/validation discipline;
5. `ROADMAP.md` — completed phase map;
6. `ACCEPTANCE.md` — final developer gates and native handoff;
7. `PROGRESS.md` — final repository/test evidence;
8. `AUDIT.md` — condensed audit history and final independent verdict.

Accepted Core foundation detail also remains under `psychopatzCore/Docs/npc_foundation/`.
