# Unified Semantic Evidence Architecture

**Status:** DEVELOPER COMPLETE — E0–E7 accepted; READY FOR USER LIVE TEST.

## Parent objective

Standardize Project Hoomans on one modular, bounded, domain-agnostic semantic-context evidence architecture so current and future semantic mechanics can use conversation context, current-day memory, durable memory, salience and pragmatic relations without creating feature-specific memory stores, transcript persistence, or competing dialogue/behavior systems.

The accepted Pragmatic Dialogue Beat Director remains a consumer of this architecture. PsychopatzCore remains generic human-text NLU. Gameplay/domain systems remain authoritative for facts, permissions and mutations.

## Success criterion

A new semantic mechanic can be introduced primarily by registering authoritative domain metadata/adapters plus semantic relations and dialogue content. It must not require a new parser, memory database, context manager, response engine or resolver-specific conditional.

Acceptance must prove this with real adopters and one synthetic future-mechanic fixture whose registration requires no generic-resolver implementation change.

## Core invariants

- one semantic pipeline; no apology/gratitude/promise-specific memory managers;
- no new persistent ModData root for semantic evidence;
- session context stays ephemeral and bounded;
- today's episodic projection reuses compact record.memory.s/t;
- durable meaning reuses owning relationship/conduct/knowledge/event authorities and existing compact projection where appropriate;
- derived contextual relevance and obligations are runtime-only;
- full transcripts, realized sentences, generated choices and reasoning traces are never persisted;
- retention salience, semantic confidence, effective strength/decay, recency, relevance and deterministic priority remain distinct concepts;
- persistent mutation remains server-authoritative;
- generated Dialogue/CodeBuilder artifacts remain downstream output.

## Minimal read order

1. root AGENTS.md;
2. this README.md;
3. ARCHITECTURE.md;
4. AGENT_RUNBOOK.md;
5. ROADMAP.md;
6. HARNESS_ACCEPTANCE.md only when implementing/accepting a gate;
7. PROGRESS.md last.

Read AUDIT.md only when a baseline/ownership question needs revision-specific evidence.

## Relationship to prior jobs

docs/Jobs/PragmaticDialogueBeatDirector owns the accepted conversation/director foundation. Its previously planned contextual U0-U4 expansion is superseded as an execution plan by this job; the apology symptom becomes the first adopter/regression here.

Do not restart accepted C0-C11/L0-L5 work unless new evidence identifies a regression in that owner.

## Current steady state

The unified evidence architecture is now the accepted semantic-context foundation. New mechanics should register domain-owned evidence metadata/adapters and semantic relations, then reuse the existing provider → InteractionContext → PragmaticResolver → InteractionDirector path. The remaining acceptance surface is user-owned native SP/MP verification; implementation history and exact final test evidence live in `PROGRESS.md`.
